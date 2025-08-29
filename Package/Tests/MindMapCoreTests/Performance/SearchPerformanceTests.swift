import Foundation
import Testing
@testable import MindMapCore

struct SearchPerformanceTests {
    
    // MARK: - Performance Benchmarks
    
    /// パフォーマンステストの基準値
    static let maxSearchTime: TimeInterval = 0.1 // 100ms
    static let maxIndexCreationTime: TimeInterval = 1.0 // 1秒
    static let maxAdvancedSearchTime: TimeInterval = 0.2 // 200ms
    static let maxMemoryGrowth: Double = 50.0 // 50MB
    
    @Test("基本検索のパフォーマンステスト")
    func testBasicSearchPerformance() async throws {
        // Given
        let repository = MockMindMapRepository()
        repository.setupLargeDataset()
        let useCase = FullTextSearchUseCase(repository: repository)
        
        let searchRequest = SearchRequest(
            query: "test",
            type: .fullText,
            filters: [],
            mindMapId: nil,
            limit: 50
        )
        
        // 10回の測定の平均を取る
        var executionTimes: [TimeInterval] = []
        
        for _ in 1...10 {
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = try await useCase.execute(searchRequest)
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            executionTimes.append(executionTime)
        }
        
        let averageTime = executionTimes.reduce(0, +) / Double(executionTimes.count)
        let maxTime = executionTimes.max() ?? 0
        let minTime = executionTimes.min() ?? 0
        
        // Then
        #expect(averageTime < Self.maxSearchTime, "平均検索時間が基準値を超えています: \(averageTime)s > \(Self.maxSearchTime)s")
        
        print("   Average search time: \(String(format: "%.3f", averageTime))s")
        print("   Min search time: \(String(format: "%.3f", minTime))s")
        print("   Max search time: \(String(format: "%.3f", maxTime))s")
    }
    
    @Test("大規模データセットでの検索パフォーマンステスト")
    func testLargeDatasetSearchPerformance() async throws {
        // Given
        let repository = MockMindMapRepository()
        let useCase = FullTextSearchUseCase(repository: repository)
        
        // 段階的にデータサイズを増加させてテスト
        let dataSizes = [100, 500, 1000, 5000, 10000]
        var performanceResults: [(size: Int, time: TimeInterval)] = []
        
        for dataSize in dataSizes {
            repository.setupLargeDataset(size: dataSize)
            
            let searchRequest = SearchRequest(
                query: "test",
                type: .fullText,
                filters: [],
                mindMapId: nil,
                limit: 50
            )
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = try await useCase.execute(searchRequest)
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            
            performanceResults.append((size: dataSize, time: executionTime))
            
            // スケーラビリティチェック（データサイズに対して線形に近い増加）
            #expect(executionTime < Self.maxSearchTime * Double(dataSize) / 1000.0, 
                   "データサイズ \(dataSize) での検索時間が許容範囲を超えています: \(executionTime)s")
        }
        
        print("   Performance scaling results:")
        for result in performanceResults {
            print("     \(result.size) records: \(String(format: "%.3f", result.time))s")
        }
    }
    
    @Test("インデックス作成パフォーマンステスト")
    func testIndexCreationPerformance() async throws {
        // Given
        let repository = MockMindMapRepository()
        let useCase = CreateSearchIndexUseCase(repository: repository)
        
        let mindMapIds = (1...10).map { _ in UUID() }
        var creationTimes: [TimeInterval] = []
        
        for mindMapId in mindMapIds {
            let indexRequest = IndexRequest(mindMapId: mindMapId)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = try await useCase.execute(indexRequest)
            let executionTime = CFAbsoluteTimeGetCurrent() - startTime
            
            creationTimes.append(executionTime)
        }
        
        let averageCreationTime = creationTimes.reduce(0, +) / Double(creationTimes.count)
        
        // Then
        #expect(averageCreationTime < Self.maxIndexCreationTime,
               "平均インデックス作成時間が基準値を超えています: \(averageCreationTime)s > \(Self.maxIndexCreationTime)s")
        
        print("   Average index creation time: \(String(format: "%.3f", averageCreationTime))s")
        print("   Total creation times: \(creationTimes.map { String(format: "%.3f", $0) }.joined(separator: "s, "))s")
    }
    
    @Test("高度な検索機能のパフォーマンステスト")
    func testAdvancedSearchPerformance() async throws {
        // Given
        let advancedSearchService = AdvancedSearchService()
        let results = createLargeSearchResultSet(count: 5000)
        
        // ソートのパフォーマンステスト
        let startSortTime = CFAbsoluteTimeGetCurrent()
        let sortedResults = try await advancedSearchService.sortResults(
            results,
            by: [
                SortCriterion(field: .relevanceScore, order: .descending),
                SortCriterion(field: .matchTypePriority, order: .descending)
            ]
        )
        let sortTime = CFAbsoluteTimeGetCurrent() - startSortTime
        
        #expect(sortTime < Self.maxAdvancedSearchTime,
               "ソート処理時間が基準値を超えています: \(sortTime)s > \(Self.maxAdvancedSearchTime)s")
        
        // グルーピングのパフォーマンステスト
        let startGroupTime = CFAbsoluteTimeGetCurrent()
        let groupedResults = try await advancedSearchService.groupResults(sortedResults, by: .matchType)
        let groupTime = CFAbsoluteTimeGetCurrent() - startGroupTime
        
        #expect(groupTime < Self.maxAdvancedSearchTime,
               "グルーピング処理時間が基準値を超えています: \(groupTime)s > \(Self.maxAdvancedSearchTime)s")
        
        // ファセット生成のパフォーマンステスト
        let startFacetTime = CFAbsoluteTimeGetCurrent()
        let facets = try await advancedSearchService.generateFacets(from: results)
        let facetTime = CFAbsoluteTimeGetCurrent() - startFacetTime
        
        #expect(facetTime < Self.maxAdvancedSearchTime / 2,
               "ファセット生成時間が基準値を超えています: \(facetTime)s > \(Self.maxAdvancedSearchTime / 2)s")
        
        print("   Advanced search performance:")
        print("     Sorting \(results.count) results: \(String(format: "%.3f", sortTime))s")
        print("     Grouping results: \(String(format: "%.3f", groupTime))s")
        print("     Facet generation: \(String(format: "%.3f", facetTime))s")
        print("     Groups created: \(groupedResults.groups.count)")
        print("     Facet categories: \(facets.matchTypeFacet.count)")
    }
    
    @Test("同時検索リクエストのパフォーマンステスト")
    func testConcurrentSearchPerformance() async throws {
        // Given
        let repository = MockMindMapRepository()
        repository.setupLargeDataset()
        let useCase = FullTextSearchUseCase(repository: repository)
        
        let searchRequests = (1...20).map { i in
            SearchRequest(
                query: "concurrent test \(i)",
                type: .fullText,
                filters: [],
                mindMapId: nil,
                limit: 50
            )
        }
        
        // When - 同時実行
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let results = try await withThrowingTaskGroup(of: SearchResponse.self) { group in
            for request in searchRequests {
                group.addTask {
                    return try await useCase.execute(request)
                }
            }
            
            var responses: [SearchResponse] = []
            for try await result in group {
                responses.append(result)
            }
            return responses
        }
        
        let totalTime = CFAbsoluteTimeGetCurrent() - startTime
        let averageTimePerRequest = totalTime / Double(searchRequests.count)
        
        // Then
        #expect(results.count == searchRequests.count, "すべてのリクエストが完了していません")
        #expect(averageTimePerRequest < Self.maxSearchTime * 2, 
               "同時実行時の平均応答時間が基準値を超えています: \(averageTimePerRequest)s")
        
        print("   Concurrent search performance:")
        print("     Total requests: \(searchRequests.count)")
        print("     Total time: \(String(format: "%.3f", totalTime))s")
        print("     Average time per request: \(String(format: "%.3f", averageTimePerRequest))s")
        print("     Throughput: \(String(format: "%.1f", Double(searchRequests.count) / totalTime)) requests/second")
    }
    
    @Test("メモリ使用量パフォーマンステスト")
    func testMemoryUsagePerformance() async throws {
        // Given
        let repository = MockMindMapRepository()
        let useCase = FullTextSearchUseCase(repository: repository)
        
        // 初期メモリ使用量を測定
        let initialMemory = getCurrentMemoryUsage()
        
        // 大量のデータで複数回検索を実行
        for iteration in 1...100 {
            repository.setupLargeDataset(size: 1000)
            
            let searchRequest = SearchRequest(
                query: "memory test \(iteration)",
                type: .fullText,
                filters: [.tag("performance")],
                mindMapId: nil,
                limit: 100
            )
            
            let _ = try await useCase.execute(searchRequest)
            
            // 10回ごとにメモリ使用量をチェック
            if iteration % 10 == 0 {
                let currentMemory = getCurrentMemoryUsage()
                let memoryGrowth = currentMemory - initialMemory
                
                #expect(memoryGrowth < Self.maxMemoryGrowth,
                       "メモリ使用量の増加が基準値を超えています: \(memoryGrowth)MB > \(Self.maxMemoryGrowth)MB (iteration: \(iteration))")
            }
        }
        
        let finalMemory = getCurrentMemoryUsage()
        let totalMemoryGrowth = finalMemory - initialMemory
        
        print("   Memory usage performance:")
        print("     Initial memory: \(String(format: "%.1f", initialMemory))MB")
        print("     Final memory: \(String(format: "%.1f", finalMemory))MB")
        print("     Memory growth: \(String(format: "%.1f", totalMemoryGrowth))MB")
    }
    
    @Test("検索履歴パフォーマンステスト")
    func testSearchHistoryPerformance() async throws {
        // Given
        let mockRepository = MockSearchHistoryRepository()
        let recordUseCase = RecordSearchHistoryUseCase(repository: mockRepository)
        let getRecentUseCase = GetRecentSearchesUseCase(repository: mockRepository)
        let getFrequentUseCase = GetFrequentQueriesUseCase(repository: mockRepository)
        
        // 大量の検索履歴を作成
        let historyEntries = (1...10000).map { i in
            SearchRequest(
                query: "history test \(i % 100)", // 100種類のクエリを繰り返し
                type: SearchType.allCases[i % SearchType.allCases.count],
                filters: [],
                mindMapId: nil
            )
        }
        
        // 履歴記録のパフォーマンステスト
        let recordStartTime = CFAbsoluteTimeGetCurrent()
        for entry in historyEntries {
            try await recordUseCase.execute(searchRequest: entry, resultsCount: Int.random(in: 1...100))
        }
        let recordTime = CFAbsoluteTimeGetCurrent() - recordStartTime
        
        // 最近の検索取得のパフォーマンステスト
        let recentStartTime = CFAbsoluteTimeGetCurrent()
        let recentSearches = try await getRecentUseCase.execute(limit: 50)
        let recentTime = CFAbsoluteTimeGetCurrent() - recentStartTime
        
        // 頻繁なクエリ取得のパフォーマンステスト
        let frequentStartTime = CFAbsoluteTimeGetCurrent()
        let frequentQueries = try await getFrequentUseCase.execute(limit: 20)
        let frequentTime = CFAbsoluteTimeGetCurrent() - frequentStartTime
        
        // Then
        #expect(recordTime / Double(historyEntries.count) < 0.001, // 1msec per entry
               "履歴記録の平均時間が基準値を超えています")
        #expect(recentTime < 0.05, // 50msec
               "最近の検索取得時間が基準値を超えています: \(recentTime)s")
        #expect(frequentTime < 0.1, // 100msec
               "頻繁なクエリ取得時間が基準値を超えています: \(frequentTime)s")
        
        print("   Search history performance:")
        print("     Record \(historyEntries.count) entries: \(String(format: "%.3f", recordTime))s")
        print("     Get recent searches: \(String(format: "%.3f", recentTime))s")
        print("     Get frequent queries: \(String(format: "%.3f", frequentTime))s")
        print("     Recent searches count: \(recentSearches.count)")
        print("     Frequent queries count: \(frequentQueries.count)")
    }
    
    // MARK: - Helper Methods
    
    private func createLargeSearchResultSet(count: Int) -> [SearchResult] {
        let mindMapIds = (0..<10).map { _ in UUID() }
        let matchTypes: [SearchMatchType] = [.title, .content, .tag]
        
        return (0..<count).map { i in
            SearchResult(
                nodeId: UUID(),
                mindMapId: mindMapIds[i % mindMapIds.count],
                relevanceScore: Double.random(in: 0.1...1.0),
                matchType: matchTypes[i % matchTypes.count],
                highlightedText: "Performance test result \(i)",
                matchPosition: Int.random(in: 0...50)
            )
        }
    }
    
    private func getCurrentMemoryUsage() -> Double {
        let taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(taskInfo.resident_size) / (1024 * 1024) // MB
        }
        return 0.0
    }
}

// MARK: - Extended Mock Repository for Performance Testing

extension MockMindMapRepository {
    func setupLargeDataset(size: Int = 10000) {
        mindMaps.removeAll()
        
        for i in 0..<size {
            let mindMap = MindMap(
                title: "Performance Test MindMap \(i)",
                rootNodeID: UUID()
            )
            mindMaps[mindMap.id] = mindMap
        }
    }
}

// MARK: - Performance Optimization Recommendations

/*
 パフォーマンス最適化の推奨事項:

 1. 検索インデックスの最適化
    - インメモリキャッシュの実装
    - インデックスの事前読み込み
    - 部分マッチの最適化

 2. データ構造の最適化
    - 検索結果のページング
    - 遅延読み込み（Lazy Loading）
    - メモリプールの使用

 3. 並行処理の最適化
    - 検索処理の並列化
    - バックグラウンドインデックス更新
    - キューベースの処理

 4. キャッシング戦略
    - 検索結果のキャッシュ
    - 頻繁なクエリのプリキャッシュ
    - LRUキャッシュの実装

 5. データベース最適化（実装時）
    - インデックスの適切な設計
    - クエリの最適化
    - 接続プールの使用

 6. UI/UXの最適化
    - インクリメンタル検索
    - 検索候補の表示
    - 結果の段階的読み込み
*/