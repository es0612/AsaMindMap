import Foundation
import CoreData
import MindMapCore

// MARK: - Core Data Node Repository
@available(iOS 16.0, macOS 13.0, *)
public final class CoreDataNodeRepository: NodeRepositoryProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let coreDataStack: CoreDataStack
    
    // MARK: - Initialization
    public init(coreDataStack: CoreDataStack = .shared) {
        self.coreDataStack = coreDataStack
    }
    
    // MARK: - Node Operations
    public func save(_ node: Node) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            // Check if entity already exists
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", node.id as CVarArg)
            
            let existingEntity = try context.fetch(fetchRequest).first
            let entity = existingEntity ?? NodeEntity.fromDomainModel(node, context: context)
            
            if existingEntity != nil {
                entity.updateFromDomainModel(node)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func findByID(_ id: UUID) async throws -> Node? {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let entity = try context.fetch(fetchRequest).first
            return entity?.toDomainModel()
        }
    }
    
    public func findAll() async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func delete(_ id: UUID) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
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
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            fetchRequest.fetchLimit = 1
            
            let count = try context.count(for: fetchRequest)
            return count > 0
        }
    }
    
    // MARK: - Relationship Operations
    public func findByMindMapID(_ mindMapID: UUID) async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "mindMap.id == %@", mindMapID as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findChildren(of parentID: UUID) async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "parentID == %@", parentID as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findParent(of nodeID: UUID) async throws -> Node? {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", nodeID as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let nodeEntity = try context.fetch(fetchRequest).first,
                  let parentID = nodeEntity.parentID else {
                return nil
            }
            
            let parentFetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            parentFetchRequest.predicate = NSPredicate(format: "id == %@", parentID as CVarArg)
            parentFetchRequest.fetchLimit = 1
            
            let parentEntity = try context.fetch(parentFetchRequest).first
            return parentEntity?.toDomainModel()
        }
    }
    
    public func findRootNodes() async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "parentID == nil")
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    // MARK: - Search Operations
    public func findByText(_ text: String) async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "text CONTAINS[cd] %@", text)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findTasks(completed: Bool?) async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            var predicate = NSPredicate(format: "isTask == YES")
            
            if let completed = completed {
                let completedPredicate = NSPredicate(format: "isCompleted == %@", NSNumber(value: completed))
                predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, completedPredicate])
            }
            
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = predicate
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    public func findByTag(_ tagID: UUID) async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "ANY tags.id == %@", tagID as CVarArg)
            fetchRequest.sortDescriptors = [NSSortDescriptor(key: "updatedAt", ascending: false)]
            
            let entities = try context.fetch(fetchRequest)
            return entities.map { $0.toDomainModel() }
        }
    }
    
    // MARK: - Batch Operations
    public func saveAll(_ nodes: [Node]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            for node in nodes {
                let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "id == %@", node.id as CVarArg)
                
                let existingEntity = try context.fetch(fetchRequest).first
                let entity = existingEntity ?? NodeEntity.fromDomainModel(node, context: context)
                
                if existingEntity != nil {
                    entity.updateFromDomainModel(node)
                }
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func deleteAll(_ ids: [UUID]) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids)
            
            let entities = try context.fetch(fetchRequest)
            for entity in entities {
                context.delete(entity)
            }
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    // MARK: - Hierarchy Operations
    public func moveNode(_ nodeID: UUID, to newParentID: UUID?) async throws {
        let context = coreDataStack.newBackgroundContext()
        
        try await context.perform {
            let fetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", nodeID as CVarArg)
            
            guard let nodeEntity = try context.fetch(fetchRequest).first else {
                throw CoreDataError.fetchError(NSError(domain: "NodeNotFound", code: 404, userInfo: nil))
            }
            
            nodeEntity.parentID = newParentID
            nodeEntity.updatedAt = Date()
            
            try self.coreDataStack.saveContext(context)
        }
    }
    
    public func getNodeHierarchy(_ rootID: UUID) async throws -> [Node] {
        let context = coreDataStack.viewContext
        
        return try await context.perform {
            var allNodes: [Node] = []
            var nodesToProcess: [UUID] = [rootID]
            
            while !nodesToProcess.isEmpty {
                let currentNodeID = nodesToProcess.removeFirst()
                
                // Get current node
                let nodeFetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
                nodeFetchRequest.predicate = NSPredicate(format: "id == %@", currentNodeID as CVarArg)
                
                if let nodeEntity = try context.fetch(nodeFetchRequest).first {
                    allNodes.append(nodeEntity.toDomainModel())
                    
                    // Get children
                    let childrenFetchRequest: NSFetchRequest<NodeEntity> = NodeEntity.fetchRequest()
                    childrenFetchRequest.predicate = NSPredicate(format: "parentID == %@", currentNodeID as CVarArg)
                    
                    let childEntities = try context.fetch(childrenFetchRequest)
                    let childIDs = childEntities.map { $0.id! }
                    nodesToProcess.append(contentsOf: childIDs)
                }
            }
            
            return allNodes
        }
    }
}