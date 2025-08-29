import Foundation

// MARK: - Saved Search

/// 保存済み検索
public struct SavedSearch: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var description: String
    public var query: String
    public var searchType: SearchType
    public var filters: [SearchFilter]
    public let createdAt: Date
    public var updatedAt: Date
    public var useCount: Int
    public var lastUsedAt: Date?
    public var isShared: Bool
    public var sharedAt: Date?
    
    /// 最大名前長
    public static let maxNameLength = 100
    
    public init(
        name: String,
        description: String,
        query: String,
        searchType: SearchType,
        filters: [SearchFilter]
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.query = query
        self.searchType = searchType
        self.filters = filters
        self.createdAt = Date()
        self.updatedAt = Date()
        self.useCount = 0
        self.lastUsedAt = nil
        self.isShared = false
        self.sharedAt = nil
    }
    
    /// 名前が有効かどうか
    public var isValidName: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count <= Self.maxNameLength
    }
    
    /// クエリが有効かどうか
    public var isValidQuery: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 保存済み検索が有効かどうか
    public var isValid: Bool {
        isValidName && isValidQuery
    }
    
    /// 使用回数を増加
    public mutating func incrementUseCount() {
        useCount += 1
        lastUsedAt = Date()
        updatedAt = Date()
    }
    
    /// 検索設定を更新
    public mutating func updateSearch(
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
        self.updatedAt = Date()
    }
    
    /// 共有設定
    public mutating func markAsShared() {
        isShared = true
        sharedAt = Date()
        updatedAt = Date()
    }
    
    /// プライベート設定
    public mutating func markAsPrivate() {
        isShared = false
        sharedAt = nil
        updatedAt = Date()
    }
    
    /// SearchRequestに変換
    public func toSearchRequest(limit: Int = 50, offset: Int = 0) -> SearchRequest {
        return SearchRequest(
            query: query,
            type: searchType,
            filters: filters,
            mindMapId: nil,
            limit: limit,
            offset: offset
        )
    }
}

// MARK: - Saved Search Collection

/// 保存済み検索コレクション
public struct SavedSearchCollection: Identifiable, Codable {
    public let id: UUID
    public var searches: [SavedSearch]
    public let createdAt: Date
    public var updatedAt: Date
    
    /// 最大保存数
    public static let maxSavedSearches = 50
    
    public init(searches: [SavedSearch] = []) {
        self.id = UUID()
        self.searches = searches
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 総数
    public var totalCount: Int {
        searches.count
    }
    
    /// 共有されている検索の数
    public var sharedCount: Int {
        searches.filter { $0.isShared }.count
    }
    
    /// プライベート検索の数
    public var privateCount: Int {
        searches.filter { !$0.isShared }.count
    }
    
    /// 検索を追加
    public mutating func addSearch(_ savedSearch: SavedSearch) {
        // 重複チェック
        if hasDuplicateQuery(savedSearch.query, searchType: savedSearch.searchType, filters: savedSearch.filters) {
            return
        }
        
        searches.append(savedSearch)
        
        // 制限チェック
        if searches.count > Self.maxSavedSearches {
            // 最も使用頻度の低いものを削除（作成日時でソート）
            searches.sort { lhs, rhs in
                if lhs.useCount != rhs.useCount {
                    return lhs.useCount > rhs.useCount
                }
                return lhs.createdAt > rhs.createdAt
            }
            searches = Array(searches.prefix(Self.maxSavedSearches))
        }
        
        updatedAt = Date()
    }
    
    /// 重複クエリの存在チェック
    public func hasDuplicateQuery(_ query: String, searchType: SearchType, filters: [SearchFilter]) -> Bool {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        return searches.contains { savedSearch in
            savedSearch.query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedQuery &&
            savedSearch.searchType == searchType &&
            savedSearch.filters == filters
        }
    }
    
    /// IDで検索を取得
    public func findSearchById(_ id: UUID) -> SavedSearch? {
        return searches.first { $0.id == id }
    }
    
    /// 名前で検索を取得
    public func findSearchesByName(_ name: String) -> [SavedSearch] {
        let searchName = name.lowercased()
        return searches.filter { $0.name.lowercased().contains(searchName) }
    }
    
    /// 検索を削除
    public mutating func removeSearch(id: UUID) -> Bool {
        let originalCount = searches.count
        searches.removeAll { $0.id == id }
        
        if searches.count < originalCount {
            updatedAt = Date()
            return true
        }
        return false
    }
    
    /// 人気の検索を取得（使用回数順）
    public func getPopularSearches(limit: Int = 10) -> [SavedSearch] {
        return searches
            .sorted { $0.useCount > $1.useCount }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 最近使用した検索を取得
    public func getRecentlyUsedSearches(limit: Int = 10) -> [SavedSearch] {
        return searches
            .filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? Date.distantPast) > ($1.lastUsedAt ?? Date.distantPast) }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 最近作成した検索を取得
    public func getRecentlyCreatedSearches(limit: Int = 10) -> [SavedSearch] {
        return searches
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 共有検索を取得
    public func getSharedSearches() -> [SavedSearch] {
        return searches.filter { $0.isShared }
    }
    
    /// プライベート検索を取得
    public func getPrivateSearches() -> [SavedSearch] {
        return searches.filter { !$0.isShared }
    }
    
    /// 検索タイプ別統計
    public func getSearchTypeStatistics() -> [SearchType: Int] {
        Dictionary(grouping: searches, by: { $0.searchType })
            .mapValues { $0.count }
    }
    
    /// 使用頻度統計
    public func getUsageStatistics() -> SavedSearchUsageStatistics {
        let totalUses = searches.reduce(0) { $0 + $1.useCount }
        let averageUses = searches.isEmpty ? 0.0 : Double(totalUses) / Double(searches.count)
        let mostUsedSearch = searches.max { $0.useCount < $1.useCount }
        let unusedSearches = searches.filter { $0.useCount == 0 }
        
        return SavedSearchUsageStatistics(
            totalSavedSearches: totalCount,
            totalUses: totalUses,
            averageUsesPerSearch: averageUses,
            mostUsedSearch: mostUsedSearch,
            unusedSearchCount: unusedSearches.count
        )
    }
}

// MARK: - Usage Statistics

/// 保存済み検索の使用統計
public struct SavedSearchUsageStatistics: Codable {
    public let totalSavedSearches: Int
    public let totalUses: Int
    public let averageUsesPerSearch: Double
    public let mostUsedSearch: SavedSearch?
    public let unusedSearchCount: Int
    
    public init(
        totalSavedSearches: Int,
        totalUses: Int,
        averageUsesPerSearch: Double,
        mostUsedSearch: SavedSearch?,
        unusedSearchCount: Int
    ) {
        self.totalSavedSearches = totalSavedSearches
        self.totalUses = totalUses
        self.averageUsesPerSearch = averageUsesPerSearch
        self.mostUsedSearch = mostUsedSearch
        self.unusedSearchCount = unusedSearchCount
    }
}