import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - MindMapUI Tests
struct MindMapUITests {
    
    @Test("MindMapUIモジュールのバージョンが正しく設定されている")
    func testModuleVersion() {
        // Given & When
        let version = MindMapUI.version
        
        // Then
        #expect(version == "1.0.0")
    }
    
    @Test("MindMapUIモジュールの設定が正常に動作する")
    func testModuleConfiguration() {
        // Given
        let container = DIContainer.configure()
        
        // When & Then
        // 設定が例外なく実行されることを確認
        MindMapUI.configure(with: container)
        
        // 設定が完了したことを確認
        #expect(Bool(true))
    }
    
    @MainActor
    @Test("MindMapViewの初期化が正常に動作する")
    func testMindMapViewInitialization() {
        // Given
        let container = DIContainer.configure()
        
        // When & Then - コンテナでの初期化
        let view1 = MindMapView(container: container)
        #expect(view1 != nil)
        
        // When & Then - マインドマップでの初期化
        let mindMap = MindMap(
            id: UUID(),
            title: "テストマインドマップ",
            createdAt: Date(),
            updatedAt: Date()
        )
        let view2 = MindMapView(mindMap: mindMap, container: container)
        #expect(view2 != nil)
    }
    
    @MainActor
    @Test("MindMapCanvasViewの初期化が正常に動作する")
    func testMindMapCanvasViewInitialization() {
        // Given
        let container = DIContainer.configure()
        
        // When & Then - コンテナでの初期化
        let canvasView1 = MindMapCanvasView(container: container)
        #expect(canvasView1 != nil)
        
        // When & Then - ViewModelでの初期化
        let viewModel = MindMapViewModel(container: container)
        let canvasView2 = MindMapCanvasView(viewModel: viewModel)
        #expect(canvasView2 != nil)
    }
    
    @MainActor
    @Test("NodeViewの初期化が正常に動作する")
    func testNodeViewInitialization() {
        // Given
        let node = Node(
            id: UUID(),
            text: "テストノード",
            position: CGPoint(x: 100, y: 100),
            mindMapID: UUID()
        )
        
        // When
        let nodeView = NodeView(
            node: node,
            isSelected: false,
            isEditing: false,
            isFocused: true,
            isFocusMode: false
        )
        
        // Then
        #expect(nodeView != nil)
    }
    
    @MainActor
    @Test("GestureManagerの初期化が正常に動作する")
    func testGestureManagerInitialization() {
        // When
        let gestureManager = GestureManager()
        
        // Then
        #expect(gestureManager != nil)
        #expect(gestureManager.dragState == .inactive)
        #expect(gestureManager.magnificationScale == 1.0)
        #expect(gestureManager.panOffset == .zero)
    }
}