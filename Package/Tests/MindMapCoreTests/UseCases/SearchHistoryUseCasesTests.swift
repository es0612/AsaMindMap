import Foundation
import Testing
@testable import MindMapCore

struct SearchHistoryUseCasesTests {
    
    @Test("検索履歴記録のユースケース")
    func testRecordSearchHistoryUseCase() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let useCase = RecordSearchHistoryUseCase(repository: mockRepository)
        
        let searchRequest = SearchRequest(
            query: "重要なアイデア",
            type: .fullText,
            filters: [.tag("プロジェクト")],
            mindMapId: nil
        )
        let resultsCount = 5
        
        // When
        try await useCase.execute(searchRequest: searchRequest, resultsCount: resultsCount)
        
        // Then
        #expect(mockRepository.recordCallCount == 1)
        #expect(mockRepository.lastRecordedEntry?.query == "重要なアイデア")
        #expect(mockRepository.lastRecordedEntry?.searchType == .fullText)
        #expect(mockRepository.lastRecordedEntry?.resultsCount == 5)
    }
    
    @Test("検索履歴取得のユースケース")
    func testGetSearchHistoryUseCase() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let useCase = GetSearchHistoryUseCase(repository: mockRepository)
        
        // モック履歴データを設定
        mockRepository.setupMockHistory()
        
        // When
        let history = try await useCase.execute()
        
        // Then
        #expect(history.entries.count > 0)
        #expect(mockRepository.getHistoryCallCount == 1)
    }
    
    @Test("最近の検索取得のユースケース")
    func testGetRecentSearchesUseCase() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let useCase = GetRecentSearchesUseCase(repository: mockRepository)
        mockRepository.setupMockHistory()
        
        let limit = 5
        
        // When
        let recentSearches = try await useCase.execute(limit: limit)
        
        // Then
        #expect(recentSearches.count <= limit)
        #expect(mockRepository.getRecentCallCount == 1)
    }
    
    @Test("頻繁な検索クエリ取得のユースケース")
    func testGetFrequentQueriesUseCase() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let useCase = GetFrequentQueriesUseCase(repository: mockRepository)
        mockRepository.setupMockHistory()
        
        let limit = 3
        
        // When
        let frequentQueries = try await useCase.execute(limit: limit)
        
        // Then
        #expect(frequentQueries.count <= limit)
        #expect(mockRepository.getFrequentQueriesCallCount == 1)
    }
    
    @Test("検索履歴お気に入り管理のユースケース")
    func testManageSearchHistoryFavoritesUseCase() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let useCase = ManageSearchHistoryFavoritesUseCase(repository: mockRepository)
        mockRepository.setupMockHistory()
        
        let entryId = UUID()
        
        // When - お気に入りに追加
        try await useCase.addToFavorites(entryId: entryId)
        
        // Then
        #expect(mockRepository.addToFavoritesCallCount == 1)
        
        // When - お気に入りから削除
        try await useCase.removeFromFavorites(entryId: entryId)
        
        // Then
        #expect(mockRepository.removeFromFavoritesCallCount == 1)
        
        // When - お気に入り一覧取得
        let favorites = try await useCase.getFavorites()
        
        // Then
        #expect(mockRepository.getFavoritesCallCount == 1)
    }
    
    @Test("検索履歴クリーンアップのユースケース")
    func testCleanupSearchHistoryUseCase() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let useCase = CleanupSearchHistoryUseCase(repository: mockRepository)
        
        let olderThan = Date().addingTimeInterval(-86400 * 7) // 7日前
        
        // When
        let cleanedCount = try await useCase.execute(olderThan: olderThan)
        
        // Then
        #expect(cleanedCount >= 0)
        #expect(mockRepository.cleanupCallCount == 1)
    }
    
    @Test("検索履歴統計取得のユースケース")
    func testGetSearchHistoryStatisticsUseCase() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let useCase = GetSearchHistoryStatisticsUseCase(repository: mockRepository)
        mockRepository.setupMockHistory()
        
        // When
        let statistics = try await useCase.execute()
        
        // Then
        #expect(statistics.totalSearchCount >= 0)
        #expect(statistics.favoriteCount >= 0)
        #expect(!statistics.searchTypeDistribution.isEmpty)
        #expect(mockRepository.getStatisticsCallCount == 1)
    }
}

// MARK: - Mock Repository for Search History

class MockSearchHistoryRepository: SearchHistoryRepositoryProtocol {
    var searchHistory = SearchHistory()
    var recordCallCount = 0
    var getHistoryCallCount = 0
    var getRecentCallCount = 0
    var getFrequentQueriesCallCount = 0
    var addToFavoritesCallCount = 0
    var removeFromFavoritesCallCount = 0
    var getFavoritesCallCount = 0
    var cleanupCallCount = 0
    var getStatisticsCallCount = 0
    
    var lastRecordedEntry: SearchHistoryEntry?
    
    func recordSearch(entry: SearchHistoryEntry) async throws {
        recordCallCount += 1
        lastRecordedEntry = entry
        searchHistory.addEntry(entry)
    }
    
    func getSearchHistory() async throws -> SearchHistory {
        getHistoryCallCount += 1
        return searchHistory
    }
    
    func getRecentSearches(limit: Int) async throws -> [SearchHistoryEntry] {
        getRecentCallCount += 1
        return searchHistory.getRecentSearches(limit: limit)
    }
    
    func getFrequentQueries(limit: Int) async throws -> [String] {
        getFrequentQueriesCallCount += 1
        return searchHistory.getMostFrequentQueries(limit: limit)
    }
    
    func addToFavorites(entryId: UUID) async throws {
        addToFavoritesCallCount += 1
        // Mock implementation
    }
    
    func removeFromFavorites(entryId: UUID) async throws {
        removeFromFavoritesCallCount += 1
        // Mock implementation
    }
    
    func getFavoriteSearches() async throws -> [SearchHistoryEntry] {
        getFavoritesCallCount += 1
        return searchHistory.getFavoriteSearches()
    }
    
    func cleanupOldEntries(olderThan date: Date) async throws -> Int {
        cleanupCallCount += 1
        return searchHistory.cleanupOldEntries(olderThan: date)
    }
    
    func getSearchStatistics() async throws -> SearchHistoryStatistics {
        getStatisticsCallCount += 1
        return SearchHistoryStatistics(
            totalSearchCount: searchHistory.totalSearchCount,
            favoriteCount: searchHistory.favoriteCount,
            searchTypeDistribution: searchHistory.getSearchTypeStatistics(),
            filterUsageDistribution: searchHistory.getFilterUsageStatistics(),
            averageResultsPerSearch: 5.0
        )
    }
    
    func setupMockHistory() {
        let entries = [
            SearchHistoryEntry(query: "アイデア", searchType: .fullText, filters: [], resultsCount: 5),
            SearchHistoryEntry(query: "プロジェクト", searchType: .exactMatch, filters: [.tag("重要")], resultsCount: 3),
            SearchHistoryEntry(query: "タスク", searchType: .fuzzy, filters: [.nodeType(.task)], resultsCount: 8)
        ]
        
        for entry in entries {
            searchHistory.addEntry(entry)
        }
    }
}