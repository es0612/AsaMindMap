import SwiftUI
import Combine
import MindMapCore

@MainActor
public class PaywallViewModel: ObservableObject {
    
    @Published public var products: [Product] = []
    @Published public var selectedProductId: String?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var showSuccess = false
    
    private let loadProductsUseCase: LoadAvailableProductsUseCaseProtocol
    private let purchaseUseCase: PurchasePremiumUseCaseProtocol
    private let restoreUseCase: RestorePurchasesUseCaseProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    public init(
        loadProductsUseCase: LoadAvailableProductsUseCaseProtocol,
        purchaseUseCase: PurchasePremiumUseCaseProtocol,
        restoreUseCase: RestorePurchasesUseCaseProtocol
    ) {
        self.loadProductsUseCase = loadProductsUseCase
        self.purchaseUseCase = purchaseUseCase
        self.restoreUseCase = restoreUseCase
    }
    
    public var selectedProduct: Product? {
        return products.first { $0.id == selectedProductId }
    }
    
    public func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await loadProductsUseCase.execute()
            products = response.products
            
            // Auto-select the first product (usually monthly)
            if let firstProduct = products.first {
                selectedProductId = firstProduct.id
            }
        } catch {
            errorMessage = "製品の読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    public func selectProduct(_ productId: String) {
        selectedProductId = productId
    }
    
    public func purchase() async {
        guard let selectedProductId = selectedProductId else {
            errorMessage = "製品を選択してください"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let request = PurchasePremiumRequest(productId: selectedProductId)
            let response = try await purchaseUseCase.execute(request)
            
            if response.isSuccess {
                showSuccess = true
            } else if let error = response.error {
                errorMessage = "購入に失敗しました: \(error.localizedDescription)"
            } else {
                errorMessage = "購入に失敗しました"
            }
        } catch {
            if let monetizationError = error as? MonetizationError {
                switch monetizationError {
                case .purchaseFailed:
                    errorMessage = "購入処理に失敗しました。しばらく時間をおいて再度お試しください。"
                case .storeKitNotAvailable:
                    errorMessage = "App内課金がご利用いただけません。"
                default:
                    errorMessage = "予期しないエラーが発生しました: \(error.localizedDescription)"
                }
            } else {
                errorMessage = "購入に失敗しました: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    public func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await restoreUseCase.execute()
            
            if response.restoredPurchases.isEmpty {
                errorMessage = "復元できる購入履歴が見つかりませんでした"
            } else {
                showSuccess = true
            }
        } catch {
            errorMessage = "購入履歴の復元に失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}