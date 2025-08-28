import Testing
import Foundation
@testable import MindMapCore

struct MonetizationEntitiesTests {
    
    // MARK: - Product Tests
    
    @Test("Product作成の正常系")
    func testProductCreation() throws {
        // Given
        let productId = "premium_monthly"
        let displayName = "Premium Monthly"
        let description = "月額プレミアムプラン"
        let price = 500.0
        
        // When
        let product = try Product(
            id: productId,
            displayName: displayName,
            description: description,
            price: price,
            type: .subscription(.monthly)
        )
        
        // Then
        #expect(product.id == productId)
        #expect(product.displayName == displayName)
        #expect(product.description == description)
        #expect(product.price == price)
        #expect(product.type == .subscription(.monthly))
    }
    
    @Test("Product無効な価格でエラー")
    func testProductInvalidPrice() {
        // Given & When & Then
        #expect(throws: ProductError.invalidPrice) {
            try Product(
                id: "test",
                displayName: "Test",
                description: "Test",
                price: -1.0,
                type: .subscription(.monthly)
            )
        }
    }
    
    // MARK: - Subscription Tests
    
    @Test("Subscription作成とステータス管理")
    func testSubscriptionCreation() {
        // Given
        let productId = "premium_yearly"
        let expirationDate = Date().addingTimeInterval(365 * 24 * 60 * 60)
        
        // When
        let subscription = MindMapCore.Subscription(
            productId: productId,
            isActive: true,
            expirationDate: expirationDate,
            autoRenewing: true
        )
        
        // Then
        #expect(subscription.productId == productId)
        #expect(subscription.isActive == true)
        #expect(subscription.expirationDate == expirationDate)
        #expect(subscription.autoRenewing == true)
        #expect(subscription.isValid == true)
    }
    
    @Test("Subscription期限切れステータス")
    func testSubscriptionExpired() {
        // Given
        let pastDate = Date().addingTimeInterval(-24 * 60 * 60)
        
        // When
        let subscription = MindMapCore.Subscription(
            productId: "premium_monthly",
            isActive: false,
            expirationDate: pastDate,
            autoRenewing: false
        )
        
        // Then
        #expect(subscription.isValid == false)
        #expect(subscription.isExpired == true)
    }
    
    // MARK: - PurchaseState Tests
    
    @Test("PurchaseState初期化とアップデート")
    func testPurchaseStateManagement() {
        // Given
        var purchaseState = PurchaseState()
        let subscription = MindMapCore.Subscription(
            productId: "premium_monthly",
            isActive: true,
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            autoRenewing: true
        )
        
        // When
        purchaseState.updateSubscription(subscription)
        
        // Then
        #expect(purchaseState.hasPremium == true)
        #expect(purchaseState.activeSubscription?.productId == "premium_monthly")
    }
    
    @Test("PurchaseStateプレミアム機能アクセス判定")
    func testPurchaseStatePremiumAccess() {
        // Given
        var purchaseState = PurchaseState()
        
        // When & Then - 初期状態では無料
        #expect(purchaseState.hasPremium == false)
        #expect(purchaseState.canAccessFeature(.advancedFormatting) == false)
        #expect(purchaseState.canAccessFeature(.cloudSync) == true) // 基本機能
        
        // When - プレミアム有効化
        let subscription = MindMapCore.Subscription(
            productId: "premium_monthly",
            isActive: true,
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            autoRenewing: true
        )
        purchaseState.updateSubscription(subscription)
        
        // Then - プレミアム機能にアクセス可能
        #expect(purchaseState.hasPremium == true)
        #expect(purchaseState.canAccessFeature(.advancedFormatting) == true)
        #expect(purchaseState.canAccessFeature(.cloudSync) == true)
    }
}