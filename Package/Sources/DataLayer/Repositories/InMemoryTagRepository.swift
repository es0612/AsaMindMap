import Foundation
import MindMapCore

// MARK: - In-Memory Tag Repository (for testing)
@available(iOS 16.0, macOS 13.0, *)
public final class InMemoryTagRepository: TagRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private var tags: [UUID: Tag] = [:]
    private let queue = DispatchQueue(label: "InMemoryTagRepository", attributes: .concurrent)
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Tag Operations
    public func save(_ tag: Tag) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.tags[tag.id] = tag
                continuation.resume()
            }
        }
    }
    
    public func findByID(_ id: UUID) async throws -> Tag? {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.tags[id])
            }
        }
    }
    
    public func findAll() async throws -> [Tag] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let allTags = Array(self.tags.values)
                    .sorted { $0.name < $1.name }
                continuation.resume(returning: allTags)
            }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.tags.removeValue(forKey: id)
                continuation.resume()
            }
        }
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.tags[id] != nil)
            }
        }
    }
    
    // MARK: - Search Operations
    public func findByName(_ name: String) async throws -> [Tag] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.tags.values.filter { tag in
                    tag.name.localizedCaseInsensitiveContains(name)
                }.sorted { $0.name < $1.name }
                
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findByColor(_ color: NodeColor) async throws -> [Tag] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.tags.values.filter { $0.color == color }
                    .sorted { $0.name < $1.name }
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findByNode(_ nodeID: UUID) async throws -> [Tag] {
        // In-memory implementation doesn't track node relationships directly
        // This would need to be implemented based on how you want to associate tags with nodes
        return await withCheckedContinuation { continuation in
            queue.async {
                // For now, return empty array - in a real implementation, you'd filter by nodeID
                continuation.resume(returning: [])
            }
        }
    }
    
    public func findMostUsed(limit: Int) async throws -> [Tag] {
        return await withCheckedContinuation { continuation in
            queue.async {
                // In-memory implementation doesn't track usage count directly
                // For now, return all tags limited by the specified limit
                let limitedTags = Array(self.tags.values.prefix(limit))
                    .sorted { $0.name < $1.name }
                continuation.resume(returning: limitedTags)
            }
        }
    }
    
    // MARK: - Usage Operations
    public func getUsageCount(for tagID: UUID) async throws -> Int {
        // In-memory implementation doesn't track usage count directly
        // For now, return 0
        return 0
    }
    
    public func findUnusedTags() async throws -> [Tag] {
        // In-memory implementation doesn't track usage directly
        // For now, return empty array
        return []
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ tags: [Tag]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for tag in tags {
                    self.tags[tag.id] = tag
                }
                continuation.resume()
            }
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for id in ids {
                    self.tags.removeValue(forKey: id)
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Test Utilities
    public func clear() async {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.tags.removeAll()
                continuation.resume()
            }
        }
    }
    
    public func count() async -> Int {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.tags.count)
            }
        }
    }
}