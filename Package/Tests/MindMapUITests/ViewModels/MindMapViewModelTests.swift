import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - MindMapViewModel Tests
@MainActor
struct MindMapViewModelTests {
    
    private let container = DIContainer.configure()
    
    // MARK: - Initialization Tests
    
    @Test("ViewModelの初期化が正しく行われる")
    func testInitialization() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        
        // Then
        #expect(viewModel.mindMap == nil)
        #expect(viewModel.nodes.isEmpty)
        #expect(viewModel.selectedNodeIDs.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.errorMessage == nil)
        #expect(viewModel.showError == false)
        #expect(viewModel.zoomScale == 1.0)
        #expect(viewModel.panOffset == .zero)
        #expect(viewModel.isFocusMode == false)
    }
    
    // MARK: - Mind Map Creation Tests
    
    @Test("新しいマインドマップの作成が正常に動作する")
    func testCreateNewMindMap() async {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let title = "テストマインドマップ"
        
        // When
        viewModel.createNewMindMap(title: title)
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        #expect(viewModel.mindMap != nil)
        #expect(viewModel.mindMap?.title == title)
        #expect(viewModel.nodes.count == 1)
        #expect(viewModel.nodes.first?.text == title)
        #expect(viewModel.isLoading == false)
    }
    
    @Test("デフォルトタイトルでのマインドマップ作成")
    func testCreateNewMindMapWithDefaultTitle() async {
        // Given
        let viewModel = MindMapViewModel(container: container)
        
        // When
        viewModel.createNewMindMap()
        
        // Wait for async operation
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Then
        #expect(viewModel.mindMap != nil)
        #expect(viewModel.mindMap?.title == "新しいマインドマップ")
        #expect(viewModel.nodes.count == 1)
    }
    
    // MARK: - Node Selection Tests
    
    @Test("ノードの選択が正常に動作する")
    func testSelectNode() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let nodeID = UUID()
        
        // When
        viewModel.selectNode(nodeID)
        
        // Then
        #expect(viewModel.selectedNodeIDs.contains(nodeID))
    }
    
    @Test("ノードの選択解除が正常に動作する")
    func testDeselectNode() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let nodeID = UUID()
        
        // When - 選択してから解除
        viewModel.selectNode(nodeID)
        #expect(viewModel.selectedNodeIDs.contains(nodeID))
        
        viewModel.selectNode(nodeID)
        
        // Then
        #expect(!viewModel.selectedNodeIDs.contains(nodeID))
    }
    
    @Test("複数ノードの選択が正常に動作する")
    func testMultipleNodeSelection() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let nodeID1 = UUID()
        let nodeID2 = UUID()
        
        // When
        viewModel.selectNode(nodeID1)
        viewModel.selectNode(nodeID2)
        
        // Then
        #expect(viewModel.selectedNodeIDs.contains(nodeID1))
        #expect(viewModel.selectedNodeIDs.contains(nodeID2))
        #expect(viewModel.selectedNodeIDs.count == 2)
    }
    
    // MARK: - Node Editing Tests
    
    @Test("ノード編集の開始が正常に動作する")
    func testStartEditingNode() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let nodeID = UUID()
        
        // When
        viewModel.startEditingNode(nodeID)
        
        // Then
        #expect(viewModel.editingNodeID == nodeID)
        #expect(viewModel.isEditingText == true)
    }
    
    @Test("ノード編集の終了が正常に動作する")
    func testFinishEditingNode() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let nodeID = UUID()
        
        // When
        viewModel.startEditingNode(nodeID)
        viewModel.finishEditingNode()
        
        // Then
        #expect(viewModel.editingNodeID == nil)
        #expect(viewModel.isEditingText == false)
    }
    
    @Test("ノードテキストの更新が正常に動作する")
    func testUpdateNodeText() async {
        // Given
        let viewModel = MindMapViewModel(container: container)
        viewModel.createNewMindMap(title: "テスト")
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        guard let nodeID = viewModel.nodes.first?.id else {
            Issue.record("ノードが見つかりません")
            return
        }
        
        let newText = "更新されたテキスト"
        
        // When
        viewModel.updateNodeText(nodeID, text: newText)
        
        // Then
        let updatedNode = viewModel.nodes.first { $0.id == nodeID }
        #expect(updatedNode?.text == newText)
    }
    
    // MARK: - Canvas Navigation Tests
    
    @Test("キャンバス変換のリセットが正常に動作する")
    func testResetCanvasTransform() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        viewModel.zoomScale = 2.0
        viewModel.panOffset = CGSize(width: 100, height: 100)
        
        // When
        viewModel.resetCanvasTransform()
        
        // Then - アニメーション中の可能性があるため、近似値で確認
        #expect(abs(viewModel.zoomScale - 1.0) < 0.1)
        #expect(abs(viewModel.panOffset.width) < 10)
        #expect(abs(viewModel.panOffset.height) < 10)
    }
    
    @Test("ブランチフォーカスが正常に動作する")
    func testFocusOnBranch() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let nodeID = UUID()
        
        // When
        viewModel.focusOnBranch(nodeID)
        
        // Then
        #expect(viewModel.focusedBranchID == nodeID)
        #expect(viewModel.isFocusMode == true)
    }
    
    @Test("フォーカスモードの終了が正常に動作する")
    func testExitFocusMode() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let nodeID = UUID()
        
        // When - フォーカスモードに入ってから終了
        viewModel.focusOnBranch(nodeID)
        #expect(viewModel.isFocusMode == true)
        
        viewModel.exitFocusMode()
        
        // Then
        #expect(viewModel.isFocusMode == false)
        #expect(viewModel.focusedBranchID == nil)
    }
    
    // MARK: - Gesture Handling Tests
    
    @Test("パンジェスチャーの処理が正常に動作する")
    func testHandlePanGesture() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let translation = CGSize(width: 50, height: 30)
        
        // When
        viewModel.handlePanGesture(translation)
        
        // Then
        #expect(viewModel.panOffset == translation)
    }
    
    @Test("ズームジェスチャーの処理が正常に動作する")
    func testHandleZoomGesture() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let scale: CGFloat = 1.5
        
        // When
        viewModel.handleZoomGesture(scale)
        
        // Then
        #expect(viewModel.zoomScale == scale)
    }
    
    @Test("ズームの制限が正常に動作する")
    func testHandleZoomGestureWithLimits() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        
        // When - 最小値以下のズーム
        viewModel.handleZoomGesture(0.1)
        
        // Then
        #expect(viewModel.zoomScale == 0.5) // 最小値にクランプ
        
        // When - 最大値以上のズーム
        viewModel.zoomScale = 1.0
        viewModel.handleZoomGesture(5.0)
        
        // Then
        #expect(viewModel.zoomScale == 3.0) // 最大値にクランプ
    }
    
    // MARK: - Focus Mode Helper Tests
    
    @Test("フォーカスブランチの判定が正常に動作する")
    func testIsNodeInFocusedBranch() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let focusedNodeID = UUID()
        let otherNodeID = UUID()
        
        // When - フォーカスモードでない場合
        // Then - すべてのノードが「フォーカス内」とみなされる
        #expect(viewModel.isNodeInFocusedBranch(focusedNodeID) == true)
        #expect(viewModel.isNodeInFocusedBranch(otherNodeID) == true)
        
        // When - フォーカスモードに入る
        viewModel.focusOnBranch(focusedNodeID)
        
        // Then - フォーカスされたノードのみが「フォーカス内」
        #expect(viewModel.isNodeInFocusedBranch(focusedNodeID) == true)
        #expect(viewModel.isNodeInFocusedBranch(otherNodeID) == false)
    }
    
    // MARK: - Load Mind Map Tests
    
    @Test("マインドマップの読み込みが正常に動作する")
    func testLoadMindMap() {
        // Given
        let viewModel = MindMapViewModel(container: container)
        let mindMap = MindMap(
            id: UUID(),
            title: "読み込みテスト",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        let node = Node(
            id: UUID(),
            text: "テストノード",
            position: CGPoint(x: 100, y: 100),
            mindMapID: mindMap.id
        )
        
        mindMap.nodes = [node]
        
        // When
        viewModel.loadMindMap(mindMap)
        
        // Then
        #expect(viewModel.mindMap?.id == mindMap.id)
        #expect(viewModel.mindMap?.title == mindMap.title)
        #expect(viewModel.nodes.count == 1)
        #expect(viewModel.nodes.first?.text == "テストノード")
    }
}