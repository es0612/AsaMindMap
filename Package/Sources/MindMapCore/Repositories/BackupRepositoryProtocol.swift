import Foundation

// MARK: - BackupStorageProtocol
public protocol BackupStorageProtocol {
    func save(_ backup: Backup) async throws
    func load(id: UUID) async throws -> Backup?
    func loadAll() async throws -> [Backup]
    func delete(id: UUID) async throws
}

// MARK: - CloudKitBackupStorageProtocol  
public protocol CloudKitBackupStorageProtocol {
    func uploadBackup(_ backup: Backup) async throws
    func downloadBackup(id: UUID) async throws -> Backup?
    func listCloudBackups() async throws -> [Backup]
    func deleteCloudBackup(id: UUID) async throws
}

// MARK: - Backup Errors
public enum BackupError: Error, LocalizedError {
    case backupNotFound
    case invalidBackupData
    case storageError(String)
    case integrityCheckFailed
    case cloudKitError(String)
    
    public var errorDescription: String? {
        switch self {
        case .backupNotFound:
            return "Backup not found"
        case .invalidBackupData:
            return "Invalid backup data"
        case .storageError(let message):
            return "Storage error: \(message)"
        case .integrityCheckFailed:
            return "Backup integrity check failed"
        case .cloudKitError(let message):
            return "CloudKit error: \(message)"
        }
    }
}