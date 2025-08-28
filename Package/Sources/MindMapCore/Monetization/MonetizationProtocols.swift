import Foundation
import Combine

// MARK: - Monetization Service Protocol

public protocol MonetizationServiceProtocol {
    var subscriptionStatusPublisher: AnyPublisher<SubscriptionStatus, Never> { get }
    
    func loadAvailableProducts() async throws -> [Product]
    func purchase(productId: String) async throws -> PurchaseResult
    func restorePurchases() async throws -> [Subscription]
    func validateReceipt(_ receiptData: String) async throws -> ReceiptValidationResult
}

// Note: PurchaseStateRepositoryProtocol is now defined in PurchaseStateManager.swift

// MARK: - Use Case Request/Response Types

// Purchase Premium
public struct PurchasePremiumRequest {
    public let productId: String
    
    public init(productId: String) {
        self.productId = productId
    }
}

public struct PurchasePremiumResponse {
    public let isSuccess: Bool
    public let subscription: Subscription?
    public let error: MonetizationError?
    
    public init(
        isSuccess: Bool,
        subscription: Subscription? = nil,
        error: MonetizationError? = nil
    ) {
        self.isSuccess = isSuccess
        self.subscription = subscription
        self.error = error
    }
}

// Restore Purchases
public struct RestorePurchasesResponse {
    public let restoredPurchases: [Subscription]
    
    public init(restoredPurchases: [Subscription]) {
        self.restoredPurchases = restoredPurchases
    }
}

// Validate Premium Access
public struct ValidatePremiumAccessRequest {
    public let feature: PremiumFeature
    
    public init(feature: PremiumFeature) {
        self.feature = feature
    }
}

public struct ValidatePremiumAccessResponse {
    public let hasAccess: Bool
    public let subscription: Subscription?
    
    public init(hasAccess: Bool, subscription: Subscription? = nil) {
        self.hasAccess = hasAccess
        self.subscription = subscription
    }
}

// Load Available Products
public struct LoadAvailableProductsResponse {
    public let products: [Product]
    
    public init(products: [Product]) {
        self.products = products
    }
}

// Validate Receipt
public struct ValidateReceiptRequest {
    public let receiptData: String
    
    public init(receiptData: String) {
        self.receiptData = receiptData
    }
}

public struct ValidateReceiptResponse {
    public let isValid: Bool
    public let activeSubscriptions: [Subscription]
    
    public init(isValid: Bool, activeSubscriptions: [Subscription]) {
        self.isValid = isValid
        self.activeSubscriptions = activeSubscriptions
    }
}

// MARK: - Use Case Protocols

public protocol PurchasePremiumUseCaseProtocol {
    func execute(_ request: PurchasePremiumRequest) async throws -> PurchasePremiumResponse
}

public protocol RestorePurchasesUseCaseProtocol {
    func execute() async throws -> RestorePurchasesResponse
}

public protocol ValidatePremiumAccessUseCaseProtocol {
    func execute(_ request: ValidatePremiumAccessRequest) async throws -> ValidatePremiumAccessResponse
}

public protocol LoadAvailableProductsUseCaseProtocol {
    func execute() async throws -> LoadAvailableProductsResponse
}

public protocol ValidateReceiptUseCaseProtocol {
    func execute(_ request: ValidateReceiptRequest) async throws -> ValidateReceiptResponse
}