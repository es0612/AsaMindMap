import Foundation

// MARK: - Search Use Case Errors

public enum SearchError: Error, LocalizedError {
    case emptyQuery
    case invalidFilters
    case searchFailed(String)
    case indexNotReady
    
    public var errorDescription: String? {
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

// MARK: - Search Request/Response Types

public struct SearchRequest: Codable, Equatable {
    public let query: String
    public let type: SearchType
    public let filters: [SearchFilter]
    public let mindMapId: UUID?
    public let limit: Int
    public let offset: Int
    
    public init(
        query: String,
        type: SearchType,
        filters: [SearchFilter],
        mindMapId: UUID?,
        limit: Int = 50,
        offset: Int = 0
    ) {
        self.query = query
        self.type = type
        self.filters = filters
        self.mindMapId = mindMapId
        self.limit = limit
        self.offset = offset
    }
    
    public var isValid: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

public struct SearchResponse: Codable {
    public let query: String
    public let searchType: SearchType
    public let results: [SearchResult]
    public let totalResults: Int
    public let appliedFilters: [SearchFilter]
    public let executionTimeMs: Double
    
    public init(
        query: String,
        searchType: SearchType,
        results: [SearchResult],
        totalResults: Int,
        appliedFilters: [SearchFilter],
        executionTimeMs: Double
    ) {
        self.query = query
        self.searchType = searchType
        self.results = results
        self.totalResults = totalResults
        self.appliedFilters = appliedFilters
        self.executionTimeMs = executionTimeMs
    }
}

// MARK: - Index Request/Response Types

public struct IndexRequest: Codable {
    public let mindMapId: UUID
    public let forceRebuild: Bool
    
    public init(mindMapId: UUID, forceRebuild: Bool = false) {
        self.mindMapId = mindMapId
        self.forceRebuild = forceRebuild
    }
}

public struct IndexCreationResponse: Codable {
    public let mindMapId: UUID
    public let indexedNodesCount: Int
    public let success: Bool
    public let error: String?
    
    public init(mindMapId: UUID, indexedNodesCount: Int, success: Bool, error: String? = nil) {
        self.mindMapId = mindMapId
        self.indexedNodesCount = indexedNodesCount
        self.success = success
        self.error = error
    }
}

public enum IndexAction: String, Codable {
    case create = "create"
    case update = "update"
    case delete = "delete"
}

public struct UpdateIndexRequest: Codable {
    public let nodeId: UUID
    public let action: IndexAction
    public let content: String?
    
    public init(nodeId: UUID, action: IndexAction, content: String? = nil) {
        self.nodeId = nodeId
        self.action = action
        self.content = content
    }
}

public struct IndexUpdateResponse: Codable {
    public let nodeId: UUID
    public let action: IndexAction
    public let success: Bool
    public let error: String?
    
    public init(nodeId: UUID, action: IndexAction, success: Bool, error: String? = nil) {
        self.nodeId = nodeId
        self.action = action
        self.success = success
        self.error = error
    }
}

public struct IndexRebuildResponse: Codable {
    public let totalMindMaps: Int
    public let totalIndexedNodes: Int
    public let success: Bool
    public let error: String?
    
    public init(totalMindMaps: Int, totalIndexedNodes: Int, success: Bool, error: String? = nil) {
        self.totalMindMaps = totalMindMaps
        self.totalIndexedNodes = totalIndexedNodes
        self.success = success
        self.error = error
    }
}

// MARK: - Search Use Case Protocols

public protocol SearchRepositoryProtocol {
    func search(_ request: SearchRequest) async throws -> [SearchResult]
    func createSearchIndex(for mindMapId: UUID) async throws -> IndexCreationResponse
    func updateSearchIndex(_ request: UpdateIndexRequest) async throws -> IndexUpdateResponse
    func rebuildAllSearchIndexes() async throws -> IndexRebuildResponse
}

public protocol FullTextSearchUseCaseProtocol {
    func execute(_ request: SearchRequest) async throws -> SearchResponse
}

public protocol CreateSearchIndexUseCaseProtocol {
    func execute(_ request: IndexRequest) async throws -> IndexCreationResponse
}

public protocol UpdateSearchIndexUseCaseProtocol {
    func execute(_ request: UpdateIndexRequest) async throws -> IndexUpdateResponse
}

public protocol RebuildSearchIndexesUseCaseProtocol {
    func execute() async throws -> IndexRebuildResponse
}

// MARK: - Use Case Implementations

public final class FullTextSearchUseCase: FullTextSearchUseCaseProtocol {
    private let repository: SearchRepositoryProtocol
    
    public init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: SearchRequest) async throws -> SearchResponse {
        // Validate request
        guard request.isValid else {
            throw SearchError.emptyQuery
        }
        
        guard request.filters.allSatisfy({ $0.isValid }) else {
            throw SearchError.invalidFilters
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            let results = try await repository.search(request)
            let executionTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000 // Convert to milliseconds
            
            // Apply additional filtering and limiting
            let limitedResults = Array(results.prefix(request.limit))
            
            return SearchResponse(
                query: request.query,
                searchType: request.type,
                results: limitedResults,
                totalResults: results.count,
                appliedFilters: request.filters,
                executionTimeMs: executionTime
            )
        } catch {
            throw SearchError.searchFailed(error.localizedDescription)
        }
    }
}

public final class CreateSearchIndexUseCase: CreateSearchIndexUseCaseProtocol {
    private let repository: SearchRepositoryProtocol
    
    public init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: IndexRequest) async throws -> IndexCreationResponse {
        return try await repository.createSearchIndex(for: request.mindMapId)
    }
}

public final class UpdateSearchIndexUseCase: UpdateSearchIndexUseCaseProtocol {
    private let repository: SearchRepositoryProtocol
    
    public init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: UpdateIndexRequest) async throws -> IndexUpdateResponse {
        return try await repository.updateSearchIndex(request)
    }
}

public final class RebuildSearchIndexesUseCase: RebuildSearchIndexesUseCaseProtocol {
    private let repository: SearchRepositoryProtocol
    
    public init(repository: SearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> IndexRebuildResponse {
        return try await repository.rebuildAllSearchIndexes()
    }
}

// MARK: - Extensions