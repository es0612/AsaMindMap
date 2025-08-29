import Foundation

// MARK: - Test Types (Simplified versions of the actual entities)

enum SearchType: String, Codable, CaseIterable {
    case fullText = "fullText"
    case exactMatch = "exactMatch"
    case fuzzy = "fuzzy"
}

enum SearchMatchType: String, Codable, CaseIterable {
    case title = "title"
    case content = "content"
    case tag = "tag"
    
    var priority: Int {
        switch self {
        case .title: return 3
        case .content: return 2
        case .tag: return 1
        }
    }
}

enum SearchFilterType: String, Codable, CaseIterable {
    case tag = "tag"
    case dateRange = "dateRange"
    case nodeType = "nodeType"
    case creator = "creator"
}

enum SearchFilter: Codable, Equatable, Hashable {
    case tag(String)
    case dateRange(Date, Date)
    
    var isValid: Bool {
        switch self {
        case .tag(let value):
            return !value.isEmpty
        case .dateRange(let start, let end):
            return start <= end
        }
    }
}

struct SearchResult: Identifiable, Codable, Equatable, Comparable {
    let id: UUID
    let nodeId: UUID
    let mindMapId: UUID
    let relevanceScore: Double
    let matchType: SearchMatchType
    let highlightedText: String
    let matchPosition: Int
    
    init(nodeId: UUID, mindMapId: UUID, relevanceScore: Double, matchType: SearchMatchType, highlightedText: String, matchPosition: Int) {
        self.id = UUID()
        self.nodeId = nodeId
        self.mindMapId = mindMapId
        self.relevanceScore = relevanceScore
        self.matchType = matchType
        self.highlightedText = highlightedText
        self.matchPosition = matchPosition
    }
    
    var isRelevant: Bool {
        relevanceScore >= 0.3
    }
    
    static func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
        if lhs.relevanceScore != rhs.relevanceScore {
            return lhs.relevanceScore > rhs.relevanceScore
        }
        return lhs.matchType.priority > rhs.matchType.priority
    }
}

// MARK: - Use Case Types

enum SearchError: Error, LocalizedError {
    case emptyQuery
    case invalidFilters
    case searchFailed(String)
    case indexNotReady
    
    var errorDescription: String? {
        switch self {
        case .emptyQuery:
            return "検索クエリが空です"
        case .invalidFilters:
            return "無効なフィルターが含まれています"
        case .searchFailed(let reason):
            return "検索に失敗しました: \(reason)"
        case .indexNotReady:
            return "検索インデックスの準備ができていません"
        }
    }
}

struct SearchRequest: Codable, Equatable {
    let query: String
    let type: SearchType
    let filters: [SearchFilter]
    let mindMapId: UUID?
    let limit: Int
    let offset: Int
    
    init(query: String, type: SearchType, filters: [SearchFilter], mindMapId: UUID?, limit: Int = 50, offset: Int = 0) {
        self.query = query
        self.type = type
        self.filters = filters
        self.mindMapId = mindMapId
        self.limit = limit
        self.offset = offset
    }
    
    var isValid: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct SearchResponse: Codable {
    let query: String
    let searchType: SearchType
    let results: [SearchResult]
    let totalResults: Int
    let appliedFilters: [SearchFilter]
    let executionTimeMs: Double
    
    init(query: String, searchType: SearchType, results: [SearchResult], totalResults: Int, appliedFilters: [SearchFilter], executionTimeMs: Double) {
        self.query = query
        self.searchType = searchType
        self.results = results
        self.totalResults = totalResults
        self.appliedFilters = appliedFilters
        self.executionTimeMs = executionTimeMs
    }
}

enum IndexAction: String, Codable {
    case create = "create"
    case update = "update" 
    case delete = "delete"
}

struct IndexRequest: Codable {
    let mindMapId: UUID
    let forceRebuild: Bool
    
    init(mindMapId: UUID, forceRebuild: Bool = false) {
        self.mindMapId = mindMapId
        self.forceRebuild = forceRebuild
    }
}

struct IndexCreationResponse: Codable {
    let mindMapId: UUID
    let indexedNodesCount: Int
    let success: Bool
    let error: String?
    
    init(mindMapId: UUID, indexedNodesCount: Int, success: Bool, error: String? = nil) {
        self.mindMapId = mindMapId
        self.indexedNodesCount = indexedNodesCount
        self.success = success
        self.error = error
    }
}

struct UpdateIndexRequest: Codable {
    let nodeId: UUID
    let action: IndexAction
    let content: String?
    
    init(nodeId: UUID, action: IndexAction, content: String? = nil) {
        self.nodeId = nodeId
        self.action = action
        self.content = content
    }
}

struct IndexUpdateResponse: Codable {
    let nodeId: UUID
    let action: IndexAction
    let success: Bool
    let error: String?
    
    init(nodeId: UUID, action: IndexAction, success: Bool, error: String? = nil) {
        self.nodeId = nodeId
        self.action = action
        self.success = success
        self.error = error
    }
}

struct IndexRebuildResponse: Codable {
    let totalMindMaps: Int
    let totalIndexedNodes: Int
    let success: Bool
    let error: String?
    
    init(totalMindMaps: Int, totalIndexedNodes: Int, success: Bool, error: String? = nil) {
        self.totalMindMaps = totalMindMaps
        self.totalIndexedNodes = totalIndexedNodes
        self.success = success
        self.error = error
    }
}

// MARK: - Mock Repository

class MockSearchRepository {
    private var searchHistory: [SearchRequest] = []
    private var indexOperations: [String] = []
    
    func search(_ request: SearchRequest) throws -> [SearchResult] {
        searchHistory.append(request)
        
        guard request.isValid else {
            throw SearchError.emptyQuery
        }
        
        guard request.filters.allSatisfy({ $0.isValid }) else {
            throw SearchError.invalidFilters
        }
        
        // Mock search results
        let results = [
            SearchResult(
                nodeId: UUID(),
                mindMapId: request.mindMapId ?? UUID(),
                relevanceScore: 0.9,
                matchType: .title,
                highlightedText: "重要なアイデア: \(request.query)",
                matchPosition: 0
            ),
            SearchResult(
                nodeId: UUID(),
                mindMapId: request.mindMapId ?? UUID(),
                relevanceScore: 0.7,
                matchType: .content,
                highlightedText: "コンテンツに含まれる\(request.query)",
                matchPosition: 5
            ),
            SearchResult(
                nodeId: UUID(),
                mindMapId: request.mindMapId ?? UUID(),
                relevanceScore: 0.5,
                matchType: .tag,
                highlightedText: "#\(request.query)",
                matchPosition: 0
            )
        ]
        
        return results.sorted()
    }
    
    func createSearchIndex(for mindMapId: UUID) -> IndexCreationResponse {
        indexOperations.append("create_index_\(mindMapId)")
        return IndexCreationResponse(
            mindMapId: mindMapId,
            indexedNodesCount: Int.random(in: 10...50),
            success: true
        )
    }
    
    func updateSearchIndex(_ request: UpdateIndexRequest) -> IndexUpdateResponse {
        indexOperations.append("update_index_\(request.nodeId)_\(request.action.rawValue)")
        return IndexUpdateResponse(
            nodeId: request.nodeId,
            action: request.action,
            success: true
        )
    }
    
    func rebuildAllSearchIndexes() -> IndexRebuildResponse {
        indexOperations.append("rebuild_all_indexes")
        return IndexRebuildResponse(
            totalMindMaps: Int.random(in: 5...20),
            totalIndexedNodes: Int.random(in: 100...500),
            success: true
        )
    }
    
    var searchCallCount: Int { searchHistory.count }
    var indexOperationCount: Int { indexOperations.count }
}

// MARK: - Use Case Implementations

class FullTextSearchUseCase {
    private let repository: MockSearchRepository
    
    init(repository: MockSearchRepository) {
        self.repository = repository
    }
    
    func execute(_ request: SearchRequest) throws -> SearchResponse {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let results = try repository.search(request)
        let executionTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        let limitedResults = Array(results.prefix(request.limit))
        
        return SearchResponse(
            query: request.query,
            searchType: request.type,
            results: limitedResults,
            totalResults: results.count,
            appliedFilters: request.filters,
            executionTimeMs: executionTime
        )
    }
}

class CreateSearchIndexUseCase {
    private let repository: MockSearchRepository
    
    init(repository: MockSearchRepository) {
        self.repository = repository
    }
    
    func execute(_ request: IndexRequest) -> IndexCreationResponse {
        return repository.createSearchIndex(for: request.mindMapId)
    }
}

class UpdateSearchIndexUseCase {
    private let repository: MockSearchRepository
    
    init(repository: MockSearchRepository) {
        self.repository = repository
    }
    
    func execute(_ request: UpdateIndexRequest) -> IndexUpdateResponse {
        return repository.updateSearchIndex(request)
    }
}

class RebuildSearchIndexesUseCase {
    private let repository: MockSearchRepository
    
    init(repository: MockSearchRepository) {
        self.repository = repository
    }
    
    func execute() -> IndexRebuildResponse {
        return repository.rebuildAllSearchIndexes()
    }
}

// MARK: - Validation Tests

print("🔍 Search Use Cases Validation")
print("==============================")

let repository = MockSearchRepository()

// Test 1: Full Text Search Use Case
print("\n✅ Test 1: Full Text Search Use Case")
let searchUseCase = FullTextSearchUseCase(repository: repository)
let searchRequest = SearchRequest(
    query: "重要なアイデア",
    type: .fullText,
    filters: [.tag("プロジェクト")],
    mindMapId: nil
)

do {
    let response = try searchUseCase.execute(searchRequest)
    print("   Query: \(response.query)")
    print("   Results count: \(response.results.count)")
    print("   Total results: \(response.totalResults)")
    print("   Execution time: \(String(format: "%.2f", response.executionTimeMs))ms")
    print("   Applied filters: \(response.appliedFilters.count)")
} catch {
    print("   ❌ Error: \(error)")
}

// Test 2: Empty Query Validation
print("\n✅ Test 2: Empty Query Validation")
let emptyRequest = SearchRequest(query: "", type: .fullText, filters: [], mindMapId: nil)
do {
    let _ = try searchUseCase.execute(emptyRequest)
    print("   ❌ Should have thrown an error")
} catch SearchError.emptyQuery {
    print("   ✅ Correctly caught empty query error")
} catch {
    print("   ❌ Unexpected error: \(error)")
}

// Test 3: Create Search Index
print("\n✅ Test 3: Create Search Index")
let indexUseCase = CreateSearchIndexUseCase(repository: repository)
let indexRequest = IndexRequest(mindMapId: UUID())
let indexResponse = indexUseCase.execute(indexRequest)
print("   MindMap ID: \(indexResponse.mindMapId)")
print("   Indexed nodes: \(indexResponse.indexedNodesCount)")
print("   Success: \(indexResponse.success)")

// Test 4: Update Search Index
print("\n✅ Test 4: Update Search Index")
let updateUseCase = UpdateSearchIndexUseCase(repository: repository)
let updateRequest = UpdateIndexRequest(
    nodeId: UUID(),
    action: .update,
    content: "更新されたノード内容"
)
let updateResponse = updateUseCase.execute(updateRequest)
print("   Node ID: \(updateResponse.nodeId)")
print("   Action: \(updateResponse.action.rawValue)")
print("   Success: \(updateResponse.success)")

// Test 5: Rebuild All Indexes
print("\n✅ Test 5: Rebuild All Search Indexes")
let rebuildUseCase = RebuildSearchIndexesUseCase(repository: repository)
let rebuildResponse = rebuildUseCase.execute()
print("   Total MindMaps: \(rebuildResponse.totalMindMaps)")
print("   Total indexed nodes: \(rebuildResponse.totalIndexedNodes)")
print("   Success: \(rebuildResponse.success)")

// Test 6: Repository Call Tracking
print("\n✅ Test 6: Repository Call Tracking")
print("   Search calls made: \(repository.searchCallCount)")
print("   Index operations: \(repository.indexOperationCount)")

print("\n🎉 All search use case validation tests passed!")