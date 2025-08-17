import Foundation
import CoreData
import MindMapCore

// MARK: - Core Data Stack
@available(iOS 16.0, macOS 13.0, *)
public class CoreDataStack {
    
    // MARK: - Singleton
    public static let shared = CoreDataStack()
    
    // MARK: - Properties
    private let modelName = "MindMapDataModel"
    
    // MARK: - Core Data Stack
    public lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: modelName)
        
        // Configure store description
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        storeDescription?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { [weak self] _, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Core Data error: \(error), \(error.userInfo)")
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    public var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Background Context
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
    
    // MARK: - Save Context
    public func saveContext() throws {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            try context.save()
        }
    }
    
    public func saveContext(_ context: NSManagedObjectContext) throws {
        if context.hasChanges {
            try context.save()
        }
    }
    
    // MARK: - Batch Operations
    public func performBatchDelete(entityName: String, predicate: NSPredicate? = nil) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetchRequest.predicate = predicate
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        deleteRequest.resultType = .resultTypeObjectIDs
        
        let result = try viewContext.execute(deleteRequest) as? NSBatchDeleteResult
        let objectIDArray = result?.result as? [NSManagedObjectID]
        let changes = [NSDeletedObjectsKey: objectIDArray ?? []]
        
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
    }
    
    // MARK: - Private Initialization
    private init() {}
}

// MARK: - Error Handling
public enum CoreDataError: LocalizedError {
    case saveError(Error)
    case fetchError(Error)
    case deleteError(Error)
    case contextError(String)
    
    public var errorDescription: String? {
        switch self {
        case .saveError(let error):
            return "保存エラー: \(error.localizedDescription)"
        case .fetchError(let error):
            return "取得エラー: \(error.localizedDescription)"
        case .deleteError(let error):
            return "削除エラー: \(error.localizedDescription)"
        case .contextError(let message):
            return "コンテキストエラー: \(message)"
        }
    }
}