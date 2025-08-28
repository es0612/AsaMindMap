import XCTest
import Foundation
import Combine
@testable import MindMapCore
@testable import DataLayer

@MainActor
class MonetizationIntegrationTests: XCTestCase {
    
    private var monetizationService: MockMonetizationService!
    private var purchaseStateManager: MockPurchaseStateManager!
    private var receiptValidationService: MockReceiptValidationService!
    private var repository: InMemoryPurchaseStateRepository!
    private var logger: Logger!
    
    // Use Cases
    private var purchasePremiumUseCase: PurchasePremiumUseCase!
    private var restorePurchasesUseCase: RestorePurchasesUseCase!
    private var validatePremiumAccessUseCase: ValidatePremiumAccessUseCase!
    private var validateReceiptUseCase: ValidateReceiptUseCase!
    
    override func setUp() {
        super.setUp()
        
        // Setup dependencies
        repository = InMemoryPurchaseStateRepository()
        receiptValidationService = MockReceiptValidationService()
        logger = Logger.shared
        
        monetizationService = MockMonetizationService()
        purchaseStateManager = MockPurchaseStateManager()
        
        // Setup use cases
        purchasePremiumUseCase = PurchasePremiumUseCase(
            service: monetizationService,
            repository: repository
        )
        
        restorePurchasesUseCase = RestorePurchasesUseCase(
            service: monetizationService,
            repository: repository
        )
        
        validatePremiumAccessUseCase = ValidatePremiumAccessUseCase(
            repository: repository
        )
        
        validateReceiptUseCase = ValidateReceiptUseCase(
            service: monetizationService,
            repository: repository
        )
    }
    
    override func tearDown() {
        monetizationService = nil
        purchaseStateManager = nil
        receiptValidationService = nil
        repository = nil
        logger = nil
        
        purchasePremiumUseCase = nil
        restorePurchasesUseCase = nil
        validatePremiumAccessUseCase = nil
        validateReceiptUseCase = nil
        
        super.tearDown()
    }
    
    // MARK: - Full Purchase Flow Tests
    
    func testFullPurchaseFlow_SuccessPath() async throws {
        // Arrange
        let productId = "com.example.premium_monthly"
        let subscription = createMockSubscription(productId: productId, isActive: true)
        
        monetizationService.mockPurchaseResult = PurchaseResult(
            isSuccess: true,
            subscription: subscription,
            error: nil
        )
        
        // Act 1: Purchase premium
        let purchaseRequest = PurchasePremiumRequest(productId: productId)
        let purchaseResponse = try await purchasePremiumUseCase.execute(purchaseRequest)
        
        // Act 2: Validate premium access
        let accessRequest = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        let accessResponse = try await validatePremiumAccessUseCase.execute(accessRequest)
        
        // Assert
        XCTAssertTrue(purchaseResponse.isSuccess)
        XCTAssertNotNil(purchaseResponse.subscription)
        XCTAssertNil(purchaseResponse.error)
        
        XCTAssertTrue(accessResponse.hasAccess)
        XCTAssertNotNil(accessResponse.subscription)
    }
    
    func testFullPurchaseFlow_FailurePath() async throws {
        // Arrange
        let productId = "com.example.premium_monthly"
        let error = MonetizationError.purchaseFailed(reason: "Payment declined")
        
        monetizationService.mockPurchaseResult = PurchaseResult(
            isSuccess: false,
            subscription: nil,
            error: error
        )
        
        // Act 1: Attempt purchase
        let purchaseRequest = PurchasePremiumRequest(productId: productId)
        let purchaseResponse = try await purchasePremiumUseCase.execute(purchaseRequest)
        
        // Act 2: Check premium access (should be false)
        let accessRequest = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        let accessResponse = try await validatePremiumAccessUseCase.execute(accessRequest)
        
        // Assert
        XCTAssertFalse(purchaseResponse.isSuccess)
        XCTAssertNil(purchaseResponse.subscription)
        XCTAssertNotNil(purchaseResponse.error)
        
        XCTAssertFalse(accessResponse.hasAccess)
        XCTAssertNil(accessResponse.subscription)
    }
    
    // MARK: - Purchase Restoration Flow Tests
    
    func testPurchaseRestorationFlow_WithExistingPurchases() async throws {
        // Arrange
        let subscription1 = createMockSubscription(productId: "com.example.premium", isActive: true)
        let subscription2 = createMockSubscription(productId: "com.example.premium_yearly", isActive: true)
        
        monetizationService.mockRestoredSubscriptions = [subscription1, subscription2]
        
        // Act
        let restoreResponse = try await restorePurchasesUseCase.execute()
        
        // Assert
        XCTAssertEqual(restoreResponse.restoredPurchases.count, 2)
        XCTAssertTrue(restoreResponse.restoredPurchases.contains { $0.productId == "com.example.premium" })
        XCTAssertTrue(restoreResponse.restoredPurchases.contains { $0.productId == "com.example.premium_yearly" })
    }
    
    // MARK: - Receipt Validation Flow Tests
    
    func testReceiptValidationFlow_WithValidReceipt() async throws {
        // Arrange
        let receiptData = "valid_receipt_data_123"
        let subscription = createMockSubscription(productId: "com.example.premium", isActive: true)
        
        monetizationService.mockReceiptValidationResult = ReceiptValidationResult(
            isValid: true,
            activeSubscriptions: [subscription]
        )
        
        // Act
        let receiptRequest = ValidateReceiptRequest(receiptData: receiptData)
        let receiptResponse = try await validateReceiptUseCase.execute(receiptRequest)
        
        // Assert
        XCTAssertTrue(receiptResponse.isValid)
        XCTAssertEqual(receiptResponse.activeSubscriptions.count, 1)
        XCTAssertEqual(receiptResponse.activeSubscriptions.first?.productId, "com.example.premium")
    }
    
    // MARK: - Feature Access Tests
    
    func testFeatureAccess_BasicFeatures_AlwaysAllowed() async throws {
        // Arrange - No premium subscription
        
        // Act - Test basic features
        let cloudSyncRequest = ValidatePremiumAccessRequest(feature: .cloudSync)
        let basicFormattingRequest = ValidatePremiumAccessRequest(feature: .basicFormatting)
        
        let cloudSyncResponse = try await validatePremiumAccessUseCase.execute(cloudSyncRequest)
        let basicFormattingResponse = try await validatePremiumAccessUseCase.execute(basicFormattingRequest)
        
        // Assert - Basic features should always be accessible
        XCTAssertTrue(cloudSyncResponse.hasAccess)
        XCTAssertTrue(basicFormattingResponse.hasAccess)
    }
    
    func testFeatureAccess_PremiumFeatures_RequireSubscription() async throws {
        // Arrange - No premium subscription initially
        
        // Act 1 - Test premium features without subscription
        let advancedFormattingRequest = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        let unlimitedNodesRequest = ValidatePremiumAccessRequest(feature: .unlimitedNodes)
        let premiumExportRequest = ValidatePremiumAccessRequest(feature: .premiumExport)
        
        let noAccessAdvanced = try await validatePremiumAccessUseCase.execute(advancedFormattingRequest)
        let noAccessUnlimited = try await validatePremiumAccessUseCase.execute(unlimitedNodesRequest)
        let noAccessExport = try await validatePremiumAccessUseCase.execute(premiumExportRequest)
        
        // Assert 1 - Premium features should be blocked
        XCTAssertFalse(noAccessAdvanced.hasAccess)
        XCTAssertFalse(noAccessUnlimited.hasAccess)
        XCTAssertFalse(noAccessExport.hasAccess)
        
        // Arrange 2 - Add premium subscription
        let subscription = createMockSubscription(productId: "com.example.premium", isActive: true)
        let purchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium",
            transactionId: "txn_123",
            originalTransactionId: "orig_123",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            isRestored: false,
            validationStatus: .verified
        )
        try await repository.savePurchaseState(purchaseState)
        
        // Act 2 - Test premium features with subscription
        let withAccessAdvanced = try await validatePremiumAccessUseCase.execute(advancedFormattingRequest)
        let withAccessUnlimited = try await validatePremiumAccessUseCase.execute(unlimitedNodesRequest)
        let withAccessExport = try await validatePremiumAccessUseCase.execute(premiumExportRequest)
        
        // Assert 2 - Premium features should now be accessible
        XCTAssertTrue(withAccessAdvanced.hasAccess)
        XCTAssertTrue(withAccessUnlimited.hasAccess)
        XCTAssertTrue(withAccessExport.hasAccess)
    }
    
    // MARK: - Subscription Expiry Tests
    
    func testSubscriptionExpiry_BlocksAccessAfterExpiration() async throws {
        // Arrange - Add expired subscription
        let expiredPurchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium_monthly",
            transactionId: "txn_expired",
            originalTransactionId: "orig_expired",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), // Expired yesterday
            isRestored: false,
            validationStatus: .verified
        )
        try await repository.savePurchaseState(expiredPurchaseState)
        
        // Act
        let accessRequest = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        let accessResponse = try await validatePremiumAccessUseCase.execute(accessRequest)
        
        // Assert - Should not have access due to expiry
        XCTAssertFalse(accessResponse.hasAccess)
    }
    
    // MARK: - Multi-Product Support Tests
    
    func testMultipleProducts_HandledCorrectly() async throws {
        // Arrange - Multiple active subscriptions
        let monthlyState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium_monthly",
            transactionId: "txn_monthly",
            originalTransactionId: "orig_monthly",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            isRestored: false,
            validationStatus: .verified
        )
        
        let yearlyState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium_yearly",
            transactionId: "txn_yearly",
            originalTransactionId: "orig_yearly",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .year, value: 1, to: Date()),
            isRestored: false,
            validationStatus: .verified
        )
        
        try await repository.savePurchaseState(monthlyState)
        try await repository.savePurchaseState(yearlyState)
        
        // Act
        let accessRequest = ValidatePremiumAccessRequest(feature: .advancedFormatting)
        let accessResponse = try await validatePremiumAccessUseCase.execute(accessRequest)
        
        // Assert - Should have access with any active subscription
        XCTAssertTrue(accessResponse.hasAccess)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandling_NetworkFailure() async throws {
        // Arrange
        monetizationService.shouldThrowError = true
        
        // Act & Assert
        let purchaseRequest = PurchasePremiumRequest(productId: "com.example.premium")
        
        do {
            _ = try await purchasePremiumUseCase.execute(purchaseRequest)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is MonetizationError)
        }
    }
    
    // MARK: - Performance Tests
    
    func testMonetizationSystem_Performance() {
        let purchaseRequest = PurchasePremiumRequest(productId: "com.example.premium")
        
        measure {
            Task {
                _ = try? await purchasePremiumUseCase.execute(purchaseRequest)
            }
        }
    }
    
    // MARK: - Concurrent Access Tests
    
    func testConcurrentPremiumAccess_HandlesSafely() async throws {
        // Arrange
        let subscription = createMockSubscription(productId: "com.example.premium", isActive: true)
        let purchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium",
            transactionId: "txn_123",
            originalTransactionId: "orig_123",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            isRestored: false,
            validationStatus: .verified
        )
        try await repository.savePurchaseState(purchaseState)
        
        // Act - Multiple concurrent access checks
        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    let request = ValidatePremiumAccessRequest(feature: .advancedFormatting)
                    let response = try? await self.validatePremiumAccessUseCase.execute(request)
                    return response?.hasAccess ?? false
                }
            }
            
            // Assert - All should return true
            for await hasAccess in group {
                XCTAssertTrue(hasAccess)
            }
        }
    }
}

// MARK: - Test Helper Methods

extension MonetizationIntegrationTests {
    
    func createMockSubscription(
        productId: String,
        isActive: Bool,
        expirationDate: Date? = nil
    ) -> MindMapCore.Subscription {
        return MindMapCore.Subscription(
            productId: productId,
            isActive: isActive,
            expirationDate: expirationDate ?? Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
            autoRenewing: true
        )
    }
}

// Using MockMonetizationService from MonetizationMocks.swift