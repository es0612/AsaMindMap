import XCTest
import Foundation
@testable import MindMapCore

class ReceiptValidationServiceTests: XCTestCase {
    
    private var receiptValidationService: ReceiptValidationService!
    private var mockReceiptValidationService: MockReceiptValidationService!
    
    override func setUp() {
        super.setUp()
        receiptValidationService = ReceiptValidationService()
        mockReceiptValidationService = MockReceiptValidationService()
    }
    
    override func tearDown() {
        receiptValidationService = nil
        mockReceiptValidationService = nil
        super.tearDown()
    }
    
    // MARK: - Receipt Validation Tests
    
    func testValidateReceipt_WithValidReceipt_ReturnsSuccess() async throws {
        // Arrange
        mockReceiptValidationService.shouldSucceed = true
        let receiptData = "valid receipt data".data(using: .utf8)!
        let request = ReceiptValidationRequest(receiptData: receiptData, environment: .sandbox)
        
        // Act
        let response = try await mockReceiptValidationService.validateReceipt(request)
        
        // Assert
        XCTAssertTrue(response.isValid)
        XCTAssertEqual(response.status, 0)
        XCTAssertNotNil(response.receipt)
        XCTAssertNil(response.errorMessage)
    }
    
    func testValidateReceipt_WithInvalidReceipt_ReturnsFailure() async throws {
        // Arrange
        mockReceiptValidationService.shouldSucceed = false
        let receiptData = "invalid receipt data".data(using: .utf8)!
        let request = ReceiptValidationRequest(receiptData: receiptData, environment: .sandbox)
        
        // Act
        let response = try await mockReceiptValidationService.validateReceipt(request)
        
        // Assert
        XCTAssertFalse(response.isValid)
        XCTAssertEqual(response.status, 21002)
        XCTAssertNil(response.receipt)
        XCTAssertNotNil(response.errorMessage)
    }
    
    func testGetAppStoreReceipt_WithMockService_ReturnsData() throws {
        // Act
        let receiptData = try mockReceiptValidationService.getAppStoreReceipt()
        
        // Assert
        XCTAssertFalse(receiptData.isEmpty)
        XCTAssertEqual(String(data: receiptData, encoding: .utf8), "mock receipt data")
    }
    
    // MARK: - Receipt Environment Tests
    
    func testReceiptEnvironment_Production_HasCorrectURL() {
        // Arrange
        let environment = ReceiptEnvironment.production
        
        // Act
        let url = environment.verificationURL
        
        // Assert
        XCTAssertEqual(url.absoluteString, "https://buy.itunes.apple.com/verifyReceipt")
    }
    
    func testReceiptEnvironment_Sandbox_HasCorrectURL() {
        // Arrange
        let environment = ReceiptEnvironment.sandbox
        
        // Act
        let url = environment.verificationURL
        
        // Assert
        XCTAssertEqual(url.absoluteString, "https://sandbox.itunes.apple.com/verifyReceipt")
    }
    
    // MARK: - Validated Receipt Tests
    
    func testValidatedReceipt_Creation_SetsCorrectValues() {
        // Arrange
        let bundleId = "com.example.asamindmap"
        let applicationVersion = "1.0.0"
        let inAppPurchase = ValidatedInAppPurchase(
            productId: "com.example.premium",
            transactionId: "123456789",
            originalTransactionId: "987654321",
            purchaseDate: Date(),
            originalPurchaseDate: Date(),
            expiresDate: nil,
            quantity: 1
        )
        
        // Act
        let validatedReceipt = ValidatedReceipt(
            bundleId: bundleId,
            applicationVersion: applicationVersion,
            inAppPurchases: [inAppPurchase]
        )
        
        // Assert
        XCTAssertEqual(validatedReceipt.bundleId, bundleId)
        XCTAssertEqual(validatedReceipt.applicationVersion, applicationVersion)
        XCTAssertEqual(validatedReceipt.inAppPurchases.count, 1)
        XCTAssertEqual(validatedReceipt.inAppPurchases.first?.productId, "com.example.premium")
    }
    
    // MARK: - Receipt Validation Error Tests
    
    func testReceiptValidationError_LocalizedDescription() {
        // Arrange & Act & Assert
        XCTAssertEqual(ReceiptValidationError.receiptNotFound.localizedDescription, "App Store receipt not found")
        XCTAssertEqual(ReceiptValidationError.networkError.localizedDescription, "Network error during receipt validation")
        XCTAssertEqual(ReceiptValidationError.invalidResponse.localizedDescription, "Invalid response from App Store")
        XCTAssertEqual(ReceiptValidationError.invalidReceiptData.localizedDescription, "Invalid receipt data")
    }
    
    // MARK: - Integration Tests (Mock Service)
    
    func testReceiptValidationFlow_EndToEnd_WithMockService() async throws {
        // Arrange
        mockReceiptValidationService.shouldSucceed = true
        let mockReceipt = ValidatedReceipt(
            bundleId: "com.example.asamindmap",
            applicationVersion: "1.0.0",
            inAppPurchases: [
                ValidatedInAppPurchase(
                    productId: "com.example.premium_monthly",
                    transactionId: "txn_123",
                    originalTransactionId: "orig_123",
                    purchaseDate: Date(),
                    originalPurchaseDate: Date(),
                    expiresDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                    quantity: 1
                )
            ]
        )
        mockReceiptValidationService.validatedReceipt = mockReceipt
        
        // Act
        let receiptData = try mockReceiptValidationService.getAppStoreReceipt()
        let request = ReceiptValidationRequest(receiptData: receiptData, environment: .sandbox)
        let response = try await mockReceiptValidationService.validateReceipt(request)
        
        // Assert
        XCTAssertTrue(response.isValid)
        XCTAssertEqual(response.status, 0)
        XCTAssertNotNil(response.receipt)
        XCTAssertEqual(response.receipt?.bundleId, "com.example.asamindmap")
        XCTAssertEqual(response.receipt?.inAppPurchases.count, 1)
        XCTAssertEqual(response.receipt?.inAppPurchases.first?.productId, "com.example.premium_monthly")
    }
    
    // MARK: - Performance Tests
    
    func testReceiptValidation_Performance() {
        // Arrange
        let receiptData = "test receipt data".data(using: .utf8)!
        let request = ReceiptValidationRequest(receiptData: receiptData, environment: .sandbox)
        
        // Act & Assert
        measure {
            Task {
                _ = try? await mockReceiptValidationService.validateReceipt(request)
            }
        }
    }
    
    // MARK: - Edge Cases
    
    func testValidateReceipt_WithEmptyReceiptData_HandlesGracefully() async throws {
        // Arrange
        let emptyReceiptData = Data()
        let request = ReceiptValidationRequest(receiptData: emptyReceiptData, environment: .sandbox)
        mockReceiptValidationService.shouldSucceed = false
        
        // Act
        let response = try await mockReceiptValidationService.validateReceipt(request)
        
        // Assert
        XCTAssertFalse(response.isValid)
        XCTAssertNotNil(response.errorMessage)
    }
}

// MARK: - Test Helper Extensions

extension ReceiptValidationServiceTests {
    
    func createMockValidatedInAppPurchase(
        productId: String = "com.example.premium",
        transactionId: String = "txn_123",
        originalTransactionId: String = "orig_123",
        purchaseDate: Date = Date(),
        expiresDate: Date? = nil
    ) -> ValidatedInAppPurchase {
        return ValidatedInAppPurchase(
            productId: productId,
            transactionId: transactionId,
            originalTransactionId: originalTransactionId,
            purchaseDate: purchaseDate,
            originalPurchaseDate: purchaseDate,
            expiresDate: expiresDate,
            quantity: 1
        )
    }
    
    func createMockValidatedReceipt(
        bundleId: String = "com.example.asamindmap",
        applicationVersion: String = "1.0.0",
        inAppPurchases: [ValidatedInAppPurchase] = []
    ) -> ValidatedReceipt {
        return ValidatedReceipt(
            bundleId: bundleId,
            applicationVersion: applicationVersion,
            inAppPurchases: inAppPurchases
        )
    }
}