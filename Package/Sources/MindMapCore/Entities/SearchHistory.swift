import Foundation

// MARK: - Search History Entry

/// 検索履歴エントリ
public struct SearchHistoryEntry: Identifiable, Codable, Equatable {
    public let id: UUID
    public let query: String
    public let searchType: SearchType
    public let filters: [SearchFilter]
    public let resultsCount: Int
    public var searchedAt: Date
    public var isFavorite: Bool
    public var favoriteMarkedAt: Date?
    
    public init(
        query: String,
        searchType: SearchType,
        filters: [SearchFilter],
        resultsCount: Int
    ) {
        self.id = UUID()
        self.query = query
        self.searchType = searchType
        self.filters = filters
        self.resultsCount = resultsCount
        self.searchedAt = Date()
        self.isFavorite = false
        self.favoriteMarkedAt = nil
    }
    
    /// クエリが有効かどうか
    public var isValidQuery: Bool {
        !trimmedQuery.isEmpty
    }
    
    /// トリムされたクエリ
    public var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// お気に入りに追加
    public mutating func markAsFavorite() {
        isFavorite = true
        favoriteMarkedAt = Date()
    }
    
    /// お気に入りから削除
    public mutating func removeFromFavorites() {
        isFavorite = false
        favoriteMarkedAt = nil
    }
}

// MARK: - Search History Collection

/// 検索履歴コレクション
public struct SearchHistory: Identifiable, Codable {
    public let id: UUID
    public var entries: [SearchHistoryEntry]
    public let createdAt: Date
    public var updatedAt: Date
    
    /// 最大エントリ数
    public static let maxEntries = 100
    
    public init(entries: [SearchHistoryEntry] = []) {
        self.id = UUID()
        self.entries = entries.sorted { $0.searchedAt > $1.searchedAt } // 最新順でソート
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 総検索回数
    public var totalSearchCount: Int {
        entries.count
    }
    
    /// お気に入り数
    public var favoriteCount: Int {
        entries.filter { $0.isFavorite }.count
    }
    
    /// エントリを追加
    public mutating func addEntry(_ entry: SearchHistoryEntry) {
        entries.insert(entry, at: 0) // 先頭に追加（最新順を維持）
        
        // エントリ数制限チェック
        if entries.count > Self.maxEntries {
            entries = Array(entries.prefix(Self.maxEntries))
        }
        
        updatedAt = Date()
    }
    
    /// 最近の検索を取得
    public func getRecentSearches(limit: Int = 10) -> [SearchHistoryEntry] {
        return Array(entries.prefix(limit))
    }
    
    /// お気に入り検索を取得
    public func getFavoriteSearches() -> [SearchHistoryEntry] {
        return entries.filter { $0.isFavorite }
    }
    
    /// 最も頻繁なクエリを取得
    public func getMostFrequentQueries(limit: Int = 5) -> [String] {
        let queryFrequencies = Dictionary(grouping: entries, by: { $0.trimmedQuery.lowercased() })
            .mapValues { $0.count }
        
        return queryFrequencies.sorted { $0.value > $1.value }
            .prefix(limit)
            .compactMap { queryFrequencies.keys.contains($0.key) ? $0.key : nil }
    }
    
    /// 特定クエリの検索回数を取得
    public func getQueryFrequency(_ query: String) -> Int {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return entries.filter { $0.trimmedQuery.lowercased() == trimmedQuery }.count
    }
    
    /// 古いエントリをクリーンアップ
    public mutating func cleanupOldEntries(olderThan date: Date) -> Int {
        let originalCount = entries.count
        entries = entries.filter { $0.searchedAt >= date }
        updatedAt = Date()
        return originalCount - entries.count
    }
    
    /// 検索タイプ別統計
    public func getSearchTypeStatistics() -> [SearchType: Int] {
        Dictionary(grouping: entries, by: { $0.searchType })
            .mapValues { $0.count }
    }
    
    /// フィルター使用統計
    public func getFilterUsageStatistics() -> [String: Int] {
        var filterStats: [String: Int] = [:]
        
        for entry in entries {
            for filter in entry.filters {
                let filterKey: String
                switch filter {
                case .tag(let tag):
                    filterKey = "tag:\(tag)"
                case .dateRange:
                    filterKey = "dateRange"
                case .nodeType(let type):
                    filterKey = "nodeType:\(type.rawValue)"
                case .creator:
                    filterKey = "creator"
                }
                filterStats[filterKey, default: 0] += 1
            }
        }
        
        return filterStats
    }
}