import SwiftUI
import MindMapCore
import DesignSystem

public struct PaywallView: View {
    @StateObject private var viewModel: PaywallViewModel
    @Environment(\.dismiss) private var dismiss
    
    public init(viewModel: PaywallViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    public var body: some View {
        NavigationView {
            ScrollView(.vertical) {
                VStack(spacing: 24) {
                    headerSection
                    featuresSection
                    productsSection
                    footerSection
                }
                .padding()
            }
            .navigationTitle("プレミアムプラン")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                #endif
            }
        }
        .overlay(alignment: .center) {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .alert("エラー", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .alert("購入完了", isPresented: .constant(viewModel.showSuccess)) {
            Button("OK") {
                viewModel.showSuccess = false
                dismiss()
            }
        } message: {
            Text("プレミアムプランのご購入ありがとうございます！")
        }
        .task {
            await viewModel.loadProducts()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
            
            Text("AsaMindMap Premium")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("より豊かなマインドマップ体験を")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("プレミアム機能")
                .font(.title2)
                .fontWeight(.bold)
            
            FeatureRow(
                icon: "paintbrush.pointed.fill",
                title: "高度な書式設定",
                description: "豊富なカラーパレット、フォント、スタイルオプション"
            )
            
            FeatureRow(
                icon: "infinity",
                title: "無制限ノード",
                description: "制限なしで大規模なマインドマップを作成"
            )
            
            FeatureRow(
                icon: "square.and.arrow.up.fill",
                title: "プレミアムエクスポート",
                description: "高品質PDF、カスタムテンプレート、一括エクスポート"
            )
            
            FeatureRow(
                icon: "person.2.fill",
                title: "コラボレーション機能",
                description: "リアルタイム共同編集、コメント、共有権限管理"
            )
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(12)
    }
    
    private var productsSection: some View {
        VStack(spacing: 16) {
            Text("プランを選択")
                .font(.title2)
                .fontWeight(.bold)
            
            ForEach(viewModel.products, id: \.id) { product in
                ProductCard(
                    product: product,
                    isSelected: viewModel.selectedProductId == product.id,
                    onSelect: { viewModel.selectProduct(product.id) }
                )
            }
            
            if let selectedProduct = viewModel.selectedProduct {
                PurchaseButton(
                    product: selectedProduct,
                    isLoading: viewModel.isLoading
                ) {
                    await viewModel.purchase()
                }
            }
            
            Button("購入履歴を復元") {
                Task {
                    await viewModel.restorePurchases()
                }
            }
            .foregroundColor(.blue)
            .font(.footnote)
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("自動更新サブスクリプション")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("購入後はApp Storeのサブスクリプション設定からいつでもキャンセルできます")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct ProductCard: View {
    let product: Product
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if case .subscription(.yearly) = product.type {
                            Text("お得")
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                    }
                    
                    Text(product.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                VStack {
                    Text("¥\(Int(product.price))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if case .subscription(.monthly) = product.type {
                        Text("/月")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if case .subscription(.yearly) = product.type {
                        Text("/年")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray, lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PurchaseButton: View {
    let product: Product
    let isLoading: Bool
    let onPurchase: () async -> Void
    
    var body: some View {
        Button {
            Task {
                await onPurchase()
            }
        } label: {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isLoading ? "処理中..." : "購入する")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isLoading ? Color.gray : Color.blue)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }
}