import Testing
import CloudKit
@testable import MindMapCore

// MARK: - CloudKit Sync Manager Tests
struct CloudKitSyncManagerTests {
    
    // MARK: - Test Setup
    func createTestSyncManager() -> CloudKitSyncManager {
        let mockMindMapRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        return CloudKitSyncManager(
            mindMapRepository: mockMindMapRepository,
            nodeRepository: mockNodeRepository,
            isTestMode: true
        )
    }
    
    func createTestMindMap() -> MindMap {
        return MindMap(
            id: UUID(),
            title: "Test MindMap",
            rootNodeID: UUID(),
            nodeIDs: Set([UUID()]),
            version: 1
        )
    }
    
    func createTestNode() -> Node {
        return Node(
            id: UUID(),
            text: "Test Node",
            position: CGPoint(x: 0, y: 0),
            parentID: nil
        )
    }
    
    // MARK: - Offline Mode Tests
    @Test("オフラインモードの切り替えテスト")
    func testOfflineModeToggle() async throws {
        // Given
        let syncManager = createTestSyncManager()
        
        // When & Then
        #expect(!syncManager.isOfflineMode())
        
        syncManager.enableOfflineMode(true)
        #expect(syncManager.isOfflineMode())
        
        syncManager.enableOfflineMode(false)
        #expect(!syncManager.isOfflineMode())
    }
    
    @Test("オフラインモード時の同期エラー")
    func testSyncErrorWhenOffline() async throws {
        // Given
        let syncManager = createTestSyncManager()
        syncManager.enableOfflineMode(true)
        
        // When & Then - syncMindMaps should fail
        do {
            try await syncManager.syncMindMaps()
            Issue.record("Expected networkUnavailable error")
        } catch let error as SyncError {
            #expect(error == .networkUnavailable)
        }
        
        // When & Then - syncMindMap should fail
        let testMindMap = createTestMindMap()
        do {
            _ = try await syncManager.syncMindMap(testMindMap)
            Issue.record("Expected networkUnavailable error")
        } catch let error as SyncError {
            #expect(error == .networkUnavailable)
        }
        
        // When & Then - syncNodes should fail
        do {
            _ = try await syncManager.syncNodes(for: UUID())
            Issue.record("Expected networkUnavailable error")
        } catch let error as SyncError {
            #expect(error == .networkUnavailable)
        }
    }
    
    // MARK: - Sync Implementation Tests (GREEN phase - basic functionality)
    @Test("単一マインドマップ競合解決テスト")
    func testConflictResolution() async throws {
        // Given
        let syncManager = createTestSyncManager()
        
        let olderDate = Date(timeIntervalSince1970: 1000)
        let newerDate = Date(timeIntervalSince1970: 2000)
        
        let localMindMap = MindMap(
            id: UUID(),
            title: "Local MindMap",
            rootNodeID: UUID(),
            nodeIDs: Set([UUID()]),
            createdAt: olderDate,
            updatedAt: newerDate,
            version: 1
        )
        
        let remoteMindMap = MindMap(
            id: UUID(),
            title: "Remote MindMap",
            rootNodeID: UUID(),
            nodeIDs: Set([UUID()]),
            createdAt: olderDate,
            updatedAt: olderDate,
            version: 1
        )
        
        // When - Local is newer
        let resolvedMindMap = try await syncManager.handleConflict(local: localMindMap, remote: remoteMindMap)
        
        // Then - Local should win
        #expect(resolvedMindMap.id == localMindMap.id)
        #expect(resolvedMindMap.title == "Local MindMap")
    }
    
    @Test("競合解決テスト（リモートが新しい場合）")
    func testConflictResolutionRemoteNewer() async throws {
        // Given
        let syncManager = createTestSyncManager()
        
        let olderDate = Date(timeIntervalSince1970: 1000)
        let newerDate = Date(timeIntervalSince1970: 2000)
        
        let localMindMap = MindMap(
            id: UUID(),
            title: "Local MindMap",
            rootNodeID: UUID(),
            nodeIDs: Set([UUID()]),
            createdAt: olderDate,
            updatedAt: olderDate,
            version: 1
        )
        
        let remoteMindMap = MindMap(
            id: UUID(),
            title: "Remote MindMap",
            rootNodeID: UUID(),
            nodeIDs: Set([UUID()]),
            createdAt: olderDate,
            updatedAt: newerDate,
            version: 1
        )
        
        // When - Remote is newer
        let resolvedMindMap = try await syncManager.handleConflict(local: localMindMap, remote: remoteMindMap)
        
        // Then - Remote should win
        #expect(resolvedMindMap.id == remoteMindMap.id)
        #expect(resolvedMindMap.title == "Remote MindMap")
    }
    
    // MARK: - Data Structure Tests
    @Test("SyncResult構造体テスト")
    func testSyncResultStructure() {
        // Given
        let mindMap = createTestMindMap()
        let node = createTestNode()
        let conflict = ConflictResolution(
            localItem: mindMap,
            remoteItem: mindMap,
            resolvedItem: mindMap,
            strategy: .localWins
        )
        let error = SyncError.networkUnavailable
        
        // When
        let syncResult = SyncResult(
            syncedMindMaps: [mindMap],
            syncedNodes: [node],
            conflicts: [conflict],
            errors: [error]
        )
        
        // Then
        #expect(syncResult.syncedMindMaps.count == 1)
        #expect(syncResult.syncedNodes.count == 1)
        #expect(syncResult.conflicts.count == 1)
        #expect(syncResult.errors.count == 1)
    }
    
    @Test("ConflictResolution構造体テスト")
    func testConflictResolutionStructure() {
        // Given
        let mindMap = createTestMindMap()
        
        // When
        let conflict = ConflictResolution(
            localItem: mindMap,
            remoteItem: mindMap,
            resolvedItem: mindMap,
            strategy: .merge
        )
        
        // Then
        #expect(conflict.strategy == .merge)
        #expect(conflict.localItem.id == mindMap.id)
        #expect(conflict.remoteItem.id == mindMap.id)
        #expect(conflict.resolvedItem.id == mindMap.id)
    }
    
    @Test("SyncableItemプロトコル準拠テスト")
    func testSyncableItemConformance() {
        // Given
        let mindMap = createTestMindMap()
        let node = createTestNode()
        
        // When & Then - MindMap should conform to SyncableItem
        #expect(mindMap.lastModified == mindMap.updatedAt)
        #expect(mindMap.version == 1)
        
        // When & Then - Node should conform to SyncableItem
        #expect(node.lastModified == node.updatedAt)
        #expect(node.version == 1)
    }
    
    @Test("SyncError列挙型テスト")
    func testSyncErrorTypes() {
        // Given & When & Then
        let errors: [SyncError] = [
            .networkUnavailable,
            .iCloudAccountNotFound,
            .permissionDenied,
            .conflictResolutionFailed,
            .dataCorrupted,
            .quotaExceeded,
            .unknownError("test")
        ]
        
        #expect(errors.count == 7)
        #expect(errors.contains(.networkUnavailable))
        #expect(errors.contains(.unknownError("test")))
    }
    
    @Test("CloudKitスキーマ定数テスト")
    func testCloudKitSchemaConstants() {
        // Given & When & Then
        #expect(CloudKitSchema.mindMapRecordType == "MindMap")
        #expect(CloudKitSchema.nodeRecordType == "Node")
        #expect(CloudKitSchema.mediaRecordType == "Media")
        #expect(CloudKitSchema.tagRecordType == "Tag")
        
        // MindMap fields
        #expect(CloudKitSchema.MindMapFields.title == "title")
        #expect(CloudKitSchema.MindMapFields.version == "version")
        
        // Node fields
        #expect(CloudKitSchema.NodeFields.text == "text")
        #expect(CloudKitSchema.NodeFields.position == "position")
    }
}

