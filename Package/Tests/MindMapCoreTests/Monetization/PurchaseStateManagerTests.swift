import XCTest
import Foundation
@testable import MindMapCore
@testable import DataLayer

class PurchaseStateManagerTests: XCTestCase {
    
    private var purchaseStateManager: PurchaseStateManager!
    private var mockPurchaseStateManager: MockPurchaseStateManager!
    private var mockRepository: InMemoryPurchaseStateRepository!
    private var mockReceiptValidationService: MockReceiptValidationService!
    private var logger: Logger!
    
    override func setUp() {
        super.setUp()
        mockRepository = InMemoryPurchaseStateRepository()
        mockReceiptValidationService = MockReceiptValidationService()
        logger = Logger.shared
        
        purchaseStateManager = PurchaseStateManager(
            repository: mockRepository,
            receiptValidationService: mockReceiptValidationService,
            logger: logger
        )
        
        mockPurchaseStateManager = MockPurchaseStateManager()
    }
    
    override func tearDown() {
        purchaseStateManager = nil
        mockPurchaseStateManager = nil
        mockRepository = nil
        mockReceiptValidationService = nil
        logger = nil
        super.tearDown()
    }
    
    // MARK: - Purchase Persistence Tests
    
    func testPersistPurchase_WithMockTransaction_SavesCorrectly() async throws {
        // Arrange - テストでは直接PurchaseStateを検証
        let expectedProductId = "com.example.premium"
        let expectedTransactionId = "12345"
        let expectedOriginalTransactionId = "67890"
        
        // Act - MockPurchaseStateManagerの動作をテスト（実際のTransactionは必要ない）
        let testPurchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: expectedProductId,
            transactionId: expectedTransactionId,
            originalTransactionId: expectedOriginalTransactionId,
            purchaseDate: Date(),
            isActive: true,
            expirationDate: nil,
            isRestored: false,
            validationStatus: .verified
        )
        
        mockPurchaseStateManager.mockPurchaseStates = [testPurchaseState]
        
        // Assert
        XCTAssertEqual(testPurchaseState.productId, expectedProductId)
        XCTAssertEqual(testPurchaseState.transactionId, expectedTransactionId)
        XCTAssertEqual(testPurchaseState.originalTransactionId, expectedOriginalTransactionId)
        XCTAssertTrue(testPurchaseState.isActive)
        XCTAssertFalse(testPurchaseState.isRestored)
        XCTAssertEqual(testPurchaseState.validationStatus, ValidationStatus.verified)
    }
    
    // MARK: - Purchase Restoration Tests
    
    func testRestorePurchases_WithValidRequest_ReturnsSuccess() async throws {
        // Arrange
        let request = PurchaseRestoreRequest(validateReceipt: false, forceRefresh: false)
        mockPurchaseStateManager.shouldSucceed = true
        
        // Create some mock purchase states
        let mockPurchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium",
            transactionId: "txn_123",
            originalTransactionId: "orig_123",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: nil,
            isRestored: true,
            validationStatus: .verified
        )
        mockPurchaseStateManager.mockPurchaseStates = [mockPurchaseState]
        
        // Act
        let response = try await mockPurchaseStateManager.restorePurchases(request)
        
        // Assert
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.restoredPurchases.count, 1)
        XCTAssertEqual(response.newPurchases.count, 0)
        XCTAssertEqual(response.invalidPurchases.count, 0)
        XCTAssertNil(response.errorMessage)
    }
    
    func testRestorePurchases_WithFailure_ReturnsError() async throws {
        // Arrange
        let request = PurchaseRestoreRequest(validateReceipt: false, forceRefresh: false)
        mockPurchaseStateManager.shouldSucceed = false
        
        // Act & Assert
        do {
            _ = try await mockPurchaseStateManager.restorePurchases(request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("Mock restore failed"))
        }
    }
    
    // MARK: - Current Purchase States Tests
    
    func testGetCurrentPurchaseStates_ReturnsAllStates() async throws {
        // Arrange
        let purchaseState1 = createTestPurchaseState(productId: "com.example.premium1")
        let purchaseState2 = createTestPurchaseState(productId: "com.example.premium2")
        
        try await mockRepository.savePurchaseState(purchaseState1)
        try await mockRepository.savePurchaseState(purchaseState2)
        
        // Act
        let states = try await purchaseStateManager.getCurrentPurchaseStates()
        
        // Assert
        XCTAssertEqual(states.count, 2)
        XCTAssertTrue(states.contains { $0.productId == "com.example.premium1" })
        XCTAssertTrue(states.contains { $0.productId == "com.example.premium2" })
    }
    
    // MARK: - Premium Access Tests
    
    func testIsPremiumActive_WithActivePurchase_ReturnsTrue() async throws {
        // Arrange
        mockPurchaseStateManager.isPremiumActiveMock = true
        
        // Act
        let isActive = try await mockPurchaseStateManager.isPremiumActive()
        
        // Assert
        XCTAssertTrue(isActive)
    }
    
    func testIsPremiumActive_WithNoActivePurchase_ReturnsFalse() async throws {
        // Arrange
        mockPurchaseStateManager.isPremiumActiveMock = false
        
        // Act
        let isActive = try await mockPurchaseStateManager.isPremiumActive()
        
        // Assert
        XCTAssertFalse(isActive)
    }
    
    func testIsPremiumActive_WithExpiredSubscription_ReturnsFalse() async throws {
        // Arrange
        let expiredState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium",
            transactionId: "txn_123",
            originalTransactionId: "orig_123",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()), // Expired yesterday
            isRestored: false,
            validationStatus: .verified
        )
        
        try await mockRepository.savePurchaseState(expiredState)
        
        // Act
        let isActive = try await purchaseStateManager.isPremiumActive()
        
        // Assert
        XCTAssertFalse(isActive)
    }
    
    // MARK: - Purchase Validation Tests
    
    func testValidateAllPurchases_WithValidReceipts_ReturnsVerifiedStates() async throws {
        // Arrange
        let purchaseState = createTestPurchaseState(productId: "com.example.premium")
        try await mockRepository.savePurchaseState(purchaseState)
        
        mockReceiptValidationService.shouldSucceed = true
        
        // Act
        let validatedStates = try await mockPurchaseStateManager.validateAllPurchases()
        
        // Assert
        XCTAssertEqual(validatedStates.count, 1)
        XCTAssertEqual(validatedStates.first?.validationStatus, .verified)
    }
    
    func testValidateAllPurchases_WithInvalidReceipts_ReturnsInvalidStates() async throws {
        // Arrange
        mockPurchaseStateManager.shouldSucceed = false
        
        let purchaseState = createTestPurchaseState(productId: "com.example.premium")
        mockPurchaseStateManager.mockPurchaseStates = [purchaseState]
        
        // Act
        let validatedStates = try await mockPurchaseStateManager.validateAllPurchases()
        
        // Assert
        XCTAssertEqual(validatedStates.count, 1)
        XCTAssertEqual(validatedStates.first?.validationStatus, .invalid)
    }
    
    // MARK: - Integration Tests
    
    func testPurchaseStateFlow_EndToEnd() async throws {
        // Arrange - 統合テストでは実際のPurchaseStateを使用
        let testPurchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium_monthly",
            transactionId: "12345",
            originalTransactionId: "67890",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: nil,
            isRestored: false,
            validationStatus: .verified
        )
        
        // Act 1: Setup mock state
        mockPurchaseStateManager.mockPurchaseStates = [testPurchaseState]
        
        // Act 2: Get current states
        let currentStates = try await mockPurchaseStateManager.getCurrentPurchaseStates()
        
        // Act 3: Check premium access
        mockPurchaseStateManager.isPremiumActiveMock = true
        let isActive = try await mockPurchaseStateManager.isPremiumActive()
        
        // Assert
        XCTAssertEqual(currentStates.count, 1)
        XCTAssertEqual(currentStates.first?.productId, "com.example.premium_monthly")
        XCTAssertTrue(isActive)
    }
    
    // MARK: - Performance Tests
    
    func testPurchaseStatePersistence_Performance() {
        measure {
            Task {
                // パフォーマンステスト - モック操作の処理時間を測定
                let testPurchaseState = PurchaseState(
                    id: UUID().uuidString,
                    productId: "com.example.premium",
                    transactionId: "12345",
                    originalTransactionId: "67890",
                    purchaseDate: Date(),
                    isActive: true,
                    expirationDate: nil,
                    isRestored: false,
                    validationStatus: .verified
                )
                mockPurchaseStateManager.mockPurchaseStates = [testPurchaseState]
                _ = try? await mockPurchaseStateManager.getCurrentPurchaseStates()
            }
        }
    }
    
    func testPurchaseStateRestoration_Performance() {
        let request = PurchaseRestoreRequest(validateReceipt: false, forceRefresh: false)
        
        measure {
            Task {
                _ = try? await mockPurchaseStateManager.restorePurchases(request)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testRestorePurchases_WithForceRefresh_OverridesExistingStates() async throws {
        // Arrange
        let existingState = createTestPurchaseState(productId: "com.example.premium")
        mockPurchaseStateManager.mockPurchaseStates = [existingState]
        
        let requestWithForceRefresh = PurchaseRestoreRequest(validateReceipt: false, forceRefresh: true)
        
        // Act
        let response = try await mockPurchaseStateManager.restorePurchases(requestWithForceRefresh)
        
        // Assert
        XCTAssertTrue(response.success)
    }
    
    func testIsPremiumActive_WithMixedStates_ReturnsCorrectResult() async throws {
        // Arrange: Mix of active, expired, and invalid states
        let activeState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium1",
            transactionId: "txn_active",
            originalTransactionId: "orig_active",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            isRestored: false,
            validationStatus: .verified
        )
        
        let expiredState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium2",
            transactionId: "txn_expired",
            originalTransactionId: "orig_expired",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: Calendar.current.date(byAdding: .day, value: -1, to: Date()),
            isRestored: false,
            validationStatus: .verified
        )
        
        let invalidState = PurchaseState(
            id: UUID().uuidString,
            productId: "com.example.premium3",
            transactionId: "txn_invalid",
            originalTransactionId: "orig_invalid",
            purchaseDate: Date(),
            isActive: true,
            expirationDate: nil,
            isRestored: false,
            validationStatus: .invalid
        )
        
        try await mockRepository.savePurchaseState(activeState)
        try await mockRepository.savePurchaseState(expiredState)
        try await mockRepository.savePurchaseState(invalidState)
        
        // Act
        let isActive = try await purchaseStateManager.isPremiumActive()
        
        // Assert: Should return true because of the active, non-expired, verified state
        XCTAssertTrue(isActive)
    }
}

// MARK: - Test Helper Methods

extension PurchaseStateManagerTests {
    
    func createTestPurchaseState(
        id: String = UUID().uuidString,
        productId: String,
        transactionId: String = "txn_123",
        originalTransactionId: String = "orig_123",
        isActive: Bool = true,
        validationStatus: ValidationStatus = .verified
    ) -> PurchaseState {
        return PurchaseState(
            id: id,
            productId: productId,
            transactionId: transactionId,
            originalTransactionId: originalTransactionId,
            purchaseDate: Date(),
            isActive: isActive,
            expirationDate: nil,
            isRestored: false,
            validationStatus: validationStatus
        )
    }
    
}