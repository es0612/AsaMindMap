import Foundation

// MARK: - Match Types

/// 検索マッチタイプの定義
public enum SearchMatchType: String, Codable, CaseIterable {
    case title = "title"
    case content = "content"
    case tag = "tag"
    
    /// マッチタイプの優先度（高いほど重要）
    public var priority: Int {
        switch self {
        case .title:
            return 3
        case .content:
            return 2
        case .tag:
            return 1
        }
    }
}

// MARK: - Search Result Entity

/// 検索結果を表すエンティティ
public struct SearchResult: Identifiable, Codable {
    public let id: UUID
    public let nodeId: UUID
    public let mindMapId: UUID
    public let relevanceScore: Double
    public let matchType: SearchMatchType
    public let highlightedText: String
    public let matchPosition: Int
    
    public init(
        nodeId: UUID,
        mindMapId: UUID,
        relevanceScore: Double,
        matchType: SearchMatchType,
        highlightedText: String,
        matchPosition: Int
    ) {
        self.id = UUID()
        self.nodeId = nodeId
        self.mindMapId = mindMapId
        self.relevanceScore = relevanceScore
        self.matchType = matchType
        self.highlightedText = highlightedText
        self.matchPosition = matchPosition
    }
    
    /// 関連性が十分高いかどうか（閾値: 0.3）
    public var isRelevant: Bool {
        relevanceScore >= 0.3
    }
    
    /// マッチタイプによる優先度
    public var priority: Int {
        matchType.priority
    }
    
    /// 検索語をハイライトしたテキストを取得
    public func getHighlightedText(searchTerm: String) -> String {
        // 簡単な実装：検索語が含まれていることを確認
        guard highlightedText.contains(searchTerm) else {
            return highlightedText
        }
        
        // 実際のハイライト処理は将来的に拡張
        return highlightedText.replacingOccurrences(
            of: searchTerm,
            with: "**\(searchTerm)**",
            options: .caseInsensitive
        )
    }
}

// MARK: - Extensions

extension SearchResult: Equatable {
    public static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.nodeId == rhs.nodeId &&
        lhs.mindMapId == rhs.mindMapId &&
        lhs.relevanceScore == rhs.relevanceScore &&
        lhs.matchType == rhs.matchType
    }
}

extension SearchResult: Comparable {
    public static func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
        // 関連性スコアで降順ソート（高い方が上）
        if lhs.relevanceScore != rhs.relevanceScore {
            return lhs.relevanceScore > rhs.relevanceScore
        }
        
        // スコアが同じ場合はマッチタイプの優先度で比較
        return lhs.priority > rhs.priority
    }
}

extension SearchResult: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(nodeId)
        hasher.combine(mindMapId)
    }
}