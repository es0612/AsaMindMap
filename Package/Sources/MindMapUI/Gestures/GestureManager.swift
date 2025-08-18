import SwiftUI
import Combine

// MARK: - Gesture State
public enum DragState {
    case inactive
    case dragging(translation: CGSize)
}

// MARK: - Gesture Manager
@available(iOS 16.0, macOS 14.0, *)
@MainActor
public final class GestureManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var magnificationScale: CGFloat = 1.0
    @Published public var lastMagnificationScale: CGFloat = 1.0
    @Published public var panOffset: CGSize = .zero
    @Published public var lastPanOffset: CGSize = .zero
    
    // MARK: - Gesture State
    @GestureState public var dragState: DragState = .inactive
    @Published public var isDraggingNode: Bool = false
    @Published public var draggedNodeID: UUID?
    @Published public var dragStartPosition: CGPoint = .zero
    @Published public var currentDragPosition: CGPoint = .zero
    
    // MARK: - Gesture Configuration
    public var minimumZoomScale: CGFloat = 0.5
    public var maximumZoomScale: CGFloat = 3.0
    public var doubleTapZoomScale: CGFloat = 2.0
    
    // MARK: - Callbacks
    public var onPanChanged: ((CGSize) -> Void)?
    public var onPanEnded: ((CGSize) -> Void)?
    public var onZoomChanged: ((CGFloat) -> Void)?
    public var onZoomEnded: ((CGFloat) -> Void)?
    public var onDoubleTap: (() -> Void)?
    public var onNodeTap: ((UUID) -> Void)?
    public var onNodeDoubleTap: ((UUID) -> Void)?
    public var onNodeLongPress: ((UUID) -> Void)?
    public var onNodeDragStarted: ((UUID, CGPoint) -> Void)?
    public var onNodeDragChanged: ((UUID, CGPoint, CGPoint) -> Void)?
    public var onNodeDragEnded: ((UUID, CGPoint, CGPoint) -> Void)?
    public var onCanvasDoubleTap: ((CGPoint) -> Void)?
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Gesture Factories
    public func makePanGesture() -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { [weak self] value in
                guard let self = self else { return }
                let newOffset = CGSize(
                    width: self.lastPanOffset.width + value.translation.width,
                    height: self.lastPanOffset.height + value.translation.height
                )
                self.panOffset = newOffset
                self.onPanChanged?(newOffset)
            }
            .onEnded { [weak self] value in
                guard let self = self else { return }
                let finalOffset = CGSize(
                    width: self.lastPanOffset.width + value.translation.width,
                    height: self.lastPanOffset.height + value.translation.height
                )
                self.lastPanOffset = finalOffset
                self.panOffset = finalOffset
                self.onPanEnded?(finalOffset)
            }
    }
    
    public func makeMagnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { [weak self] value in
                guard let self = self else { return }
                let newScale = self.lastMagnificationScale * value
                let clampedScale = max(self.minimumZoomScale, min(self.maximumZoomScale, newScale))
                self.magnificationScale = clampedScale
                self.onZoomChanged?(clampedScale)
            }
            .onEnded { [weak self] value in
                guard let self = self else { return }
                let finalScale = self.lastMagnificationScale * value
                let clampedScale = max(self.minimumZoomScale, min(self.maximumZoomScale, finalScale))
                self.lastMagnificationScale = clampedScale
                self.magnificationScale = clampedScale
                self.onZoomEnded?(clampedScale)
            }
    }
    
    public func makeDoubleTapGesture() -> some Gesture {
        TapGesture(count: 2)
            .onEnded { [weak self] _ in
                self?.onDoubleTap?()
            }
    }
    
    public func makeCanvasDoubleTapGesture() -> some Gesture {
        TapGesture(count: 2)
            .onEnded { [weak self] _ in
                self?.onDoubleTap?()
            }
    }
    
    public func makeCombinedCanvasGestures() -> some Gesture {
        SimultaneousGesture(
            makePanGesture(),
            SimultaneousGesture(
                makeMagnificationGesture(),
                makeDoubleTapGesture()
            )
        )
    }
    
    // MARK: - Node Gesture Factories
    public func makeNodeTapGesture(nodeID: UUID) -> some Gesture {
        TapGesture()
            .onEnded { [weak self] _ in
                self?.onNodeTap?(nodeID)
            }
    }
    
    public func makeNodeDoubleTapGesture(nodeID: UUID) -> some Gesture {
        TapGesture(count: 2)
            .onEnded { [weak self] _ in
                self?.onNodeDoubleTap?(nodeID)
            }
    }
    
    public func makeNodeLongPressGesture(nodeID: UUID) -> some Gesture {
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { [weak self] _ in
                self?.onNodeLongPress?(nodeID)
            }
    }
    
    public func makeNodeDragGesture(nodeID: UUID) -> some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { [weak self] value in
                guard let self = self else { return }
                
                if !self.isDraggingNode {
                    // Start dragging
                    self.isDraggingNode = true
                    self.draggedNodeID = nodeID
                    self.dragStartPosition = value.startLocation
                    self.onNodeDragStarted?(nodeID, value.startLocation)
                }
                
                self.currentDragPosition = value.location
                self.onNodeDragChanged?(nodeID, value.startLocation, value.location)
            }
            .onEnded { [weak self] value in
                guard let self = self else { return }
                
                self.isDraggingNode = false
                self.draggedNodeID = nil
                self.onNodeDragEnded?(nodeID, value.startLocation, value.location)
                
                // Reset drag positions
                self.dragStartPosition = .zero
                self.currentDragPosition = .zero
            }
    }
    
    public func makeCombinedNodeGestures(nodeID: UUID) -> some Gesture {
        SimultaneousGesture(
            ExclusiveGesture(
                makeNodeDoubleTapGesture(nodeID: nodeID),
                ExclusiveGesture(
                    makeNodeLongPressGesture(nodeID: nodeID),
                    makeNodeTapGesture(nodeID: nodeID)
                )
            ),
            makeNodeDragGesture(nodeID: nodeID)
        )
    }
    
    // MARK: - Gesture State Management
    public func resetGestureState() {
        magnificationScale = 1.0
        lastMagnificationScale = 1.0
        panOffset = .zero
        lastPanOffset = .zero
    }
    
    public func setZoomScale(_ scale: CGFloat, animated: Bool = true) {
        let clampedScale = max(minimumZoomScale, min(maximumZoomScale, scale))
        
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                magnificationScale = clampedScale
                lastMagnificationScale = clampedScale
            }
        } else {
            magnificationScale = clampedScale
            lastMagnificationScale = clampedScale
        }
    }
    
    public func setPanOffset(_ offset: CGSize, animated: Bool = true) {
        if animated {
            withAnimation(.easeInOut(duration: 0.3)) {
                panOffset = offset
                lastPanOffset = offset
            }
        } else {
            panOffset = offset
            lastPanOffset = offset
        }
    }
    
    // MARK: - Utility Methods
    public func convertPointToCanvas(_ point: CGPoint) -> CGPoint {
        let scaledPoint = CGPoint(
            x: (point.x - panOffset.width) / magnificationScale,
            y: (point.y - panOffset.height) / magnificationScale
        )
        return scaledPoint
    }
    
    public func convertPointFromCanvas(_ point: CGPoint) -> CGPoint {
        let screenPoint = CGPoint(
            x: point.x * magnificationScale + panOffset.width,
            y: point.y * magnificationScale + panOffset.height
        )
        return screenPoint
    }
}

// MARK: - Gesture Extensions
@available(iOS 16.0, macOS 14.0, *)
extension GestureManager {
    
    // MARK: - Animation Helpers
    public func animateToFitContent(contentBounds: CGRect, screenSize: CGSize) {
        let padding: CGFloat = 50
        let availableWidth = screenSize.width - padding * 2
        let availableHeight = screenSize.height - padding * 2
        
        let scaleX = availableWidth / contentBounds.width
        let scaleY = availableHeight / contentBounds.height
        let scale = min(scaleX, scaleY, maximumZoomScale)
        
        let centerX = contentBounds.midX
        let centerY = contentBounds.midY
        
        let targetOffset = CGSize(
            width: screenSize.width / 2 - centerX * scale,
            height: screenSize.height / 2 - centerY * scale
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            setZoomScale(scale, animated: false)
            setPanOffset(targetOffset, animated: false)
        }
    }
    
    public func animateToCenter(on point: CGPoint, screenSize: CGSize) {
        let targetOffset = CGSize(
            width: screenSize.width / 2 - point.x * magnificationScale,
            height: screenSize.height / 2 - point.y * magnificationScale
        )
        
        withAnimation(.easeInOut(duration: 0.4)) {
            setPanOffset(targetOffset, animated: false)
        }
    }
    
    public func animateToFocusOnNode(at position: CGPoint, screenSize: CGSize, zoomScale: CGFloat = 1.5) {
        let clampedScale = max(minimumZoomScale, min(maximumZoomScale, zoomScale))
        
        let targetOffset = CGSize(
            width: screenSize.width / 2 - position.x * clampedScale,
            height: screenSize.height / 2 - position.y * clampedScale
        )
        
        withAnimation(.easeInOut(duration: 0.5)) {
            setZoomScale(clampedScale, animated: false)
            setPanOffset(targetOffset, animated: false)
        }
    }
    
    public func smoothZoomToScale(_ targetScale: CGFloat, around point: CGPoint, screenSize: CGSize) {
        let clampedScale = max(minimumZoomScale, min(maximumZoomScale, targetScale))
        
        // Calculate the offset to keep the point under the user's finger/cursor
        let currentPointInScreen = CGPoint(
            x: point.x * magnificationScale + panOffset.width,
            y: point.y * magnificationScale + panOffset.height
        )
        
        let newOffset = CGSize(
            width: currentPointInScreen.x - point.x * clampedScale,
            height: currentPointInScreen.y - point.y * clampedScale
        )
        
        withAnimation(.interactiveSpring(response: 0.3, dampingFraction: 0.8)) {
            setZoomScale(clampedScale, animated: false)
            setPanOffset(newOffset, animated: false)
        }
    }
}