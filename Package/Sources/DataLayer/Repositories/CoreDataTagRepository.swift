import Foundation
import CoreData
import MindMapCore

// MARK: - Core Data Tag Repository
@available(iOS 16.0, macOS 13.0, *)
public final class CoreDataTagRepository: TagRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    
    // MARK: - Initialization
    public init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Tag Operations
    public func save(_ tag: Tag) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            // Check if entity already exists
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
            
            let existingEntity = try context.fetch(fetchRequest).first
            let entity = existingEntity ?? TagEntity.fromDomainModel(tag, context: context)
            
            if existingEntity != nil {
                entity.updateFromDomainModel(tag)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func findByID(_ id: UUID) async throws -> Tag? {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let entity = try context.fetch(fetchRequest).first
            return entity?.toDomainModel()
        }
    }
    
    public func findAll() async throws -> [Tag] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
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
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let count = try context.count(for: fetchRequest)
            return count > 0
        }
    }
    
    // MARK: - Search Operations
    public func findByName(_ name: String) async throws -> [Tag] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name CONTAINS[cd] %@", name)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findByColor(_ color: NodeColor) async throws -> [Tag] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "color == %@", color.rawValue)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findByNode(_ nodeID: UUID) async throws -> [Tag] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ANY nodes.id == %@", nodeID as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findMostUsed(limit: Int) async throws -> [Tag] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "nodes.@count", ascending: false)]
            fetchRequest.fetchLimit = limit
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    // MARK: - Usage Operations
    public func getUsageCount(for tagID: UUID) async throws -> Int {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", tagID as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let entity = try context.fetch(fetchRequest).first else {
                return 0
            }
            
            return entity.nodes?.count ?? 0
        }
    }
    
    public func findUnusedTags() async throws -> [Tag] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "nodes.@count == 0")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ tags: [Tag]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            for tag in tags {
                let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", tag.id as CVarArg)
                
                let existingEntity = try context.fetch(fetchRequest).first
                let entity = existingEntity ?? TagEntity.fromDomainModel(tag, context: context)
                
                if existingEntity != nil {
                    entity.updateFromDomainModel(tag)
                }
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
            
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
}