import Foundation

// MARK: - Filter Types

/// 検索フィルターのタイプ
public enum SearchFilterType: String, Codable, CaseIterable {
    case tag = "tag"
    case dateRange = "dateRange"
    case nodeType = "nodeType"
    case creator = "creator"
}

// MARK: - Search Filter Entity

/// 検索フィルターを表すエンティティ
public enum SearchFilter: Codable, Equatable {
    case tag(String)
    case dateRange(Date, Date)
    case nodeType(NodeType)
    case creator(UUID)
    
    /// フィルターのタイプ
    public var type: SearchFilterType {
        switch self {
        case .tag:
            return .tag
        case .dateRange:
            return .dateRange
        case .nodeType:
            return .nodeType
        case .creator:
            return .creator
        }
    }
    
    /// タグフィルターの値
    public var value: String? {
        switch self {
        case .tag(let value):
            return value
        default:
            return nil
        }
    }
    
    /// 日付範囲フィルターの開始日
    public var startDate: Date? {
        switch self {
        case .dateRange(let start, _):
            return start
        default:
            return nil
        }
    }
    
    /// 日付範囲フィルターの終了日
    public var endDate: Date? {
        switch self {
        case .dateRange(_, let end):
            return end
        default:
            return nil
        }
    }
    
    /// ノードタイプフィルターの値
    public var nodeType: NodeType? {
        switch self {
        case .nodeType(let type):
            return type
        default:
            return nil
        }
    }
    
    /// 作成者フィルターの値
    public var creatorId: UUID? {
        switch self {
        case .creator(let id):
            return id
        default:
            return nil
        }
    }
    
    /// フィルターが有効かどうか
    public var isValid: Bool {
        switch self {
        case .tag(let value):
            return !value.isEmpty
        case .dateRange(let start, let end):
            return start <= end
        case .nodeType:
            return true
        case .creator:
            return true
        }
    }
}

// MARK: - Hashable Extension

extension SearchFilter: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        switch self {
        case .tag(let value):
            hasher.combine(value)
        case .dateRange(let start, let end):
            hasher.combine(start)
            hasher.combine(end)
        case .nodeType(let type):
            hasher.combine(type)
        case .creator(let id):
            hasher.combine(id)
        }
    }
}