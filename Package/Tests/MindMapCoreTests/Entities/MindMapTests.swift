import Testing
import Foundation
@testable import MindMapCore

struct MindMapTests {
    
    @Test("マインドマップ作成時の初期状態")
    func testMindMapCreation() {
        // Given
        let title = "テストマインドマップ"
        
        // When
        let mindMap = MindMap(title: title)
        
        // Then
        #expect(mindMap.title == title)
        #expect(mindMap.rootNodeID == nil)
        #expect(mindMap.nodeIDs.isEmpty)
        #expect(mindMap.tagIDs.isEmpty)
        #expect(mindMap.mediaIDs.isEmpty)
        #expect(mindMap.isShared == false)
        #expect(mindMap.shareURL == nil)
        #expect(mindMap.sharePermissions == .private)
        #expect(mindMap.version == 1)
        #expect(mindMap.lastSyncedAt == nil)
        #expect(mindMap.hasNodes == false)
        #expect(mindMap.hasRootNode == false)
        #expect(mindMap.isEmpty == true)
        #expect(mindMap.needsSync == true)
    }
    
    @Test("タイトル更新")
    func testUpdateTitle() async {
        // Given
        var mindMap = MindMap(title: "元のタイトル")
        let originalVersion = mindMap.version
        let originalUpdatedAt = mindMap.updatedAt
        
        // Wait a small amount to ensure time difference
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // When
        mindMap.updateTitle("新しいタイトル")
        
        // Then
        #expect(mindMap.title == "新しいタイトル")
        #expect(mindMap.version == originalVersion + 1)
        #expect(mindMap.updatedAt >= originalUpdatedAt)
    }
    
    @Test("ルートノード設定")
    func testSetRootNode() {
        // Given
        var mindMap = MindMap(title: "テスト")
        let rootNodeID = UUID()
        let originalVersion = mindMap.version
        
        // When
        mindMap.setRootNode(rootNodeID)
        
        // Then
        #expect(mindMap.rootNodeID == rootNodeID)
        #expect(mindMap.nodeIDs.contains(rootNodeID))
        #expect(mindMap.hasRootNode == true)
        #expect(mindMap.hasNodes == true)
        #expect(mindMap.isEmpty == false)
        #expect(mindMap.version == originalVersion + 1)
    }
    
    @Test("ノード管理")
    func testNodeManagement() {
        // Given
        var mindMap = MindMap(title: "テスト")
        let nodeID1 = UUID()
        let nodeID2 = UUID()
        
        // When - ノード追加
        mindMap.addNode(nodeID1)
        mindMap.addNode(nodeID2)
        
        // Then
        #expect(mindMap.nodeIDs.contains(nodeID1))
        #expect(mindMap.nodeIDs.contains(nodeID2))
        #expect(mindMap.nodeCount == 2)
        
        // When - ノード削除
        mindMap.removeNode(nodeID1)
        
        // Then
        #expect(!mindMap.nodeIDs.contains(nodeID1))
        #expect(mindMap.nodeIDs.contains(nodeID2))
        #expect(mindMap.nodeCount == 1)
    }
    
    @Test("ルートノード削除時の処理")
    func testRemoveRootNode() {
        // Given
        var mindMap = MindMap(title: "テスト")
        let rootNodeID = UUID()
        mindMap.setRootNode(rootNodeID)
        
        // When
        mindMap.removeNode(rootNodeID)
        
        // Then
        #expect(mindMap.rootNodeID == nil)
        #expect(!mindMap.nodeIDs.contains(rootNodeID))
        #expect(mindMap.hasRootNode == false)
    }
    
    @Test("タグ管理")
    func testTagManagement() {
        // Given
        var mindMap = MindMap(title: "テスト")
        let tagID = UUID()
        
        // When - タグ追加
        mindMap.addTag(tagID)
        
        // Then
        #expect(mindMap.tagIDs.contains(tagID))
        
        // When - タグ削除
        mindMap.removeTag(tagID)
        
        // Then
        #expect(!mindMap.tagIDs.contains(tagID))
    }
    
    @Test("メディア管理")
    func testMediaManagement() {
        // Given
        var mindMap = MindMap(title: "テスト")
        let mediaID = UUID()
        
        // When - メディア追加
        mindMap.addMedia(mediaID)
        
        // Then
        #expect(mindMap.mediaIDs.contains(mediaID))
        
        // When - メディア削除
        mindMap.removeMedia(mediaID)
        
        // Then
        #expect(!mindMap.mediaIDs.contains(mediaID))
    }
    
    @Test("共有機能")
    func testSharingFunctionality() {
        // Given
        var mindMap = MindMap(title: "テスト")
        let shareURL = "https://example.com/share/123"
        let originalVersion = mindMap.version
        
        // When - 共有有効化
        mindMap.enableSharing(url: shareURL, permissions: .readOnly)
        
        // Then
        #expect(mindMap.isShared == true)
        #expect(mindMap.shareURL == shareURL)
        #expect(mindMap.sharePermissions == .readOnly)
        #expect(mindMap.version == originalVersion + 1)
        
        // When - 共有無効化
        mindMap.disableSharing()
        
        // Then
        #expect(mindMap.isShared == false)
        #expect(mindMap.shareURL == nil)
        #expect(mindMap.sharePermissions == .private)
    }
    
    @Test("同期状態管理")
    func testSyncStateManagement() {
        // Given
        var mindMap = MindMap(title: "テスト")
        
        // Then - 初期状態では同期が必要
        #expect(mindMap.needsSync == true)
        
        // When - 同期完了をマーク
        mindMap.markAsSynced()
        
        // Then - 同期不要になる
        #expect(mindMap.needsSync == false)
        #expect(mindMap.lastSyncedAt != nil)
        
        // When - 更新を行う
        mindMap.updateTitle("更新されたタイトル")
        
        // Then - 再び同期が必要になる
        #expect(mindMap.needsSync == true)
    }
    
    @Test("バージョン管理")
    func testVersionManagement() {
        // Given
        var mindMap = MindMap(title: "テスト")
        let initialVersion = mindMap.version
        
        // When - 複数の更新を実行
        mindMap.updateTitle("新タイトル")
        mindMap.addNode(UUID())
        mindMap.addTag(UUID())
        
        // Then - バージョンが適切に増加
        #expect(mindMap.version == initialVersion + 3)
    }
}