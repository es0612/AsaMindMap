import Foundation

// MARK: - Purchase Premium Use Case

public class PurchasePremiumUseCase: PurchasePremiumUseCaseProtocol {
    private let service: MonetizationServiceProtocol
    private let repository: PurchaseStateRepositoryProtocol
    
    public init(
        service: MonetizationServiceProtocol,
        repository: PurchaseStateRepositoryProtocol
    ) {
        self.service = service
        self.repository = repository
    }
    
    public func execute(_ request: PurchasePremiumRequest) async throws -> PurchasePremiumResponse {
        do {
            let result = try await service.purchase(productId: request.productId)
            
            if result.isSuccess, let subscription = result.subscription {
                // Create new purchase state for this subscription
                let purchaseState = PurchaseState(
                    id: UUID().uuidString,
                    productId: request.productId,
                    transactionId: UUID().uuidString, // This would come from the actual transaction
                    originalTransactionId: UUID().uuidString,
                    purchaseDate: Date(),
                    isActive: subscription.isActive,
                    expirationDate: subscription.expirationDate,
                    isRestored: false,
                    validationStatus: .verified,
                    lastValidated: Date()
                )
                try await repository.savePurchaseState(purchaseState)
                
                return PurchasePremiumResponse(
                    isSuccess: true,
                    subscription: subscription
                )
            } else {
                return PurchasePremiumResponse(
                    isSuccess: false,
                    error: .purchaseFailed(reason: "Purchase failed")
                )
            }
        } catch {
            throw MonetizationError.purchaseFailed(reason: "Purchase failed with error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Restore Purchases Use Case

public class RestorePurchasesUseCase: RestorePurchasesUseCaseProtocol {
    private let service: MonetizationServiceProtocol
    private let repository: PurchaseStateRepositoryProtocol
    
    public init(
        service: MonetizationServiceProtocol,
        repository: PurchaseStateRepositoryProtocol
    ) {
        self.service = service
        self.repository = repository
    }
    
    public func execute() async throws -> RestorePurchasesResponse {
        let restoredSubscriptions = try await service.restorePurchases()
        
        // Update or create purchase states for restored subscriptions
        for subscription in restoredSubscriptions.filter({ $0.isValid }) {
            let existingState = try await repository.getPurchaseState(for: subscription.productId)
            
            if var existingState = existingState {
                // Update existing purchase state
                existingState.isActive = subscription.isActive
                existingState.expirationDate = subscription.expirationDate
                existingState.isRestored = true
                existingState.validationStatus = .verified
                existingState.lastValidated = Date()
                try await repository.savePurchaseState(existingState)
            } else {
                // Create new purchase state for restored subscription
                let purchaseState = PurchaseState(
                    id: UUID().uuidString,
                    productId: subscription.productId,
                    transactionId: UUID().uuidString,
                    originalTransactionId: UUID().uuidString,
                    purchaseDate: Date(),
                    isActive: subscription.isActive,
                    expirationDate: subscription.expirationDate,
                    isRestored: true,
                    validationStatus: .verified,
                    lastValidated: Date()
                )
                try await repository.savePurchaseState(purchaseState)
            }
        }
        
        return RestorePurchasesResponse(restoredPurchases: restoredSubscriptions)
    }
}

// MARK: - Validate Premium Access Use Case

public class ValidatePremiumAccessUseCase: ValidatePremiumAccessUseCaseProtocol {
    private let repository: PurchaseStateRepositoryProtocol
    
    public init(repository: PurchaseStateRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: ValidatePremiumAccessRequest) async throws -> ValidatePremiumAccessResponse {
        let allPurchaseStates = try await repository.getAllPurchaseStates()
        let activePurchaseStates = allPurchaseStates.filter { $0.isActive && $0.validationStatus == .verified && !$0.isExpired }
        
        // Check if any active purchase state allows access to the requested feature
        let hasAccess = activePurchaseStates.contains { purchaseState in
            purchaseState.canAccessFeature(request.feature)
        }
        
        return ValidatePremiumAccessResponse(
            hasAccess: hasAccess,
            subscription: activePurchaseStates.first?.activeSubscription
        )
    }
}

// MARK: - Load Available Products Use Case

public class LoadAvailableProductsUseCase: LoadAvailableProductsUseCaseProtocol {
    private let service: MonetizationServiceProtocol
    
    public init(service: MonetizationServiceProtocol) {
        self.service = service
    }
    
    public func execute() async throws -> LoadAvailableProductsResponse {
        let products = try await service.loadAvailableProducts()
        return LoadAvailableProductsResponse(products: products)
    }
}

// MARK: - Validate Receipt Use Case

public class ValidateReceiptUseCase: ValidateReceiptUseCaseProtocol {
    private let service: MonetizationServiceProtocol
    private let repository: PurchaseStateRepositoryProtocol
    
    public init(
        service: MonetizationServiceProtocol,
        repository: PurchaseStateRepositoryProtocol
    ) {
        self.service = service
        self.repository = repository
    }
    
    public func execute(_ request: ValidateReceiptRequest) async throws -> ValidateReceiptResponse {
        let validationResult = try await service.validateReceipt(request.receiptData)
        
        if validationResult.isValid {
            // Update purchase states with active subscriptions
            for activeSubscription in validationResult.activeSubscriptions {
                let existingState = try await repository.getPurchaseState(for: activeSubscription.productId)
                
                if var existingState = existingState {
                    // Update existing purchase state
                    existingState.isActive = activeSubscription.isActive
                    existingState.expirationDate = activeSubscription.expirationDate
                    existingState.validationStatus = .verified
                    existingState.lastValidated = Date()
                    try await repository.savePurchaseState(existingState)
                } else {
                    // Create new purchase state for validated subscription
                    let purchaseState = PurchaseState(
                        id: UUID().uuidString,
                        productId: activeSubscription.productId,
                        transactionId: UUID().uuidString,
                        originalTransactionId: UUID().uuidString,
                        purchaseDate: Date(),
                        isActive: activeSubscription.isActive,
                        expirationDate: activeSubscription.expirationDate,
                        isRestored: false,
                        validationStatus: .verified,
                        lastValidated: Date()
                    )
                    try await repository.savePurchaseState(purchaseState)
                }
            }
        }
        
        return ValidateReceiptResponse(
            isValid: validationResult.isValid,
            activeSubscriptions: validationResult.activeSubscriptions
        )
    }
}