import SwiftUI
import Combine
import MindMapCore

// MARK: - Mind Map View Model
@available(iOS 16.0, macOS 14.0, *)
@MainActor
public final class MindMapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var mindMap: MindMap?
    @Published public var nodes: [Node] = []
    @Published public var selectedNodeIDs: Set<UUID> = []
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    @Published public var showError: Bool = false
    
    // MARK: - Canvas State
    @Published public var canvasTransform: CGAffineTransform = .identity
    @Published public var zoomScale: CGFloat = 1.0
    @Published public var panOffset: CGSize = .zero
    @Published public var focusedBranchID: UUID?
    @Published public var isFocusMode: Bool = false
    
    // MARK: - Editing State
    @Published public var editingNodeID: UUID?
    @Published public var isEditingText: Bool = false
    
    // MARK: - Dependencies
    private let container: DIContainerProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(container: DIContainerProtocol) {
        self.container = container
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Simple binding without complex Combine operations for now
        // This avoids the macOS availability issues
    }
    
    // MARK: - Mind Map Operations
    public func createNewMindMap(title: String = "新しいマインドマップ") {
        isLoading = true
        
        Task {
            var newMindMap = MindMap(
                id: UUID(),
                title: title,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            // Create root node
            let rootNode = Node(
                id: UUID(),
                text: title,
                position: CGPoint(x: 0, y: 0)
            )
            
            newMindMap.setRootNode(rootNode.id)
            
            await MainActor.run {
                self.mindMap = newMindMap
                self.nodes = [rootNode]
                self.isLoading = false
                self.resetCanvasTransform()
            }
        }
    }
    
    public func loadMindMap(_ mindMap: MindMap) {
        self.mindMap = mindMap
        // In a real implementation, we would load nodes from repository
        // For now, just reset the canvas
        resetCanvasTransform()
    }
    
    // MARK: - Node Operations
    public func selectNode(_ nodeID: UUID) {
        if selectedNodeIDs.contains(nodeID) {
            selectedNodeIDs.remove(nodeID)
        } else {
            selectedNodeIDs.insert(nodeID)
        }
    }
    
    public func startEditingNode(_ nodeID: UUID) {
        editingNodeID = nodeID
        isEditingText = true
    }
    
    public func finishEditingNode() {
        editingNodeID = nil
        isEditingText = false
    }
    
    public func updateNodeText(_ nodeID: UUID, text: String) {
        guard let nodeIndex = nodes.firstIndex(where: { $0.id == nodeID }) else { return }
        
        var updatedNode = nodes[nodeIndex]
        updatedNode.updateText(text)
        
        nodes[nodeIndex] = updatedNode
        
        // Update mindMap version
        mindMap?.incrementVersion()
    }
    
    public func updateNodePosition(_ nodeID: UUID, position: CGPoint) {
        guard let nodeIndex = nodes.firstIndex(where: { $0.id == nodeID }) else { return }
        
        var updatedNode = nodes[nodeIndex]
        updatedNode.updatePosition(position)
        
        nodes[nodeIndex] = updatedNode
        
        // Update mindMap version
        mindMap?.incrementVersion()
    }
    
    // MARK: - Canvas Navigation
    public func resetCanvasTransform() {
        // Simple assignment without animation for now
        canvasTransform = .identity
        zoomScale = 1.0
        panOffset = .zero
    }
    
    public func fitToScreen() {
        guard !nodes.isEmpty else { return }
        
        // Calculate bounding box of all nodes
        let positions = nodes.map { $0.position }
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? 0
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0
        
        let contentWidth = maxX - minX + 200 // Add padding
        let contentHeight = maxY - minY + 200
        
        // Calculate scale to fit screen (assuming screen size)
        let screenWidth: CGFloat = 400 // Will be updated with actual screen size
        let screenHeight: CGFloat = 600
        
        let scaleX = screenWidth / contentWidth
        let scaleY = screenHeight / contentHeight
        let scale = min(scaleX, scaleY, 2.0) // Max zoom of 2x
        
        let centerX = (minX + maxX) / 2
        let centerY = (minY + maxY) / 2
        
        // Simple assignment without animation
        zoomScale = scale
        panOffset = CGSize(
            width: -centerX * scale,
            height: -centerY * scale
        )
        canvasTransform = CGAffineTransform(scaleX: scale, y: scale)
            .translatedBy(x: -centerX, y: -centerY)
    }
    
    public func focusOnBranch(_ nodeID: UUID) {
        focusedBranchID = nodeID
        isFocusMode = true
        
        // Find the node and center on it
        guard let node = nodes.first(where: { $0.id == nodeID }) else { return }
        
        // Simple assignment without animation
        panOffset = CGSize(
            width: -node.position.x * zoomScale,
            height: -node.position.y * zoomScale
        )
    }
    
    public func exitFocusMode() {
        isFocusMode = false
        focusedBranchID = nil
    }
    
    // MARK: - Gesture Handling
    public func handlePanGesture(_ translation: CGSize) {
        panOffset = CGSize(
            width: panOffset.width + translation.width,
            height: panOffset.height + translation.height
        )
        updateCanvasTransform()
    }
    
    public func handleZoomGesture(_ scale: CGFloat) {
        let newScale = max(0.5, min(3.0, zoomScale * scale))
        zoomScale = newScale
        updateCanvasTransform()
    }
    
    private func updateCanvasTransform() {
        canvasTransform = CGAffineTransform(scaleX: zoomScale, y: zoomScale)
            .translatedBy(x: panOffset.width / zoomScale, y: panOffset.height / zoomScale)
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        isLoading = false
    }
}

// MARK: - Helper Extensions
@available(iOS 16.0, macOS 14.0, *)
extension MindMapViewModel {
    public func isNodeInFocusedBranch(_ nodeID: UUID) -> Bool {
        guard isFocusMode, let focusedID = focusedBranchID else { return true }
        
        // For now, simple implementation - in a real app, this would traverse the node hierarchy
        return nodeID == focusedID || isChildOfFocusedBranch(nodeID)
    }
    
    private func isChildOfFocusedBranch(_ nodeID: UUID) -> Bool {
        // Simplified implementation - would need proper hierarchy traversal
        guard let node = nodes.first(where: { $0.id == nodeID }) else { return false }
        return node.parentID == focusedBranchID
    }
}

// MARK: - Private Extensions for MindMap
@available(iOS 16.0, macOS 14.0, *)
private extension MindMap {
    mutating func incrementVersion() {
        // Simple version increment without the private method
        version += 1
        updatedAt = Date()
    }
}