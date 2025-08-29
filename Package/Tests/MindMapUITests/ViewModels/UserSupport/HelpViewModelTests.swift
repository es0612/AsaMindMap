import Testing
import Foundation
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

struct HelpViewModelTests {
    
    @Test("ヘルプViewModelの初期化テスト")
    func testHelpViewModelInitialization() {
        // When
        let viewModel = HelpViewModel()
        
        // Then
        #expect(viewModel.helpContents.isEmpty)
        #expect(viewModel.selectedCategory == .gettingStarted)
        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.filteredContents.isEmpty)
    }
    
    @Test("ヘルプコンテンツ読み込みテスト")
    func testLoadHelpContents() async {
        // Given
        let viewModel = HelpViewModel()
        
        // When
        await viewModel.loadHelpContents()
        
        // Then
        #expect(!viewModel.helpContents.isEmpty)
        #expect(!viewModel.filteredContents.isEmpty)
    }
    
    @Test("カテゴリフィルタリングテスト")
    func testCategoryFiltering() async {
        // Given
        let viewModel = HelpViewModel()
        await viewModel.loadHelpContents()
        
        // When
        viewModel.selectCategory(.advanced)
        
        // Then
        #expect(viewModel.selectedCategory == .advanced)
        let advancedContents = viewModel.filteredContents.filter { $0.category == .advanced }
        #expect(viewModel.filteredContents.count == advancedContents.count)
    }
    
    @Test("検索機能テスト")
    func testSearchFunctionality() async {
        // Given
        let viewModel = HelpViewModel()
        await viewModel.loadHelpContents()
        
        // When
        viewModel.searchText = "マインドマップ"
        
        // Then
        let searchResults = viewModel.filteredContents.filter { 
            $0.title.contains("マインドマップ") || $0.content.contains("マインドマップ") 
        }
        #expect(viewModel.filteredContents.count == searchResults.count)
    }
}