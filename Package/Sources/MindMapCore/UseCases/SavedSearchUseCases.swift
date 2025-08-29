import Foundation

// MARK: - Saved Search Repository Protocol

public protocol SavedSearchRepositoryProtocol {
    func save(_ savedSearch: SavedSearch) async throws
    func findById(_ id: UUID) async throws -> SavedSearch?
    func findAll() async throws -> [SavedSearch]
    func update(_ savedSearch: SavedSearch) async throws
    func delete(id: UUID) async throws
    func incrementUseCount(id: UUID) async throws
    func getPopularSearches(limit: Int) async throws -> [SavedSearch]
    func markAsShared(id: UUID) async throws
    func markAsPrivate(id: UUID) async throws
    func getUsageStatistics() async throws -> SavedSearchUsageStatistics
}

// MARK: - Request/Response Types

public struct CreateSavedSearchRequest: Codable, Equatable {
    public let name: String
    public let description: String
    public let query: String
    public let searchType: SearchType
    public let filters: [SearchFilter]
    
    public init(
        name: String,
        description: String,
        query: String,
        searchType: SearchType,
        filters: [SearchFilter]
    ) {
        self.name = name
        self.description = description
        self.query = query
        self.searchType = searchType
        self.filters = filters
    }
    
    public var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && 
               trimmedName.count <= SavedSearch.maxNameLength && 
               !trimmedQuery.isEmpty
    }
}

public struct UpdateSavedSearchRequest: Codable, Equatable {
    public let id: UUID
    public let name: String
    public let description: String
    public let query: String
    public let searchType: SearchType
    public let filters: [SearchFilter]
    
    public init(
        id: UUID,
        name: String,
        description: String,
        query: String,
        searchType: SearchType,
        filters: [SearchFilter]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.query = query
        self.searchType = searchType
        self.filters = filters
    }
    
    public var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && 
               trimmedName.count <= SavedSearch.maxNameLength && 
               !trimmedQuery.isEmpty
    }
}

// MARK: - Error Types

public enum SavedSearchError: Error, LocalizedError {
    case invalidRequest
    case searchNotFound
    case duplicateName
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "無効なリクエストです"
        case .searchNotFound:
            return "保存済み検索が見つかりません"
        case .duplicateName:
            return "同じ名前の保存済み検索が既に存在します"
        case .saveFailed(let reason):
            return "保存に失敗しました: \(reason)"
        case .updateFailed(let reason):
            return "更新に失敗しました: \(reason)"
        case .deleteFailed(let reason):
            return "削除に失敗しました: \(reason)"
        }
    }
}

// MARK: - Use Case Protocols

public protocol CreateSavedSearchUseCaseProtocol {
    func execute(request: CreateSavedSearchRequest) async throws -> SavedSearch
}

public protocol GetSavedSearchesUseCaseProtocol {
    func execute() async throws -> [SavedSearch]
}

public protocol UpdateSavedSearchUseCaseProtocol {
    func execute(request: UpdateSavedSearchRequest) async throws
}

public protocol DeleteSavedSearchUseCaseProtocol {
    func execute(id: UUID) async throws
}

public protocol ExecuteSavedSearchUseCaseProtocol {
    func execute(id: UUID) async throws -> SearchResponse
}

public protocol GetPopularSavedSearchesUseCaseProtocol {
    func execute(limit: Int) async throws -> [SavedSearch]
}

public protocol ShareSavedSearchUseCaseProtocol {
    func shareSearch(id: UUID) async throws
    func unshareSearch(id: UUID) async throws
}

public protocol GetSavedSearchStatisticsUseCaseProtocol {
    func execute() async throws -> SavedSearchUsageStatistics
}

// MARK: - Use Case Implementations

/// 保存済み検索作成のユースケース
public final class CreateSavedSearchUseCase: CreateSavedSearchUseCaseProtocol {
    private let repository: SavedSearchRepositoryProtocol
    
    public init(repository: SavedSearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(request: CreateSavedSearchRequest) async throws -> SavedSearch {
        // リクエスト検証
        guard request.isValid else {
            throw SavedSearchError.invalidRequest
        }
        
        // 重複名チェック（シンプルな実装）
        let existingSearches = try await repository.findAll()
        let trimmedRequestName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if existingSearches.contains(where: { 
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedRequestName.lowercased() 
        }) {
            throw SavedSearchError.duplicateName
        }
        
        // SavedSearch作成
        let savedSearch = SavedSearch(
            name: request.name,
            description: request.description,
            query: request.query,
            searchType: request.searchType,
            filters: request.filters
        )
        
        do {
            try await repository.save(savedSearch)
            return savedSearch
        } catch {
            throw SavedSearchError.saveFailed(error.localizedDescription)
        }
    }
}

/// 保存済み検索一覧取得のユースケース
public final class GetSavedSearchesUseCase: GetSavedSearchesUseCaseProtocol {
    private let repository: SavedSearchRepositoryProtocol
    
    public init(repository: SavedSearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> [SavedSearch] {
        return try await repository.findAll()
    }
}

/// 保存済み検索更新のユースケース
public final class UpdateSavedSearchUseCase: UpdateSavedSearchUseCaseProtocol {
    private let repository: SavedSearchRepositoryProtocol
    
    public init(repository: SavedSearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(request: UpdateSavedSearchRequest) async throws {
        // リクエスト検証
        guard request.isValid else {
            throw SavedSearchError.invalidRequest
        }
        
        // 検索存在確認
        guard var existingSearch = try await repository.findById(request.id) else {
            throw SavedSearchError.searchNotFound
        }
        
        // 更新実行
        existingSearch.updateSearch(
            name: request.name,
            description: request.description,
            query: request.query,
            searchType: request.searchType,
            filters: request.filters
        )
        
        do {
            try await repository.update(existingSearch)
        } catch {
            throw SavedSearchError.updateFailed(error.localizedDescription)
        }
    }
}

/// 保存済み検索削除のユースケース
public final class DeleteSavedSearchUseCase: DeleteSavedSearchUseCaseProtocol {
    private let repository: SavedSearchRepositoryProtocol
    
    public init(repository: SavedSearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(id: UUID) async throws {
        // 存在確認
        guard try await repository.findById(id) != nil else {
            throw SavedSearchError.searchNotFound
        }
        
        do {
            try await repository.delete(id: id)
        } catch {
            throw SavedSearchError.deleteFailed(error.localizedDescription)
        }
    }
}

/// 保存済み検索実行のユースケース
public final class ExecuteSavedSearchUseCase: ExecuteSavedSearchUseCaseProtocol {
    private let savedSearchRepository: SavedSearchRepositoryProtocol
    private let searchRepository: SearchRepositoryProtocol
    
    public init(
        savedSearchRepository: SavedSearchRepositoryProtocol,
        searchRepository: SearchRepositoryProtocol
    ) {
        self.savedSearchRepository = savedSearchRepository
        self.searchRepository = searchRepository
    }
    
    public func execute(id: UUID) async throws -> SearchResponse {
        // 保存済み検索を取得
        guard let savedSearch = try await savedSearchRepository.findById(id) else {
            throw SavedSearchError.searchNotFound
        }
        
        // SearchRequestに変換
        let searchRequest = savedSearch.toSearchRequest()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 検索実行
        let results = try await searchRepository.search(searchRequest)
        let executionTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
        
        // 使用回数を増加
        try await savedSearchRepository.incrementUseCount(id: id)
        
        // SearchResponseを作成
        return SearchResponse(
            query: savedSearch.query,
            searchType: savedSearch.searchType,
            results: Array(results.prefix(searchRequest.limit)),
            totalResults: results.count,
            appliedFilters: savedSearch.filters,
            executionTimeMs: executionTime
        )
    }
}

/// 人気の保存済み検索取得のユースケース
public final class GetPopularSavedSearchesUseCase: GetPopularSavedSearchesUseCaseProtocol {
    private let repository: SavedSearchRepositoryProtocol
    
    public init(repository: SavedSearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(limit: Int = 10) async throws -> [SavedSearch] {
        let validLimit = max(1, min(limit, 50)) // 1-50の範囲に制限
        return try await repository.getPopularSearches(limit: validLimit)
    }
}

/// 保存済み検索共有のユースケース
public final class ShareSavedSearchUseCase: ShareSavedSearchUseCaseProtocol {
    private let repository: SavedSearchRepositoryProtocol
    
    public init(repository: SavedSearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func shareSearch(id: UUID) async throws {
        // 存在確認
        guard try await repository.findById(id) != nil else {
            throw SavedSearchError.searchNotFound
        }
        
        try await repository.markAsShared(id: id)
    }
    
    public func unshareSearch(id: UUID) async throws {
        // 存在確認
        guard try await repository.findById(id) != nil else {
            throw SavedSearchError.searchNotFound
        }
        
        try await repository.markAsPrivate(id: id)
    }
}

/// 保存済み検索統計取得のユースケース
public final class GetSavedSearchStatisticsUseCase: GetSavedSearchStatisticsUseCaseProtocol {
    private let repository: SavedSearchRepositoryProtocol
    
    public init(repository: SavedSearchRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> SavedSearchUsageStatistics {
        return try await repository.getUsageStatistics()
    }
}