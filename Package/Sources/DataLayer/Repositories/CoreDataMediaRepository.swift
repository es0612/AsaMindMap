import Foundation
import CoreData
import MindMapCore

// MARK: - Core Data Media Repository
@available(iOS 16.0, macOS 13.0, *)
public final class CoreDataMediaRepository: MediaRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    
    // MARK: - Initialization
    public init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Media Operations
    public func save(_ media: Media) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            // Check if entity already exists
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", media.id as CVarArg)
            
            let existingEntity = try context.fetch(fetchRequest).first
            let entity = existingEntity ?? MediaEntity.fromDomainModel(media, context: context)
            
            if existingEntity != nil {
                entity.updateFromDomainModel(media)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func findByID(_ id: UUID) async throws -> Media? {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let entity = try context.fetch(fetchRequest).first
            return entity?.toDomainModel()
        }
    }
    
    public func findAll() async throws -> [Media] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func exists(_ id: UUID) async throws -> Bool {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let count = try context.count(for: fetchRequest)
            return count > 0
        }
    }
    
    // MARK: - Type-based Operations
    public func findByType(_ type: MediaType) async throws -> [Media] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "type == %@", type.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findByNode(_ nodeID: UUID) async throws -> [Media] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ANY nodes.id == %@", nodeID as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    // MARK: - Storage Operations
    public func saveMediaData(_ data: Data, for mediaID: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            
            guard let entity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.fetchError(NSError(domain: "MediaNotFound", code: 404, userInfo: nil))
            }
            
            entity.data = data
            entity.fileSize = Int64(data.count)
            entity.updatedAt = Date()
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func loadMediaData(for mediaID: UUID) async throws -> Data? {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let entity = try context.fetch(fetchRequest).first
            return entity?.data
        }
    }
    
    public func deleteMediaData(for mediaID: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", mediaID as CVarArg)
            
            guard let entity = try context.fetch(fetchRequest).first else {
                return // Media not found, nothing to delete
            }
            
            entity.data = nil
            entity.thumbnailData = nil
            entity.fileSize = 0
            entity.updatedAt = Date()
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ media: [Media]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            for mediaItem in media {
                let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", mediaItem.id as CVarArg)
                
                let existingEntity = try context.fetch(fetchRequest).first
                let entity = existingEntity ?? MediaEntity.fromDomainModel(mediaItem, context: context)
                
                if existingEntity != nil {
                    entity.updateFromDomainModel(mediaItem)
                }
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
            
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    // MARK: - Cleanup Operations
    public func findOrphanedMedia() async throws -> [Media] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MediaEntity> = MediaEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "nodes.@count == 0 AND mindMap == nil")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func cleanupOrphanedMedia() async throws {
        let orphanedMedia = try await findOrphanedMedia()
        let orphanedIDs = orphanedMedia.map { $0.id }
        
        if !orphanedIDs.isEmpty {
            try await deleteAll(orphanedIDs)
        }
    }
}