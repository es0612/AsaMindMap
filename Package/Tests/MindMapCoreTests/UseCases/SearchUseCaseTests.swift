import Foundation
import Testing
@testable import MindMapCore

struct SearchUseCaseTests {
    
    @Test("全文検索ユースケースの実行")
    func testFullTextSearchExecution() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        
        let request = SearchRequest(
            query: "重要なアイデア",
            type: .fullText,
            filters: [.tag("プロジェクト")],
            mindMapId: nil
        )
        
        // When
        let response = try await searchUseCase.execute(request)
        
        // Then
        #expect(response.results.count > 0)
        #expect(response.query == request.query)
        #expect(response.totalResults >= response.results.count)
        #expect(response.results.allSatisfy { $0.isRelevant })
    }
    
    @Test("空の検索クエリでのバリデーションエラー")
    func testEmptyQueryValidation() async {
        // Given
        let mockRepository = MockMindMapRepository()
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        
        let request = SearchRequest(
            query: "",
            type: .fullText,
            filters: [],
            mindMapId: nil
        )
        
        // When & Then
        await #expect(throws: SearchError.emptyQuery) {
            try await searchUseCase.execute(request)
        }
    }
    
    @Test("マインドマップ固有の検索")
    func testMindMapSpecificSearch() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        let mindMapId = UUID()
        
        let request = SearchRequest(
            query: "テスト",
            type: .fullText,
            filters: [],
            mindMapId: mindMapId
        )
        
        // When
        let response = try await searchUseCase.execute(request)
        
        // Then
        #expect(response.results.allSatisfy { $0.mindMapId == mindMapId })
        #expect(mockRepository.searchCallHistory.contains { $0.mindMapId == mindMapId })
    }
    
    @Test("フィルター付き検索の実行")
    func testFilteredSearch() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        
        let tagFilter = SearchFilter.tag("重要")
        let dateFilter = SearchFilter.dateRange(
            Date().addingTimeInterval(-86400),
            Date()
        )
        
        let request = SearchRequest(
            query: "プロジェクト",
            type: .fullText,
            filters: [tagFilter, dateFilter],
            mindMapId: nil
        )
        
        // When
        let response = try await searchUseCase.execute(request)
        
        // Then
        #expect(response.appliedFilters.count == 2)
        #expect(response.appliedFilters.contains(tagFilter))
        #expect(response.appliedFilters.contains(dateFilter))
        #expect(response.results.allSatisfy { $0.isRelevant })
    }
    
    @Test("曖昧検索の実行")
    func testFuzzySearch() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        
        let request = SearchRequest(
            query: "プロジェクト", // Potential typos should be handled
            type: .fuzzy,
            filters: [],
            mindMapId: nil
        )
        
        // When
        let response = try await searchUseCase.execute(request)
        
        // Then
        #expect(response.searchType == .fuzzy)
        #expect(response.results.count >= 0)
        // Fuzzy search should have some tolerance for typos
        #expect(mockRepository.searchCallHistory.last?.type == .fuzzy)
    }
    
    @Test("完全一致検索の実行")
    func testExactMatchSearch() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        
        let exactQuery = "重要なプロジェクト"
        let request = SearchRequest(
            query: exactQuery,
            type: .exactMatch,
            filters: [],
            mindMapId: nil
        )
        
        // When
        let response = try await searchUseCase.execute(request)
        
        // Then
        #expect(response.searchType == .exactMatch)
        #expect(response.results.allSatisfy { result in
            result.highlightedText.contains(exactQuery)
        })
    }
    
    @Test("検索結果のランキング")
    func testSearchResultRanking() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        
        let request = SearchRequest(
            query: "重要",
            type: .fullText,
            filters: [],
            mindMapId: nil
        )
        
        // When
        let response = try await searchUseCase.execute(request)
        
        // Then
        // Results should be sorted by relevance score (descending)
        for i in 0..<response.results.count-1 {
            let current = response.results[i]
            let next = response.results[i+1]
            #expect(current.relevanceScore >= next.relevanceScore)
        }
    }
    
    @Test("大量データでの検索パフォーマンス")
    func testSearchPerformanceWithLargeDataset() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        mockRepository.setupLargeDataset() // This should be implemented in the mock
        let searchUseCase = FullTextSearchUseCase(repository: mockRepository)
        
        let request = SearchRequest(
            query: "テスト",
            type: .fullText,
            filters: [],
            mindMapId: nil
        )
        
        // When
        let startTime = CFAbsoluteTimeGetCurrent()
        let response = try await searchUseCase.execute(request)
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Then
        #expect(timeElapsed < 1.0) // Should complete within 1 second
        #expect(response.results.count <= 100) // Should limit results for performance
        #expect(response.executionTimeMs > 0)
    }
}

// MARK: - Search Index Use Case Tests

struct SearchIndexUseCaseTests {
    
    @Test("インデックス作成ユースケースの実行")
    func testCreateSearchIndex() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let indexUseCase = CreateSearchIndexUseCase(repository: mockRepository)
        
        let mindMapId = UUID()
        let request = IndexRequest(mindMapId: mindMapId, forceRebuild: false)
        
        // When
        let response = try await indexUseCase.execute(request)
        
        // Then
        #expect(response.mindMapId == mindMapId)
        #expect(response.indexedNodesCount > 0)
        #expect(response.success)
        #expect(mockRepository.indexCreationCalled)
    }
    
    @Test("インデックス更新ユースケースの実行")
    func testUpdateSearchIndex() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let indexUseCase = UpdateSearchIndexUseCase(repository: mockRepository)
        
        let nodeId = UUID()
        let request = UpdateIndexRequest(
            nodeId: nodeId,
            action: .update,
            content: "更新されたノード内容"
        )
        
        // When
        let response = try await indexUseCase.execute(request)
        
        // Then
        #expect(response.nodeId == nodeId)
        #expect(response.action == .update)
        #expect(response.success)
        #expect(mockRepository.indexUpdateCalled)
    }
    
    @Test("インデックス削除ユースケースの実行")
    func testDeleteFromSearchIndex() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let indexUseCase = UpdateSearchIndexUseCase(repository: mockRepository)
        
        let nodeId = UUID()
        let request = UpdateIndexRequest(
            nodeId: nodeId,
            action: .delete,
            content: nil
        )
        
        // When
        let response = try await indexUseCase.execute(request)
        
        // Then
        #expect(response.nodeId == nodeId)
        #expect(response.action == .delete)
        #expect(response.success)
        #expect(mockRepository.indexUpdateCalled)
    }
    
    @Test("全インデックス再構築")
    func testRebuildAllSearchIndexes() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let indexUseCase = RebuildSearchIndexesUseCase(repository: mockRepository)
        
        // When
        let response = try await indexUseCase.execute()
        
        // Then
        #expect(response.totalMindMaps > 0)
        #expect(response.totalIndexedNodes > 0)
        #expect(response.success)
        #expect(mockRepository.fullRebuildCalled)
    }
}