import XCTest
@testable import MindMapCore

/// バックアップユースケースの単体テスト
/// Task 22: バックアップ・復元機能
final class BackupUseCasesTests: XCTestCase {
    
    var backupManager: BackupManagerProtocol!
    var mockRepository: MockMindMapRepository!
    var mockBackupStorage: MockBackupStorageProtocol!
    
    override func setUp() {
        super.setUp()
        mockRepository = MockMindMapRepository()
        mockBackupStorage = MockBackupStorageProtocol()
        backupManager = BackupManager(
            mindMapRepository: mockRepository,
            backupStorage: mockBackupStorage
        )
    }
    
    override func tearDown() {
        backupManager = nil
        mockRepository = nil
        mockBackupStorage = nil
        super.tearDown()
    }
    
    // MARK: - Create Backup Tests
    
    func testCreateLocalBackup() async throws {
        // Given
        let mindMaps = [
            MindMap(title: "Map 1"),
            MindMap(title: "Map 2")
        ]
        mockRepository.mindMaps = mindMaps
        
        // When
        let backup = try await backupManager.createBackup(type: .local)
        
        // Then
        XCTAssertNotNil(backup)
        XCTAssertEqual(backup.type, .local)
        XCTAssertEqual(backup.mindMaps.count, 2)
        XCTAssertTrue(mockBackupStorage.saveBackupCalled)
    }
    
    func testCreateCloudKitBackup() async throws {
        // Given
        let mindMaps = [MindMap(title: "Cloud Map")]
        mockRepository.mindMaps = mindMaps
        
        // When
        let backup = try await backupManager.createBackup(type: .cloudKit)
        
        // Then
        XCTAssertEqual(backup.type, .cloudKit)
        XCTAssertEqual(backup.mindMaps.count, 1)
    }
    
    func testCreateBackupEmptyData() async {
        // Given
        mockRepository.mindMaps = []
        
        // When & Then
        do {
            _ = try await backupManager.createBackup(type: .local)
            XCTFail("Should throw error for empty data")
        } catch {
            XCTAssertTrue(error is BackupError)
            XCTAssertEqual(error as? BackupError, .emptyBackup)
        }
    }
    
    // MARK: - List Backups Tests
    
    func testListLocalBackups() async throws {
        // Given
        let backup1 = Backup(mindMaps: [MindMap(title: "Map1")], type: .local, version: "1.0")
        let backup2 = Backup(mindMaps: [MindMap(title: "Map2")], type: .local, version: "1.1")
        mockBackupStorage.storedBackups = [backup1, backup2]
        
        // When
        let backups = try await backupManager.listBackups(type: .local)
        
        // Then
        XCTAssertEqual(backups.count, 2)
        XCTAssertTrue(backups.allSatisfy { $0.type == .local })
    }
    
    func testListBackupsSortedByDate() async throws {
        // Given
        let oldBackup = Backup(mindMaps: [MindMap(title: "Old")], type: .local, version: "1.0")
        let newBackup = Backup(mindMaps: [MindMap(title: "New")], type: .local, version: "1.1")
        mockBackupStorage.storedBackups = [oldBackup, newBackup]
        
        // When
        let backups = try await backupManager.listBackups(type: .local)
        
        // Then
        XCTAssertEqual(backups.count, 2)
        // Should be sorted by date (newest first)
        XCTAssertTrue(backups[0].createdAt >= backups[1].createdAt)
    }
    
    // MARK: - Restore Backup Tests
    
    func testRestoreBackup() async throws {
        // Given
        let originalMindMaps = [MindMap(title: "Original")]
        let backupMindMaps = [MindMap(title: "Backup")]
        let backup = Backup(mindMaps: backupMindMaps, type: .local, version: "1.0")
        mockRepository.mindMaps = originalMindMaps
        mockBackupStorage.storedBackups = [backup]
        
        // When
        let result = try await backupManager.restoreBackup(backup.id)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.restoredItemCount, 1)
        XCTAssertTrue(mockRepository.saveAllCalled)
    }
    
    func testRestoreNonExistentBackup() async {
        // Given
        let nonExistentId = UUID()
        mockBackupStorage.storedBackups = []
        
        // When & Then
        do {
            _ = try await backupManager.restoreBackup(nonExistentId)
            XCTFail("Should throw error for non-existent backup")
        } catch {
            XCTAssertTrue(error is BackupError)
            XCTAssertEqual(error as? BackupError, .backupNotFound)
        }
    }
    
    // MARK: - Selective Restore Tests
    
    func testSelectiveRestore() async throws {
        // Given
        let mindMap1 = MindMap(title: "Map 1")
        let mindMap2 = MindMap(title: "Map 2")
        let backup = Backup(mindMaps: [mindMap1, mindMap2], type: .local, version: "1.0")
        mockBackupStorage.storedBackups = [backup]
        
        // When
        let result = try await backupManager.selectiveRestore(
            backupId: backup.id,
            itemIds: [mindMap1.id]
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.restoredItemCount, 1)
    }
    
    // MARK: - Data Integrity Tests
    
    func testVerifyBackupIntegrity() async throws {
        // Given
        let mindMaps = [MindMap(title: "Test")]
        let backup = Backup(mindMaps: mindMaps, type: .local, version: "1.0")
        mockBackupStorage.storedBackups = [backup]
        
        // When
        let isValid = try await backupManager.verifyBackupIntegrity(backup.id)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testVerifyCorruptedBackup() async throws {
        // Given
        let backup = Backup(mindMaps: [MindMap(title: "Test")], type: .local, version: "1.0")
        mockBackupStorage.storedBackups = [backup]
        mockBackupStorage.simulateCorruption = true
        
        // When
        let isValid = try await backupManager.verifyBackupIntegrity(backup.id)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Version Management Tests
    
    func testBackupVersioning() async throws {
        // Given
        mockRepository.mindMaps = [MindMap(title: "Test")]
        
        // When
        let backup1 = try await backupManager.createBackup(type: .local)
        let backup2 = try await backupManager.createBackup(type: .local)
        
        // Then
        let version1 = BackupVersion(backup1.version)
        let version2 = BackupVersion(backup2.version)
        XCTAssertTrue(version2 > version1)
    }
    
    func testGetBackupHistory() async throws {
        // Given
        let backup1 = Backup(mindMaps: [MindMap(title: "V1")], type: .local, version: "1.0")
        let backup2 = Backup(mindMaps: [MindMap(title: "V2")], type: .local, version: "1.1")
        mockBackupStorage.storedBackups = [backup1, backup2]
        
        // When
        let history = try await backupManager.getBackupHistory(limit: 10)
        
        // Then
        XCTAssertEqual(history.count, 2)
        XCTAssertTrue(history[0].createdAt >= history[1].createdAt)
    }
}