import Foundation
import CloudKit

// MARK: - CloudKit Sync Manager Protocol
public protocol CloudKitSyncManagerProtocol {
    func syncMindMaps() async throws
    func syncMindMap(_ mindMap: MindMap) async throws -> MindMap
    func syncNodes(for mindMapID: UUID) async throws -> [Node]
    func handleConflict(local: MindMap, remote: MindMap) async throws -> MindMap
    func isOfflineMode() -> Bool
    func enableOfflineMode(_ enabled: Bool)
}

// MARK: - Sync Result
public struct SyncResult {
    public let syncedMindMaps: [MindMap]
    public let syncedNodes: [Node]
    public let conflicts: [ConflictResolution]
    public let errors: [SyncError]
    
    public init(
        syncedMindMaps: [MindMap] = [],
        syncedNodes: [Node] = [],
        conflicts: [ConflictResolution] = [],
        errors: [SyncError] = []
    ) {
        self.syncedMindMaps = syncedMindMaps
        self.syncedNodes = syncedNodes
        self.conflicts = conflicts
        self.errors = errors
    }
}

// MARK: - Conflict Resolution
public struct ConflictResolution {
    public let localItem: SyncableItem
    public let remoteItem: SyncableItem
    public let resolvedItem: SyncableItem
    public let strategy: ConflictStrategy
    
    public init(
        localItem: SyncableItem,
        remoteItem: SyncableItem,
        resolvedItem: SyncableItem,
        strategy: ConflictStrategy
    ) {
        self.localItem = localItem
        self.remoteItem = remoteItem
        self.resolvedItem = resolvedItem
        self.strategy = strategy
    }
}

// MARK: - Conflict Strategy
public enum ConflictStrategy {
    case localWins
    case remoteWins
    case merge
    case userChoice
}

// MARK: - Syncable Item
public protocol SyncableItem {
    var id: UUID { get }
    var lastModified: Date { get }
    var version: Int { get }
}

// MARK: - Sync Error
public enum SyncError: Error, Equatable {
    case networkUnavailable
    case iCloudAccountNotFound
    case permissionDenied
    case conflictResolutionFailed
    case dataCorrupted
    case quotaExceeded
    case unknownError(String)
}

// MARK: - CloudKit Record Extensions
extension MindMap: SyncableItem {
    public var lastModified: Date { updatedAt }
}

extension Node: SyncableItem {
    public var lastModified: Date { updatedAt }
    public var version: Int { 1 } // 将来的にバージョン管理を実装
}

// MARK: - CloudKit Sync Manager Implementation
public final class CloudKitSyncManager: CloudKitSyncManagerProtocol {
    
    private let privateDatabase: CKDatabase?
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    private var isOfflineModeEnabled: Bool = false
    private let isTestMode: Bool
    
    // MARK: - Initialization
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        container: CKContainer? = nil,
        isTestMode: Bool = false
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.isTestMode = isTestMode
        
        if isTestMode {
            // テストモードではCloudKitデータベースを使用しない
            self.privateDatabase = nil
        } else if let container = container {
            self.privateDatabase = container.privateCloudDatabase
        } else {
            self.privateDatabase = CKContainer.default().privateCloudDatabase
        }
    }
    
    // MARK: - Public Methods
    public func syncMindMaps() async throws {
        if isOfflineModeEnabled {
            throw SyncError.networkUnavailable
        }
        
        // Get local mind maps
        let localMindMaps = try await mindMapRepository.findAll()
        
        // Fetch remote mind maps from CloudKit
        let remoteRecords = try await fetchMindMapRecords()
        
        // Sync each mind map
        for localMindMap in localMindMaps {
            if let remoteRecord = remoteRecords.first(where: { $0.recordID.recordName == localMindMap.id.uuidString }) {
                // Update remote record if local is newer
                if localMindMap.lastModified > (remoteRecord.modificationDate ?? Date.distantPast) {
                    try await uploadMindMapRecord(localMindMap)
                }
            } else {
                // Upload new mind map to CloudKit
                try await uploadMindMapRecord(localMindMap)
            }
        }
        
        // Download new remote mind maps
        for remoteRecord in remoteRecords {
            let recordID = UUID(uuidString: remoteRecord.recordID.recordName) ?? UUID()
            if try await mindMapRepository.findByID(recordID) == nil {
                let mindMap = try convertRecordToMindMap(remoteRecord)
                try await mindMapRepository.save(mindMap)
            }
        }
    }
    
    public func syncMindMap(_ mindMap: MindMap) async throws -> MindMap {
        if isOfflineModeEnabled {
            throw SyncError.networkUnavailable
        }
        
        // Try to fetch remote version
        do {
            let remoteRecord = try await fetchMindMapRecord(id: mindMap.id)
            
            // Check for conflicts
            if let remoteModification = remoteRecord.modificationDate,
               mindMap.lastModified > remoteModification {
                // Local is newer, upload to CloudKit
                try await uploadMindMapRecord(mindMap)
                return mindMap
            } else {
                // Remote is newer or same, use remote version
                let remoteMindMap = try convertRecordToMindMap(remoteRecord)
                try await mindMapRepository.save(remoteMindMap)
                return remoteMindMap
            }
        } catch {
            // Remote doesn't exist, upload local version
            try await uploadMindMapRecord(mindMap)
            return mindMap
        }
    }
    
    public func syncNodes(for mindMapID: UUID) async throws -> [Node] {
        if isOfflineModeEnabled {
            throw SyncError.networkUnavailable
        }
        
        // Get local nodes
        let localNodes = try await nodeRepository.findByMindMapID(mindMapID)
        
        // Fetch remote nodes from CloudKit
        let remoteRecords = try await fetchNodeRecords(for: mindMapID)
        
        var syncedNodes: [Node] = []
        
        // Sync each local node
        for localNode in localNodes {
            if let remoteRecord = remoteRecords.first(where: { $0.recordID.recordName == localNode.id.uuidString }) {
                // Update based on modification date
                if localNode.lastModified > (remoteRecord.modificationDate ?? Date.distantPast) {
                    try await uploadNodeRecord(localNode, mindMapID: mindMapID)
                    syncedNodes.append(localNode)
                } else {
                    let remoteNode = try convertRecordToNode(remoteRecord)
                    try await nodeRepository.save(remoteNode)
                    syncedNodes.append(remoteNode)
                }
            } else {
                // Upload new node to CloudKit
                try await uploadNodeRecord(localNode, mindMapID: mindMapID)
                syncedNodes.append(localNode)
            }
        }
        
        // Download new remote nodes
        for remoteRecord in remoteRecords {
            let recordID = UUID(uuidString: remoteRecord.recordID.recordName) ?? UUID()
            if !localNodes.contains(where: { $0.id == recordID }) {
                let remoteNode = try convertRecordToNode(remoteRecord)
                try await nodeRepository.save(remoteNode)
                syncedNodes.append(remoteNode)
            }
        }
        
        return syncedNodes
    }
    
    public func handleConflict(local: MindMap, remote: MindMap) async throws -> MindMap {
        // Simple conflict resolution: use the most recently modified version
        if local.lastModified > remote.lastModified {
            return local
        } else {
            return remote
        }
    }
    
    public func isOfflineMode() -> Bool {
        return isOfflineModeEnabled
    }
    
    public func enableOfflineMode(_ enabled: Bool) {
        isOfflineModeEnabled = enabled
    }
    
    // MARK: - Private CloudKit Methods
    
    private func fetchMindMapRecords() async throws -> [CKRecord] {
        if isTestMode {
            // テストモードでは空の配列を返す
            return []
        }
        
        guard let database = privateDatabase else {
            throw SyncError.networkUnavailable
        }
        
        let query = CKQuery(recordType: CloudKitSchema.mindMapRecordType, predicate: NSPredicate(value: true))
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            return matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return record
                case .failure:
                    return nil
                }
            }
        } catch {
            throw mapCloudKitError(error)
        }
    }
    
    private func fetchMindMapRecord(id: UUID) async throws -> CKRecord {
        if isTestMode {
            // テストモードでは例外をスロー
            throw SyncError.dataCorrupted
        }
        
        guard let database = privateDatabase else {
            throw SyncError.networkUnavailable
        }
        
        let recordID = CKRecord.ID(recordName: id.uuidString)
        
        do {
            let record = try await database.record(for: recordID)
            return record
        } catch {
            throw mapCloudKitError(error)
        }
    }
    
    private func fetchNodeRecords(for mindMapID: UUID) async throws -> [CKRecord] {
        if isTestMode {
            // テストモードでは空の配列を返す
            return []
        }
        
        guard let database = privateDatabase else {
            throw SyncError.networkUnavailable
        }
        
        let predicate = NSPredicate(format: "%K == %@", CloudKitSchema.NodeFields.mindMapID, mindMapID.uuidString)
        let query = CKQuery(recordType: CloudKitSchema.nodeRecordType, predicate: predicate)
        
        do {
            let (matchResults, _) = try await database.records(matching: query)
            return matchResults.compactMap { _, result in
                switch result {
                case .success(let record):
                    return record
                case .failure:
                    return nil
                }
            }
        } catch {
            throw mapCloudKitError(error)
        }
    }
    
    private func uploadMindMapRecord(_ mindMap: MindMap) async throws {
        if isTestMode {
            // テストモードでは実際のCloudKit操作を行わない
            return
        }
        
        guard let database = privateDatabase else {
            throw SyncError.networkUnavailable
        }
        
        let record = convertMindMapToRecord(mindMap)
        
        do {
            _ = try await database.save(record)
        } catch {
            throw mapCloudKitError(error)
        }
    }
    
    private func uploadNodeRecord(_ node: Node, mindMapID: UUID) async throws {
        if isTestMode {
            // テストモードでは実際のCloudKit操作を行わない
            return
        }
        
        guard let database = privateDatabase else {
            throw SyncError.networkUnavailable
        }
        
        let record = convertNodeToRecord(node, mindMapID: mindMapID)
        
        do {
            _ = try await database.save(record)
        } catch {
            throw mapCloudKitError(error)
        }
    }
    
    // MARK: - Record Conversion Methods
    
    private func convertMindMapToRecord(_ mindMap: MindMap) -> CKRecord {
        let recordID = CKRecord.ID(recordName: mindMap.id.uuidString)
        let record = CKRecord(recordType: CloudKitSchema.mindMapRecordType, recordID: recordID)
        
        record[CloudKitSchema.MindMapFields.title] = mindMap.title
        record[CloudKitSchema.MindMapFields.rootNodeID] = mindMap.rootNodeID?.uuidString
        record[CloudKitSchema.MindMapFields.nodeIDs] = Array(mindMap.nodeIDs).map { $0.uuidString }
        record[CloudKitSchema.MindMapFields.tagIDs] = Array(mindMap.tagIDs).map { $0.uuidString }
        record[CloudKitSchema.MindMapFields.mediaIDs] = Array(mindMap.mediaIDs).map { $0.uuidString }
        record[CloudKitSchema.MindMapFields.isShared] = mindMap.isShared
        record[CloudKitSchema.MindMapFields.createdAt] = mindMap.createdAt
        record[CloudKitSchema.MindMapFields.updatedAt] = mindMap.updatedAt
        record[CloudKitSchema.MindMapFields.version] = mindMap.version
        
        return record
    }
    
    private func convertRecordToMindMap(_ record: CKRecord) throws -> MindMap {
        guard let title = record[CloudKitSchema.MindMapFields.title] as? String,
              let createdAt = record[CloudKitSchema.MindMapFields.createdAt] as? Date,
              let updatedAt = record[CloudKitSchema.MindMapFields.updatedAt] as? Date,
              let version = record[CloudKitSchema.MindMapFields.version] as? Int else {
            throw SyncError.dataCorrupted
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let rootNodeID = (record[CloudKitSchema.MindMapFields.rootNodeID] as? String).flatMap { UUID(uuidString: $0) }
        let nodeIDStrings = record[CloudKitSchema.MindMapFields.nodeIDs] as? [String] ?? []
        let tagIDStrings = record[CloudKitSchema.MindMapFields.tagIDs] as? [String] ?? []
        let mediaIDStrings = record[CloudKitSchema.MindMapFields.mediaIDs] as? [String] ?? []
        let isShared = record[CloudKitSchema.MindMapFields.isShared] as? Bool ?? false
        
        let nodeIDs = Set(nodeIDStrings.compactMap { UUID(uuidString: $0) })
        let tagIDs = Set(tagIDStrings.compactMap { UUID(uuidString: $0) })
        let mediaIDs = Set(mediaIDStrings.compactMap { UUID(uuidString: $0) })
        
        return MindMap(
            id: id,
            title: title,
            rootNodeID: rootNodeID,
            nodeIDs: nodeIDs,
            tagIDs: tagIDs,
            mediaIDs: mediaIDs,
            isShared: isShared,
            createdAt: createdAt,
            updatedAt: updatedAt,
            version: version
        )
    }
    
    private func convertNodeToRecord(_ node: Node, mindMapID: UUID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: node.id.uuidString)
        let record = CKRecord(recordType: CloudKitSchema.nodeRecordType, recordID: recordID)
        
        record[CloudKitSchema.NodeFields.text] = node.text
        record[CloudKitSchema.NodeFields.position] = "\(node.position.x),\(node.position.y)"
        record[CloudKitSchema.NodeFields.parentID] = node.parentID?.uuidString
        record[CloudKitSchema.NodeFields.mindMapID] = mindMapID.uuidString
        record[CloudKitSchema.NodeFields.mediaIDs] = Array(node.mediaIDs).map { $0.uuidString }
        record[CloudKitSchema.NodeFields.tagIDs] = Array(node.tagIDs).map { $0.uuidString }
        record[CloudKitSchema.NodeFields.isTask] = node.isTask
        record[CloudKitSchema.NodeFields.isCompleted] = node.isCompleted
        record[CloudKitSchema.NodeFields.createdAt] = node.createdAt
        record[CloudKitSchema.NodeFields.updatedAt] = node.updatedAt
        record[CloudKitSchema.NodeFields.version] = node.version
        
        return record
    }
    
    private func convertRecordToNode(_ record: CKRecord) throws -> Node {
        guard let text = record[CloudKitSchema.NodeFields.text] as? String,
              let positionString = record[CloudKitSchema.NodeFields.position] as? String,
              let mindMapIDString = record[CloudKitSchema.NodeFields.mindMapID] as? String,
              let _ = UUID(uuidString: mindMapIDString),
              let createdAt = record[CloudKitSchema.NodeFields.createdAt] as? Date,
              let updatedAt = record[CloudKitSchema.NodeFields.updatedAt] as? Date,
              let _ = record[CloudKitSchema.NodeFields.version] as? Int else {
            throw SyncError.dataCorrupted
        }
        
        let id = UUID(uuidString: record.recordID.recordName) ?? UUID()
        let parentID = (record[CloudKitSchema.NodeFields.parentID] as? String).flatMap { UUID(uuidString: $0) }
        
        // Parse position
        let positionComponents = positionString.components(separatedBy: ",")
        let position = CGPoint(
            x: Double(positionComponents.first ?? "0") ?? 0,
            y: Double(positionComponents.last ?? "0") ?? 0
        )
        
        let mediaIDStrings = record[CloudKitSchema.NodeFields.mediaIDs] as? [String] ?? []
        let tagIDStrings = record[CloudKitSchema.NodeFields.tagIDs] as? [String] ?? []
        let isTask = record[CloudKitSchema.NodeFields.isTask] as? Bool ?? false
        let isCompleted = record[CloudKitSchema.NodeFields.isCompleted] as? Bool ?? false
        
        let mediaIDs = Set(mediaIDStrings.compactMap { UUID(uuidString: $0) })
        let tagIDs = Set(tagIDStrings.compactMap { UUID(uuidString: $0) })
        
        return Node(
            id: id,
            text: text,
            position: position,
            isTask: isTask,
            isCompleted: isCompleted,
            parentID: parentID,
            mediaIDs: mediaIDs,
            tagIDs: tagIDs,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
    
    // MARK: - Error Mapping
    
    private func mapCloudKitError(_ error: Error) -> SyncError {
        guard let ckError = error as? CKError else {
            return .unknownError(error.localizedDescription)
        }
        
        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .notAuthenticated:
            return .iCloudAccountNotFound
        case .permissionFailure:
            return .permissionDenied
        case .quotaExceeded:
            return .quotaExceeded
        case .serverRecordChanged:
            return .conflictResolutionFailed
        default:
            return .unknownError(ckError.localizedDescription)
        }
    }
}

// MARK: - CloudKit Schema Constants
public struct CloudKitSchema {
    public static let mindMapRecordType = "MindMap"
    public static let nodeRecordType = "Node"
    public static let mediaRecordType = "Media"
    public static let tagRecordType = "Tag"
    
    // MindMap record fields
    public struct MindMapFields {
        public static let title = "title"
        public static let rootNodeID = "rootNodeID"
        public static let nodeIDs = "nodeIDs"
        public static let tagIDs = "tagIDs"
        public static let mediaIDs = "mediaIDs"
        public static let isShared = "isShared"
        public static let createdAt = "createdAt"
        public static let updatedAt = "updatedAt"
        public static let version = "version"
    }
    
    // Node record fields
    public struct NodeFields {
        public static let text = "text"
        public static let position = "position"
        public static let parentID = "parentID"
        public static let mindMapID = "mindMapID"
        public static let style = "style"
        public static let mediaIDs = "mediaIDs"
        public static let tagIDs = "tagIDs"
        public static let isTask = "isTask"
        public static let isCompleted = "isCompleted"
        public static let createdAt = "createdAt"
        public static let updatedAt = "updatedAt"
        public static let version = "version"
    }
}