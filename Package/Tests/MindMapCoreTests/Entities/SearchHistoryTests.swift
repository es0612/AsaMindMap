import Foundation
import Testing
@testable import MindMapCore

struct SearchHistoryTests {
    
    @Test("検索履歴エントリの作成と基本プロパティ")
    func testSearchHistoryEntryCreation() async throws {
        // Given
        let query = "重要なアイデア"
        let searchType = SearchType.fullText
        let filters: [SearchFilter] = [.tag("プロジェクト")]
        let resultsCount = 5
        
        // When
        let historyEntry = SearchHistoryEntry(
            query: query,
            searchType: searchType,
            filters: filters,
            resultsCount: resultsCount
        )
        
        // Then
        #expect(historyEntry.id != UUID())
        #expect(historyEntry.query == query)
        #expect(historyEntry.searchType == searchType)
        #expect(historyEntry.filters == filters)
        #expect(historyEntry.resultsCount == resultsCount)
        #expect(historyEntry.searchedAt <= Date())
        #expect(!historyEntry.isFavorite)
    }
    
    @Test("検索履歴エントリの空クエリ検証")
    func testSearchHistoryEntryEmptyQuery() async throws {
        // Given
        let emptyQuery = ""
        let validQuery = "  "
        
        // When
        let emptyEntry = SearchHistoryEntry(query: emptyQuery, searchType: .fullText, filters: [], resultsCount: 0)
        let whitespaceEntry = SearchHistoryEntry(query: validQuery, searchType: .fullText, filters: [], resultsCount: 0)
        
        // Then
        #expect(!emptyEntry.isValidQuery)
        #expect(!whitespaceEntry.isValidQuery)
    }
    
    @Test("検索履歴エントリの有効クエリ検証")
    func testSearchHistoryEntryValidQuery() async throws {
        // Given
        let validQuery = "アイデア"
        let queryWithSpaces = "  重要なアイデア  "
        
        // When
        let validEntry = SearchHistoryEntry(query: validQuery, searchType: .fullText, filters: [], resultsCount: 3)
        let spacedEntry = SearchHistoryEntry(query: queryWithSpaces, searchType: .fullText, filters: [], resultsCount: 2)
        
        // Then
        #expect(validEntry.isValidQuery)
        #expect(spacedEntry.isValidQuery)
        #expect(validEntry.trimmedQuery == validQuery)
        #expect(spacedEntry.trimmedQuery == "重要なアイデア")
    }
    
    @Test("検索履歴エントリのお気に入りフラグ")
    func testSearchHistoryEntryFavorite() async throws {
        // Given
        var historyEntry = SearchHistoryEntry(
            query: "お気に入り検索",
            searchType: .fullText,
            filters: [],
            resultsCount: 10
        )
        
        // When
        historyEntry.markAsFavorite()
        
        // Then
        #expect(historyEntry.isFavorite)
        #expect(historyEntry.favoriteMarkedAt != nil)
        
        // When - remove from favorites
        historyEntry.removeFromFavorites()
        
        // Then
        #expect(!historyEntry.isFavorite)
        #expect(historyEntry.favoriteMarkedAt == nil)
    }
    
    @Test("検索履歴コレクションの作成")
    func testSearchHistoryCollectionCreation() async throws {
        // Given
        let entries = [
            SearchHistoryEntry(query: "アイデア1", searchType: .fullText, filters: [], resultsCount: 5),
            SearchHistoryEntry(query: "アイデア2", searchType: .exactMatch, filters: [.tag("重要")], resultsCount: 3),
            SearchHistoryEntry(query: "アイデア3", searchType: .fuzzy, filters: [], resultsCount: 8)
        ]
        
        // When
        let history = SearchHistory(entries: entries)
        
        // Then
        #expect(history.id != UUID())
        #expect(history.entries.count == 3)
        #expect(history.totalSearchCount == 3)
        #expect(history.favoriteCount == 0)
    }
    
    @Test("検索履歴の最近の検索")
    func testSearchHistoryRecentSearches() async throws {
        // Given
        let history = SearchHistory()
        let oldEntry = SearchHistoryEntry(query: "古い検索", searchType: .fullText, filters: [], resultsCount: 1)
        var modifiedOldEntry = oldEntry
        modifiedOldEntry.searchedAt = Date().addingTimeInterval(-86400) // 1日前
        
        let recentEntry = SearchHistoryEntry(query: "最近の検索", searchType: .fullText, filters: [], resultsCount: 2)
        
        var updatedHistory = history
        updatedHistory.addEntry(modifiedOldEntry)
        updatedHistory.addEntry(recentEntry)
        
        // When
        let recentSearches = updatedHistory.getRecentSearches(limit: 1)
        
        // Then
        #expect(recentSearches.count == 1)
        #expect(recentSearches.first?.query == "最近の検索")
    }
    
    @Test("検索履歴の頻度統計")
    func testSearchHistoryFrequencyStats() async throws {
        // Given
        let history = SearchHistory()
        let entries = [
            SearchHistoryEntry(query: "アイデア", searchType: .fullText, filters: [], resultsCount: 5),
            SearchHistoryEntry(query: "プロジェクト", searchType: .fullText, filters: [], resultsCount: 3),
            SearchHistoryEntry(query: "アイデア", searchType: .exactMatch, filters: [], resultsCount: 2), // 重複クエリ
        ]
        
        var updatedHistory = history
        for entry in entries {
            updatedHistory.addEntry(entry)
        }
        
        // When
        let frequentQueries = updatedHistory.getMostFrequentQueries(limit: 2)
        let queryFrequency = updatedHistory.getQueryFrequency("アイデア")
        
        // Then
        #expect(frequentQueries.count <= 2)
        #expect(queryFrequency == 2) // "アイデア"は2回検索されている
    }
    
    @Test("検索履歴のクリーンアップ")
    func testSearchHistoryCleanup() async throws {
        // Given
        var history = SearchHistory()
        let oldDate = Date().addingTimeInterval(-86400 * 8) // 8日前
        
        for i in 1...5 {
            var entry = SearchHistoryEntry(query: "クエリ\(i)", searchType: .fullText, filters: [], resultsCount: i)
            if i <= 3 {
                entry.searchedAt = oldDate
            }
            history.addEntry(entry)
        }
        
        #expect(history.entries.count == 5)
        
        // When
        let cleanedCount = history.cleanupOldEntries(olderThan: Date().addingTimeInterval(-86400 * 7)) // 7日以上古いものを削除
        
        // Then
        #expect(cleanedCount == 3) // 3つの古いエントリが削除された
        #expect(history.entries.count == 2) // 2つの新しいエントリが残っている
    }
    
    @Test("検索履歴のエントリ制限")
    func testSearchHistoryEntryLimit() async throws {
        // Given
        var history = SearchHistory()
        
        // When - 制限を超えるエントリを追加
        for i in 1...150 {
            let entry = SearchHistoryEntry(query: "クエリ\(i)", searchType: .fullText, filters: [], resultsCount: 1)
            history.addEntry(entry)
        }
        
        // Then
        #expect(history.entries.count <= SearchHistory.maxEntries)
        #expect(history.entries.count == SearchHistory.maxEntries)
        
        // 最新のエントリが保持されていることを確認
        let lastEntry = history.entries.first // entries は最新順でソートされている
        #expect(lastEntry?.query == "クエリ150")
    }
}