import Foundation
import Combine

// MARK: - Monetization Service Implementation

public class MonetizationService: MonetizationServiceProtocol {
    private let storeKit: StoreKitServiceProtocol
    private let productIds = [
        "premium_monthly",
        "premium_yearly"
    ]
    
    public var subscriptionStatusPublisher: AnyPublisher<SubscriptionStatus, Never> {
        storeKit.subscriptionStatusPublisher
    }
    
    public init(storeKit: StoreKitServiceProtocol) {
        self.storeKit = storeKit
    }
    
    public func loadAvailableProducts() async throws -> [Product] {
        let storeKitProducts = try await storeKit.loadProducts(productIds: productIds)
        
        return storeKitProducts.compactMap { storeKitProduct in
            let productType: ProductType
            
            switch storeKitProduct.type {
            case .autoRenewableSubscription:
                if storeKitProduct.id.contains("monthly") {
                    productType = .subscription(.monthly)
                } else if storeKitProduct.id.contains("yearly") {
                    productType = .subscription(.yearly)
                } else {
                    productType = .subscription(.monthly) // デフォルト
                }
            case .consumable, .nonConsumable, .nonRenewingSubscription:
                productType = .oneTime
            }
            
            return try? Product(
                id: storeKitProduct.id,
                displayName: storeKitProduct.displayName,
                description: storeKitProduct.description,
                price: storeKitProduct.price,
                type: productType
            )
        }
    }
    
    public func purchase(productId: String) async throws -> PurchaseResult {
        let storeKitResult = try await storeKit.purchase(productId: productId)
        
        if storeKitResult.isSuccess {
            // Create subscription from purchase
            let subscription = Subscription(
                productId: productId,
                isActive: true,
                expirationDate: calculateExpirationDate(for: productId),
                autoRenewing: true
            )
            
            return PurchaseResult(
                isSuccess: true,
                productId: productId,
                transactionId: storeKitResult.transactionId,
                subscription: subscription,
                error: nil
            )
        } else {
            return PurchaseResult(
                isSuccess: false,
                productId: productId,
                transactionId: nil,
                subscription: nil,
                error: storeKitResult.error
            )
        }
    }
    
    public func restorePurchases() async throws -> [Subscription] {
        let transactions = try await storeKit.restorePurchases()
        
        return transactions.compactMap { transaction in
            guard transaction.isActive else { return nil }
            
            return Subscription(
                productId: transaction.productId,
                isActive: transaction.isActive,
                expirationDate: transaction.expirationDate ?? Date(),
                autoRenewing: true
            )
        }
    }
    
    public func validateReceipt(_ receiptData: String) async throws -> ReceiptValidationResult {
        let storeKitResult = try await storeKit.validateReceipt(receiptData)
        
        let activeSubscriptions = storeKitResult.activeSubscriptions.map { transaction in
            Subscription(
                productId: transaction.productId,
                isActive: transaction.isActive,
                expirationDate: transaction.expirationDate ?? Date(),
                autoRenewing: true
            )
        }
        
        return ReceiptValidationResult(
            isValid: storeKitResult.isValid,
            activeSubscriptions: activeSubscriptions
        )
    }
    
    // MARK: - Private Helpers
    
    private func calculateExpirationDate(for productId: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        if productId.contains("monthly") {
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        } else if productId.contains("yearly") {
            return calendar.date(byAdding: .year, value: 1, to: now) ?? now
        } else {
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        }
    }
}