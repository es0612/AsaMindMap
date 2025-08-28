import Testing
import Foundation
@testable import MindMapCore

struct MonetizationUseCaseTests {
    
    // MARK: - Purchase Use Case Tests
    
    @Test("プレミアム購入ユースケースの正常系")
    func testPurchasePremiumSuccess() async throws {
        // Given
        let mockService = MockMonetizationService()
        let mockRepository = MockPurchaseStateRepository()
        let useCase = PurchasePremiumUseCase(
            service: mockService,
            repository: mockRepository
        )
        let request = PurchasePremiumRequest(productId: "premium_monthly")
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isSuccess == true)
        #expect(response.subscription?.productId == "premium_monthly")
        #expect(mockRepository.saveCallCount == 1)
    }
    
    @Test("購入失敗時のエラーハンドリング")
    func testPurchasePremiumFailure() async {
        // Given
        let mockService = MockMonetizationService()
        mockService.shouldFailPurchase = true
        let mockRepository = MockPurchaseStateRepository()
        let useCase = PurchasePremiumUseCase(
            service: mockService,
            repository: mockRepository
        )
        let request = PurchasePremiumRequest(productId: "premium_monthly")
        
        // When & Then
        do {
            _ = try await useCase.execute(request)
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
        #expect(mockRepository.saveCallCount == 0)
    }
    
    // MARK: - Restore Purchases Use Case Tests
    
    @Test("購入復元ユースケースの正常系")
    func testRestorePurchasesSuccess() async throws {
        // Given
        let mockService = MockMonetizationService()
        let mockRepository = MockPurchaseStateRepository()
        mockService.addMockPurchase("premium_yearly", active: true)
        let useCase = RestorePurchasesUseCase(
            service: mockService,
            repository: mockRepository
        )
        
        // When
        let response = try await useCase.execute()
        
        // Then
        #expect(response.restoredPurchases.count == 1)
        #expect(response.restoredPurchases.first?.productId == "premium_yearly")
        #expect(mockRepository.saveCallCount == 1)
    }
    
    @Test("復元する購入がない場合")
    func testRestoreNoPurchases() async throws {
        // Given
        let mockService = MockMonetizationService()
        let mockRepository = MockPurchaseStateRepository()
        let useCase = RestorePurchasesUseCase(
            service: mockService,
            repository: mockRepository
        )
        
        // When
        let response = try await useCase.execute()
        
        // Then
        #expect(response.restoredPurchases.count == 0)
        #expect(mockRepository.saveCallCount == 0) // Nothing to save
    }
    
    // MARK: - Validate Premium Access Use Case Tests
    
    @Test("プレミアムアクセス検証の正常系")
    func testValidatePremiumAccessSuccess() async throws {
        // Given
        let mockRepository = MockPurchaseStateRepository()
        let activeSubscription = MindMapCore.Subscription(
            productId: "premium_monthly",
            isActive: true,
            expirationDate: Date().addingTimeInterval(30 * 24 * 60 * 60),
            autoRenewing: true
        )
        var purchaseState = PurchaseState()
        purchaseState.updateSubscription(activeSubscription)
        mockRepository.mockPurchaseStates[activeSubscription.productId] = purchaseState
        
        let useCase = ValidatePremiumAccessUseCase(repository: mockRepository)
        let request = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.hasAccess == true)
        #expect(response.subscription?.isActive == true)
    }
    
    @Test("プレミアムアクセス権限なし")
    func testValidatePremiumAccessDenied() async throws {
        // Given
        let mockRepository = MockPurchaseStateRepository()
        let useCase = ValidatePremiumAccessUseCase(repository: mockRepository)
        let request = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.hasAccess == false)
        #expect(response.subscription == nil)
    }
    
    @Test("期限切れサブスクリプションのアクセス検証")
    func testValidateExpiredSubscriptionAccess() async throws {
        // Given
        let mockRepository = MockPurchaseStateRepository()
        let expiredSubscription = MindMapCore.Subscription(
            productId: "premium_monthly",
            isActive: false,
            expirationDate: Date().addingTimeInterval(-24 * 60 * 60),
            autoRenewing: false
        )
        var purchaseState = PurchaseState()
        purchaseState.updateSubscription(expiredSubscription)
        mockRepository.mockPurchaseStates[expiredSubscription.productId] = purchaseState
        
        let useCase = ValidatePremiumAccessUseCase(repository: mockRepository)
        let request = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.hasAccess == false)
        #expect(response.subscription?.isExpired == true)
    }
    
    // MARK: - Load Available Products Use Case Tests
    
    @Test("利用可能製品読み込みユースケース")
    func testLoadAvailableProductsSuccess() async throws {
        // Given
        let mockService = MockMonetizationService()
        let useCase = LoadAvailableProductsUseCase(service: mockService)
        
        // When
        let response = try await useCase.execute()
        
        // Then
        #expect(response.products.count > 0)
        #expect(response.products.contains { $0.id == "premium_monthly" })
        #expect(response.products.contains { $0.id == "premium_yearly" })
    }
    
    @Test("製品読み込み失敗時のエラーハンドリング")
    func testLoadAvailableProductsFailure() async {
        // Given
        let mockService = MockMonetizationService()
        mockService.shouldFailProductLoading = true
        let useCase = LoadAvailableProductsUseCase(service: mockService)
        
        // When & Then
        await #expect(throws: MonetizationError.productsLoadFailed) {
            try await useCase.execute()
        }
    }
    
    // MARK: - Receipt Validation Use Case Tests
    
    @Test("レシート検証ユースケースの正常系")
    func testValidateReceiptSuccess() async throws {
        // Given
        let mockService = MockMonetizationService()
        let mockRepository = MockPurchaseStateRepository()
        let useCase = ValidateReceiptUseCase(
            service: mockService,
            repository: mockRepository
        )
        let request = ValidateReceiptRequest(receiptData: "valid_receipt")
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.activeSubscriptions.count > 0)
        #expect(mockRepository.saveCallCount == 1)
    }
    
    @Test("無効レシート検証時のエラー")
    func testValidateInvalidReceipt() async {
        // Given
        let mockService = MockMonetizationService()
        mockService.shouldFailReceiptValidation = true
        let mockRepository = MockPurchaseStateRepository()
        let useCase = ValidateReceiptUseCase(
            service: mockService,
            repository: mockRepository
        )
        let request = ValidateReceiptRequest(receiptData: "invalid_receipt")
        
        // When & Then
        await #expect(throws: MonetizationError.receiptValidationFailed) {
            try await useCase.execute(request)
        }
    }
}