import Foundation

// MARK: - Product

public struct Product: Equatable, Codable {
    public let id: String
    public let displayName: String
    public let description: String
    public let price: Double
    public let type: ProductType
    
    public init(
        id: String,
        displayName: String,
        description: String,
        price: Double,
        type: ProductType
    ) throws {
        guard price >= 0 else {
            throw ProductError.invalidPrice
        }
        
        self.id = id
        self.displayName = displayName
        self.description = description
        self.price = price
        self.type = type
    }
}

// MARK: - Product Type

public enum ProductType: Equatable, Codable {
    case subscription(SubscriptionPeriod)
    case oneTime
    
    public enum SubscriptionPeriod: String, Codable, CaseIterable {
        case monthly = "monthly"
        case yearly = "yearly"
    }
}

// MARK: - Product Error

public enum ProductError: Error, LocalizedError {
    case invalidPrice
    
    public var errorDescription: String? {
        switch self {
        case .invalidPrice:
            return "製品価格は0以上である必要があります"
        }
    }
}

// MARK: - Subscription

public struct Subscription: Equatable, Codable {
    public let productId: String
    public let isActive: Bool
    public let expirationDate: Date
    public let autoRenewing: Bool
    
    public init(
        productId: String,
        isActive: Bool,
        expirationDate: Date,
        autoRenewing: Bool
    ) {
        self.productId = productId
        self.isActive = isActive
        self.expirationDate = expirationDate
        self.autoRenewing = autoRenewing
    }
    
    public var isValid: Bool {
        return isActive && !isExpired
    }
    
    public var isExpired: Bool {
        return expirationDate < Date()
    }
}

// MARK: - Validation Status

public enum ValidationStatus: String, Codable, CaseIterable {
    case verified = "verified"
    case invalid = "invalid"
    case unknown = "unknown"
}

// MARK: - Purchase State

public struct PurchaseState: Equatable, Codable {
    public let id: String
    public let productId: String
    public let transactionId: String
    public let originalTransactionId: String
    public var purchaseDate: Date
    public var isActive: Bool
    public var expirationDate: Date?
    public var isRestored: Bool
    public var validationStatus: ValidationStatus
    public var lastValidated: Date
    
    // Legacy support for existing functionality
    public var activeSubscription: Subscription? {
        guard isActive && validationStatus == .verified else { return nil }
        
        if let expirationDate = expirationDate {
            return MindMapCore.Subscription(
                productId: productId,
                isActive: isActive,
                expirationDate: expirationDate,
                autoRenewing: true
            )
        }
        return nil
    }
    
    public var lastUpdated: Date {
        return lastValidated
    }
    
    public init(
        id: String,
        productId: String,
        transactionId: String,
        originalTransactionId: String,
        purchaseDate: Date,
        isActive: Bool,
        expirationDate: Date? = nil,
        isRestored: Bool = false,
        validationStatus: ValidationStatus = .unknown,
        lastValidated: Date = Date()
    ) {
        self.id = id
        self.productId = productId
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.purchaseDate = purchaseDate
        self.isActive = isActive
        self.expirationDate = expirationDate
        self.isRestored = isRestored
        self.validationStatus = validationStatus
        self.lastValidated = lastValidated
    }
    
    // Legacy init for backward compatibility
    public init() {
        self.id = UUID().uuidString
        self.productId = ""
        self.transactionId = ""
        self.originalTransactionId = ""
        self.purchaseDate = Date()
        self.isActive = false
        self.expirationDate = nil
        self.isRestored = false
        self.validationStatus = .unknown
        self.lastValidated = Date()
    }
    
    public var hasPremium: Bool {
        return isActive && validationStatus == .verified && !isExpired
    }
    
    public var isExpired: Bool {
        guard let expirationDate = expirationDate else {
            return false // No expiration date means one-time purchase
        }
        return expirationDate < Date()
    }
    
    public mutating func updateSubscription(_ subscription: Subscription) {
        // Update fields based on subscription (productId should not change)
        self.isActive = subscription.isActive
        self.expirationDate = subscription.expirationDate
        self.validationStatus = subscription.isActive ? .verified : .invalid
        self.lastValidated = Date()
    }
    
    public func canAccessFeature(_ feature: PremiumFeature) -> Bool {
        switch feature {
        case .cloudSync, .basicFormatting:
            return true // 基本機能は誰でもアクセス可能
        case .advancedFormatting, .unlimitedNodes, .premiumExport, .collaborativeFeatures:
            return hasPremium
        }
    }
}

// MARK: - Premium Features

public enum PremiumFeature: String, CaseIterable, Codable {
    case cloudSync = "cloud_sync"
    case basicFormatting = "basic_formatting"
    case advancedFormatting = "advanced_formatting"
    case unlimitedNodes = "unlimited_nodes"
    case premiumExport = "premium_export"
    case collaborativeFeatures = "collaborative_features"
}

// MARK: - Purchase Result

public struct PurchaseResult: Equatable {
    public let isSuccess: Bool
    public let productId: String
    public let transactionId: String?
    public let subscription: Subscription?
    public let error: PurchaseError?
    
    public init(
        isSuccess: Bool,
        productId: String,
        transactionId: String? = nil,
        subscription: Subscription? = nil,
        error: PurchaseError? = nil
    ) {
        self.isSuccess = isSuccess
        self.productId = productId
        self.transactionId = transactionId
        self.subscription = subscription
        self.error = error
    }
    
    // Convenience initializer for testing
    public init(
        isSuccess: Bool,
        subscription: Subscription? = nil,
        error: MonetizationError? = nil
    ) {
        self.isSuccess = isSuccess
        self.productId = subscription?.productId ?? "unknown"
        self.transactionId = nil
        self.subscription = subscription
        self.error = error.map { PurchaseError.monetizationError($0) }
    }
}

// MARK: - Purchase Error

public enum PurchaseError: Error, LocalizedError, Equatable {
    case userCancelled
    case paymentNotAllowed
    case storeProductNotAvailable
    case networkError
    case unknown
    case monetizationError(MonetizationError)
    
    public var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "ユーザーによって購入がキャンセルされました"
        case .paymentNotAllowed:
            return "支払いが許可されていません"
        case .storeProductNotAvailable:
            return "製品が利用できません"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .unknown:
            return "不明なエラーが発生しました"
        case .monetizationError(let error):
            return error.localizedDescription
        }
    }
}

// MARK: - Receipt Validation Result

public struct ReceiptValidationResult: Equatable {
    public let isValid: Bool
    public let activeSubscriptions: [Subscription]
    
    public init(isValid: Bool, activeSubscriptions: [Subscription]) {
        self.isValid = isValid
        self.activeSubscriptions = activeSubscriptions
    }
}

// MARK: - Subscription Status

public enum SubscriptionStatus: Equatable {
    case active(String) // productId
    case expired(String) // productId
    case cancelled(String) // productId
    case unknown
    
    public var isActive: Bool {
        if case .active = self {
            return true
        }
        return false
    }
    
    public var productId: String? {
        switch self {
        case .active(let id), .expired(let id), .cancelled(let id):
            return id
        case .unknown:
            return nil
        }
    }
}

// MARK: - Monetization Error

public enum MonetizationError: Error, LocalizedError, Equatable {
    case productsLoadFailed
    case purchaseFailed(reason: String)
    case receiptValidationFailed
    case storeKitNotAvailable
    case invalidConfiguration
    case networkError
    
    public var errorDescription: String? {
        switch self {
        case .productsLoadFailed:
            return "製品の読み込みに失敗しました"
        case .purchaseFailed(let reason):
            return "購入に失敗しました: \(reason)"
        case .receiptValidationFailed:
            return "レシート検証に失敗しました"
        case .storeKitNotAvailable:
            return "StoreKitが利用できません"
        case .invalidConfiguration:
            return "設定が無効です"
        case .networkError:
            return "ネットワークエラーが発生しました"
        }
    }
}