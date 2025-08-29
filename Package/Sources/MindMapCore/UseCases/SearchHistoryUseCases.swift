import Foundation

// MARK: - Search History Repository Protocol

public protocol SearchHistoryRepositoryProtocol {
    func recordSearch(entry: SearchHistoryEntry) async throws
    func getSearchHistory() async throws -> SearchHistory
    func getRecentSearches(limit: Int) async throws -> [SearchHistoryEntry]
    func getFrequentQueries(limit: Int) async throws -> [String]
    func addToFavorites(entryId: UUID) async throws
    func removeFromFavorites(entryId: UUID) async throws
    func getFavoriteSearches() async throws -> [SearchHistoryEntry]
    func cleanupOldEntries(olderThan date: Date) async throws -> Int
    func getSearchStatistics() async throws -> SearchHistoryStatistics
}

// MARK: - Search History Statistics

public struct SearchHistoryStatistics: Codable {
    public let totalSearchCount: Int
    public let favoriteCount: Int
    public let searchTypeDistribution: [SearchType: Int]
    public let filterUsageDistribution: [String: Int]
    public let averageResultsPerSearch: Double
    
    public init(
        totalSearchCount: Int,
        favoriteCount: Int,
        searchTypeDistribution: [SearchType: Int],
        filterUsageDistribution: [String: Int],
        averageResultsPerSearch: Double
    ) {
        self.totalSearchCount = totalSearchCount
        self.favoriteCount = favoriteCount
        self.searchTypeDistribution = searchTypeDistribution
        self.filterUsageDistribution = filterUsageDistribution
        self.averageResultsPerSearch = averageResultsPerSearch
    }
}

// MARK: - Use Case Protocols

public protocol RecordSearchHistoryUseCaseProtocol {
    func execute(searchRequest: SearchRequest, resultsCount: Int) async throws
}

public protocol GetSearchHistoryUseCaseProtocol {
    func execute() async throws -> SearchHistory
}

public protocol GetRecentSearchesUseCaseProtocol {
    func execute(limit: Int) async throws -> [SearchHistoryEntry]
}

public protocol GetFrequentQueriesUseCaseProtocol {
    func execute(limit: Int) async throws -> [String]
}

public protocol ManageSearchHistoryFavoritesUseCaseProtocol {
    func addToFavorites(entryId: UUID) async throws
    func removeFromFavorites(entryId: UUID) async throws
    func getFavorites() async throws -> [SearchHistoryEntry]
}

public protocol CleanupSearchHistoryUseCaseProtocol {
    func execute(olderThan date: Date) async throws -> Int
}

public protocol GetSearchHistoryStatisticsUseCaseProtocol {
    func execute() async throws -> SearchHistoryStatistics
}

// MARK: - Use Case Implementations

/// 検索履歴記録のユースケース
public final class RecordSearchHistoryUseCase: RecordSearchHistoryUseCaseProtocol {
    private let repository: SearchHistoryRepositoryProtocol
    
    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(searchRequest: SearchRequest, resultsCount: Int) async throws {
        // 無効なリクエストは記録しない
        guard searchRequest.isValid else { return }
        
        let historyEntry = SearchHistoryEntry(
            query: searchRequest.query,
            searchType: searchRequest.type,
            filters: searchRequest.filters,
            resultsCount: resultsCount
        )
        
        try await repository.recordSearch(entry: historyEntry)
    }
}

/// 検索履歴取得のユースケース
public final class GetSearchHistoryUseCase: GetSearchHistoryUseCaseProtocol {
    private let repository: SearchHistoryRepositoryProtocol
    
    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> SearchHistory {
        return try await repository.getSearchHistory()
    }
}

/// 最近の検索取得のユースケース
public final class GetRecentSearchesUseCase: GetRecentSearchesUseCaseProtocol {
    private let repository: SearchHistoryRepositoryProtocol
    
    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(limit: Int = 10) async throws -> [SearchHistoryEntry] {
        let validLimit = max(1, min(limit, 50)) // 1-50の範囲に制限
        return try await repository.getRecentSearches(limit: validLimit)
    }
}

/// 頻繁な検索クエリ取得のユースケース
public final class GetFrequentQueriesUseCase: GetFrequentQueriesUseCaseProtocol {
    private let repository: SearchHistoryRepositoryProtocol
    
    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(limit: Int = 5) async throws -> [String] {
        let validLimit = max(1, min(limit, 20)) // 1-20の範囲に制限
        return try await repository.getFrequentQueries(limit: validLimit)
    }
}

/// 検索履歴お気に入り管理のユースケース
public final class ManageSearchHistoryFavoritesUseCase: ManageSearchHistoryFavoritesUseCaseProtocol {
    private let repository: SearchHistoryRepositoryProtocol
    
    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func addToFavorites(entryId: UUID) async throws {
        try await repository.addToFavorites(entryId: entryId)
    }
    
    public func removeFromFavorites(entryId: UUID) async throws {
        try await repository.removeFromFavorites(entryId: entryId)
    }
    
    public func getFavorites() async throws -> [SearchHistoryEntry] {
        return try await repository.getFavoriteSearches()
    }
}

/// 検索履歴クリーンアップのユースケース
public final class CleanupSearchHistoryUseCase: CleanupSearchHistoryUseCaseProtocol {
    private let repository: SearchHistoryRepositoryProtocol
    
    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(olderThan date: Date = Date().addingTimeInterval(-86400 * 30)) async throws -> Int {
        // デフォルトでは30日以上前のエントリを削除
        return try await repository.cleanupOldEntries(olderThan: date)
    }
}

/// 検索履歴統計取得のユースケース
public final class GetSearchHistoryStatisticsUseCase: GetSearchHistoryStatisticsUseCaseProtocol {
    private let repository: SearchHistoryRepositoryProtocol
    
    public init(repository: SearchHistoryRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> SearchHistoryStatistics {
        return try await repository.getSearchStatistics()
    }
}