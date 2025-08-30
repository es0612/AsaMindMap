import Foundation
@testable import MindMapCore

/// バックアップストレージのモック実装
/// Task 22: バックアップ・復元機能テスト用
class MockBackupStorageProtocol: BackupStorageProtocol {
    
    // Test state
    var storedBackups: [Backup] = []
    var saveBackupCalled = false
    var deleteBackupCalled = false
    var simulateCorruption = false
    
    // MARK: - BackupStorageProtocol Implementation
    
    func saveBackup(_ backup: Backup) async throws {
        saveBackupCalled = true
        storedBackups.append(backup)
    }
    
    func loadBackup(id: UUID) async throws -> Backup? {
        return storedBackups.first { $0.id == id }
    }
    
    func listBackups(type: BackupType) async throws -> [Backup] {
        return storedBackups.filter { $0.type == type }
    }
    
    func deleteBackup(id: UUID) async throws {
        deleteBackupCalled = true
        storedBackups.removeAll { $0.id == id }
    }
    
    func getBackupSize(id: UUID) async throws -> Int {
        guard let backup = storedBackups.first(where: { $0.id == id }) else {
            throw BackupError.backupNotFound
        }
        return backup.estimatedSize
    }
    
    func verifyBackupIntegrity(id: UUID) async throws -> Bool {
        guard storedBackups.contains(where: { $0.id == id }) else {
            throw BackupError.backupNotFound
        }
        return !simulateCorruption
    }
    
    func getStorageInfo() async throws -> BackupStorageInfo {
        let totalSize = storedBackups.reduce(0) { $0 + $1.estimatedSize }
        return BackupStorageInfo(
            totalBackups: storedBackups.count,
            totalSize: totalSize,
            availableSpace: 1_000_000_000 // 1GB
        )
    }
}

/// CloudKitバックアップストレージのモック実装
class MockCloudKitBackupStorage: CloudKitBackupStorageProtocol {
    
    var storedBackups: [Backup] = []
    var syncInProgress = false
    var syncError: Error?
    
    func saveBackupToCloud(_ backup: Backup) async throws {
        if let error = syncError {
            throw error
        }
        storedBackups.append(backup)
    }
    
    func loadBackupFromCloud(id: UUID) async throws -> Backup? {
        if let error = syncError {
            throw error
        }
        return storedBackups.first { $0.id == id }
    }
    
    func syncWithCloud() async throws {
        if let error = syncError {
            throw error
        }
        syncInProgress = true
        // Simulate sync delay
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        syncInProgress = false
    }
    
    func getCloudBackupStatus() async throws -> CloudBackupStatus {
        return CloudBackupStatus(
            lastSync: Date(),
            syncInProgress: syncInProgress,
            availableStorage: 5_000_000_000 // 5GB
        )
    }
}