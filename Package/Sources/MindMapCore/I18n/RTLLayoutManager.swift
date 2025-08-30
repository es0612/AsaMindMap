import Foundation
import CoreGraphics

// MARK: - RTL Layout Manager

public class RTLLayoutManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var currentLayoutDirection: LayoutDirection = .leftToRight
    
    private let rtlLanguages: Set<SupportedLanguage> = [.arabic, .hebrew]
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public Methods
    
    public func isRTLLanguage(_ language: SupportedLanguage) -> Bool {
        return rtlLanguages.contains(language)
    }
    
    public func layoutDirection(for language: SupportedLanguage) -> LayoutDirection {
        return isRTLLanguage(language) ? .rightToLeft : .leftToRight
    }
    
    public func setLayoutDirection(for language: SupportedLanguage) {
        currentLayoutDirection = layoutDirection(for: language)
    }
    
    public func adjustMindMapLayout(_ mindMap: MindMap, for direction: LayoutDirection) -> MindMap {
        guard direction == .rightToLeft else { return mindMap }
        
        // For the current architecture, MindMap only stores node IDs
        // RTL layout adjustment would need to be handled at the presentation layer
        // where actual Node objects with positions are available
        // For now, return the mindMap unchanged as the layout adjustment
        // will be handled by the UI layer
        return mindMap
    }
    
    public func textAlignment(for direction: LayoutDirection) -> TextAlignment {
        switch direction {
        case .leftToRight:
            return .leading
        case .rightToLeft:
            return .trailing
        }
    }
    
    public func transformPointForRTL(_ point: CGPoint, containerWidth: CGFloat) -> CGPoint {
        return CGPoint(x: containerWidth - point.x, y: point.y)
    }
    
    public func connectionDirection(from parent: Node, to child: Node, layout: LayoutDirection) -> ConnectionDirection {
        let dx = child.position.x - parent.position.x
        let dy = child.position.y - parent.position.y
        
        if layout == .rightToLeft {
            // Reverse horizontal direction for RTL
            if abs(dx) > abs(dy) {
                return dx > 0 ? .leftToRight : .leftToRight
            } else {
                return dx > 0 && dy > 0 ? .topLeftToBottomRight : .topRightToBottomLeft
            }
        } else {
            // Standard LTR logic
            if abs(dx) > abs(dy) {
                return .leftToRight
            } else if dy > 0 {
                return dx > 0 ? .topLeftToBottomRight : .topRightToBottomLeft
            } else {
                return .topToBottom
            }
        }
    }
    
    public func adjustSwipeDirection(_ direction: SwipeDirection, for layout: LayoutDirection) -> SwipeDirection {
        guard layout == .rightToLeft else { return direction }
        
        switch direction {
        case .left:
            return .right
        case .right:
            return .left
        case .up, .down:
            return direction
        }
    }
    
    public func adjustMenuPosition(_ touchPoint: CGPoint, for direction: LayoutDirection) -> CGPoint {
        let offset: CGFloat = 10
        
        switch direction {
        case .leftToRight:
            return CGPoint(x: touchPoint.x + offset, y: touchPoint.y)
        case .rightToLeft:
            return CGPoint(x: touchPoint.x - offset, y: touchPoint.y)
        }
    }
}