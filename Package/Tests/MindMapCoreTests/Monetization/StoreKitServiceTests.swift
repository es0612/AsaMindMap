import Testing
import Foundation
@testable import MindMapCore

struct StoreKitServiceTests {
    
    // MARK: - Product Loading Tests
    
    @Test("利用可能製品の読み込み")
    func testLoadAvailableProducts() async throws {
        // Given
        let mockStoreKit = MockStoreKitService()
        let service = MonetizationService(storeKit: mockStoreKit)
        
        // When
        let products = try await service.loadAvailableProducts()
        
        // Then
        #expect(products.count > 0)
        #expect(products.contains { $0.id == "premium_monthly" })
        #expect(products.contains { $0.id == "premium_yearly" })
    }
    
    @Test("製品読み込み失敗時のエラーハンドリング")
    func testLoadAvailableProductsError() async {
        // Given
        let mockStoreKit = MockStoreKitService()
        mockStoreKit.shouldFailProductLoading = true
        let service = MonetizationService(storeKit: mockStoreKit)
        
        // When & Then
        await #expect(throws: MonetizationError.productsLoadFailed) {
            try await service.loadAvailableProducts()
        }
    }
    
    // MARK: - Purchase Tests
    
    @Test("サブスクリプション購入の正常系")
    func testPurchaseSubscription() async throws {
        // Given
        let mockStoreKit = MockStoreKitService()
        let service = MonetizationService(storeKit: mockStoreKit)
        let productId = "premium_monthly"
        
        // When
        let result = try await service.purchase(productId: productId)
        
        // Then
        #expect(result.isSuccess == true)
        #expect(result.productId == productId)
        #expect(result.transactionId != nil)
    }
    
    @Test("購入キャンセル時のハンドリング")
    func testPurchaseCancelled() async throws {
        // Given
        let mockStoreKit = MockStoreKitService()
        mockStoreKit.simulatePurchaseCancellation = true
        let service = MonetizationService(storeKit: mockStoreKit)
        
        // When
        let result = try await service.purchase(productId: "premium_monthly")
        
        // Then
        #expect(result.isSuccess == false)
        #expect(result.error == .userCancelled)
    }
    
    @Test("購入失敗時のエラーハンドリング")
    func testPurchaseFailure() async {
        // Given
        let mockStoreKit = MockStoreKitService()
        mockStoreKit.shouldFailPurchase = true
        let service = MonetizationService(storeKit: mockStoreKit)
        
        // When & Then
        do {
            _ = try await service.purchase(productId: "premium_monthly")
            #expect(Bool(false), "Expected error to be thrown")
        } catch let error as MonetizationError {
            switch error {
            case .purchaseFailed:
                // Expected error type
                #expect(Bool(true))
            default:
                #expect(Bool(false), "Unexpected error type: \(error)")
            }
        } catch {
            #expect(Bool(false), "Unexpected error: \(error)")
        }
    }
    
    // MARK: - Restore Tests
    
    @Test("購入復元の正常系")
    func testRestorePurchases() async throws {
        // Given
        let mockStoreKit = MockStoreKitService()
        mockStoreKit.addMockPurchase("premium_yearly", active: true)
        let service = MonetizationService(storeKit: mockStoreKit)
        
        // When
        let restoredPurchases = try await service.restorePurchases()
        
        // Then
        #expect(restoredPurchases.count == 1)
        #expect(restoredPurchases.first?.productId == "premium_yearly")
        #expect(restoredPurchases.first?.isActive == true)
    }
    
    @Test("復元する購入がない場合")
    func testRestoreNoPurchases() async throws {
        // Given
        let mockStoreKit = MockStoreKitService()
        let service = MonetizationService(storeKit: mockStoreKit)
        
        // When
        let restoredPurchases = try await service.restorePurchases()
        
        // Then
        #expect(restoredPurchases.count == 0)
    }
    
    // MARK: - Receipt Validation Tests
    
    @Test("レシート検証の正常系")
    func testReceiptValidation() async throws {
        // Given
        let mockStoreKit = MockStoreKitService()
        let service = MonetizationService(storeKit: mockStoreKit)
        let mockReceipt = "mock_receipt_data"
        
        // When
        let validationResult = try await service.validateReceipt(mockReceipt)
        
        // Then
        #expect(validationResult.isValid == true)
        #expect(validationResult.activeSubscriptions.count > 0)
    }
    
    @Test("無効なレシートの検証")
    func testInvalidReceiptValidation() async {
        // Given
        let mockStoreKit = MockStoreKitService()
        mockStoreKit.shouldFailReceiptValidation = true
        let service = MonetizationService(storeKit: mockStoreKit)
        
        // When & Then
        await #expect(throws: MonetizationError.receiptValidationFailed) {
            try await service.validateReceipt("invalid_receipt")
        }
    }
    
    // MARK: - Subscription Status Tests
    
    @Test("サブスクリプションステータス監視")
    func testSubscriptionStatusMonitoring() async throws {
        // Given
        let mockStoreKit = MockStoreKitService()
        let service = MonetizationService(storeKit: mockStoreKit)
        var statusUpdates: [SubscriptionStatus] = []
        
        // When
        let cancellable = service.subscriptionStatusPublisher
            .sink { status in
                statusUpdates.append(status)
            }
        
        // Simulate status change
        mockStoreKit.simulateStatusChange(.active("premium_monthly"))
        
        // Then
        #expect(statusUpdates.count > 0)
        #expect(statusUpdates.last?.isActive == true)
        
        cancellable.cancel()
    }
}