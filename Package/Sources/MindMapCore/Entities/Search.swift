import Foundation

// MARK: - Search Types

/// 検索タイプの定義
public enum SearchType: String, Codable, CaseIterable {
    case fullText = "fullText"
    case exactMatch = "exactMatch"
    case fuzzy = "fuzzy"
}

/// ノードタイプの定義
public enum NodeType: String, Codable, CaseIterable {
    case regular = "regular"
    case task = "task"
}

// MARK: - Search Entity

/// 検索クエリを表すエンティティ
public struct Search: Identifiable, Codable {
    public let id: UUID
    public let query: String
    public let type: SearchType
    public let filters: [SearchFilter]
    public let createdAt: Date
    
    public init(query: String, type: SearchType, filters: [SearchFilter], createdAt: Date) {
        self.id = UUID()
        self.query = query
        self.type = type
        self.filters = filters
        self.createdAt = createdAt
    }
    
    /// 空の検索かどうか
    public var isEmpty: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 有効な検索かどうか
    public var isValid: Bool {
        !isEmpty
    }
    
    /// 指定されたフィルターを持っているかチェック
    public func hasFilter(_ filter: SearchFilter) -> Bool {
        filters.contains(filter)
    }
}

// MARK: - Extensions

extension Search: Equatable {
    public static func == (lhs: Search, rhs: Search) -> Bool {
        lhs.query == rhs.query &&
        lhs.type == rhs.type &&
        lhs.filters == rhs.filters
    }
}

extension Search: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(query)
        hasher.combine(type)
        hasher.combine(filters)
    }
}