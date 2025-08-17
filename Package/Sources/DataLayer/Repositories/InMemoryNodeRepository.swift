import Foundation
import MindMapCore

// MARK: - In-Memory Node Repository (for testing)
@available(iOS 16.0, macOS 13.0, *)
public final class InMemoryNodeRepository: NodeRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private var nodes: [UUID: Node] = [:]
    private let queue = DispatchQueue(label: "InMemoryNodeRepository", attributes: .concurrent)
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Node Operations
    public func save(_ node: Node) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.nodes[node.id] = node
                continuation.resume()
            }
        }
    }
    
    public func findByID(_ id: UUID) async throws -> Node? {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.nodes[id])
            }
        }
    }
    
    public func findAll() async throws -> [Node] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let allNodes = Array(self.nodes.values)
                    .sorted { $0.createdAt < $1.createdAt }
                continuation.resume(returning: allNodes)
            }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.nodes.removeValue(forKey: id)
                continuation.resume()
            }
        }
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.nodes[id] != nil)
            }
        }
    }
    
    // MARK: - Relationship Operations
    public func findByMindMapID(_ mindMapID: UUID) async throws -> [Node] {
        // In-memory implementation doesn't track MindMap relationships directly
        // This would need to be implemented based on how you want to associate nodes with mind maps
        return await withCheckedContinuation { continuation in
            queue.async {
                // For now, return all nodes - in a real implementation, you'd filter by mindMapID
                let allNodes = Array(self.nodes.values)
                    .sorted { $0.createdAt < $1.createdAt }
                continuation.resume(returning: allNodes)
            }
        }
    }
    
    public func findChildren(of parentID: UUID) async throws -> [Node] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let children = self.nodes.values.filter { node in
                    node.parentID == parentID
                }.sorted { $0.createdAt < $1.createdAt }
                
                continuation.resume(returning: Array(children))
            }
        }
    }
    
    public func findParent(of nodeID: UUID) async throws -> Node? {
        return await withCheckedContinuation { continuation in
            queue.async {
                guard let node = self.nodes[nodeID],
                      let parentID = node.parentID else {
                    continuation.resume(returning: nil)
                    return
                }
                
                continuation.resume(returning: self.nodes[parentID])
            }
        }
    }
    
    public func findRootNodes() async throws -> [Node] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let rootNodes = self.nodes.values.filter { node in
                    node.parentID == nil
                }.sorted { $0.createdAt < $1.createdAt }
                
                continuation.resume(returning: Array(rootNodes))
            }
        }
    }
    
    // MARK: - Search Operations
    public func findByText(_ text: String) async throws -> [Node] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.nodes.values.filter { node in
                    node.text.localizedCaseInsensitiveContains(text)
                }.sorted { $0.updatedAt > $1.updatedAt }
                
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findTasks(completed: Bool?) async throws -> [Node] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.nodes.values.filter { node in
                    guard node.isTask else { return false }
                    
                    if let completed = completed {
                        return node.isCompleted == completed
                    }
                    return true
                }.sorted { $0.updatedAt > $1.updatedAt }
                
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findByTag(_ tagID: UUID) async throws -> [Node] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.nodes.values.filter { node in
                    node.tagIDs.contains(tagID)
                }.sorted { $0.updatedAt > $1.updatedAt }
                
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ nodes: [Node]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for node in nodes {
                    self.nodes[node.id] = node
                }
                continuation.resume()
            }
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for id in ids {
                    self.nodes.removeValue(forKey: id)
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Hierarchy Operations
    public func moveNode(_ nodeID: UUID, to newParentID: UUID?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                guard var node = self.nodes[nodeID] else {
                    continuation.resume(throwing: NSError(domain: "NodeNotFound", code: 404, userInfo: nil))
                    return
                }
                
                node.parentID = newParentID
                node.updatedAt = Date()
                self.nodes[nodeID] = node
                continuation.resume()
            }
        }
    }
    
    public func getNodeHierarchy(_ rootID: UUID) async throws -> [Node] {
        return await withCheckedContinuation { continuation in
            queue.async {
                var allNodes: [Node] = []
                var nodesToProcess: [UUID] = [rootID]
                
                while !nodesToProcess.isEmpty {
                    let currentNodeID = nodesToProcess.removeFirst()
                    
                    if let node = self.nodes[currentNodeID] {
                        allNodes.append(node)
                        
                        // Add children to processing queue
                        let children = self.nodes.values.filter { $0.parentID == currentNodeID }
                        nodesToProcess.append(contentsOf: children.map { $0.id })
                    }
                }
                
                continuation.resume(returning: allNodes)
            }
        }
    }
    
    // MARK: - Test Utilities
    public func clear() async {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.nodes.removeAll()
                continuation.resume()
            }
        }
    }
    
    public func count() async -> Int {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.nodes.count)
            }
        }
    }
}