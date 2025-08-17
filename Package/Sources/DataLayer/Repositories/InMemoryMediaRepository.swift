import Foundation
import MindMapCore

// MARK: - In-Memory Media Repository (for testing)
@available(iOS 16.0, macOS 13.0, *)
public final class InMemoryMediaRepository: MediaRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private var media: [UUID: Media] = [:]
    private let queue = DispatchQueue(label: "InMemoryMediaRepository", attributes: .concurrent)
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Media Operations
    public func save(_ media: Media) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.media[media.id] = media
                continuation.resume()
            }
        }
    }
    
    public func findByID(_ id: UUID) async throws -> Media? {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.media[id])
            }
        }
    }
    
    public func findAll() async throws -> [Media] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let allMedia = Array(self.media.values)
                    .sorted { $0.createdAt > $1.createdAt }
                continuation.resume(returning: allMedia)
            }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                self.media.removeValue(forKey: id)
                continuation.resume()
            }
        }
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.media[id] != nil)
            }
        }
    }
    
    // MARK: - Type-based Operations
    public func findByType(_ type: MediaType) async throws -> [Media] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let filtered = self.media.values.filter { $0.type == type }
                    .sorted { $0.createdAt > $1.createdAt }
                continuation.resume(returning: Array(filtered))
            }
        }
    }
    
    public func findByNode(_ nodeID: UUID) async throws -> [Media] {
        // In-memory implementation doesn't track node relationships directly
        // This would need to be implemented based on how you want to associate media with nodes
        return await withCheckedContinuation { continuation in
            queue.async {
                // For now, return empty array - in a real implementation, you'd filter by nodeID
                continuation.resume(returning: [])
            }
        }
    }
    
    // MARK: - Storage Operations
    public func saveMediaData(_ data: Data, for mediaID: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                guard var mediaItem = self.media[mediaID] else {
                    continuation.resume(throwing: NSError(domain: "MediaNotFound", code: 404, userInfo: nil))
                    return
                }
                
                mediaItem.updateData(data)
                self.media[mediaID] = mediaItem
                continuation.resume()
            }
        }
    }
    
    public func loadMediaData(for mediaID: UUID) async throws -> Data? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let mediaItem = self.media[mediaID]
                continuation.resume(returning: mediaItem?.data)
            }
        }
    }
    
    public func deleteMediaData(for mediaID: UUID) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                guard var mediaItem = self.media[mediaID] else {
                    continuation.resume()
                    return
                }
                
                mediaItem.data = nil
                mediaItem.thumbnailData = nil
                mediaItem.fileSize = nil
                self.media[mediaID] = mediaItem
                continuation.resume()
            }
        }
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ media: [Media]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for mediaItem in media {
                    self.media[mediaItem.id] = mediaItem
                }
                continuation.resume()
            }
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                for id in ids {
                    self.media.removeValue(forKey: id)
                }
                continuation.resume()
            }
        }
    }
    
    // MARK: - Cleanup Operations
    public func findOrphanedMedia() async throws -> [Media] {
        // In-memory implementation doesn't track relationships directly
        // For now, return empty array
        return []
    }
    
    public func cleanupOrphanedMedia() async throws {
        // No-op for in-memory implementation
    }
    
    // MARK: - Test Utilities
    public func clear() async {
        await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.media.removeAll()
                continuation.resume()
            }
        }
    }
    
    public func count() async -> Int {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.media.count)
            }
        }
    }
}