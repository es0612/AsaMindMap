import Foundation

/// スマート提案システム
/// 関連コンテンツ推薦とパーソナライズド提案を提供
@available(iOS 15.0, *)
public final class SmartSuggestionSystem {
    private var userPreferences: UserPreferences = UserPreferences()
    private var learningData: LearningData = LearningData()
    
    public init() {}
    
    /// ノードに基づく提案生成
    public func generateSuggestions(for node: GeneratedNode) async throws -> [AISuggestion] {
        // コンテキスト分析
        let context = analyzeContext(node)
        
        // 関連トピック生成
        let relatedTopics = generateRelatedTopics(for: node.text, context: context)
        
        // アクション提案
        let actionSuggestions = generateActionSuggestions(for: node.text)
        
        // パーソナライズド提案
        let personalizedSuggestions = generatePersonalizedSuggestions(for: node, preferences: userPreferences)
        
        var allSuggestions: [AISuggestion] = []
        allSuggestions.append(contentsOf: relatedTopics)
        allSuggestions.append(contentsOf: actionSuggestions)
        allSuggestions.append(contentsOf: personalizedSuggestions)
        
        // スコアでソート
        return Array(allSuggestions.sorted { $0.confidence > $1.confidence }.prefix(5))
    }
    
    /// 関連コンテンツ推薦
    public func recommendContent(for mindMapId: String) async throws -> [ContentRecommendation] {
        // マインドマップのコンテキスト取得
        let context = await getContextForMindMap(mindMapId)
        
        // 類似マインドマップ検索
        let similarMaps = findSimilarMindMaps(context: context)
        
        // 外部リソース推薦
        let externalResources = recommendExternalResources(context: context)
        
        var recommendations: [ContentRecommendation] = []
        recommendations.append(contentsOf: similarMaps)
        recommendations.append(contentsOf: externalResources)
        
        return Array(recommendations.sorted { $0.relevanceScore > $1.relevanceScore }.prefix(5))
    }
    
    /// ユーザー学習データ更新
    public func updateLearning(interaction: UserInteraction) {
        learningData.interactions.append(interaction)
        updateUserPreferences(based: interaction)
    }
    
    /// パーソナライゼーション設定
    public func updatePersonalization(preferences: UserPreferences) {
        self.userPreferences = preferences
    }
    
    /// 学習統計取得
    public func getLearningStats() -> LearningStats {
        return LearningStats(
            totalInteractions: learningData.interactions.count,
            preferredCategories: calculatePreferredCategories(),
            accuracyScore: calculateAccuracyScore(),
            lastUpdated: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func analyzeContext(_ node: GeneratedNode) -> SuggestionContext {
        // ノードレベル分析
        let level = node.level
        
        // カテゴリ推定
        let category = estimateCategory(from: node.text)
        
        // 関連キーワード抽出
        let keywords = extractKeywords(from: node.text)
        
        return SuggestionContext(
            nodeLevel: level,
            category: category,
            keywords: keywords,
            hasChildren: !node.children.isEmpty
        )
    }
    
    private func generateRelatedTopics(for text: String, context: SuggestionContext) -> [AISuggestion] {
        // カテゴリベースの関連トピック
        let relatedTopics = getRelatedTopicsForCategory(context.category)
        
        return relatedTopics.map { topic in
            AISuggestion(
                id: UUID(),
                type: .relatedTopic,
                content: topic,
                confidence: 0.8,
                category: context.category,
                reasoning: "「\(text)」に関連するトピックです"
            )
        }
    }
    
    private func generateActionSuggestions(for text: String) -> [AISuggestion] {
        let actions = [
            "詳細を調査する",
            "タスクに変換する",
            "期限を設定する",
            "責任者を割り当てる",
            "リソースをリンクする"
        ]
        
        return actions.map { action in
            AISuggestion(
                id: UUID(),
                type: .actionItem,
                content: action,
                confidence: 0.7,
                category: "アクション",
                reasoning: "「\(text)」に対する推奨アクションです"
            )
        }
    }
    
    private func generatePersonalizedSuggestions(for node: GeneratedNode, preferences: UserPreferences) -> [AISuggestion] {
        guard !preferences.preferredCategories.isEmpty else { return [] }
        
        let personalizedContent = preferences.preferredCategories.map { category in
            "「\(category)」の観点から\(node.text)を分析"
        }
        
        return personalizedContent.map { content in
            AISuggestion(
                id: UUID(),
                type: .personalized,
                content: content,
                confidence: 0.9,
                category: "パーソナライズ",
                reasoning: "あなたの興味に基づく提案です"
            )
        }
    }
    
    private func getContextForMindMap(_ mindMapId: String) async -> MindMapContext {
        // 実際の実装では、データベースからマインドマップの内容を取得
        return MindMapContext(
            id: mindMapId,
            mainTopic: "サンプルトピック",
            categories: ["ビジネス"],
            keywords: ["計画", "戦略"]
        )
    }
    
    private func findSimilarMindMaps(context: MindMapContext) -> [ContentRecommendation] {
        // 類似マインドマップの検索ロジック
        let similarMaps = [
            "プロジェクト計画テンプレート",
            "戦略マップサンプル",
            "業務分析フレームワーク"
        ]
        
        return similarMaps.map { title in
            ContentRecommendation(
                id: UUID(),
                type: .similarMindMap,
                title: title,
                description: "類似するマインドマップです",
                relevanceScore: 0.8,
                source: "内部データベース"
            )
        }
    }
    
    private func recommendExternalResources(context: MindMapContext) -> [ContentRecommendation] {
        // 外部リソース推薦ロジック
        let resources = [
            ("Wikipedia記事", "関連する百科事典記事"),
            ("参考文献", "学術論文や書籍"),
            ("ウェブリソース", "関連するウェブサイト")
        ]
        
        return resources.map { (title, description) in
            ContentRecommendation(
                id: UUID(),
                type: .externalResource,
                title: title,
                description: description,
                relevanceScore: 0.7,
                source: "外部データベース"
            )
        }
    }
    
    private func estimateCategory(from text: String) -> String {
        let businessKeywords = ["プロジェクト", "計画", "戦略", "売上", "目標"]
        let educationKeywords = ["学習", "勉強", "教育", "研究"]
        let personalKeywords = ["趣味", "健康", "家族", "旅行"]
        
        if businessKeywords.contains(where: text.contains) {
            return "ビジネス"
        } else if educationKeywords.contains(where: text.contains) {
            return "教育"
        } else if personalKeywords.contains(where: text.contains) {
            return "個人"
        } else {
            return "一般"
        }
    }
    
    private func extractKeywords(from text: String) -> [String] {
        // シンプルなキーワード抽出
        let words = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
        return words.filter { $0.count > 2 }
    }
    
    private func getRelatedTopicsForCategory(_ category: String) -> [String] {
        switch category {
        case "ビジネス":
            return ["競合分析", "市場調査", "収益モデル", "リスク管理"]
        case "教育":
            return ["学習計画", "復習方法", "参考資料", "評価基準"]
        case "個人":
            return ["目標設定", "時間管理", "習慣形成", "振り返り"]
        default:
            return ["詳細情報", "関連事項", "参考資料", "次のステップ"]
        }
    }
    
    private func updateUserPreferences(based interaction: UserInteraction) {
        // ユーザーの行動に基づいて好みを更新
        if case .accepted = interaction.action {
            if !userPreferences.preferredCategories.contains(interaction.category) {
                userPreferences.preferredCategories.append(interaction.category)
            }
        }
    }
    
    private func calculatePreferredCategories() -> [String] {
        let interactions = learningData.interactions
        let categoryCount = interactions.reduce(into: [String: Int]()) { counts, interaction in
            counts[interaction.category, default: 0] += 1
        }
        
        return categoryCount.sorted { $0.value > $1.value }.map { $0.key }
    }
    
    private func calculateAccuracyScore() -> Double {
        let interactions = learningData.interactions
        guard !interactions.isEmpty else { return 0.0 }
        
        let acceptedCount = interactions.filter { 
            if case .accepted = $0.action { return true }
            return false
        }.count
        
        return Double(acceptedCount) / Double(interactions.count)
    }
}

// MARK: - Data Models

/// AI提案
public struct AISuggestion {
    public let id: UUID
    public let type: SuggestionType
    public let content: String
    public let confidence: Double
    public let category: String
    public let reasoning: String
    
    public enum SuggestionType {
        case relatedTopic
        case actionItem
        case personalized
        case template
    }
}

/// コンテンツ推薦
public struct ContentRecommendation {
    public let id: UUID
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let relevanceScore: Double
    public let source: String
    
    public enum RecommendationType {
        case similarMindMap
        case externalResource
        case template
        case relatedContent
    }
}

/// 提案コンテキスト
struct SuggestionContext {
    let nodeLevel: Int
    let category: String
    let keywords: [String]
    let hasChildren: Bool
}

/// ユーザー設定
public struct UserPreferences {
    public var preferredCategories: [String] = []
    public var suggestionFrequency: Int = 5
    public var enablePersonalization: Bool = true
    
    public init() {}
}

/// 学習データ
struct LearningData {
    var interactions: [UserInteraction] = []
}

/// ユーザーインタラクション
public struct UserInteraction {
    public let suggestionId: UUID
    public let action: InteractionAction
    public let category: String
    public let timestamp: Date
    
    public enum InteractionAction {
        case accepted
        case rejected
        case modified
    }
}

/// 学習統計
public struct LearningStats {
    public let totalInteractions: Int
    public let preferredCategories: [String]
    public let accuracyScore: Double
    public let lastUpdated: Date
}

/// マインドマップコンテキスト
struct MindMapContext {
    let id: String
    let mainTopic: String
    let categories: [String]
    let keywords: [String]
}