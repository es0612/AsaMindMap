import SwiftUI
import MindMapCore
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Mind Map View
@available(iOS 16.0, macOS 14.0, *)
public struct MindMapView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: MindMapViewModel
    @State private var showingCreateSheet = false
    @State private var showingErrorAlert = false
    
    private let container: DIContainerProtocol
    
    // MARK: - Initialization
    public init(container: DIContainerProtocol) {
        self.container = container
        self._viewModel = StateObject(wrappedValue: MindMapViewModel(container: container))
    }
    
    public init(mindMap: MindMap, container: DIContainerProtocol) {
        self.container = container
        let vm = MindMapViewModel(container: container)
        vm.loadMindMap(mindMap)
        self._viewModel = StateObject(wrappedValue: vm)
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            ZStack {
                // Main Canvas
                if viewModel.mindMap != nil {
                    MindMapCanvasView(viewModel: viewModel)
                } else {
                    emptyStateView
                }
                
                // Loading Overlay
                if viewModel.isLoading {
                    loadingOverlay
                }
                
                // Focus Mode Controls
                if viewModel.isFocusMode {
                    focusModeControls
                }
            }
            .navigationTitle(viewModel.mindMap?.title ?? "AsaMindMap")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    if viewModel.isFocusMode {
                        Button("フォーカス解除") {
                            viewModel.exitFocusMode()
                        }
                        .foregroundColor(.orange)
                    }
                }
                
                ToolbarItemGroup(placement: .secondaryAction) {
                    Button(action: {
                        viewModel.fitToScreen()
                    }) {
                        Image(systemName: "viewfinder")
                    }
                    .accessibilityLabel("全体表示")
                    
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新しいマインドマップ")
                }
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            createMindMapSheet
        }
        .alert("エラー", isPresented: $showingErrorAlert) {
            Button("OK") {
                viewModel.showError = false
            }
        } message: {
            Text(viewModel.errorMessage ?? "不明なエラーが発生しました")
        }
        .onReceive(viewModel.$showError) { showError in
            showingErrorAlert = showError
        }
    }
    
    // MARK: - Empty State View
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("マインドマップを作成")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("アイデアを視覚的に整理して、\n創造性を解き放ちましょう")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                viewModel.createNewMindMap()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("新しいマインドマップを作成")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(25)
            }
            .accessibilityLabel("新しいマインドマップを作成")
        }
        .padding()
    }
    
    // MARK: - Loading Overlay
    @ViewBuilder
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("読み込み中...")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            .padding(24)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 8)
        }
    }
    
    // MARK: - Focus Mode Controls
    @ViewBuilder
    private var focusModeControls: some View {
        VStack {
            Spacer()
            
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Focus indicator
                    HStack {
                        Image(systemName: "scope")
                            .foregroundColor(.orange)
                        Text("フォーカスモード")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(16)
                    
                    // Exit button
                    Button(action: {
                        viewModel.exitFocusMode()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.orange)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("フォーカスモードを終了")
                }
                .padding(.trailing, 16)
            }
            .padding(.bottom, 100) // Account for potential tab bar
        }
    }
    
    // MARK: - Create Mind Map Sheet
    @ViewBuilder
    private var createMindMapSheet: some View {
        NavigationView {
            CreateMindMapView { title in
                viewModel.createNewMindMap(title: title)
                showingCreateSheet = false
            }
            .navigationTitle("新しいマインドマップ")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingCreateSheet = false
                    }
                }
            }
        }
    }
}

// MARK: - Create Mind Map View
@available(iOS 16.0, *)
private struct CreateMindMapView: View {
    @State private var title: String = ""
    let onCreate: (String) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("タイトル")
                    .font(.headline)
                
                TextField("マインドマップのタイトルを入力", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear {
                        title = "新しいマインドマップ"
                    }
            }
            
            Button(action: {
                onCreate(title.isEmpty ? "新しいマインドマップ" : title)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("作成")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 16.0, macOS 14.0, *)
struct MindMapView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Empty state
            MindMapView(container: DIContainer.configure())
                .previewDisplayName("Empty State")
            
            // With mind map
            MindMapView(
                mindMap: MindMap(
                    id: UUID(),
                    title: "サンプルマインドマップ",
                    createdAt: Date(),
                    updatedAt: Date()
                ),
                container: DIContainer.configure()
            )
            .previewDisplayName("With Mind Map")
        }
    }
}
#endif