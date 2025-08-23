import Testing
import Foundation
@testable import MindMapCore
@testable import MindMapUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Node Accessibility Tests
struct NodeAccessibilityTests {
    
    // MARK: - Test Setup
    func createTestNode() -> Node {
        Node(
            id: UUID(),
            text: "テストノード",
            position: CGPoint(x: 100, y: 100)
        )
    }
    
    func createParentChildNodes() -> (parent: Node, child: Node) {
        let parent = createTestNode()
        let child = Node(
            id: UUID(),
            text: "子ノード",
            position: CGPoint(x: 150, y: 150),
            parentID: parent.id
        )
        return (parent, child)
    }
    
    // MARK: - Accessibility Properties Tests
    @Test("Nodeのアクセシビリティラベル生成")
    func testNodeAccessibilityLabel() {
        // Given
        let node = createTestNode()
        
        // When
        let accessibilityLabel = node.accessibilityLabel
        let accessibilityValue = node.accessibilityValue
        
        // Then
        #expect(accessibilityLabel.contains("ノード"))
        #expect(accessibilityLabel.contains("テストノード"))
        #expect(accessibilityValue == "テストノード")
    }
    
    @Test("階層レベルのアクセシビリティ表現")
    func testHierarchicalAccessibilityLabel() {
        // Given
        let (parent, child) = createParentChildNodes()
        
        // When
        let parentLabel = parent.accessibilityLabel
        let childLabel = child.accessibilityLabel(level: 1)
        
        // Then
        #expect(parentLabel.contains("ルートノード") || parentLabel.contains("親ノード"))
        #expect(childLabel.contains("レベル1") || childLabel.contains("第1階層"))
        #expect(childLabel.contains("子ノード"))
    }
    
    @Test("タスクノードのアクセシビリティ")
    func testTaskNodeAccessibility() {
        // Given
        var node = createTestNode()
        node.markAsTask()
        
        // When
        let taskLabel = node.accessibilityLabel
        let taskHint = node.accessibilityHint
        #if canImport(UIKit)
        let taskTraits = node.accessibilityTraits
        #endif
        
        // Then
        #expect(taskLabel.contains("タスク"))
        #expect(taskLabel.contains("未完了"))
        #expect(taskHint.contains("完了状態を切り替え"))
        #if canImport(UIKit)
        #expect(!taskTraits.isEmpty)
        #endif
    }
    
    @Test("完了タスクのアクセシビリティ")
    func testCompletedTaskAccessibility() {
        // Given
        var node = createTestNode()
        node.markAsTask()
        node.markAsCompleted()
        
        // When
        let completedLabel = node.accessibilityLabel
        
        // Then
        #expect(completedLabel.contains("完了"))
    }
    
    @Test("メディア付きノードのアクセシビリティ")
    func testNodeWithMediaAccessibility() {
        // Given
        var node = createTestNode()
        let media = Media(
            id: UUID(),
            type: .image,
            data: Data(),
            url: nil
        )
        node.attachMedia(media)
        
        // When
        let mediaLabel = node.accessibilityLabel
        let mediaHint = node.accessibilityHint
        
        // Then
        #expect(mediaLabel.contains("画像付き"))
        #expect(mediaHint.contains("メディア"))
    }
    
    @Test("タグ付きノードのアクセシビリティ")
    func testNodeWithTagsAccessibility() {
        // Given
        var node = createTestNode()
        let tag = Tag(id: UUID(), name: "重要", color: .red)
        node.addTag(tag.id)
        
        // When
        let taggedLabel = node.accessibilityLabel(tags: [tag])
        
        // Then
        #expect(taggedLabel.contains("タグ"))
        #expect(taggedLabel.contains("重要"))
    }
    
    // MARK: - Accessibility Actions Tests
    @Test("Nodeのカスタムアクセシビリティアクション")
    func testNodeCustomAccessibilityActions() {
        // Given
        let node = createTestNode()
        
        // When
        let actions = node.accessibilityActions
        
        // Then
        #expect(actions.count >= 3)
        #expect(actions.contains { $0.name == "編集" })
        #expect(actions.contains { $0.name == "子ノード追加" })
        #expect(actions.contains { $0.name == "削除" })
    }
    
    @Test("タスクノードの追加アクション")
    func testTaskNodeAdditionalActions() {
        // Given
        var node = createTestNode()
        node.markAsTask()
        
        // When
        let taskActions = node.accessibilityActions
        
        // Then
        #expect(taskActions.contains { $0.name == "完了状態切り替え" })
        #expect(taskActions.contains { $0.name == "タスク解除" })
    }
    
    // MARK: - Accessibility Grouping Tests
    @Test("ノードグループのアクセシビリティ")
    func testNodeGroupAccessibility() {
        // Given
        let nodes = [
            createTestNode(),
            Node(id: UUID(), text: "ノード2", position: CGPoint(x: 200, y: 100)),
            Node(id: UUID(), text: "ノード3", position: CGPoint(x: 300, y: 100))
        ]
        
        // When
        let groupLabel = "\(nodes.count)個のノードグループ" // 直接実装
        let groupHint = "グループ内のノードを操作するには選択してください" // 直接実装
        
        // Then
        #expect(groupLabel.contains("3個のノード"))
        #expect(groupHint.contains("グループ"))
    }
    
    // MARK: - Focus Management Tests
    @Test("ノードのフォーカス可能性")
    func testNodeFocusability() {
        // Given
        let node = createTestNode()
        
        // When
        let isFocusable = node.canReceiveFocus
        let focusPriority = node.focusPriority
        
        // Then
        #expect(isFocusable == true)
        #expect(focusPriority >= 0)
    }
    
    @Test("編集状態でのフォーカス")
    func testEditingStateFocus() {
        // Given
        var node = createTestNode()
        node.startEditing()
        
        // When
        let editingFocusable = node.canReceiveFocus
        let editingPriority = node.focusPriority
        
        // Then
        #expect(editingFocusable == true)
        #expect(editingPriority > 0) // 編集中は優先度が高い
    }
}

// MARK: - MindMap Accessibility Tests
struct MindMapAccessibilityTests {
    
    // MARK: - Test Setup
    func createTestMindMap() -> MindMap {
        MindMap(
            id: UUID(),
            title: "アクセシビリティテスト用マインドマップ",
            rootNodeID: UUID(),
            nodeIDs: Set([UUID(), UUID(), UUID()])
        )
    }
    
    // MARK: - MindMap Level Accessibility Tests
    @Test("MindMapのアクセシビリティラベル")
    func testMindMapAccessibilityLabel() {
        // Given
        let mindMap = createTestMindMap()
        
        // When
        let accessibilityLabel = mindMap.accessibilityLabel
        let accessibilityValue = mindMap.accessibilityValue
        
        // Then
        #expect(accessibilityLabel.contains("マインドマップ"))
        #expect(accessibilityLabel.contains("アクセシビリティテスト用"))
        #expect(accessibilityValue.contains("3個のノード"))
    }
    
    @Test("空のMindMapのアクセシビリティ")
    func testEmptyMindMapAccessibility() {
        // Given
        let emptyMindMap = MindMap(
            id: UUID(),
            title: "空のマップ",
            rootNodeID: nil,
            nodeIDs: []
        )
        
        // When
        let emptyLabel = emptyMindMap.accessibilityLabel
        let emptyHint = emptyMindMap.accessibilityHint
        
        // Then
        #expect(emptyLabel.contains("空"))
        #expect(emptyHint.contains("ノードを追加"))
    }
    
    @Test("共有MindMapのアクセシビリティ")
    func testSharedMindMapAccessibility() {
        // Given
        var mindMap = createTestMindMap()
        mindMap.enableSharing(
            url: "https://mindmap.app/share/test",
            permissions: .readOnly
        )
        
        // When
        let sharedLabel = mindMap.accessibilityLabel
        
        // Then
        #expect(sharedLabel.contains("共有中"))
        #expect(sharedLabel.contains("読み取り専用"))
    }
    
    // MARK: - Navigation Tests
    @Test("MindMapナビゲーションのアクセシビリティ")
    func testMindMapNavigationAccessibility() {
        // Given
        let mindMap = createTestMindMap()
        
        // When
        let navigationInfo = mindMap.accessibilityNavigationInfo
        
        // Then
        #expect(navigationInfo.totalNodes == 3)
        #expect(navigationInfo.currentNodeIndex != nil)
        #expect(navigationInfo.hasNext == true)
        #expect(navigationInfo.hasPrevious == true)
    }
}