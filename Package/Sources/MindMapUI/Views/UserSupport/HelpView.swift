import SwiftUI
import MindMapCore

public struct HelpView: View {
    
    @StateObject private var viewModel = HelpViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
NavigationView {
            VStack(spacing: 0) {
                // カテゴリ選択
                categorySelector
                
                // 検索バー
                searchBar
                
                // コンテンツリスト
                if viewModel.isLoading {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage {
                    errorView(message: errorMessage)
                } else {
                    contentList
                }
            }
            .navigationTitle("ヘルプ")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
            .task {
                await viewModel.loadHelpContents()
            }
        }
    }
    
    // MARK: - View Components
    
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(HelpCategory.allCases, id: \.self) { category in
                    CategoryChip(
                        category: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.selectCategory(category)
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("ヘルプを検索", text: $viewModel.searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if !viewModel.searchText.isEmpty {
                Button("クリア") {
                    viewModel.clearSearch()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    private var contentList: some View {
        List(viewModel.filteredContents) { content in
            NavigationLink(destination: HelpDetailView(content: content)) {
                HelpContentRow(content: content)
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("ヘルプを読み込んでいます...")
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Button("再試行") {
                Task {
                    await viewModel.loadHelpContents()
                }
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Supporting Views

struct CategoryChip: View {
    let category: HelpCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(category.displayName)
                .font(.subheadline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct HelpContentRow: View {
    let content: HelpContent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(content.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if content.isMultiStep {
                    Image(systemName: "list.number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(content.content)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(content.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                
                Spacer()
                
                if content.stepCount > 0 {
                    Text("\(content.stepCount)ステップ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    HelpView()
}