import Foundation
import MindMapCore

// MARK: - In-Memory MindMap Repository (for testing)
@available(iOS 16.0, macOS 13.0, *)
public final class InMemoryMindMapRepository: MindMapRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private var mindMaps: [UUID: MindMap] = [:]
    private let queue = DispatchQueue(label: "InMemoryMindMapRepository", attributes: .concurrent)
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - MindMap Operations
    public func save(_ mindMap: MindMap) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.mindMaps[mindMap.id] = mindMap
                continuation.resume()
            }
        }
    }
    
    public func findByID(_ id: UUID) async throws -> MindMap? {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.mindMaps[id])
            }
        }
    }
    
    public func findAll() async throws -> [MindMap] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let allMindMaps = Array(self.mindMaps.values)
                    .sorted { $0.updatedAt > $1.updatedAt }
                continuation.resume(returning: allMindMaps)
            }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.mindMaps.removeValue(forKey: id)
                continuation.resume()
            }
        }
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.mindMaps[id] != nil)
            }
        }
    }
    
    // MARK: - Search Operations
    public func findByTitle(_ title: String) async throws -> [MindMap] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.mindMaps.values.filter { mindMap in
                    mindMap.title.localizedCaseInsensitiveContains(title)
                }.sorted { $0.updatedAt > $1.updatedAt }
                
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findByDateRange(from: Date, to: Date) async throws -> [MindMap] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.mindMaps.values.filter { mindMap in
                    mindMap.createdAt >= from && mindMap.createdAt <= to
                }.sorted { $0.createdAt > $1.createdAt }
                
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findShared() async throws -> [MindMap] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.mindMaps.values.filter { $0.isShared }
                    .sorted { $0.updatedAt > $1.updatedAt }
                
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findRecentlyModified(limit: Int) async throws -> [MindMap] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let sorted = self.mindMaps.values
                    .sorted { $0.updatedAt > $1.updatedAt }
                    .prefix(limit)
                
                continuation.resume(returning: Array(sorted))
            }
        }
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ mindMaps: [MindMap]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for mindMap in mindMaps {
                    self.mindMaps[mindMap.id] = mindMap
                }
                continuation.resume()
            }
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for id in ids {
                    self.mindMaps.removeValue(forKey: id)
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Sync Operations
    public func findNeedingSync() async throws -> [MindMap] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let needingSync = self.mindMaps.values.filter { mindMap in
                    mindMap.needsSync
                }.sorted { $0.updatedAt > $1.updatedAt }
                
                continuation.resume(returning: Array(needingSync))
            }
        }
    }
    
    public func markAsSynced(_ id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                if var mindMap = self.mindMaps[id] {
                    mindMap.markAsSynced()
                    self.mindMaps[id] = mindMap
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Test Utilities
    public func clear() async {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.mindMaps.removeAll()
                continuation.resume()
            }
        }
    }
    
    public func count() async -> Int {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.mindMaps.count)
            }
        }
    }
}