import Testing
import Foundation
import CoreGraphics
@testable import MindMapCore

struct NodeTests {
    
    @Test("ノード作成時にIDが自動生成される")
    func testNodeCreationGeneratesID() {
        // Given
        let text = "テストノード"
        let position = CGPoint(x: 100, y: 100)
        
        // When
        let node = Node(text: text, position: position)
        
        // Then
        #expect(node.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
        #expect(node.text == text)
        #expect(node.position == position)
        #expect(node.backgroundColor == .default)
        #expect(node.textColor == .primary)
        #expect(node.fontSize == 16.0)
        #expect(node.isCollapsed == false)
        #expect(node.isTask == false)
        #expect(node.isCompleted == false)
        #expect(node.parentID == nil)
        #expect(node.childIDs.isEmpty)
        #expect(node.mediaIDs.isEmpty)
        #expect(node.tagIDs.isEmpty)
    }
    
    @Test("ノードテキスト更新")
    func testUpdateNodeText() async {
        // Given
        var node = Node(text: "元のテキスト", position: .zero)
        let originalUpdatedAt = node.updatedAt
        
        // Wait a small amount to ensure time difference
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // When
        node.updateText("新しいテキスト")
        
        // Then
        #expect(node.text == "新しいテキスト")
        #expect(node.updatedAt >= originalUpdatedAt)
    }
    
    @Test("ノード位置更新")
    func testUpdateNodePosition() async {
        // Given
        var node = Node(text: "テスト", position: CGPoint(x: 0, y: 0))
        let newPosition = CGPoint(x: 200, y: 300)
        let originalUpdatedAt = node.updatedAt
        
        // Wait a small amount to ensure time difference
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // When
        node.updatePosition(newPosition)
        
        // Then
        #expect(node.position == newPosition)
        #expect(node.updatedAt >= originalUpdatedAt)
    }
    
    @Test("子ノード追加と削除")
    func testChildNodeManagement() {
        // Given
        var parentNode = Node(text: "親ノード", position: .zero)
        let childID = UUID()
        
        // When - 子ノード追加
        parentNode.addChild(childID)
        
        // Then
        #expect(parentNode.childIDs.contains(childID))
        #expect(parentNode.hasChildren == true)
        
        // When - 子ノード削除
        parentNode.removeChild(childID)
        
        // Then
        #expect(!parentNode.childIDs.contains(childID))
        #expect(parentNode.hasChildren == false)
    }
    
    @Test("タスク機能の切り替え")
    func testTaskToggle() {
        // Given
        var node = Node(text: "タスクノード", position: .zero)
        
        // When - タスクに変換
        node.toggleTask()
        
        // Then
        #expect(node.isTask == true)
        #expect(node.isCompleted == false)
        
        // When - 完了状態に変更
        node.toggleCompleted()
        
        // Then
        #expect(node.isCompleted == true)
        
        // When - タスクを無効化
        node.toggleTask()
        
        // Then
        #expect(node.isTask == false)
        #expect(node.isCompleted == false) // タスクでなくなると完了状態もリセット
    }
    
    @Test("メディア管理")
    func testMediaManagement() {
        // Given
        var node = Node(text: "メディアノード", position: .zero)
        let mediaID = UUID()
        
        // When - メディア追加
        node.addMedia(mediaID)
        
        // Then
        #expect(node.mediaIDs.contains(mediaID))
        #expect(node.hasMedia == true)
        
        // When - メディア削除
        node.removeMedia(mediaID)
        
        // Then
        #expect(!node.mediaIDs.contains(mediaID))
        #expect(node.hasMedia == false)
    }
    
    @Test("タグ管理")
    func testTagManagement() {
        // Given
        var node = Node(text: "タグノード", position: .zero)
        let tagID = UUID()
        
        // When - タグ追加
        node.addTag(tagID)
        
        // Then
        #expect(node.tagIDs.contains(tagID))
        #expect(node.hasTags == true)
        
        // When - タグ削除
        node.removeTag(tagID)
        
        // Then
        #expect(!node.tagIDs.contains(tagID))
        #expect(node.hasTags == false)
    }
    
    @Test("ルートノード判定")
    func testRootNodeDetection() {
        // Given
        let rootNode = Node(text: "ルート", position: .zero)
        let childNode = Node(text: "子", position: .zero, parentID: UUID())
        
        // Then
        #expect(rootNode.isRoot == true)
        #expect(childNode.isRoot == false)
    }
    
    @Test("ノードの等価性")
    func testNodeEquality() {
        // Given
        let id = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        
        let node1 = Node(id: id, text: "テスト", position: .zero, createdAt: createdAt, updatedAt: updatedAt)
        let node2 = Node(id: id, text: "テスト", position: .zero, createdAt: createdAt, updatedAt: updatedAt)
        let node3 = Node(text: "テスト", position: .zero) // 異なるID
        
        // Then
        #expect(node1 == node2)
        #expect(node1 != node3)
    }
}