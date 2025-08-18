import SwiftUI
import MindMapCore
import Combine

// MARK: - Node Selection Manager
@available(iOS 16.0, macOS 14.0, *)
@MainActor
public final class NodeSelectionManager: ObservableObject {
    
    // MARK: - Selection State
    @Published public var selectedNodeIDs: Set<UUID> = []
    @Published public var editingNodeID: UUID?
    @Published public var multiSelectMode: Bool = false
    @Published public var selectionBounds: CGRect = .zero
    
    // MARK: - Editing State
    @Published public var isEditingText: Bool = false
    @Published public var editingText: String = ""
    @Published public var showContextMenu: Bool = false
    @Published public var contextMenuPosition: CGPoint = .zero
    
    // MARK: - Visual Feedback
    @Published public var selectionAnimation: Bool = false
    @Published public var highlightedNodeID: UUID?
    @Published public var dragPreviewPosition: CGPoint = .zero
    @Published public var showDragPreview: Bool = false
    @Published public var connectionPreviewStart: CGPoint = .zero
    @Published public var connectionPreviewEnd: CGPoint = .zero
    @Published public var showConnectionPreview: Bool = false
    
    // MARK: - Callbacks
    public var onSelectionChanged: ((Set<UUID>) -> Void)?
    public var onEditingStarted: ((UUID) -> Void)?
    public var onEditingEnded: ((UUID, String) -> Void)?
    public var onNodeAction: ((NodeAction, Set<UUID>) -> Void)?
    public var onNodeDragStarted: ((UUID, CGPoint) -> Void)?
    public var onNodeDragChanged: ((UUID, CGPoint, CGPoint) -> Void)?
    public var onNodeDragEnded: ((UUID, CGPoint, CGPoint) -> Void)?
    public var onConnectionDragStarted: ((UUID, CGPoint) -> Void)?
    public var onConnectionDragChanged: ((UUID, CGPoint, CGPoint) -> Void)?
    public var onConnectionDragEnded: ((UUID, CGPoint, CGPoint, UUID?) -> Void)?
    
    // MARK: - Node Actions
    public enum NodeAction: Equatable {
        case delete
        case duplicate
        case copy
        case cut
        case paste
        case addChild
        case addSibling
        case convertToTask
        case addTag
        case addMedia
        case changeColor
        case changeFont
        case group
        case ungroup
    }
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Selection Methods
    public func selectNode(_ nodeID: UUID, addToSelection: Bool = false) {
        if addToSelection && multiSelectMode {
            selectedNodeIDs.insert(nodeID)
        } else {
            selectedNodeIDs = [nodeID]
        }
        
        updateSelectionBounds()
        triggerSelectionAnimation()
        onSelectionChanged?(selectedNodeIDs)
    }
    
    public func deselectNode(_ nodeID: UUID) {
        selectedNodeIDs.remove(nodeID)
        updateSelectionBounds()
        onSelectionChanged?(selectedNodeIDs)
    }
    
    public func selectMultipleNodes(_ nodeIDs: Set<UUID>) {
        selectedNodeIDs = nodeIDs
        updateSelectionBounds()
        triggerSelectionAnimation()
        onSelectionChanged?(selectedNodeIDs)
    }
    
    public func clearSelection() {
        selectedNodeIDs.removeAll()
        selectionBounds = .zero
        onSelectionChanged?(selectedNodeIDs)
    }
    
    public func selectAll(nodes: [Node]) {
        selectedNodeIDs = Set(nodes.map { $0.id })
        updateSelectionBounds()
        onSelectionChanged?(selectedNodeIDs)
    }
    
    // MARK: - Multi-Selection
    public func enableMultiSelectMode() {
        multiSelectMode = true
    }
    
    public func disableMultiSelectMode() {
        multiSelectMode = false
        if selectedNodeIDs.count > 1 {
            // Keep only the first selected node
            if let firstNode = selectedNodeIDs.first {
                selectedNodeIDs = [firstNode]
                updateSelectionBounds()
                onSelectionChanged?(selectedNodeIDs)
            }
        }
    }
    
    public func toggleMultiSelectMode() {
        if multiSelectMode {
            disableMultiSelectMode()
        } else {
            enableMultiSelectMode()
        }
    }
    
    // MARK: - Rectangle Selection
    public func selectNodesInRect(_ rect: CGRect, nodes: [Node]) {
        let nodesInRect = nodes.filter { node in
            rect.contains(node.position)
        }
        
        let nodeIDs = Set(nodesInRect.map { $0.id })
        
        if multiSelectMode {
            selectedNodeIDs.formUnion(nodeIDs)
        } else {
            selectedNodeIDs = nodeIDs
        }
        
        updateSelectionBounds()
        onSelectionChanged?(selectedNodeIDs)
    }
    
    // MARK: - Text Editing
    public func startEditingNode(_ nodeID: UUID, currentText: String = "") {
        editingNodeID = nodeID
        editingText = currentText
        isEditingText = true
        onEditingStarted?(nodeID)
    }
    
    public func endEditingNode() {
        guard let nodeID = editingNodeID else { return }
        
        isEditingText = false
        onEditingEnded?(nodeID, editingText)
        
        editingNodeID = nil
        editingText = ""
    }
    
    public func cancelEditing() {
        isEditingText = false
        editingNodeID = nil
        editingText = ""
    }
    
    // MARK: - Context Menu
    public func showContextMenu(at position: CGPoint, for nodeIDs: Set<UUID>? = nil) {
        if let nodeIDs = nodeIDs {
            selectedNodeIDs = nodeIDs
        }
        
        contextMenuPosition = position
        showContextMenu = true
    }
    
    public func hideContextMenu() {
        showContextMenu = false
    }
    
    // MARK: - Node Actions
    public func performAction(_ action: NodeAction) {
        guard !selectedNodeIDs.isEmpty else { return }
        onNodeAction?(action, selectedNodeIDs)
    }
    
    public func canPerformAction(_ action: NodeAction) -> Bool {
        switch action {
        case .delete, .duplicate, .copy, .cut:
            return !selectedNodeIDs.isEmpty
        case .paste:
            return true // Always available if clipboard has content
        case .addChild, .addSibling:
            return selectedNodeIDs.count == 1
        case .convertToTask, .addTag, .addMedia, .changeColor, .changeFont:
            return !selectedNodeIDs.isEmpty
        case .group:
            return selectedNodeIDs.count > 1
        case .ungroup:
            return selectedNodeIDs.count == 1 // Check if selected node is a group
        }
    }
    
    // MARK: - Visual Feedback
    private func triggerSelectionAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            selectionAnimation.toggle()
        }
    }
    
    public func highlightNode(_ nodeID: UUID, duration: TimeInterval = 1.0) {
        highlightedNodeID = nodeID
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.highlightedNodeID = nil
        }
    }
    
    // MARK: - Drag Preview Management
    public func startDragPreview(at position: CGPoint) {
        dragPreviewPosition = position
        showDragPreview = true
    }
    
    public func updateDragPreview(to position: CGPoint) {
        dragPreviewPosition = position
    }
    
    public func endDragPreview() {
        showDragPreview = false
        dragPreviewPosition = .zero
    }
    
    // MARK: - Connection Preview Management
    public func startConnectionPreview(from startPoint: CGPoint) {
        connectionPreviewStart = startPoint
        connectionPreviewEnd = startPoint
        showConnectionPreview = true
    }
    
    public func updateConnectionPreview(to endPoint: CGPoint) {
        connectionPreviewEnd = endPoint
    }
    
    public func endConnectionPreview() {
        showConnectionPreview = false
        connectionPreviewStart = .zero
        connectionPreviewEnd = .zero
    }
    
    // MARK: - Selection Bounds
    private func updateSelectionBounds() {
        // This would be implemented with actual node positions
        // For now, we'll set a placeholder
        selectionBounds = .zero
    }
    
    public func updateSelectionBounds(with nodes: [Node]) {
        guard !selectedNodeIDs.isEmpty else {
            selectionBounds = .zero
            return
        }
        
        let selectedNodes = nodes.filter { selectedNodeIDs.contains($0.id) }
        guard !selectedNodes.isEmpty else {
            selectionBounds = .zero
            return
        }
        
        let positions = selectedNodes.map { $0.position }
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? 0
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0
        
        // Add padding around selection
        let padding: CGFloat = 20
        selectionBounds = CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + padding * 2,
            height: maxY - minY + padding * 2
        )
    }
    
    // MARK: - Keyboard Shortcuts
    public func handleKeyboardShortcut(_ key: String, modifiers: KeyboardModifiers) -> Bool {
        switch (key.lowercased(), modifiers) {
        case ("a", .command):
            // Select All - handled by parent
            return true
        case ("c", .command):
            performAction(.copy)
            return true
        case ("x", .command):
            performAction(.cut)
            return true
        case ("v", .command):
            performAction(.paste)
            return true
        case ("d", .command):
            performAction(.duplicate)
            return true
        case ("delete", []), ("backspace", []):
            performAction(.delete)
            return true
        case ("escape", []):
            if isEditingText {
                cancelEditing()
            } else {
                clearSelection()
            }
            return true
        case ("return", []), ("enter", []):
            if selectedNodeIDs.count == 1, let nodeID = selectedNodeIDs.first {
                startEditingNode(nodeID)
            }
            return true
        case ("tab", []):
            performAction(.addChild)
            return true
        case ("tab", .shift):
            performAction(.addSibling)
            return true
        default:
            return false
        }
    }
}

// MARK: - Selection Gesture Recognizer
@available(iOS 16.0, macOS 14.0, *)
public struct SelectionGestureRecognizer: ViewModifier {
    @ObservedObject var selectionManager: NodeSelectionManager
    let nodes: [Node]
    
    @State private var dragStart: CGPoint = .zero
    @State private var dragCurrent: CGPoint = .zero
    @State private var isDragging: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 10)
                    .onChanged { value in
                        if !isDragging {
                            dragStart = value.startLocation
                            isDragging = true
                        }
                        dragCurrent = value.location
                        
                        // Create selection rectangle
                        let selectionRect = CGRect(
                            x: min(dragStart.x, dragCurrent.x),
                            y: min(dragStart.y, dragCurrent.y),
                            width: abs(dragCurrent.x - dragStart.x),
                            height: abs(dragCurrent.y - dragStart.y)
                        )
                        
                        // Select nodes in rectangle
                        selectionManager.selectNodesInRect(selectionRect, nodes: nodes)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .overlay(
                // Selection rectangle overlay
                isDragging ? Rectangle()
                    .stroke(Color.blue, lineWidth: 1)
                    .background(Color.blue.opacity(0.1))
                    .frame(
                        width: abs(dragCurrent.x - dragStart.x),
                        height: abs(dragCurrent.y - dragStart.y)
                    )
                    .position(
                        x: (dragStart.x + dragCurrent.x) / 2,
                        y: (dragStart.y + dragCurrent.y) / 2
                    ) : nil
            )
    }
}

// MARK: - View Extension
@available(iOS 16.0, macOS 14.0, *)
extension View {
    public func selectionGesture(
        selectionManager: NodeSelectionManager,
        nodes: [Node]
    ) -> some View {
        self.modifier(SelectionGestureRecognizer(
            selectionManager: selectionManager,
            nodes: nodes
        ))
    }
}