import Foundation

// MARK: - Smart Collection Rule

/// スマートコレクションのルール
public enum SmartCollectionRule: Codable, Equatable, Hashable {
    case tagContains(String)
    case contentContains(String)
    case nodeType(NodeType)
    case isCompleted(Bool)
    case createdAfter(Date)
    case createdBefore(Date)
    case updatedAfter(Date)
    case updatedBefore(Date)
    case hasAttachments(Bool)
    case mindMapId(UUID)
    
    /// ルールの説明文
    public var description: String {
        switch self {
        case .tagContains(let tag):
            return "タグに「\(tag)」を含む"
        case .contentContains(let content):
            return "内容に「\(content)」を含む"
        case .nodeType(let type):
            switch type {
            case .regular:
                return "種類が「通常ノード」"
            case .task:
                return "種類が「タスク」"
            case .note:
                return "種類が「ノート」"
            }
        case .isCompleted(let completed):
            return completed ? "完了済み" : "未完了"
        case .createdAfter(let date):
            return "作成日が\(formatDate(date))以降"
        case .createdBefore(let date):
            return "作成日が\(formatDate(date))以前"
        case .updatedAfter(let date):
            return "更新日が\(formatDate(date))以降"
        case .updatedBefore(let date):
            return "更新日が\(formatDate(date))以前"
        case .hasAttachments(let hasAttachments):
            return hasAttachments ? "添付ファイルあり" : "添付ファイルなし"
        case .mindMapId:
            return "特定のマインドマップ内"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

/// マッチ条件
public enum SmartCollectionMatchCondition: String, Codable, CaseIterable {
    case all = "all"
    case any = "any"
    
    public var description: String {
        switch self {
        case .all:
            return "すべての条件に一致"
        case .any:
            return "いずれかの条件に一致"
        }
    }
}

// MARK: - Smart Collection

/// スマートコレクション
public struct SmartCollection: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var description: String
    public var color: NodeColor
    public var rules: [SmartCollectionRule]
    public var matchCondition: SmartCollectionMatchCondition
    public var isAutoUpdate: Bool
    public let createdAt: Date
    public var updatedAt: Date
    public var matchingNodesCount: Int
    public var lastResultsUpdate: Date?
    
    /// 最大名前長
    public static let maxNameLength = 100
    
    /// 最大ルール数
    public static let maxRules = 10
    
    public init(
        name: String,
        description: String,
        color: NodeColor
    ) {
        self.id = UUID()
        self.name = name
        self.description = description
        self.color = color
        self.rules = []
        self.matchCondition = .all
        self.isAutoUpdate = false
        self.createdAt = Date()
        self.updatedAt = Date()
        self.matchingNodesCount = 0
        self.lastResultsUpdate = nil
    }
    
    /// 名前が有効かどうか
    public var isValidName: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count <= Self.maxNameLength
    }
    
    /// コレクションが有効かどうか
    public var isValid: Bool {
        isValidName && !rules.isEmpty
    }
    
    /// ルールを追加
    public mutating func addRule(_ rule: SmartCollectionRule) {
        guard rules.count < Self.maxRules else { return }
        
        if !rules.contains(rule) {
            rules.append(rule)
            updatedAt = Date()
        }
    }
    
    /// ルールを削除
    public mutating func removeRule(_ rule: SmartCollectionRule) -> Bool {
        if let index = rules.firstIndex(of: rule) {
            rules.remove(at: index)
            updatedAt = Date()
            return true
        }
        return false
    }
    
    /// マッチ条件を設定
    public mutating func setMatchCondition(_ condition: SmartCollectionMatchCondition) {
        matchCondition = condition
        updatedAt = Date()
    }
    
    /// 自動更新を有効化
    public mutating func enableAutoUpdate() {
        isAutoUpdate = true
        updatedAt = Date()
    }
    
    /// 自動更新を無効化
    public mutating func disableAutoUpdate() {
        isAutoUpdate = false
        updatedAt = Date()
    }
    
    /// ノードがルールにマッチするかチェック
    public func matchesNode<T: SmartCollectionNodeProtocol>(_ node: T) -> Bool {
        guard !rules.isEmpty else { return false }
        
        switch matchCondition {
        case .all:
            return rules.allSatisfy { rule in
                evaluateRule(rule, for: node)
            }
        case .any:
            return rules.contains { rule in
                evaluateRule(rule, for: node)
            }
        }
    }
    
    /// ルールを評価
    private func evaluateRule<T: SmartCollectionNodeProtocol>(_ rule: SmartCollectionRule, for node: T) -> Bool {
        switch rule {
        case .tagContains(let tag):
            return node.tags.contains { $0.localizedCaseInsensitiveContains(tag) }
        case .contentContains(let content):
            return node.text.localizedCaseInsensitiveContains(content)
        case .nodeType(let type):
            return node.nodeType == type
        case .isCompleted(let completed):
            return node.isCompleted == completed
        case .createdAfter(let date):
            return node.createdAt >= date
        case .createdBefore(let date):
            return node.createdAt <= date
        case .updatedAfter(let date):
            return node.updatedAt >= date
        case .updatedBefore(let date):
            return node.updatedAt <= date
        case .hasAttachments(let hasAttachments):
            return node.hasAttachments == hasAttachments
        case .mindMapId(let mindMapId):
            return node.mindMapId == mindMapId
        }
    }
    
    /// 検索リクエストを生成
    public func generateSearchRequest() -> SearchRequest {
        var filters: [SearchFilter] = []
        var queryParts: [String] = []
        
        // ルールを検索フィルターに変換
        for rule in rules {
            switch rule {
            case .tagContains(let tag):
                filters.append(.tag(tag))
            case .contentContains(let content):
                queryParts.append(content)
            case .nodeType(let type):
                filters.append(.nodeType(type))
            case .createdAfter(let date):
                filters.append(.dateRange(date, Date.distantFuture))
            case .createdBefore(let date):
                filters.append(.dateRange(Date.distantPast, date))
            default:
                // その他のルールは検索クエリに含める
                continue
            }
        }
        
        let query = queryParts.isEmpty ? "*" : queryParts.joined(separator: " ")
        
        return SearchRequest(
            query: query,
            type: .fullText,
            filters: filters,
            mindMapId: nil,
            limit: 100
        )
    }
    
    /// 統計を更新
    public mutating func updateStatistics(matchingNodesCount: Int, lastExecutedAt: Date) {
        self.matchingNodesCount = matchingNodesCount
        self.lastResultsUpdate = lastExecutedAt
        updatedAt = Date()
    }
    
    /// ルール説明文を取得
    public func getRulesDescription() -> String {
        guard !rules.isEmpty else { return "ルールが設定されていません" }
        
        let ruleDescriptions = rules.map { $0.description }
        let conjunction = matchCondition == .all ? "かつ" : "または"
        
        return ruleDescriptions.joined(separator: conjunction)
    }
}

// MARK: - Smart Collection Node Protocol

/// スマートコレクションでノードを評価するためのプロトコル
public protocol SmartCollectionNodeProtocol {
    var id: UUID { get }
    var text: String { get }
    var nodeType: NodeType { get }
    var tags: [String] { get }
    var isCompleted: Bool { get }
    var createdAt: Date { get }
    var updatedAt: Date { get }
    var hasAttachments: Bool { get }
    var mindMapId: UUID { get }
}

// MARK: - Smart Collection Manager

/// スマートコレクション管理システム
public struct SmartCollectionManager: Codable {
    public var collections: [SmartCollection]
    public let createdAt: Date
    public var updatedAt: Date
    
    /// 最大コレクション数
    public static let maxCollections = 20
    
    public init(collections: [SmartCollection] = []) {
        self.collections = collections
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    /// 総コレクション数
    public var totalCollections: Int {
        collections.count
    }
    
    /// 自動更新が有効なコレクション数
    public var autoUpdateCollectionsCount: Int {
        collections.filter { $0.isAutoUpdate }.count
    }
    
    /// コレクションを追加
    public mutating func addCollection(_ collection: SmartCollection) {
        guard collections.count < Self.maxCollections else { return }
        
        // 名前の重複チェック
        if collections.contains(where: { $0.name == collection.name }) {
            return
        }
        
        collections.append(collection)
        updatedAt = Date()
    }
    
    /// コレクションを削除
    public mutating func removeCollection(id: UUID) -> Bool {
        let originalCount = collections.count
        collections.removeAll { $0.id == id }
        
        if collections.count < originalCount {
            updatedAt = Date()
            return true
        }
        return false
    }
    
    /// IDでコレクションを取得
    public func findCollectionById(_ id: UUID) -> SmartCollection? {
        return collections.first { $0.id == id }
    }
    
    /// 名前でコレクションを検索
    public func findCollectionsByName(_ name: String) -> [SmartCollection] {
        let searchName = name.lowercased()
        return collections.filter { $0.name.lowercased().contains(searchName) }
    }
    
    /// コレクションを更新
    public mutating func updateCollection(_ updatedCollection: SmartCollection) -> Bool {
        guard let index = collections.firstIndex(where: { $0.id == updatedCollection.id }) else {
            return false
        }
        
        collections[index] = updatedCollection
        updatedAt = Date()
        return true
    }
    
    /// 色別コレクションを取得
    public func getCollectionsByColor(_ color: NodeColor) -> [SmartCollection] {
        return collections.filter { $0.color == color }
    }
    
    /// 自動更新が有効なコレクションを取得
    public func getAutoUpdateCollections() -> [SmartCollection] {
        return collections.filter { $0.isAutoUpdate }
    }
    
    /// 最近更新されたコレクションを取得
    public func getRecentlyUpdatedCollections(limit: Int = 5) -> [SmartCollection] {
        return collections
            .sorted { $0.updatedAt > $1.updatedAt }
            .prefix(limit)
            .map { $0 }
    }
    
    /// 使用統計を取得
    public func getUsageStatistics() -> SmartCollectionUsageStatistics {
        let totalNodes = collections.reduce(0) { $0 + $1.matchingNodesCount }
        let averageNodesPerCollection = collections.isEmpty ? 0.0 : Double(totalNodes) / Double(collections.count)
        let mostActiveCollection = collections.max { $0.matchingNodesCount < $1.matchingNodesCount }
        let colorDistribution = Dictionary(grouping: collections, by: { $0.color }).mapValues { $0.count }
        
        return SmartCollectionUsageStatistics(
            totalCollections: totalCollections,
            totalMatchingNodes: totalNodes,
            averageNodesPerCollection: averageNodesPerCollection,
            mostActiveCollection: mostActiveCollection,
            colorDistribution: colorDistribution,
            autoUpdateCollectionsCount: autoUpdateCollectionsCount
        )
    }
}

// MARK: - Usage Statistics

/// スマートコレクションの使用統計
public struct SmartCollectionUsageStatistics: Codable {
    public let totalCollections: Int
    public let totalMatchingNodes: Int
    public let averageNodesPerCollection: Double
    public let mostActiveCollection: SmartCollection?
    public let colorDistribution: [NodeColor: Int]
    public let autoUpdateCollectionsCount: Int
    
    public init(
        totalCollections: Int,
        totalMatchingNodes: Int,
        averageNodesPerCollection: Double,
        mostActiveCollection: SmartCollection?,
        colorDistribution: [NodeColor: Int],
        autoUpdateCollectionsCount: Int
    ) {
        self.totalCollections = totalCollections
        self.totalMatchingNodes = totalMatchingNodes
        self.averageNodesPerCollection = averageNodesPerCollection
        self.mostActiveCollection = mostActiveCollection
        self.colorDistribution = colorDistribution
        self.autoUpdateCollectionsCount = autoUpdateCollectionsCount
    }
}