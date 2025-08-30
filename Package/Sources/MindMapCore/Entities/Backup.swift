import Foundation

// MARK: - BackupType
public enum BackupType: String, CaseIterable, Codable {
    case local
    case cloudKit
    
    public var displayName: String {
        switch self {
        case .local:
            return "ローカルバックアップ"
        case .cloudKit:
            return "iCloudバックアップ"
        }
    }
}

// MARK: - Backup Entity
public struct Backup: Identifiable, Codable {
    // MARK: - Properties
    public let id: UUID
    public let mindMaps: [MindMap]
    public let type: BackupType
    public let version: String
    public let createdAt: Date
    public let dataIntegrityHash: String?
    
    // MARK: - Initialization
    public init(
        mindMaps: [MindMap],
        type: BackupType,
        version: String,
        dataIntegrityHash: String? = nil
    ) {
        self.id = UUID()
        self.mindMaps = mindMaps
        self.type = type
        self.version = version
        self.createdAt = Date()
        self.dataIntegrityHash = dataIntegrityHash
    }
    
    // MARK: - Computed Properties
    public var mindMapCount: Int {
        return mindMaps.count
    }
    
    public var totalNodeCount: Int {
        return mindMaps.reduce(0) { $0 + $1.nodeIDs.count }
    }
    
    public var sizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(estimatedSize))
    }
    
    private var estimatedSize: Int {
        // Rough estimation based on content
        let mindMapSize = mindMaps.count * 1024 // 1KB per mind map
        let nodeSize = totalNodeCount * 256 // 256 bytes per node
        return mindMapSize + nodeSize
    }
    
    // MARK: - Business Logic
    public func isValid() -> Bool {
        guard !mindMaps.isEmpty else { return false }
        guard !version.isEmpty else { return false }
        guard dataIntegrityHash != nil && !dataIntegrityHash!.isEmpty else { return false }
        
        // Validate all mind maps have basic required properties
        return mindMaps.allSatisfy { !$0.title.isEmpty }
    }
    
    public func verifyIntegrity() -> Bool {
        guard let hash = dataIntegrityHash, !hash.isEmpty else {
            return false
        }
        
        // In a real implementation, would recalculate and compare hash
        // For now, just check that hash exists and mind maps are valid
        return isValid()
    }
    
    public func containsMindMap(withId id: UUID) -> Bool {
        return mindMaps.contains { $0.id == id }
    }
    
    public func getMindMap(withId id: UUID) -> MindMap? {
        return mindMaps.first { $0.id == id }
    }
}

// MARK: - Extensions
extension Backup: Equatable {
    public static func == (lhs: Backup, rhs: Backup) -> Bool {
        return lhs.id == rhs.id
    }
}

extension Backup: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}