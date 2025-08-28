import Foundation
import StoreKit

// MARK: - Purchase State Management Types

public struct PurchaseRestoreRequest {
    public let validateReceipt: Bool
    public let forceRefresh: Bool
    
    public init(validateReceipt: Bool = true, forceRefresh: Bool = false) {
        self.validateReceipt = validateReceipt
        self.forceRefresh = forceRefresh
    }
}

public struct PurchaseRestoreResponse {
    public let restoredPurchases: [PurchaseState]
    public let newPurchases: [PurchaseState] 
    public let invalidPurchases: [String] // Product IDs
    public let success: Bool
    public let errorMessage: String?
    
    public init(restoredPurchases: [PurchaseState], newPurchases: [PurchaseState], 
                invalidPurchases: [String], success: Bool, errorMessage: String? = nil) {
        self.restoredPurchases = restoredPurchases
        self.newPurchases = newPurchases
        self.invalidPurchases = invalidPurchases
        self.success = success
        self.errorMessage = errorMessage
    }
}

// MARK: - Purchase State Repository

public protocol PurchaseStateRepositoryProtocol {
    func savePurchaseState(_ purchaseState: PurchaseState) async throws
    func getAllPurchaseStates() async throws -> [PurchaseState]
    func getPurchaseState(for productId: String) async throws -> PurchaseState?
    func deletePurchaseState(for productId: String) async throws
    func deleteAllPurchaseStates() async throws
}

// MARK: - Purchase State Manager Protocol

public protocol PurchaseStateManagerProtocol {
    func persistPurchase(_ transaction: StoreKit.Transaction) async throws -> PurchaseState
    func restorePurchases(_ request: PurchaseRestoreRequest) async throws -> PurchaseRestoreResponse
    func getCurrentPurchaseStates() async throws -> [PurchaseState]
    func validateAllPurchases() async throws -> [PurchaseState]
    func isPremiumActive() async throws -> Bool
}

// MARK: - Purchase State Manager Implementation

public class PurchaseStateManager: PurchaseStateManagerProtocol {
    private let repository: PurchaseStateRepositoryProtocol
    private let receiptValidationService: ReceiptValidationServiceProtocol
    private let logger: Logger
    
    public init(
        repository: PurchaseStateRepositoryProtocol,
        receiptValidationService: ReceiptValidationServiceProtocol,
        logger: Logger
    ) {
        self.repository = repository
        self.receiptValidationService = receiptValidationService
        self.logger = logger
    }
    
    public func persistPurchase(_ transaction: StoreKit.Transaction) async throws -> PurchaseState {
        logger.info("Persisting purchase for product: \(transaction.productID)")
        
        // Validate the transaction
        await transaction.finish()
        
        // Create purchase state
        let purchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: transaction.productID,
            transactionId: String(transaction.id),
            originalTransactionId: String(transaction.originalID),
            purchaseDate: transaction.purchaseDate,
            isActive: true,
            expirationDate: transaction.expirationDate,
            isRestored: false,
            validationStatus: .verified,
            lastValidated: Date()
        )
        
        // Save to repository
        try await repository.savePurchaseState(purchaseState)
        
        logger.info("Successfully persisted purchase: \(purchaseState.id)")
        return purchaseState
    }
    
    public func restorePurchases(_ request: PurchaseRestoreRequest) async throws -> PurchaseRestoreResponse {
        logger.info("Starting purchase restoration")
        
        var restoredPurchases: [PurchaseState] = []
        var newPurchases: [PurchaseState] = []
        var invalidPurchases: [String] = []
        var errorMessage: String?
        
        do {
            // Get current purchases from repository
            let currentPurchases = try await repository.getAllPurchaseStates()
            let currentProductIds = Set(currentPurchases.map { $0.productId })
            
            // Restore from StoreKit
            let transactions = StoreKit.Transaction.all
            
            for await transactionResult in transactions {
                switch transactionResult {
                case .verified(let transaction):
                    let productId = transaction.productID
                    
                    if currentProductIds.contains(productId) && !request.forceRefresh {
                        // Existing purchase - update if needed
                        if let existingPurchase = currentPurchases.first(where: { $0.productId == productId }) {
                            var updatedPurchase = existingPurchase
                            updatedPurchase.isRestored = true
                            updatedPurchase.lastValidated = Date()
                            
                            if request.validateReceipt {
                                updatedPurchase = try await validateAndUpdatePurchase(updatedPurchase)
                            }
                            
                            try await repository.savePurchaseState(updatedPurchase)
                            restoredPurchases.append(updatedPurchase)
                        }
                    } else {
                        // New purchase or force refresh
                        let newPurchaseState = PurchaseState(
                            id: UUID().uuidString,
                            productId: productId,
                            transactionId: String(transaction.id),
                            originalTransactionId: String(transaction.originalID),
                            purchaseDate: transaction.purchaseDate,
                            isActive: true,
                            expirationDate: transaction.expirationDate,
                            isRestored: true,
                            validationStatus: .verified,
                            lastValidated: Date()
                        )
                        
                        var finalPurchaseState = newPurchaseState
                        if request.validateReceipt {
                            finalPurchaseState = try await validateAndUpdatePurchase(newPurchaseState)
                        }
                        
                        try await repository.savePurchaseState(finalPurchaseState)
                        newPurchases.append(finalPurchaseState)
                    }
                    
                case .unverified(let transaction, let verificationResult):
                    logger.warning("Unverified transaction for product \(transaction.productID): \(verificationResult)")
                    invalidPurchases.append(transaction.productID)
                }
            }
            
            logger.info("Purchase restoration completed. Restored: \(restoredPurchases.count), New: \(newPurchases.count), Invalid: \(invalidPurchases.count)")
            
        } catch {
            logger.error("Purchase restoration failed: \(error)")
            errorMessage = error.localizedDescription
        }
        
        return PurchaseRestoreResponse(
            restoredPurchases: restoredPurchases,
            newPurchases: newPurchases,
            invalidPurchases: invalidPurchases,
            success: errorMessage == nil,
            errorMessage: errorMessage
        )
    }
    
    public func getCurrentPurchaseStates() async throws -> [PurchaseState] {
        return try await repository.getAllPurchaseStates()
    }
    
    public func validateAllPurchases() async throws -> [PurchaseState] {
        logger.info("Validating all purchases")
        
        let purchaseStates = try await repository.getAllPurchaseStates()
        var validatedStates: [PurchaseState] = []
        
        for purchaseState in purchaseStates {
            do {
                let validatedState = try await validateAndUpdatePurchase(purchaseState)
                validatedStates.append(validatedState)
                try await repository.savePurchaseState(validatedState)
            } catch {
                logger.error("Failed to validate purchase \(purchaseState.id): \(error)")
                var invalidState = purchaseState
                invalidState.validationStatus = .invalid
                invalidState.lastValidated = Date()
                validatedStates.append(invalidState)
                try await repository.savePurchaseState(invalidState)
            }
        }
        
        return validatedStates
    }
    
    public func isPremiumActive() async throws -> Bool {
        let purchaseStates = try await repository.getAllPurchaseStates()
        
        for purchaseState in purchaseStates {
            if purchaseState.isActive && purchaseState.validationStatus == .verified {
                // Check if subscription is still active
                if let expirationDate = purchaseState.expirationDate {
                    if expirationDate > Date() {
                        return true
                    }
                } else {
                    // Non-subscription purchase (one-time purchase)
                    return true
                }
            }
        }
        
        return false
    }
    
    private func validateAndUpdatePurchase(_ purchaseState: PurchaseState) async throws -> PurchaseState {
        do {
            let receiptData = try receiptValidationService.getAppStoreReceipt()
            let request = ReceiptValidationRequest(receiptData: receiptData, environment: .production)
            let response = try await receiptValidationService.validateReceipt(request)
            
            var updatedState = purchaseState
            updatedState.lastValidated = Date()
            
            if response.isValid,
               let validatedReceipt = response.receipt,
               let purchase = validatedReceipt.inAppPurchases.first(where: { $0.productId == purchaseState.productId }) {
                
                updatedState.validationStatus = .verified
                updatedState.purchaseDate = purchase.purchaseDate
                updatedState.expirationDate = purchase.expiresDate
                
                // Check if purchase is still active
                if let expirationDate = purchase.expiresDate {
                    updatedState.isActive = expirationDate > Date()
                } else {
                    updatedState.isActive = true // One-time purchase
                }
                
            } else {
                updatedState.validationStatus = .invalid
                updatedState.isActive = false
            }
            
            return updatedState
            
        } catch {
            logger.error("Receipt validation failed for purchase \(purchaseState.id): \(error)")
            var errorState = purchaseState
            errorState.validationStatus = .invalid
            errorState.lastValidated = Date()
            return errorState
        }
    }
}

// MARK: - Mock Purchase State Manager

public class MockPurchaseStateManager: PurchaseStateManagerProtocol {
    public var mockPurchaseStates: [PurchaseState] = []
    public var shouldSucceed = true
    public var isPremiumActiveMock = false
    
    public init() {}
    
    public func persistPurchase(_ transaction: StoreKit.Transaction) async throws -> PurchaseState {
        let purchaseState = PurchaseState(
            id: UUID().uuidString,
            productId: transaction.productID,
            transactionId: String(transaction.id),
            originalTransactionId: String(transaction.originalID),
            purchaseDate: transaction.purchaseDate,
            isActive: true,
            expirationDate: transaction.expirationDate,
            isRestored: false,
            validationStatus: .verified,
            lastValidated: Date()
        )
        
        mockPurchaseStates.append(purchaseState)
        return purchaseState
    }
    
    public func restorePurchases(_ request: PurchaseRestoreRequest) async throws -> PurchaseRestoreResponse {
        if shouldSucceed {
            return PurchaseRestoreResponse(
                restoredPurchases: mockPurchaseStates,
                newPurchases: [],
                invalidPurchases: [],
                success: true
            )
        } else {
            throw NSError(domain: "MockError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock restore failed"])
        }
    }
    
    public func getCurrentPurchaseStates() async throws -> [PurchaseState] {
        return mockPurchaseStates
    }
    
    public func validateAllPurchases() async throws -> [PurchaseState] {
        return mockPurchaseStates.map { state in
            var validatedState = state
            validatedState.validationStatus = shouldSucceed ? .verified : .invalid
            validatedState.lastValidated = Date()
            return validatedState
        }
    }
    
    public func isPremiumActive() async throws -> Bool {
        return isPremiumActiveMock
    }
}