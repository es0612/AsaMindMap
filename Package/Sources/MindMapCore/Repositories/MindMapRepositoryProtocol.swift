import Foundation

// MARK: - MindMap Repository Protocol
public protocol MindMapRepositoryProtocol {
    // MARK: - MindMap Operations
    func save(_ mindMap: MindMap) async throws
    func findByID(_ id: UUID) async throws -> MindMap?
    func findAll() async throws -> [MindMap]
    func delete(_ id: UUID) async throws
    func exists(_ id: UUID) async throws -> Bool
    
    // MARK: - Search Operations
    func findByTitle(_ title: String) async throws -> [MindMap]
    func findByDateRange(from: Date, to: Date) async throws -> [MindMap]
    func findShared() async throws -> [MindMap]
    func findRecentlyModified(limit: Int) async throws -> [MindMap]
    
    // MARK: - Batch Operations
    func saveAll(_ mindMaps: [MindMap]) async throws
    func deleteAll(_ ids: [UUID]) async throws
    
    // MARK: - Sync Operations
    func findNeedingSync() async throws -> [MindMap]
    func markAsSynced(_ id: UUID) async throws
}

// MARK: - Node Repository Protocol
public protocol NodeRepositoryProtocol {
    // MARK: - Node Operations
    func save(_ node: Node) async throws
    func findByID(_ id: UUID) async throws -> Node?
    func findAll() async throws -> [Node]
    func delete(_ id: UUID) async throws
    func exists(_ id: UUID) async throws -> Bool
    
    // MARK: - Relationship Operations
    func findByMindMapID(_ mindMapID: UUID) async throws -> [Node]
    func findChildren(of parentID: UUID) async throws -> [Node]
    func findParent(of nodeID: UUID) async throws -> Node?
    func findRootNodes() async throws -> [Node]
    
    // MARK: - Search Operations
    func findByText(_ text: String) async throws -> [Node]
    func findTasks(completed: Bool?) async throws -> [Node]
    func findByTag(_ tagID: UUID) async throws -> [Node]
    
    // MARK: - Batch Operations
    func saveAll(_ nodes: [Node]) async throws
    func deleteAll(_ ids: [UUID]) async throws
    
    // MARK: - Hierarchy Operations
    func moveNode(_ nodeID: UUID, to newParentID: UUID?) async throws
    func getNodeHierarchy(_ rootID: UUID) async throws -> [Node]
}

// MARK: - Media Repository Protocol
public protocol MediaRepositoryProtocol {
    // MARK: - Media Operations
    func save(_ media: Media) async throws
    func findByID(_ id: UUID) async throws -> Media?
    func findAll() async throws -> [Media]
    func delete(_ id: UUID) async throws
    func exists(_ id: UUID) async throws -> Bool
    
    // MARK: - Type-based Operations
    func findByType(_ type: MediaType) async throws -> [Media]
    func findByNode(_ nodeID: UUID) async throws -> [Media]
    
    // MARK: - Storage Operations
    func saveMediaData(_ data: Data, for mediaID: UUID) async throws
    func loadMediaData(for mediaID: UUID) async throws -> Data?
    func deleteMediaData(for mediaID: UUID) async throws
    
    // MARK: - Batch Operations
    func saveAll(_ media: [Media]) async throws
    func deleteAll(_ ids: [UUID]) async throws
    
    // MARK: - Cleanup Operations
    func findOrphanedMedia() async throws -> [Media]
    func cleanupOrphanedMedia() async throws
}

// MARK: - Tag Repository Protocol
public protocol TagRepositoryProtocol {
    // MARK: - Tag Operations
    func save(_ tag: Tag) async throws
    func findByID(_ id: UUID) async throws -> Tag?
    func findAll() async throws -> [Tag]
    func delete(_ id: UUID) async throws
    func exists(_ id: UUID) async throws -> Bool
    
    // MARK: - Search Operations
    func findByName(_ name: String) async throws -> [Tag]
    func findByColor(_ color: NodeColor) async throws -> [Tag]
    func findByNode(_ nodeID: UUID) async throws -> [Tag]
    func findMostUsed(limit: Int) async throws -> [Tag]
    
    // MARK: - Usage Operations
    func getUsageCount(for tagID: UUID) async throws -> Int
    func findUnusedTags() async throws -> [Tag]
    
    // MARK: - Batch Operations
    func saveAll(_ tags: [Tag]) async throws
    func deleteAll(_ ids: [UUID]) async throws
}