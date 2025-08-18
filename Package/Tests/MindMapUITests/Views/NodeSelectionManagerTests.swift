import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - Node Selection Manager Tests
@MainActor
struct NodeSelectionManagerTests {
    
    // MARK: - Initialization Tests
    
    @Test("NodeSelectionManagerの初期化が正しく行われる")
    func testInitialization() {
        // Given & When
        let selectionManager = NodeSelectionManager()
        
        // Then
        #expect(selectionManager.selectedNodeIDs.isEmpty)
        #expect(selectionManager.editingNodeID == nil)
        #expect(selectionManager.multiSelectMode == false)
        #expect(selectionManager.selectionBounds == .zero)
        #expect(selectionManager.isEditingText == false)
        #expect(selectionManager.editingText.isEmpty)
        #expect(selectionManager.showContextMenu == false)
        #expect(selectionManager.contextMenuPosition == .zero)
        #expect(selectionManager.selectionAnimation == false)
        #expect(selectionManager.highlightedNodeID == nil)
    }
    
    // MARK: - Single Selection Tests
    
    @Test("単一ノードの選択が正常に動作する")
    func testSelectSingleNode() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID = UUID()
        var callbackNodeIDs: Set<UUID>?
        
        selectionManager.onSelectionChanged = { nodeIDs in
            callbackNodeIDs = nodeIDs
        }
        
        // When
        selectionManager.selectNode(nodeID)
        
        // Then
        #expect(selectionManager.selectedNodeIDs == [nodeID])
        #expect(callbackNodeIDs == [nodeID])
    }
    
    @Test("ノードの選択解除が正常に動作する")
    func testDeselectNode() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID1 = UUID()
        let nodeID2 = UUID()
        selectionManager.selectMultipleNodes([nodeID1, nodeID2])
        
        var callbackNodeIDs: Set<UUID>?
        selectionManager.onSelectionChanged = { nodeIDs in
            callbackNodeIDs = nodeIDs
        }
        
        // When
        selectionManager.deselectNode(nodeID1)
        
        // Then
        #expect(selectionManager.selectedNodeIDs == [nodeID2])
        #expect(callbackNodeIDs == [nodeID2])
    }
    
    @Test("全選択解除が正常に動作する")
    func testClearSelection() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID1 = UUID()
        let nodeID2 = UUID()
        selectionManager.selectMultipleNodes([nodeID1, nodeID2])
        
        var callbackNodeIDs: Set<UUID>?
        selectionManager.onSelectionChanged = { nodeIDs in
            callbackNodeIDs = nodeIDs
        }
        
        // When
        selectionManager.clearSelection()
        
        // Then
        #expect(selectionManager.selectedNodeIDs.isEmpty)
        #expect(selectionManager.selectionBounds == .zero)
        #expect(callbackNodeIDs?.isEmpty == true)
    }
    
    // MARK: - Multi-Selection Tests
    
    @Test("複数選択モードの有効化が正常に動作する")
    func testEnableMultiSelectMode() {
        // Given
        let selectionManager = NodeSelectionManager()
        
        // When
        selectionManager.enableMultiSelectMode()
        
        // Then
        #expect(selectionManager.multiSelectMode == true)
    }
    
    @Test("複数選択モードの無効化が正常に動作する")
    func testDisableMultiSelectMode() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID1 = UUID()
        let nodeID2 = UUID()
        let nodeID3 = UUID()
        
        selectionManager.enableMultiSelectMode()
        selectionManager.selectMultipleNodes([nodeID1, nodeID2, nodeID3])
        
        var callbackNodeIDs: Set<UUID>?
        selectionManager.onSelectionChanged = { nodeIDs in
            callbackNodeIDs = nodeIDs
        }
        
        // When
        selectionManager.disableMultiSelectMode()
        
        // Then
        #expect(selectionManager.multiSelectMode == false)
        #expect(selectionManager.selectedNodeIDs.count == 1)
        #expect(callbackNodeIDs?.count == 1)
    }
    
    @Test("複数選択モードでの追加選択が正常に動作する")
    func testSelectNodeWithAddToSelection() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID1 = UUID()
        let nodeID2 = UUID()
        
        selectionManager.enableMultiSelectMode()
        selectionManager.selectNode(nodeID1)
        
        // When
        selectionManager.selectNode(nodeID2, addToSelection: true)
        
        // Then
        #expect(selectionManager.selectedNodeIDs.contains(nodeID1))
        #expect(selectionManager.selectedNodeIDs.contains(nodeID2))
        #expect(selectionManager.selectedNodeIDs.count == 2)
    }
    
    @Test("複数ノードの一括選択が正常に動作する")
    func testSelectMultipleNodes() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeIDs = Set([UUID(), UUID(), UUID()])
        
        var callbackNodeIDs: Set<UUID>?
        selectionManager.onSelectionChanged = { nodeIDs in
            callbackNodeIDs = nodeIDs
        }
        
        // When
        selectionManager.selectMultipleNodes(nodeIDs)
        
        // Then
        #expect(selectionManager.selectedNodeIDs == nodeIDs)
        #expect(callbackNodeIDs == nodeIDs)
    }
    
    @Test("全ノード選択が正常に動作する")
    func testSelectAllNodes() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodes = [
            Node(id: UUID(), text: "Node 1", position: CGPoint(x: 0, y: 0)),
            Node(id: UUID(), text: "Node 2", position: CGPoint(x: 100, y: 0)),
            Node(id: UUID(), text: "Node 3", position: CGPoint(x: 200, y: 0))
        ]
        
        var callbackNodeIDs: Set<UUID>?
        selectionManager.onSelectionChanged = { nodeIDs in
            callbackNodeIDs = nodeIDs
        }
        
        // When
        selectionManager.selectAll(nodes: nodes)
        
        // Then
        let expectedIDs = Set(nodes.map { $0.id })
        #expect(selectionManager.selectedNodeIDs == expectedIDs)
        #expect(callbackNodeIDs == expectedIDs)
    }
    
    // MARK: - Rectangle Selection Tests
    
    @Test("矩形選択が正常に動作する")
    func testSelectNodesInRect() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodes = [
            Node(id: UUID(), text: "Node 1", position: CGPoint(x: 50, y: 50)),   // 矩形内
            Node(id: UUID(), text: "Node 2", position: CGPoint(x: 150, y: 150)), // 矩形内
            Node(id: UUID(), text: "Node 3", position: CGPoint(x: 250, y: 250))  // 矩形外
        ]
        
        let selectionRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        
        // When
        selectionManager.selectNodesInRect(selectionRect, nodes: nodes)
        
        // Then
        #expect(selectionManager.selectedNodeIDs.count == 2)
        #expect(selectionManager.selectedNodeIDs.contains(nodes[0].id))
        #expect(selectionManager.selectedNodeIDs.contains(nodes[1].id))
        #expect(!selectionManager.selectedNodeIDs.contains(nodes[2].id))
    }
    
    @Test("複数選択モードでの矩形選択が正常に動作する")
    func testSelectNodesInRectMultiSelectMode() {
        // Given
        let selectionManager = NodeSelectionManager()
        let existingNodeID = UUID()
        let nodes = [
            Node(id: UUID(), text: "Node 1", position: CGPoint(x: 50, y: 50)),
            Node(id: UUID(), text: "Node 2", position: CGPoint(x: 150, y: 150))
        ]
        
        selectionManager.enableMultiSelectMode()
        selectionManager.selectNode(existingNodeID)
        
        let selectionRect = CGRect(x: 0, y: 0, width: 200, height: 200)
        
        // When
        selectionManager.selectNodesInRect(selectionRect, nodes: nodes)
        
        // Then
        #expect(selectionManager.selectedNodeIDs.count == 3)
        #expect(selectionManager.selectedNodeIDs.contains(existingNodeID))
        #expect(selectionManager.selectedNodeIDs.contains(nodes[0].id))
        #expect(selectionManager.selectedNodeIDs.contains(nodes[1].id))
    }
    
    // MARK: - Text Editing Tests
    
    @Test("テキスト編集の開始が正常に動作する")
    func testStartEditingNode() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID = UUID()
        let initialText = "Initial Text"
        
        var editingStartedNodeID: UUID?
        selectionManager.onEditingStarted = { nodeID in
            editingStartedNodeID = nodeID
        }
        
        // When
        selectionManager.startEditingNode(nodeID, currentText: initialText)
        
        // Then
        #expect(selectionManager.editingNodeID == nodeID)
        #expect(selectionManager.editingText == initialText)
        #expect(selectionManager.isEditingText == true)
        #expect(editingStartedNodeID == nodeID)
    }
    
    @Test("テキスト編集の終了が正常に動作する")
    func testEndEditingNode() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID = UUID()
        let editedText = "Edited Text"
        
        selectionManager.startEditingNode(nodeID, currentText: "Original")
        selectionManager.editingText = editedText
        
        var editingEndedNodeID: UUID?
        var editingEndedText: String?
        selectionManager.onEditingEnded = { nodeID, text in
            editingEndedNodeID = nodeID
            editingEndedText = text
        }
        
        // When
        selectionManager.endEditingNode()
        
        // Then
        #expect(selectionManager.isEditingText == false)
        #expect(selectionManager.editingNodeID == nil)
        #expect(selectionManager.editingText.isEmpty)
        #expect(editingEndedNodeID == nodeID)
        #expect(editingEndedText == editedText)
    }
    
    @Test("テキスト編集のキャンセルが正常に動作する")
    func testCancelEditing() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID = UUID()
        
        selectionManager.startEditingNode(nodeID, currentText: "Original")
        selectionManager.editingText = "Modified"
        
        // When
        selectionManager.cancelEditing()
        
        // Then
        #expect(selectionManager.isEditingText == false)
        #expect(selectionManager.editingNodeID == nil)
        #expect(selectionManager.editingText.isEmpty)
    }
    
    // MARK: - Context Menu Tests
    
    @Test("コンテキストメニューの表示が正常に動作する")
    func testShowContextMenu() {
        // Given
        let selectionManager = NodeSelectionManager()
        let position = CGPoint(x: 100, y: 200)
        let nodeIDs: Set<UUID> = [UUID(), UUID()]
        
        // When
        selectionManager.showContextMenu(at: position, for: nodeIDs)
        
        // Then
        #expect(selectionManager.showContextMenu == true)
        #expect(selectionManager.contextMenuPosition == position)
        #expect(selectionManager.selectedNodeIDs == nodeIDs)
    }
    
    @Test("コンテキストメニューの非表示が正常に動作する")
    func testHideContextMenu() {
        // Given
        let selectionManager = NodeSelectionManager()
        selectionManager.showContextMenu(at: CGPoint(x: 100, y: 100))
        
        // When
        selectionManager.hideContextMenu()
        
        // Then
        #expect(selectionManager.showContextMenu == false)
    }
    
    // MARK: - Node Action Tests
    
    @Test("ノードアクションの実行が正常に動作する")
    func testPerformAction() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeIDs: Set<UUID> = [UUID(), UUID()]
        selectionManager.selectMultipleNodes(nodeIDs)
        
        var performedAction: NodeSelectionManager.NodeAction?
        var performedNodeIDs: Set<UUID>?
        
        selectionManager.onNodeAction = { action, nodeIDs in
            performedAction = action
            performedNodeIDs = nodeIDs
        }
        
        // When
        selectionManager.performAction(.delete)
        
        // Then
        #expect(performedAction == .delete)
        #expect(performedNodeIDs == nodeIDs)
    }
    
    @Test("アクション実行可能性の判定が正常に動作する")
    func testCanPerformAction() {
        // Given
        let selectionManager = NodeSelectionManager()
        
        // When & Then - 選択なしの場合
        #expect(selectionManager.canPerformAction(.delete) == false)
        #expect(selectionManager.canPerformAction(.copy) == false)
        #expect(selectionManager.canPerformAction(.paste) == true) // 常に利用可能
        
        // When & Then - 単一選択の場合
        selectionManager.selectNode(UUID())
        #expect(selectionManager.canPerformAction(.delete) == true)
        #expect(selectionManager.canPerformAction(.addChild) == true)
        #expect(selectionManager.canPerformAction(.group) == false) // 複数選択が必要
        
        // When & Then - 複数選択の場合
        selectionManager.selectMultipleNodes([UUID(), UUID()])
        #expect(selectionManager.canPerformAction(.group) == true)
        #expect(selectionManager.canPerformAction(.addChild) == false) // 単一選択が必要
    }
    
    // MARK: - Selection Bounds Tests
    
    @Test("選択範囲の更新が正常に動作する")
    func testUpdateSelectionBounds() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodes = [
            Node(id: UUID(), text: "Node 1", position: CGPoint(x: 50, y: 50)),
            Node(id: UUID(), text: "Node 2", position: CGPoint(x: 150, y: 100)),
            Node(id: UUID(), text: "Node 3", position: CGPoint(x: 100, y: 150))
        ]
        
        let selectedIDs = Set([nodes[0].id, nodes[2].id])
        selectionManager.selectMultipleNodes(selectedIDs)
        
        // When
        selectionManager.updateSelectionBounds(with: nodes)
        
        // Then
        let bounds = selectionManager.selectionBounds
        #expect(bounds.minX == 30) // 50 - 20 (padding)
        #expect(bounds.minY == 30) // 50 - 20 (padding)
        #expect(bounds.width == 90) // (100-50) + 40 (padding)
        #expect(bounds.height == 140) // (150-50) + 40 (padding)
    }
    
    @Test("選択なしでの選択範囲更新が正常に動作する")
    func testUpdateSelectionBoundsNoSelection() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodes = [
            Node(id: UUID(), text: "Node 1", position: CGPoint(x: 50, y: 50))
        ]
        
        // When
        selectionManager.updateSelectionBounds(with: nodes)
        
        // Then
        #expect(selectionManager.selectionBounds == .zero)
    }
    
    // MARK: - Highlight Tests
    
    @Test("ノードのハイライトが正常に動作する")
    func testHighlightNode() async {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID = UUID()
        
        // When
        selectionManager.highlightNode(nodeID, duration: 0.1)
        
        // Then
        #expect(selectionManager.highlightedNodeID == nodeID)
        
        // Wait for highlight to clear
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        #expect(selectionManager.highlightedNodeID == nil)
    }
    
    // MARK: - Keyboard Shortcut Tests
    
    @Test("キーボードショートカットの処理が正常に動作する")
    func testHandleKeyboardShortcut() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID = UUID()
        selectionManager.selectNode(nodeID)
        
        var performedAction: NodeSelectionManager.NodeAction?
        selectionManager.onNodeAction = { action, _ in
            performedAction = action
        }
        
        // When & Then - コピー
        let copyHandled = selectionManager.handleKeyboardShortcut("c", modifiers: [.command])
        #expect(copyHandled == true)
        #expect(performedAction == .copy)
        
        // When & Then - 削除
        let deleteHandled = selectionManager.handleKeyboardShortcut("delete", modifiers: [])
        #expect(deleteHandled == true)
        #expect(performedAction == .delete)
        
        // When & Then - 編集開始
        var editingStartedNodeID: UUID?
        selectionManager.onEditingStarted = { nodeID in
            editingStartedNodeID = nodeID
        }
        
        let enterHandled = selectionManager.handleKeyboardShortcut("return", modifiers: [])
        #expect(enterHandled == true)
        #expect(editingStartedNodeID == nodeID)
    }
    
    @Test("編集中のキーボードショートカット処理が正常に動作する")
    func testHandleKeyboardShortcutWhileEditing() {
        // Given
        let selectionManager = NodeSelectionManager()
        let nodeID = UUID()
        selectionManager.startEditingNode(nodeID, currentText: "Test")
        
        // When & Then - Escape キー
        let escapeHandled = selectionManager.handleKeyboardShortcut("escape", modifiers: [])
        #expect(escapeHandled == true)
        #expect(selectionManager.isEditingText == false)
        
        // When & Then - 編集再開してEnterキー
        selectionManager.startEditingNode(nodeID, currentText: "Test")
        
        var editingEndedNodeID: UUID?
        var editingEndedText: String?
        selectionManager.onEditingEnded = { nodeID, text in
            editingEndedNodeID = nodeID
            editingEndedText = text
        }
        
        let enterHandled = selectionManager.handleKeyboardShortcut("return", modifiers: [])
        #expect(enterHandled == true)
        #expect(editingEndedNodeID == nodeID)
        #expect(editingEndedText == "Test")
    }
}

// MARK: - Extensions for Testing
// Equatable conformance is now declared in the main type