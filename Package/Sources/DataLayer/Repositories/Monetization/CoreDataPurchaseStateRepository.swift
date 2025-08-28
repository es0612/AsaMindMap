import Foundation
import CoreData
import MindMapCore

public class CoreDataPurchaseStateRepository: PurchaseStateRepositoryProtocol {
    private let persistentContainer: NSPersistentContainer
    
    public init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    public func savePurchaseState(_ purchaseState: PurchaseState) async throws {
        let context = persistentContainer.newBackgroundContext()
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Find existing purchase state by productId or create new one
                    let fetchRequest: NSFetchRequest<PurchaseStateEntity> = PurchaseStateEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "id == %@ OR productId == %@", 
                                                       purchaseState.id, purchaseState.productId)
                    fetchRequest.fetchLimit = 1
                    
                    let existingEntity = try context.fetch(fetchRequest).first ?? PurchaseStateEntity(context: context)
                    
                    // Update entity with purchase state
                    existingEntity.id = purchaseState.id
                    existingEntity.productId = purchaseState.productId
                    existingEntity.transactionId = purchaseState.transactionId
                    existingEntity.originalTransactionId = purchaseState.originalTransactionId
                    existingEntity.purchaseDate = purchaseState.purchaseDate
                    existingEntity.isActive = purchaseState.isActive
                    existingEntity.expirationDate = purchaseState.expirationDate
                    existingEntity.isRestored = purchaseState.isRestored
                    existingEntity.validationStatus = purchaseState.validationStatus.rawValue
                    existingEntity.lastValidated = purchaseState.lastValidated
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func getAllPurchaseStates() async throws -> [PurchaseState] {
        let context = persistentContainer.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<PurchaseStateEntity> = PurchaseStateEntity.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "purchaseDate", ascending: false)]
                    
                    let entities = try context.fetch(fetchRequest)
                    let purchaseStates = entities.compactMap { entity -> PurchaseState? in
                        guard let id = entity.id,
                              let productId = entity.productId,
                              let transactionId = entity.transactionId,
                              let originalTransactionId = entity.originalTransactionId,
                              let purchaseDate = entity.purchaseDate,
                              let lastValidated = entity.lastValidated else {
                            return nil
                        }
                        
                        let validationStatus = ValidationStatus(rawValue: entity.validationStatus) ?? .unknown
                        
                        return PurchaseState(
                            id: id,
                            productId: productId,
                            transactionId: transactionId,
                            originalTransactionId: originalTransactionId,
                            purchaseDate: purchaseDate,
                            isActive: entity.isActive,
                            expirationDate: entity.expirationDate,
                            isRestored: entity.isRestored,
                            validationStatus: validationStatus,
                            lastValidated: lastValidated
                        )
                    }
                    
                    continuation.resume(returning: purchaseStates)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func getPurchaseState(for productId: String) async throws -> PurchaseState? {
        let context = persistentContainer.viewContext
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<PurchaseStateEntity> = PurchaseStateEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "productId == %@", productId)
                    fetchRequest.fetchLimit = 1
                    
                    guard let entity = try context.fetch(fetchRequest).first,
                          let id = entity.id,
                          let entityProductId = entity.productId,
                          let transactionId = entity.transactionId,
                          let originalTransactionId = entity.originalTransactionId,
                          let purchaseDate = entity.purchaseDate,
                          let lastValidated = entity.lastValidated else {
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let validationStatus = ValidationStatus(rawValue: entity.validationStatus) ?? .unknown
                    
                    let purchaseState = PurchaseState(
                        id: id,
                        productId: entityProductId,
                        transactionId: transactionId,
                        originalTransactionId: originalTransactionId,
                        purchaseDate: purchaseDate,
                        isActive: entity.isActive,
                        expirationDate: entity.expirationDate,
                        isRestored: entity.isRestored,
                        validationStatus: validationStatus,
                        lastValidated: lastValidated
                    )
                    
                    continuation.resume(returning: purchaseState)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func deletePurchaseState(for productId: String) async throws {
        let context = persistentContainer.newBackgroundContext()
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<PurchaseStateEntity> = PurchaseStateEntity.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "productId == %@", productId)
                    
                    let entities = try context.fetch(fetchRequest)
                    
                    for entity in entities {
                        context.delete(entity)
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    public func deleteAllPurchaseStates() async throws {
        let context = persistentContainer.newBackgroundContext()
        
        return try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<PurchaseStateEntity> = PurchaseStateEntity.fetchRequest()
                    let entities = try context.fetch(fetchRequest)
                    
                    for entity in entities {
                        context.delete(entity)
                    }
                    
                    try context.save()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}