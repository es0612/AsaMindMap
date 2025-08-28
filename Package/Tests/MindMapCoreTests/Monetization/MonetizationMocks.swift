import Foundation
import Combine
@testable import MindMapCore

// MARK: - Mock StoreKit Service

class MockStoreKitService: StoreKitServiceProtocol {
    var shouldFailProductLoading = false
    var shouldFailPurchase = false
    var shouldFailReceiptValidation = false
    var simulatePurchaseCancellation = false
    
    private var mockPurchases: [String: Bool] = [:]
    private var statusSubject = PassthroughSubject<SubscriptionStatus, Never>()
    
    var subscriptionStatusPublisher: AnyPublisher<SubscriptionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    func loadProducts(productIds: [String]) async throws -> [StoreKitProduct] {
        if shouldFailProductLoading {
            throw MonetizationError.productsLoadFailed
        }
        
        return [
            StoreKitProduct(
                id: "premium_monthly",
                displayName: "Premium Monthly",
                description: "月額プレミアムプラン",
                price: 500.0,
                type: .autoRenewableSubscription
            ),
            StoreKitProduct(
                id: "premium_yearly",
                displayName: "Premium Yearly",
                description: "年額プレミアムプラン",
                price: 5000.0,
                type: .autoRenewableSubscription
            )
        ]
    }
    
    func purchase(productId: String) async throws -> StoreKitPurchaseResult {
        if shouldFailPurchase {
            throw MonetizationError.purchaseFailed(reason: "Mock purchase failed")
        }
        
        if simulatePurchaseCancellation {
            return StoreKitPurchaseResult(
                isSuccess: false,
                productId: productId,
                transactionId: nil,
                error: .userCancelled
            )
        }
        
        return StoreKitPurchaseResult(
            isSuccess: true,
            productId: productId,
            transactionId: "mock_transaction_\(UUID())",
            error: nil
        )
    }
    
    func restorePurchases() async throws -> [StoreKitTransaction] {
        return mockPurchases.map { (productId, isActive) in
            StoreKitTransaction(
                productId: productId,
                transactionId: "mock_transaction_\(productId)",
                purchaseDate: Date(),
                expirationDate: isActive ? Date().addingTimeInterval(30 * 24 * 60 * 60) : Date().addingTimeInterval(-24 * 60 * 60),
                isActive: isActive
            )
        }
    }
    
    func validateReceipt(_ receiptData: String) async throws -> StoreKitReceiptValidationResult {
        if shouldFailReceiptValidation {
            throw MonetizationError.receiptValidationFailed
        }
        
        return StoreKitReceiptValidationResult(
            isValid: true,
            activeSubscriptions: [
                StoreKitTransaction(
                    productId: "premium_monthly",
                    transactionId: "mock_transaction",
                    purchaseDate: Date(),
                    expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                    isActive: true
                )
            ]
        )
    }
    
    // Helper methods for testing
    func addMockPurchase(_ productId: String, active: Bool) {
        mockPurchases[productId] = active
    }
    
    func simulateStatusChange(_ status: SubscriptionStatus) {
        statusSubject.send(status)
    }
}

// MARK: - Mock Monetization Service

class MockMonetizationService: MonetizationServiceProtocol {
    var shouldFailProductLoading = false
    var shouldFailPurchase = false
    var shouldFailReceiptValidation = false
    var shouldThrowError = false
    
    // Properties for integration tests
    var mockPurchaseResult: PurchaseResult?
    var mockRestoredSubscriptions: [MindMapCore.Subscription] = []
    var mockReceiptValidationResult: ReceiptValidationResult?
    
    private var mockPurchases: [String: Bool] = [:]
    private var statusSubject = PassthroughSubject<SubscriptionStatus, Never>()
    
    var subscriptionStatusPublisher: AnyPublisher<SubscriptionStatus, Never> {
        statusSubject.eraseToAnyPublisher()
    }
    
    func loadAvailableProducts() async throws -> [Product] {
        if shouldFailProductLoading {
            throw MonetizationError.productsLoadFailed
        }
        
        return [
            try! Product(
                id: "premium_monthly",
                displayName: "Premium Monthly",
                description: "月額プレミアムプラン",
                price: 500.0,
                type: .subscription(.monthly)
            ),
            try! Product(
                id: "premium_yearly",
                displayName: "Premium Yearly",
                description: "年額プレミアムプラン",
                price: 5000.0,
                type: .subscription(.yearly)
            )
        ]
    }
    
    func purchase(productId: String) async throws -> PurchaseResult {
        if shouldFailPurchase || shouldThrowError {
            throw MonetizationError.purchaseFailed(reason: "Mock purchase failed")
        }
        
        // Use mockPurchaseResult if provided for integration tests
        if let mockResult = mockPurchaseResult {
            return mockResult
        }
        
        // Default behavior
        return PurchaseResult(
            isSuccess: true,
            productId: productId,
            subscription: MindMapCore.Subscription(
                productId: productId,
                isActive: true,
                expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                autoRenewing: true
            ),
            error: nil
        )
    }
    
    func restorePurchases() async throws -> [MindMapCore.Subscription] {
        if shouldThrowError {
            throw MonetizationError.networkError
        }
        
        // Use mockRestoredSubscriptions if provided for integration tests
        if !mockRestoredSubscriptions.isEmpty {
            return mockRestoredSubscriptions
        }
        
        // Default behavior
        return mockPurchases.compactMap { (productId, isActive) in
            guard isActive else { return nil }
            return MindMapCore.Subscription(
                productId: productId,
                isActive: true,
                expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                autoRenewing: true
            )
        }
    }
    
    func validateReceipt(_ receiptData: String) async throws -> ReceiptValidationResult {
        if shouldFailReceiptValidation || shouldThrowError {
            throw MonetizationError.receiptValidationFailed
        }
        
        // Use mockReceiptValidationResult if provided for integration tests
        if let mockResult = mockReceiptValidationResult {
            return mockResult
        }
        
        // Default behavior
        return ReceiptValidationResult(
            isValid: true,
            activeSubscriptions: [
                MindMapCore.Subscription(
                    productId: "premium_monthly",
                    isActive: true,
                    expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
                    autoRenewing: true
                )
            ]
        )
    }
    
    // Helper methods for testing
    func addMockPurchase(_ productId: String, active: Bool) {
        mockPurchases[productId] = active
    }
}

// MARK: - Mock Purchase State Repository

class MockPurchaseStateRepository: PurchaseStateRepositoryProtocol {
    var mockPurchaseStates: [String: PurchaseState] = [:]
    var saveCallCount = 0
    var loadCallCount = 0
    
    func savePurchaseState(_ purchaseState: PurchaseState) async throws {
        mockPurchaseStates[purchaseState.productId] = purchaseState
        saveCallCount += 1
    }
    
    func getAllPurchaseStates() async throws -> [PurchaseState] {
        loadCallCount += 1
        return Array(mockPurchaseStates.values)
    }
    
    func getPurchaseState(for productId: String) async throws -> PurchaseState? {
        loadCallCount += 1
        return mockPurchaseStates[productId]
    }
    
    func deletePurchaseState(for productId: String) async throws {
        mockPurchaseStates.removeValue(forKey: productId)
    }
    
    func deleteAllPurchaseStates() async throws {
        mockPurchaseStates.removeAll()
    }
}