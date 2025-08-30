import Foundation

// MARK: - BackupManager
public final class BackupManager {
    // MARK: - Dependencies
    private let localStorage: BackupStorageProtocol
    private let cloudStorage: CloudKitBackupStorageProtocol
    private let mindMapRepository: MindMapRepositoryProtocol
    
    // MARK: - Initialization
    public init(
        localStorage: BackupStorageProtocol,
        cloudStorage: CloudKitBackupStorageProtocol,
        mindMapRepository: MindMapRepositoryProtocol
    ) {
        self.localStorage = localStorage
        self.cloudStorage = cloudStorage
        self.mindMapRepository = mindMapRepository
    }
    
    // MARK: - Create Backup
    public func createBackup(type: BackupType) async throws -> Backup {
        let mindMaps = try await mindMapRepository.findAll()
        
        guard !mindMaps.isEmpty else {
            throw BackupError.invalidBackupData
        }
        
        let version = generateVersion()
        let dataHash = calculateDataIntegrityHash(for: mindMaps)
        
        let backup = Backup(
            mindMaps: mindMaps,
            type: type,
            version: version,
            dataIntegrityHash: dataHash
        )
        
        guard backup.isValid() else {
            throw BackupError.invalidBackupData
        }
        
        try await saveBackup(backup, to: type)
        
        return backup
    }
    
    // MARK: - Restore Backup
    public func restoreBackup(backupId: UUID, type: BackupType) async throws {
        let backup = try await loadAndVerifyBackup(backupId: backupId, type: type)
        
        // Restore all mind maps using batch operation
        try await mindMapRepository.saveAll(backup.mindMaps)
    }
    
    // MARK: - Selective Restore
    public func selectiveRestore(
        backupId: UUID, 
        mindMapIds: [UUID],
        type: BackupType
    ) async throws {
        guard !mindMapIds.isEmpty else {
            throw BackupError.invalidBackupData
        }
        
        let backup = try await loadBackup(backupId: backupId, type: type)
        
        let selectedMindMaps = backup.mindMaps.filter { mindMapIds.contains($0.id) }
        
        guard !selectedMindMaps.isEmpty else {
            throw BackupError.backupNotFound
        }
        
        try await mindMapRepository.saveAll(selectedMindMaps)
    }
    
    // MARK: - Verify Data Integrity
    public func verifyDataIntegrity(backupId: UUID, type: BackupType) async throws -> Bool {
        let backup = try await loadBackup(backupId: backupId, type: type)
        return backup.verifyIntegrity()
    }
    
    // MARK: - Private Methods
    
    /// Load backup from storage without verification
    private func loadBackup(backupId: UUID, type: BackupType) async throws -> Backup {
        let backup: Backup?
        
        switch type {
        case .local:
            backup = try await localStorage.load(id: backupId)
        case .cloudKit:
            backup = try await cloudStorage.downloadBackup(id: backupId)
        }
        
        guard let validBackup = backup else {
            throw BackupError.backupNotFound
        }
        
        return validBackup
    }
    
    /// Load backup from storage and verify its integrity
    private func loadAndVerifyBackup(backupId: UUID, type: BackupType) async throws -> Backup {
        let backup = try await loadBackup(backupId: backupId, type: type)
        
        guard backup.verifyIntegrity() else {
            throw BackupError.integrityCheckFailed
        }
        
        return backup
    }
    
    /// Save backup to the specified storage type
    private func saveBackup(_ backup: Backup, to type: BackupType) async throws {
        switch type {
        case .local:
            try await localStorage.save(backup)
        case .cloudKit:
            try await cloudStorage.uploadBackup(backup)
        }
    }
    
    /// Generate version string for backup
    private func generateVersion() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy.MM.dd.HHmm"
        return dateFormatter.string(from: Date())
    }
    
    /// Calculate data integrity hash for mind maps
    private func calculateDataIntegrityHash(for mindMaps: [MindMap]) -> String {
        // Create a deterministic hash based on sorted UUIDs and titles
        let sortedData = mindMaps
            .sorted { $0.id.uuidString < $1.id.uuidString }
            .map { "\($0.id.uuidString):\($0.title)" }
            .joined(separator: "|")
        
        return String(sortedData.hashValue)
    }
}