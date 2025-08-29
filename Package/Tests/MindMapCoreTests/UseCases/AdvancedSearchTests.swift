import Foundation
import Testing
@testable import MindMapCore

struct AdvancedSearchTests {
    
    @Test("複数条件でのフィルタリング")
    func testMultipleFilterCombination() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let tagFilter = SearchFilter.tag("重要")
        let dateFilter = SearchFilter.dateRange(
            Date().addingTimeInterval(-86400 * 7), // 1週間前
            Date()
        )
        let nodeTypeFilter = SearchFilter.nodeType(.task)
        
        let filters = [tagFilter, dateFilter, nodeTypeFilter]
        let results = createSampleResults()
        
        // When
        let filteredResults = try await searchService.applyFilters(results, filters: filters)
        
        // Then
        #expect(filteredResults.count <= results.count)
        #expect(filteredResults.allSatisfy { result in
            searchService.matchesAllFilters(result, filters: filters)
        })
    }
    
    @Test("動的ソート機能")
    func testDynamicSorting() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let results = createSampleResults()
        
        // When - 関連性スコア降順
        let sortedByRelevance = try await searchService.sortResults(
            results,
            by: .relevanceScore,
            order: .descending
        )
        
        // Then
        #expect(sortedByRelevance.count == results.count)
        for i in 0..<sortedByRelevance.count-1 {
            #expect(sortedByRelevance[i].relevanceScore >= sortedByRelevance[i+1].relevanceScore)
        }
        
        // When - 作成日時昇順
        let sortedByDate = try await searchService.sortResults(
            results,
            by: .createdDate,
            order: .ascending
        )
        
        // Then
        for i in 0..<sortedByDate.count-1 {
            #expect(sortedByDate[i].createdAt <= sortedByDate[i+1].createdAt)
        }
    }
    
    @Test("マッチタイプによるグルーピング")
    func testGroupingByMatchType() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let results = createSampleResults()
        
        // When
        let groupedResults = try await searchService.groupResults(
            results,
            by: .matchType
        )
        
        // Then
        #expect(groupedResults.groups.count > 0)
        #expect(groupedResults.groups.count <= 3) // title, content, tag
        
        let titleGroup = groupedResults.groups.first { $0.key == "title" }
        #expect(titleGroup?.results.allSatisfy { $0.matchType == .title } == true)
        
        let contentGroup = groupedResults.groups.first { $0.key == "content" }
        #expect(contentGroup?.results.allSatisfy { $0.matchType == .content } == true)
    }
    
    @Test("マインドマップ別グルーピング")
    func testGroupingByMindMap() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let results = createSampleResults()
        
        // When
        let groupedResults = try await searchService.groupResults(
            results,
            by: .mindMap
        )
        
        // Then
        #expect(groupedResults.groups.count > 0)
        
        for group in groupedResults.groups {
            let firstMindMapId = group.results.first?.mindMapId
            #expect(group.results.allSatisfy { $0.mindMapId == firstMindMapId })
        }
    }
    
    @Test("関連性スコア範囲フィルタリング")
    func testRelevanceScoreRangeFiltering() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let results = createSampleResults()
        let minScore = 0.5
        let maxScore = 0.9
        
        // When
        let filteredResults = try await searchService.filterByRelevanceScore(
            results,
            minScore: minScore,
            maxScore: maxScore
        )
        
        // Then
        #expect(filteredResults.allSatisfy { result in
            result.relevanceScore >= minScore && result.relevanceScore <= maxScore
        })
    }
    
    @Test("ファセット検索機能")
    func testFacetedSearch() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let results = createSampleResults()
        
        // When
        let facets = try await searchService.generateFacets(from: results)
        
        // Then
        #expect(facets.matchTypeFacet.count > 0)
        #expect(facets.mindMapFacet.count > 0)
        #expect(facets.relevanceRangeFacet.count > 0)
        
        // ファセット数の合計は元の結果数と一致する
        let totalMatchTypeCounts = facets.matchTypeFacet.values.reduce(0, +)
        #expect(totalMatchTypeCounts == results.count)
    }
    
    @Test("カスタムソート条件")
    func testCustomSortCriteria() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let results = createSampleResults()
        
        // When - 複合ソート: 1. マッチタイプ優先度 2. 関連性スコア
        let sortCriteria = [
            SortCriterion(field: .matchTypePriority, order: .descending),
            SortCriterion(field: .relevanceScore, order: .descending)
        ]
        
        let sortedResults = try await searchService.sortResults(
            results,
            by: sortCriteria
        )
        
        // Then
        #expect(sortedResults.count == results.count)
        
        // マッチタイプ優先度でソートされているか確認
        for i in 0..<sortedResults.count-1 {
            let current = sortedResults[i]
            let next = sortedResults[i+1]
            
            if current.matchType.priority == next.matchType.priority {
                // 同じ優先度の場合は関連性スコアで比較
                #expect(current.relevanceScore >= next.relevanceScore)
            } else {
                // 優先度が異なる場合は優先度で比較
                #expect(current.matchType.priority >= next.matchType.priority)
            }
        }
    }
    
    @Test("検索結果の統計情報生成")
    func testSearchResultStatistics() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let results = createSampleResults()
        
        // When
        let stats = try await searchService.generateStatistics(from: results)
        
        // Then
        #expect(stats.totalResults == results.count)
        #expect(stats.averageRelevanceScore > 0)
        #expect(stats.averageRelevanceScore <= 1.0)
        #expect(stats.matchTypeDistribution.count > 0)
        #expect(stats.relevanceScoreDistribution.count > 0)
        
        // 統計の整合性確認
        let distributionSum = stats.matchTypeDistribution.values.reduce(0, +)
        #expect(distributionSum == results.count)
    }
    
    @Test("パフォーマンス制約でのページネーション")
    func testPerformanceConstrainedPagination() async throws {
        // Given
        let searchService = AdvancedSearchService()
        let largeResults = createLargeResultSet(count: 1000)
        let pageSize = 20
        let pageNumber = 2
        
        // When
        let paginatedResults = try await searchService.paginateResults(
            largeResults,
            pageSize: pageSize,
            pageNumber: pageNumber
        )
        
        // Then
        #expect(paginatedResults.results.count <= pageSize)
        #expect(paginatedResults.currentPage == pageNumber)
        #expect(paginatedResults.totalPages > 0)
        #expect(paginatedResults.totalResults == largeResults.count)
        #expect(paginatedResults.hasNextPage == (pageNumber < paginatedResults.totalPages))
        #expect(paginatedResults.hasPreviousPage == (pageNumber > 1))
    }
    
    // MARK: - Helper Methods
    
    private func createSampleResults() -> [SearchResult] {
        let mindMapIds = [UUID(), UUID(), UUID()]
        
        return [
            SearchResult(
                nodeId: UUID(),
                mindMapId: mindMapIds[0],
                relevanceScore: 0.9,
                matchType: .title,
                highlightedText: "重要なプロジェクト",
                matchPosition: 0,
                createdAt: Date().addingTimeInterval(-3600) // 1時間前
            ),
            SearchResult(
                nodeId: UUID(),
                mindMapId: mindMapIds[0],
                relevanceScore: 0.7,
                matchType: .content,
                highlightedText: "プロジェクトの詳細説明",
                matchPosition: 5,
                createdAt: Date().addingTimeInterval(-7200) // 2時間前
            ),
            SearchResult(
                nodeId: UUID(),
                mindMapId: mindMapIds[1],
                relevanceScore: 0.8,
                matchType: .title,
                highlightedText: "アイデアの整理",
                matchPosition: 0,
                createdAt: Date().addingTimeInterval(-1800) // 30分前
            ),
            SearchResult(
                nodeId: UUID(),
                mindMapId: mindMapIds[1],
                relevanceScore: 0.6,
                matchType: .tag,
                highlightedText: "#重要",
                matchPosition: 0,
                createdAt: Date().addingTimeInterval(-5400) // 1.5時間前
            ),
            SearchResult(
                nodeId: UUID(),
                mindMapId: mindMapIds[2],
                relevanceScore: 0.5,
                matchType: .content,
                highlightedText: "コンテンツ内のキーワード",
                matchPosition: 10,
                createdAt: Date().addingTimeInterval(-10800) // 3時間前
            )
        ]
    }
    
    private func createLargeResultSet(count: Int) -> [SearchResult] {
        var results: [SearchResult] = []
        let mindMapIds = (0..<10).map { _ in UUID() }
        let matchTypes: [SearchMatchType] = [.title, .content, .tag]
        
        for i in 0..<count {
            results.append(SearchResult(
                nodeId: UUID(),
                mindMapId: mindMapIds[i % mindMapIds.count],
                relevanceScore: Double.random(in: 0.1...1.0),
                matchType: matchTypes[i % matchTypes.count],
                highlightedText: "Test result \(i)",
                matchPosition: Int.random(in: 0...50),
                createdAt: Date().addingTimeInterval(TimeInterval(-i * 60)) // i分前
            ))
        }
        
        return results
    }
}