import Foundation
import Combine

// MARK: - StoreKit Product

public struct StoreKitProduct: Equatable {
    public let id: String
    public let displayName: String
    public let description: String
    public let price: Double
    public let type: StoreKitProductType
    
    public init(
        id: String,
        displayName: String,
        description: String,
        price: Double,
        type: StoreKitProductType
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.price = price
        self.type = type
    }
}

// MARK: - StoreKit Product Type

public enum StoreKitProductType: Equatable {
    case autoRenewableSubscription
    case consumable
    case nonConsumable
    case nonRenewingSubscription
}

// MARK: - StoreKit Purchase Result

public struct StoreKitPurchaseResult: Equatable {
    public let isSuccess: Bool
    public let productId: String
    public let transactionId: String?
    public let error: PurchaseError?
    
    public init(
        isSuccess: Bool,
        productId: String,
        transactionId: String? = nil,
        error: PurchaseError? = nil
    ) {
        self.isSuccess = isSuccess
        self.productId = productId
        self.transactionId = transactionId
        self.error = error
    }
}

// MARK: - StoreKit Transaction

public struct StoreKitTransaction: Equatable {
    public let productId: String
    public let transactionId: String
    public let purchaseDate: Date
    public let expirationDate: Date?
    public let isActive: Bool
    
    public init(
        productId: String,
        transactionId: String,
        purchaseDate: Date,
        expirationDate: Date? = nil,
        isActive: Bool
    ) {
        self.productId = productId
        self.transactionId = transactionId
        self.purchaseDate = purchaseDate
        self.expirationDate = expirationDate
        self.isActive = isActive
    }
}

// MARK: - StoreKit Receipt Validation Result

public struct StoreKitReceiptValidationResult: Equatable {
    public let isValid: Bool
    public let activeSubscriptions: [StoreKitTransaction]
    
    public init(isValid: Bool, activeSubscriptions: [StoreKitTransaction]) {
        self.isValid = isValid
        self.activeSubscriptions = activeSubscriptions
    }
}

// MARK: - StoreKit Service Protocol

public protocol StoreKitServiceProtocol {
    var subscriptionStatusPublisher: AnyPublisher<SubscriptionStatus, Never> { get }
    
    func loadProducts(productIds: [String]) async throws -> [StoreKitProduct]
    func purchase(productId: String) async throws -> StoreKitPurchaseResult
    func restorePurchases() async throws -> [StoreKitTransaction]
    func validateReceipt(_ receiptData: String) async throws -> StoreKitReceiptValidationResult
}