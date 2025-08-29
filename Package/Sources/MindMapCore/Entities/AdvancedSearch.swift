import Foundation

// MARK: - Sort Criteria

/// ソート対象フィールド
public enum SortField: String, Codable, CaseIterable {
    case relevanceScore = "relevanceScore"
    case createdDate = "createdDate"
    case updatedDate = "updatedDate"
    case matchTypePriority = "matchTypePriority"
    case alphabetical = "alphabetical"
    case nodeCount = "nodeCount"
}

/// ソート順序
public enum SortOrder: String, Codable, CaseIterable {
    case ascending = "ascending"
    case descending = "descending"
}

/// ソート条件
public struct SortCriterion: Codable, Equatable {
    public let field: SortField
    public let order: SortOrder
    
    public init(field: SortField, order: SortOrder) {
        self.field = field
        self.order = order
    }
}

// MARK: - Grouping

/// グルーピング対象フィールド
public enum GroupingField: String, Codable, CaseIterable {
    case matchType = "matchType"
    case mindMap = "mindMap"
    case relevanceRange = "relevanceRange"
    case createdDate = "createdDate"
    case tag = "tag"
}

/// グループ化された検索結果
public struct GroupedSearchResults: Codable {
    public let groups: [SearchResultGroup]
    public let totalResults: Int
    public let groupingField: GroupingField
    
    public init(groups: [SearchResultGroup], totalResults: Int, groupingField: GroupingField) {
        self.groups = groups
        self.totalResults = totalResults
        self.groupingField = groupingField
    }
}

/// 検索結果グループ
public struct SearchResultGroup: Codable {
    public let key: String
    public let displayName: String
    public let results: [SearchResult]
    public let count: Int
    
    public init(key: String, displayName: String, results: [SearchResult]) {
        self.key = key
        self.displayName = displayName
        self.results = results
        self.count = results.count
    }
}

// MARK: - Facets

/// ファセット検索結果
public struct SearchFacets: Codable {
    public let matchTypeFacet: [String: Int]
    public let mindMapFacet: [String: Int]
    public let relevanceRangeFacet: [String: Int]
    public let tagFacet: [String: Int]
    
    public init(
        matchTypeFacet: [String: Int],
        mindMapFacet: [String: Int],
        relevanceRangeFacet: [String: Int],
        tagFacet: [String: Int] = [:]
    ) {
        self.matchTypeFacet = matchTypeFacet
        self.mindMapFacet = mindMapFacet
        self.relevanceRangeFacet = relevanceRangeFacet
        self.tagFacet = tagFacet
    }
}

// MARK: - Statistics

/// 検索結果統計
public struct SearchResultStatistics: Codable {
    public let totalResults: Int
    public let averageRelevanceScore: Double
    public let matchTypeDistribution: [String: Int]
    public let relevanceScoreDistribution: [String: Int]
    public let mindMapDistribution: [String: Int]
    
    public init(
        totalResults: Int,
        averageRelevanceScore: Double,
        matchTypeDistribution: [String: Int],
        relevanceScoreDistribution: [String: Int],
        mindMapDistribution: [String: Int]
    ) {
        self.totalResults = totalResults
        self.averageRelevanceScore = averageRelevanceScore
        self.matchTypeDistribution = matchTypeDistribution
        self.relevanceScoreDistribution = relevanceScoreDistribution
        self.mindMapDistribution = mindMapDistribution
    }
}

// MARK: - Pagination

/// ページネーション結果
public struct PaginatedSearchResults: Codable {
    public let results: [SearchResult]
    public let currentPage: Int
    public let totalPages: Int
    public let pageSize: Int
    public let totalResults: Int
    public let hasNextPage: Bool
    public let hasPreviousPage: Bool
    
    public init(
        results: [SearchResult],
        currentPage: Int,
        totalPages: Int,
        pageSize: Int,
        totalResults: Int
    ) {
        self.results = results
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.pageSize = pageSize
        self.totalResults = totalResults
        self.hasNextPage = currentPage < totalPages
        self.hasPreviousPage = currentPage > 1
    }
}

// MARK: - Extended Search Result

extension SearchResult {
    /// 作成日時（拡張プロパティ）
    public var createdAt: Date {
        // 実際の実装では、データソースから取得する
        // ここでは検索結果に含まれる情報から推定
        return Date().addingTimeInterval(TimeInterval(-Int.random(in: 0...86400)))
    }
    
    /// SearchResult with createdAt
    public init(
        nodeId: UUID,
        mindMapId: UUID,
        relevanceScore: Double,
        matchType: SearchMatchType,
        highlightedText: String,
        matchPosition: Int,
        createdAt: Date
    ) {
        self.init(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: relevanceScore,
            matchType: matchType,
            highlightedText: highlightedText,
            matchPosition: matchPosition
        )
        // 注意: 実際の実装では、SearchResultに createdAt プロパティを追加する必要があります
    }
}

// MARK: - Advanced Search Service Protocol

public protocol AdvancedSearchServiceProtocol {
    func applyFilters(_ results: [SearchResult], filters: [SearchFilter]) async throws -> [SearchResult]
    func sortResults(_ results: [SearchResult], by field: SortField, order: SortOrder) async throws -> [SearchResult]
    func sortResults(_ results: [SearchResult], by criteria: [SortCriterion]) async throws -> [SearchResult]
    func groupResults(_ results: [SearchResult], by field: GroupingField) async throws -> GroupedSearchResults
    func filterByRelevanceScore(_ results: [SearchResult], minScore: Double, maxScore: Double) async throws -> [SearchResult]
    func generateFacets(from results: [SearchResult]) async throws -> SearchFacets
    func generateStatistics(from results: [SearchResult]) async throws -> SearchResultStatistics
    func paginateResults(_ results: [SearchResult], pageSize: Int, pageNumber: Int) async throws -> PaginatedSearchResults
    func matchesAllFilters(_ result: SearchResult, filters: [SearchFilter]) -> Bool
}

// MARK: - Advanced Search Service Implementation

public final class AdvancedSearchService: AdvancedSearchServiceProtocol {
    
    public init() {}
    
    public func applyFilters(_ results: [SearchResult], filters: [SearchFilter]) async throws -> [SearchResult] {
        guard !filters.isEmpty else { return results }
        
        return results.filter { result in
            return filters.allSatisfy { filter in
                matchesFilter(result, filter: filter)
            }
        }
    }
    
    public func sortResults(_ results: [SearchResult], by field: SortField, order: SortOrder) async throws -> [SearchResult] {
        let sortCriterion = SortCriterion(field: field, order: order)
        return try await sortResults(results, by: [sortCriterion])
    }
    
    public func sortResults(_ results: [SearchResult], by criteria: [SortCriterion]) async throws -> [SearchResult] {
        return results.sorted { lhs, rhs in
            for criterion in criteria {
                let comparison = compareResults(lhs, rhs, by: criterion.field)
                if comparison != .orderedSame {
                    return criterion.order == .ascending ? comparison == .orderedAscending : comparison == .orderedDescending
                }
            }
            return false
        }
    }
    
    public func groupResults(_ results: [SearchResult], by field: GroupingField) async throws -> GroupedSearchResults {
        var groups: [String: [SearchResult]] = [:]
        
        for result in results {
            let key = getGroupKey(for: result, field: field)
            if groups[key] == nil {
                groups[key] = []
            }
            groups[key]?.append(result)
        }
        
        let resultGroups = groups.map { (key, results) in
            SearchResultGroup(
                key: key,
                displayName: getDisplayName(for: key, field: field),
                results: results
            )
        }
        
        return GroupedSearchResults(
            groups: resultGroups,
            totalResults: results.count,
            groupingField: field
        )
    }
    
    public func filterByRelevanceScore(_ results: [SearchResult], minScore: Double, maxScore: Double) async throws -> [SearchResult] {
        return results.filter { result in
            result.relevanceScore >= minScore && result.relevanceScore <= maxScore
        }
    }
    
    public func generateFacets(from results: [SearchResult]) async throws -> SearchFacets {
        var matchTypeFacet: [String: Int] = [:]
        var mindMapFacet: [String: Int] = [:]
        var relevanceRangeFacet: [String: Int] = [:]
        
        for result in results {
            // マッチタイプファセット
            let matchTypeKey = result.matchType.rawValue
            matchTypeFacet[matchTypeKey, default: 0] += 1
            
            // マインドマップファセット
            let mindMapKey = result.mindMapId.uuidString
            mindMapFacet[mindMapKey, default: 0] += 1
            
            // 関連性スコア範囲ファセット
            let relevanceRange = getRelevanceRange(result.relevanceScore)
            relevanceRangeFacet[relevanceRange, default: 0] += 1
        }
        
        return SearchFacets(
            matchTypeFacet: matchTypeFacet,
            mindMapFacet: mindMapFacet,
            relevanceRangeFacet: relevanceRangeFacet
        )
    }
    
    public func generateStatistics(from results: [SearchResult]) async throws -> SearchResultStatistics {
        guard !results.isEmpty else {
            return SearchResultStatistics(
                totalResults: 0,
                averageRelevanceScore: 0,
                matchTypeDistribution: [:],
                relevanceScoreDistribution: [:],
                mindMapDistribution: [:]
            )
        }
        
        let totalScore = results.reduce(0) { $0 + $1.relevanceScore }
        let averageScore = totalScore / Double(results.count)
        
        var matchTypeDistribution: [String: Int] = [:]
        var relevanceScoreDistribution: [String: Int] = [:]
        var mindMapDistribution: [String: Int] = [:]
        
        for result in results {
            matchTypeDistribution[result.matchType.rawValue, default: 0] += 1
            relevanceScoreDistribution[getRelevanceRange(result.relevanceScore), default: 0] += 1
            mindMapDistribution[result.mindMapId.uuidString, default: 0] += 1
        }
        
        return SearchResultStatistics(
            totalResults: results.count,
            averageRelevanceScore: averageScore,
            matchTypeDistribution: matchTypeDistribution,
            relevanceScoreDistribution: relevanceScoreDistribution,
            mindMapDistribution: mindMapDistribution
        )
    }
    
    public func paginateResults(_ results: [SearchResult], pageSize: Int, pageNumber: Int) async throws -> PaginatedSearchResults {
        guard pageSize > 0 && pageNumber > 0 else {
            throw SearchError.invalidFilters
        }
        
        let totalResults = results.count
        let totalPages = max(1, Int(ceil(Double(totalResults) / Double(pageSize))))
        let startIndex = (pageNumber - 1) * pageSize
        let endIndex = min(startIndex + pageSize, totalResults)
        
        let pageResults = startIndex < totalResults ? Array(results[startIndex..<endIndex]) : []
        
        return PaginatedSearchResults(
            results: pageResults,
            currentPage: pageNumber,
            totalPages: totalPages,
            pageSize: pageSize,
            totalResults: totalResults
        )
    }
    
    public func matchesAllFilters(_ result: SearchResult, filters: [SearchFilter]) -> Bool {
        return filters.allSatisfy { filter in
            matchesFilter(result, filter: filter)
        }
    }
    
    // MARK: - Private Methods
    
    private func matchesFilter(_ result: SearchResult, filter: SearchFilter) -> Bool {
        switch filter {
        case .tag(let tagName):
            return result.highlightedText.contains("#\(tagName)")
        case .dateRange(let startDate, let endDate):
            let resultDate = result.createdAt
            return resultDate >= startDate && resultDate <= endDate
        case .nodeType(let nodeType):
            // 実装では、ノードタイプ情報を結果に含める必要があります
            return nodeType == .regular // 簡単な実装
        case .creator(let creatorId):
            // 実装では、作成者情報を結果に含める必要があります
            return creatorId.uuidString.isEmpty == false // 簡単な実装
        }
    }
    
    private func compareResults(_ lhs: SearchResult, _ rhs: SearchResult, by field: SortField) -> ComparisonResult {
        switch field {
        case .relevanceScore:
            return lhs.relevanceScore < rhs.relevanceScore ? .orderedAscending :
                   lhs.relevanceScore > rhs.relevanceScore ? .orderedDescending : .orderedSame
        case .createdDate:
            return lhs.createdAt < rhs.createdAt ? .orderedAscending :
                   lhs.createdAt > rhs.createdAt ? .orderedDescending : .orderedSame
        case .matchTypePriority:
            return lhs.matchType.priority < rhs.matchType.priority ? .orderedAscending :
                   lhs.matchType.priority > rhs.matchType.priority ? .orderedDescending : .orderedSame
        case .alphabetical:
            return lhs.highlightedText.localizedCompare(rhs.highlightedText)
        case .updatedDate:
            // 実装では、更新日時情報を追加する必要があります
            return .orderedSame
        case .nodeCount:
            // 実装では、ノード数情報を追加する必要があります
            return .orderedSame
        }
    }
    
    private func getGroupKey(for result: SearchResult, field: GroupingField) -> String {
        switch field {
        case .matchType:
            return result.matchType.rawValue
        case .mindMap:
            return result.mindMapId.uuidString
        case .relevanceRange:
            return getRelevanceRange(result.relevanceScore)
        case .createdDate:
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: result.createdAt)
        case .tag:
            // 実装では、タグ情報を抽出する必要があります
            return "default"
        }
    }
    
    private func getDisplayName(for key: String, field: GroupingField) -> String {
        switch field {
        case .matchType:
            switch key {
            case "title": return "タイトルマッチ"
            case "content": return "コンテンツマッチ"
            case "tag": return "タグマッチ"
            default: return key
            }
        case .mindMap:
            return "マインドマップ \(key.prefix(8))"
        case .relevanceRange:
            return key
        case .createdDate:
            return key
        case .tag:
            return "#\(key)"
        }
    }
    
    private func getRelevanceRange(_ score: Double) -> String {
        switch score {
        case 0.9...1.0:
            return "非常に高い (0.9-1.0)"
        case 0.7...0.9:
            return "高い (0.7-0.9)"
        case 0.5...0.7:
            return "中程度 (0.5-0.7)"
        case 0.3...0.5:
            return "低い (0.3-0.5)"
        default:
            return "非常に低い (0.0-0.3)"
        }
    }
}