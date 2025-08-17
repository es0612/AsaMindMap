import Foundation
import CoreData
import MindMapCore

// MARK: - Core Data MindMap Repository
@available(iOS 16.0, macOS 13.0, *)
public final class CoreDataMindMapRepository: MindMapRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    
    // MARK: - Initialization
    public init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - MindMap Operations
    public func save(_ mindMap: MindMap) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            // Check if entity already exists
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", mindMap.id as CVarArg)
            
            let existingEntity = try context.fetch(fetchRequest).first
            let entity = existingEntity ?? MindMapEntity.fromDomainModel(mindMap, context: context)
            
            if existingEntity != nil {
                entity.updateFromDomainModel(mindMap)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func findByID(_ id: UUID) async throws -> MindMap? {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let entity = try context.fetch(fetchRequest).first
            return entity?.toDomainModel()
        }
    }
    
    public func findAll() async throws -> [MindMap] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
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
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let count = try context.count(for: fetchRequest)
            return count > 0
        }
    }
    
    // MARK: - Search Operations
    public func findByTitle(_ title: String) async throws -> [MindMap] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "title CONTAINS[cd] %@", title)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findByDateRange(from: Date, to: Date) async throws -> [MindMap] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "createdAt >= %@ AND createdAt <= %@", from as CVarArg, to as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findShared() async throws -> [MindMap] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "isShared == YES")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findRecentlyModified(limit: Int) async throws -> [MindMap] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            fetchRequest.fetchLimit = limit
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ mindMaps: [MindMap]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            for mindMap in mindMaps {
                let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", mindMap.id as CVarArg)
                
                let existingEntity = try context.fetch(fetchRequest).first
                let entity = existingEntity ?? MindMapEntity.fromDomainModel(mindMap, context: context)
                
                if existingEntity != nil {
                    entity.updateFromDomainModel(mindMap)
                }
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
            
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    // MARK: - Sync Operations
    public func findNeedingSync() async throws -> [MindMap] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "lastSyncedAt == nil OR updatedAt > lastSyncedAt")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func markAsSynced(_ id: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<MindMapEntity> = MindMapEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            
            if let entity = try context.fetch(fetchRequest).first {
                entity.lastSyncedAt = Date()
                try self.coreDataStack.saveContext(context)
            }
        }
    }
}