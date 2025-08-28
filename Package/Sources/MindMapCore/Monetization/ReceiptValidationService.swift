import Foundation
import StoreKit

// MARK: - Receipt Validation Types

public struct ReceiptValidationRequest {
    public let receiptData: Data
    public let environment: ReceiptEnvironment
    
    public init(receiptData: Data, environment: ReceiptEnvironment) {
        self.receiptData = receiptData
        self.environment = environment
    }
}

public enum ReceiptEnvironment {
    case production
    case sandbox
    
    var verificationURL: URL {
        switch self {
        case .production:
            return URL(string: "https://buy.itunes.apple.com/verifyReceipt")!
        case .sandbox:
            return URL(string: "https://sandbox.itunes.apple.com/verifyReceipt")!
        }
    }
}

public struct ReceiptValidationResponse {
    public let isValid: Bool
    public let status: Int
    public let receipt: ValidatedReceipt?
    public let errorMessage: String?
    
    public init(isValid: Bool, status: Int, receipt: ValidatedReceipt?, errorMessage: String? = nil) {
        self.isValid = isValid
        self.status = status
        self.receipt = receipt
        self.errorMessage = errorMessage
    }
}

public struct ValidatedReceipt {
    public let bundleId: String
    public let applicationVersion: String
    public let inAppPurchases: [ValidatedInAppPurchase]
    
    public init(bundleId: String, applicationVersion: String, inAppPurchases: [ValidatedInAppPurchase]) {
        self.bundleId = bundleId
        self.applicationVersion = applicationVersion
        self.inAppPurchases = inAppPurchases
    }
}

public struct ValidatedInAppPurchase {
    public let productId: String
    public let transactionId: String
    public let originalTransactionId: String
    public let purchaseDate: Date
    public let originalPurchaseDate: Date
    public let expiresDate: Date?
    public let quantity: Int
    
    public init(productId: String, transactionId: String, originalTransactionId: String, 
                purchaseDate: Date, originalPurchaseDate: Date, expiresDate: Date?, quantity: Int) {
        self.productId = productId
        self.transactionId = transactionId
        self.originalTransactionId = originalTransactionId
        self.purchaseDate = purchaseDate
        self.originalPurchaseDate = originalPurchaseDate
        self.expiresDate = expiresDate
        self.quantity = quantity
    }
}

// MARK: - Receipt Validation Protocol

public protocol ReceiptValidationServiceProtocol {
    func validateReceipt(_ request: ReceiptValidationRequest) async throws -> ReceiptValidationResponse
    func getAppStoreReceipt() throws -> Data
}

// MARK: - Receipt Validation Service Implementation

public class ReceiptValidationService: ReceiptValidationServiceProtocol {
    
    public init() {}
    
    public func validateReceipt(_ request: ReceiptValidationRequest) async throws -> ReceiptValidationResponse {
        let receiptString = request.receiptData.base64EncodedString()
        let requestBody = [
            "receipt-data": receiptString,
            "password": "" // Shared secret - should be configured in production
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        
        var urlRequest = URLRequest(url: request.environment.verificationURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw ReceiptValidationError.networkError
        }
        
        let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let status = responseJSON?["status"] as? Int else {
            throw ReceiptValidationError.invalidResponse
        }
        
        if status == 0 {
            // Valid receipt
            let validatedReceipt = try parseValidatedReceipt(from: responseJSON)
            return ReceiptValidationResponse(isValid: true, status: status, receipt: validatedReceipt)
        } else if status == 21007 {
            // Sandbox receipt sent to production - retry with sandbox
            if request.environment == .production {
                let sandboxRequest = ReceiptValidationRequest(
                    receiptData: request.receiptData,
                    environment: .sandbox
                )
                return try await validateReceipt(sandboxRequest)
            } else {
                return ReceiptValidationResponse(
                    isValid: false, 
                    status: status, 
                    receipt: nil,
                    errorMessage: "Receipt validation failed with status: \(status)"
                )
            }
        } else {
            // Other error statuses
            return ReceiptValidationResponse(
                isValid: false, 
                status: status, 
                receipt: nil,
                errorMessage: "Receipt validation failed with status: \(status)"
            )
        }
    }
    
    public func getAppStoreReceipt() throws -> Data {
        guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
              FileManager.default.fileExists(atPath: appStoreReceiptURL.path) else {
            throw ReceiptValidationError.receiptNotFound
        }
        
        return try Data(contentsOf: appStoreReceiptURL)
    }
    
    private func parseValidatedReceipt(from responseJSON: [String: Any]?) throws -> ValidatedReceipt {
        guard let receiptData = responseJSON?["receipt"] as? [String: Any],
              let bundleId = receiptData["bundle_id"] as? String,
              let applicationVersion = receiptData["application_version"] as? String else {
            throw ReceiptValidationError.invalidReceiptData
        }
        
        let inAppArray = receiptData["in_app"] as? [[String: Any]] ?? []
        let inAppPurchases = inAppArray.compactMap { inAppData -> ValidatedInAppPurchase? in
            guard let productId = inAppData["product_id"] as? String,
                  let transactionId = inAppData["transaction_id"] as? String,
                  let originalTransactionId = inAppData["original_transaction_id"] as? String,
                  let purchaseDateMs = inAppData["purchase_date_ms"] as? String,
                  let originalPurchaseDateMs = inAppData["original_purchase_date_ms"] as? String,
                  let quantity = inAppData["quantity"] as? String else {
                return nil
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss VV"
            
            let purchaseDate = Date(timeIntervalSince1970: TimeInterval(purchaseDateMs)! / 1000)
            let originalPurchaseDate = Date(timeIntervalSince1970: TimeInterval(originalPurchaseDateMs)! / 1000)
            
            var expiresDate: Date?
            if let expiresDateMs = inAppData["expires_date_ms"] as? String {
                expiresDate = Date(timeIntervalSince1970: TimeInterval(expiresDateMs)! / 1000)
            }
            
            return ValidatedInAppPurchase(
                productId: productId,
                transactionId: transactionId,
                originalTransactionId: originalTransactionId,
                purchaseDate: purchaseDate,
                originalPurchaseDate: originalPurchaseDate,
                expiresDate: expiresDate,
                quantity: Int(quantity) ?? 1
            )
        }
        
        return ValidatedReceipt(
            bundleId: bundleId,
            applicationVersion: applicationVersion,
            inAppPurchases: inAppPurchases
        )
    }
}

// MARK: - Receipt Validation Errors

public enum ReceiptValidationError: Error, LocalizedError {
    case receiptNotFound
    case networkError
    case invalidResponse
    case invalidReceiptData
    
    public var errorDescription: String? {
        switch self {
        case .receiptNotFound:
            return "App Store receipt not found"
        case .networkError:
            return "Network error during receipt validation"
        case .invalidResponse:
            return "Invalid response from App Store"
        case .invalidReceiptData:
            return "Invalid receipt data"
        }
    }
}

// MARK: - Mock Receipt Validation Service

public class MockReceiptValidationService: ReceiptValidationServiceProtocol {
    public var shouldSucceed = true
    public var validatedReceipt: ValidatedReceipt?
    
    public init() {}
    
    public func validateReceipt(_ request: ReceiptValidationRequest) async throws -> ReceiptValidationResponse {
        if shouldSucceed {
            return ReceiptValidationResponse(
                isValid: true,
                status: 0,
                receipt: validatedReceipt ?? createMockValidatedReceipt()
            )
        } else {
            return ReceiptValidationResponse(
                isValid: false,
                status: 21002,
                receipt: nil,
                errorMessage: "Mock validation failure"
            )
        }
    }
    
    public func getAppStoreReceipt() throws -> Data {
        return "mock receipt data".data(using: .utf8)!
    }
    
    private func createMockValidatedReceipt() -> ValidatedReceipt {
        let mockPurchase = ValidatedInAppPurchase(
            productId: "com.example.premium",
            transactionId: "mock_transaction_123",
            originalTransactionId: "mock_original_123",
            purchaseDate: Date(),
            originalPurchaseDate: Date(),
            expiresDate: nil,
            quantity: 1
        )
        
        return ValidatedReceipt(
            bundleId: "com.example.asamindmap",
            applicationVersion: "1.0.0",
            inAppPurchases: [mockPurchase]
        )
    }
}