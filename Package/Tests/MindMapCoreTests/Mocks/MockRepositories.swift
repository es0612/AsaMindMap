import Foundation
@testable import MindMapCore

// MARK: - Mock Node Repository
public class MockNodeRepository: NodeRepositoryProtocol {
    public var nodes: [UUID: Node] = [:]
    public var saveCallCount = 0
    public var deleteCallCount = 0
    
    public init() {}
    
    public func save(_ node: Node) async throws {
        nodes[node.id] = node
        saveCallCount += 1
    }
    
    public func findByID(_ id: UUID) async throws -> Node? {
        return nodes[id]
    }
    
    public func findAll() async throws -> [Node] {
        return Array(nodes.values)
    }
    
    public func delete(_ id: UUID) async throws {
        nodes.removeValue(forKey: id)
        deleteCallCount += 1
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        return nodes[id] != nil
    }
    
    public func findByMindMapID(_ mindMapID: UUID) async throws -> [Node] {
        return Array(nodes.values)
    }
    
    public func findChildren(of parentID: UUID) async throws -> [Node] {
        return nodes.values.filter { $0.parentID == parentID }
    }
    
    public func findParent(of nodeID: UUID) async throws -> Node? {
        guard let node = nodes[nodeID], let parentID = node.parentID else { return nil }
        return nodes[parentID]
    }
    
    public func findRootNodes() async throws -> [Node] {
        return nodes.values.filter { $0.parentID == nil }
    }
    
    public func findByText(_ text: String) async throws -> [Node] {
        return nodes.values.filter { $0.text.contains(text) }
    }
    
    public func findTasks(completed: Bool?) async throws -> [Node] {
        return nodes.values.filter { node in
            guard node.isTask else { return false }
            if let completed = completed {
                return node.isCompleted == completed
            }
            return true
        }
    }
    
    public func findByTag(_ tagID: UUID) async throws -> [Node] {
        return nodes.values.filter { $0.tagIDs.contains(tagID) }
    }
    
    public func saveAll(_ nodes: [Node]) async throws {
        for node in nodes {
            try await save(node)
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        for id in ids {
            try await delete(id)
        }
    }
    
    public func moveNode(_ nodeID: UUID, to newParentID: UUID?) async throws {
        guard var node = nodes[nodeID] else { return }
        node.parentID = newParentID
        nodes[nodeID] = node
    }
    
    public func getNodeHierarchy(_ rootID: UUID) async throws -> [Node] {
        var result: [Node] = []
        if let root = nodes[rootID] {
            result.append(root)
            let children = try await findChildren(of: rootID)
            for child in children {
                let childHierarchy = try await getNodeHierarchy(child.id)
                result.append(contentsOf: childHierarchy)
            }
        }
        return result
    }
}

// MARK: - Mock MindMap Repository
public class MockMindMapRepository: MindMapRepositoryProtocol {
    public var mindMaps: [UUID: MindMap] = [:]
    public var saveCallCount = 0
    public var deleteCallCount = 0
    
    public init() {}
    
    public func save(_ mindMap: MindMap) async throws {
        mindMaps[mindMap.id] = mindMap
        saveCallCount += 1
    }
    
    public func findByID(_ id: UUID) async throws -> MindMap? {
        return mindMaps[id]
    }
    
    public func findAll() async throws -> [MindMap] {
        return Array(mindMaps.values)
    }
    
    public func delete(_ id: UUID) async throws {
        mindMaps.removeValue(forKey: id)
        deleteCallCount += 1
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        return mindMaps[id] != nil
    }
    
    public func findByTitle(_ title: String) async throws -> [MindMap] {
        return mindMaps.values.filter { $0.title.contains(title) }
    }
    
    public func findByDateRange(from: Date, to: Date) async throws -> [MindMap] {
        return mindMaps.values.filter { $0.createdAt >= from && $0.createdAt <= to }
    }
    
    public func findShared() async throws -> [MindMap] {
        return mindMaps.values.filter { $0.isShared }
    }
    
    public func findRecentlyModified(limit: Int) async throws -> [MindMap] {
        return Array(mindMaps.values.sorted { $0.updatedAt > $1.updatedAt }.prefix(limit))
    }
    
    public func saveAll(_ mindMaps: [MindMap]) async throws {
        for mindMap in mindMaps {
            try await save(mindMap)
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        for id in ids {
            try await delete(id)
        }
    }
    
    public func findNeedingSync() async throws -> [MindMap] {
        return mindMaps.values.filter { $0.needsSync }
    }
    
    public func markAsSynced(_ id: UUID) async throws {
        guard var mindMap = mindMaps[id] else { return }
        mindMap.markAsSynced()
        mindMaps[id] = mindMap
    }
}

// MARK: - Mock Media Repository
public class MockMediaRepository: MediaRepositoryProtocol {
    public var media: [UUID: Media] = [:]
    public var saveCallCount = 0
    public var deleteCallCount = 0
    
    public init() {}
    
    public func save(_ media: Media) async throws {
        self.media[media.id] = media
        saveCallCount += 1
    }
    
    public func findByID(_ id: UUID) async throws -> Media? {
        return media[id]
    }
    
    public func findAll() async throws -> [Media] {
        return Array(media.values)
    }
    
    public func delete(_ id: UUID) async throws {
        media.removeValue(forKey: id)
        deleteCallCount += 1
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        return media[id] != nil
    }
    
    public func findByType(_ type: MediaType) async throws -> [Media] {
        return media.values.filter { $0.type == type }
    }
    
    public func findByNode(_ nodeID: UUID) async throws -> [Media] {
        // Mock implementation - in real implementation this would filter by node relationship
        return Array(media.values)
    }
    
    public func saveMediaData(_ data: Data, for mediaID: UUID) async throws {
        // Mock implementation
    }
    
    public func loadMediaData(for mediaID: UUID) async throws -> Data? {
        return media[mediaID]?.data
    }
    
    public func deleteMediaData(for mediaID: UUID) async throws {
        // Mock implementation
    }
    
    public func saveAll(_ media: [Media]) async throws {
        for item in media {
            try await save(item)
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        for id in ids {
            try await delete(id)
        }
    }
    
    public func findOrphanedMedia() async throws -> [Media] {
        return []
    }
    
    public func cleanupOrphanedMedia() async throws {
        // Mock implementation
    }
}