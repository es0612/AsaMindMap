import Foundation
import MindMapCore

public class InMemoryPurchaseStateRepository: PurchaseStateRepositoryProtocol {
    private var purchaseStates: [String: PurchaseState] = [:] // keyed by product ID
    private let lock = NSLock()
    
    public init(initialStates: [PurchaseState] = []) {
        for state in initialStates {
            self.purchaseStates[state.productId] = state
        }
    }
    
    public func savePurchaseState(_ purchaseState: PurchaseState) async throws {
        lock.withLock {
            self.purchaseStates[purchaseState.productId] = purchaseState
        }
    }
    
    public func getAllPurchaseStates() async throws -> [PurchaseState] {
        lock.withLock {
            return Array(purchaseStates.values).sorted { $0.purchaseDate > $1.purchaseDate }
        }
    }
    
    public func getPurchaseState(for productId: String) async throws -> PurchaseState? {
        lock.withLock {
            return purchaseStates[productId]
        }
    }
    
    public func deletePurchaseState(for productId: String) async throws {
        lock.withLock {
            purchaseStates.removeValue(forKey: productId)
        }
    }
    
    public func deleteAllPurchaseStates() async throws {
        lock.withLock {
            purchaseStates.removeAll()
        }
    }
}