import Foundation
import SwiftUI
import Combine
import MindMapCore

@MainActor
public class HelpViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var helpContents: [HelpContent] = []
    @Published public var selectedCategory: HelpCategory = .gettingStarted
    @Published public var searchText: String = ""
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Computed Properties
    public var filteredContents: [HelpContent] {
        var filtered = helpContents
        
        // Category filter
        if selectedCategory != .gettingStarted || !searchText.isEmpty {
            filtered = filtered.filter { content in
                if !searchText.isEmpty {
                    return content.title.localizedCaseInsensitiveContains(searchText) ||
                           content.content.localizedCaseInsensitiveContains(searchText)
                } else {
                    return content.category == selectedCategory
                }
            }
        }
        
        return filtered
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    public func loadHelpContents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // シミュレートされたヘルプコンテンツの読み込み
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒の遅延
            
            let contents = createSampleHelpContents()
            helpContents = contents
            
        } catch {
            errorMessage = "ヘルプコンテンツの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    public func selectCategory(_ category: HelpCategory) {
        selectedCategory = category
    }
    
    public func clearSearch() {
        searchText = ""
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 検索テキストの変更をデバウンス
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { _ in
                // フィルタリングは computed property で自動的に行われる
            }
            .store(in: &cancellables)
    }
    
    private func createSampleHelpContents() -> [HelpContent] {
        return [
            HelpContent(
                title: "マインドマップの作成方法",
                content: "新しいマインドマップを作成するには、「新規作成」ボタンをタップしてください。",
                category: .gettingStarted,
                steps: [
                    HelpStep(order: 1, title: "新規作成をタップ", description: "メイン画面の「新規作成」ボタンをタップします"),
                    HelpStep(order: 2, title: "タイトルを入力", description: "マインドマップのタイトルを入力してください"),
                    HelpStep(order: 3, title: "中央ノードをタップ", description: "中央のノードをタップしてメインテーマを入力します")
                ]
            ),
            HelpContent(
                title: "ノードの追加と編集",
                content: "ノードを追加するには、既存のノードから長押しドラッグを行います。",
                category: .basic,
                steps: [
                    HelpStep(order: 1, title: "ノードを長押し", description: "追加したい親ノードを長押しします"),
                    HelpStep(order: 2, title: "ドラッグで子ノード作成", description: "長押しした状態でドラッグすると子ノードが作成されます"),
                    HelpStep(order: 3, title: "テキストを入力", description: "新しいノードをダブルタップしてテキストを入力します")
                ]
            ),
            HelpContent(
                title: "高度なジェスチャー操作",
                content: "Apple Pencilを使用した描画機能やマルチタッチジェスチャーについて説明します。",
                category: .advanced,
                steps: [
                    HelpStep(order: 1, title: "Apple Pencil対応", description: "Apple Pencilで自由な描画が可能です"),
                    HelpStep(order: 2, title: "ピンチズーム", description: "2本指でピンチするとズームできます"),
                    HelpStep(order: 3, title: "3本指パン", description: "3本指でドラッグするとキャンバス全体を移動できます")
                ]
            ),
            HelpContent(
                title: "アプリが起動しない場合",
                content: "アプリが正常に起動しない場合の対処法について説明します。",
                category: .troubleshooting,
                steps: [
                    HelpStep(order: 1, title: "アプリの再起動", description: "アプリを完全に終了してから再起動してください"),
                    HelpStep(order: 2, title: "デバイスの再起動", description: "デバイスを再起動してください"),
                    HelpStep(order: 3, title: "アプリの再インストール", description: "問題が解決しない場合は、アプリを再インストールしてください")
                ]
            ),
            HelpContent(
                title: "エクスポートとシェア機能",
                content: "作成したマインドマップをPDFやPNG形式でエクスポートする方法を説明します。",
                category: .features,
                steps: [
                    HelpStep(order: 1, title: "エクスポートボタン", description: "画面上部のエクスポートアイコンをタップします"),
                    HelpStep(order: 2, title: "形式を選択", description: "PDF、PNG、OPML形式から選択できます"),
                    HelpStep(order: 3, title: "シェア", description: "エクスポート後、他のアプリでシェアできます")
                ]
            )
        ]
    }
}