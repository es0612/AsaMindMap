import Foundation

// MARK: - MindMap Entity
public struct MindMap: Identifiable, Equatable, Codable {
    public let id: UUID
    public var title: String
    public var rootNodeID: UUID?
    public var nodeIDs: Set<UUID>
    public var tagIDs: Set<UUID>
    public var mediaIDs: Set<UUID>
    public var isShared: Bool
    public var shareURL: String?
    public var sharePermissions: SharePermissions
    public let createdAt: Date
    public var updatedAt: Date
    public var lastSyncedAt: Date?
    public var version: Int
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        title: String,
        rootNodeID: UUID? = nil,
        nodeIDs: Set<UUID> = [],
        tagIDs: Set<UUID> = [],
        mediaIDs: Set<UUID> = [],
        isShared: Bool = false,
        shareURL: String? = nil,
        sharePermissions: SharePermissions = .private,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastSyncedAt: Date? = nil,
        version: Int = 1
    ) {
        self.id = id
        self.title = title
        self.rootNodeID = rootNodeID
        self.nodeIDs = nodeIDs
        self.tagIDs = tagIDs
        self.mediaIDs = mediaIDs
        self.isShared = isShared
        self.shareURL = shareURL
        self.sharePermissions = sharePermissions
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.version = version
    }
    
    // MARK: - Computed Properties
    public var hasNodes: Bool {
        !nodeIDs.isEmpty
    }
    
    public var hasRootNode: Bool {
        rootNodeID != nil
    }
    
    public var nodeCount: Int {
        nodeIDs.count
    }
    
    public var isEmpty: Bool {
        nodeIDs.isEmpty
    }
    
    public var needsSync: Bool {
        guard let lastSynced = lastSyncedAt else { return true }
        return updatedAt > lastSynced
    }
    
    // MARK: - Mutating Methods
    public mutating func updateTitle(_ newTitle: String) {
        title = newTitle
        incrementVersion()
    }
    
    public mutating func setRootNode(_ nodeID: UUID) {
        rootNodeID = nodeID
        nodeIDs.insert(nodeID)
        incrementVersion()
    }
    
    public mutating func addNode(_ nodeID: UUID) {
        nodeIDs.insert(nodeID)
        incrementVersion()
    }
    
    public mutating func removeNode(_ nodeID: UUID) {
        nodeIDs.remove(nodeID)
        if rootNodeID == nodeID {
            rootNodeID = nil
        }
        incrementVersion()
    }
    
    public mutating func addTag(_ tagID: UUID) {
        tagIDs.insert(tagID)
        incrementVersion()
    }
    
    public mutating func removeTag(_ tagID: UUID) {
        tagIDs.remove(tagID)
        incrementVersion()
    }
    
    public mutating func addMedia(_ mediaID: UUID) {
        mediaIDs.insert(mediaID)
        incrementVersion()
    }
    
    public mutating func removeMedia(_ mediaID: UUID) {
        mediaIDs.remove(mediaID)
        incrementVersion()
    }
    
    public mutating func enableSharing(url: String, permissions: SharePermissions = .readOnly) {
        isShared = true
        shareURL = url
        sharePermissions = permissions
        incrementVersion()
    }
    
    public mutating func disableSharing() {
        isShared = false
        shareURL = nil
        sharePermissions = .private
        incrementVersion()
    }
    
    public mutating func markAsSynced() {
        lastSyncedAt = Date()
    }
    
    private mutating func incrementVersion() {
        version += 1
        updatedAt = Date()
    }
}

// MARK: - Share Permissions
public enum SharePermissions: String, CaseIterable, Codable {
    case `private` = "private"
    case readOnly = "readOnly"
    case readWrite = "readWrite"
    
    public var displayName: String {
        switch self {
        case .private: return "プライベート"
        case .readOnly: return "読み取り専用"
        case .readWrite: return "読み書き可能"
        }
    }
    
    public var canRead: Bool {
        self != .private
    }
    
    public var canWrite: Bool {
        self == .readWrite
    }
}