import Foundation
import NaturalLanguage

/// 自然言語処理システム
/// テキスト分類、自動タグ付け、感情分析を提供
@available(iOS 15.0, *)
public final class NaturalLanguageProcessor {
    private let tokenizer = NLTokenizer(unit: .sentence)
    private let tagger = NLTagger(tagSchemes: [.sentimentScore, .language, .lexicalClass])
    
    public init() {}
    
    /// テキスト分類
    public func classifyText(_ text: String) async throws -> ClassificationResult {
        // 言語検出
        let language = NLLanguageRecognizer.dominantLanguage(for: text)
        
        // 感情スコア算出
        let sentimentScore = calculateSentimentScore(text)
        
        // カテゴリ分類
        let categories = classifyIntoCategories(text)
        
        return ClassificationResult(
            language: language?.rawValue ?? "unknown",
            sentimentScore: sentimentScore,
            categories: categories,
            confidence: 0.85
        )
    }
    
    /// 自動タグ生成
    public func generateTags(for text: String) async throws -> [AutoTag] {
        // キーワード抽出
        let keywords = extractKeywords(text)
        
        // タグ生成
        let tags = keywords.map { keyword in
            AutoTag(
                text: keyword,
                confidence: 0.8,
                category: determineTagCategory(keyword),
                color: generateTagColor(for: keyword)
            )
        }
        
        return tags
    }
    
    /// 構造解析
    public func analyzeStructure(_ text: String) async throws -> TextStructure {
        // 行ごとに分割
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        guard let firstLine = lines.first else {
            throw NLPError.invalidInput
        }
        
        // ルートトピック決定
        let rootTopic = firstLine
        
        // ブランチ解析
        let branches = analyzeBranches(from: Array(lines.dropFirst()))
        
        return TextStructure(rootTopic: rootTopic, branches: branches)
    }
    
    /// 感情分析
    public func analyzeSentiment(text: String) async throws -> SentimentResult {
        let sentimentScore = calculateSentimentScore(text)
        let emotion = determineEmotion(from: sentimentScore)
        
        return SentimentResult(
            score: sentimentScore,
            emotion: emotion,
            confidence: 0.8
        )
    }
    
    // MARK: - Private Methods
    
    private func calculateSentimentScore(_ text: String) -> Double {
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        
        var totalScore = 0.0
        var scoreCount = 0
        
        tagger.enumerateTags(in: range, unit: .sentence, scheme: .sentimentScore) { tag, _ in
            if let tag = tag,
               let score = Double(tag.rawValue) {
                totalScore += score
                scoreCount += 1
            }
            return true
        }
        
        return scoreCount > 0 ? totalScore / Double(scoreCount) : 0.0
    }
    
    private func classifyIntoCategories(_ text: String) -> [String] {
        // シンプルなキーワードベース分類
        let businessKeywords = ["プロジェクト", "計画", "戦略", "目標", "売上"]
        let educationKeywords = ["学習", "勉強", "教育", "授業", "試験"]
        let personalKeywords = ["趣味", "家族", "健康", "旅行", "料理"]
        
        var categories: [String] = []
        
        if businessKeywords.contains(where: text.contains) {
            categories.append("ビジネス")
        }
        if educationKeywords.contains(where: text.contains) {
            categories.append("教育")
        }
        if personalKeywords.contains(where: text.contains) {
            categories.append("個人")
        }
        
        return categories.isEmpty ? ["一般"] : categories
    }
    
    private func extractKeywords(_ text: String) -> [String] {
        tagger.string = text
        let range = text.startIndex..<text.endIndex
        var keywords: [String] = []
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
            if let tag = tag,
               tag == .noun || tag == .verb {
                let keyword = String(text[tokenRange])
                if keyword.count > 2 { // 2文字以上のキーワードのみ
                    keywords.append(keyword)
                }
            }
            return true
        }
        
        // 重複削除と頻度順ソート
        let uniqueKeywords = Array(Set(keywords))
        return Array(uniqueKeywords.prefix(5)) // 上位5個
    }
    
    private func analyzeBranches(from lines: [String]) -> [TextStructure.Branch] {
        var branches: [TextStructure.Branch] = []
        var currentTitle: String?
        var currentSubBranches: [String] = []
        
        for line in lines {
            if line.hasPrefix("-") || line.hasPrefix("*") {
                // メインブランチ
                if let title = currentTitle {
                    branches.append(TextStructure.Branch(title: title, subBranches: currentSubBranches))
                }
                currentTitle = line.dropFirst().trimmingCharacters(in: .whitespaces)
                currentSubBranches = []
            } else if line.hasPrefix("  -") || line.hasPrefix("  *") {
                // サブブランチ
                let subTitle = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
                currentSubBranches.append(subTitle)
            }
        }
        
        // 最後のブランチを追加
        if let title = currentTitle {
            branches.append(TextStructure.Branch(title: title, subBranches: currentSubBranches))
        }
        
        return branches
    }
    
    private func determineTagCategory(_ keyword: String) -> String {
        let businessKeywords = ["プロジェクト", "計画", "戦略"]
        let actionKeywords = ["実行", "確認", "分析"]
        
        if businessKeywords.contains(keyword) {
            return "ビジネス"
        } else if actionKeywords.contains(keyword) {
            return "アクション"
        } else {
            return "一般"
        }
    }
    
    private func generateTagColor(for keyword: String) -> String {
        let colors = ["#FF6B6B", "#4ECDC4", "#45B7D1", "#96CEB4", "#FECA57"]
        let index = abs(keyword.hashValue) % colors.count
        return colors[index]
    }
    
    private func determineEmotion(from score: Double) -> String {
        switch score {
        case 0.5...1.0: return "ポジティブ"
        case -0.5..<0.5: return "ニュートラル"
        default: return "ネガティブ"
        }
    }
}

// MARK: - Data Models

/// 分類結果
public struct ClassificationResult {
    public let language: String
    public let sentimentScore: Double
    public let categories: [String]
    public let confidence: Double
}

/// 自動タグ
public struct AutoTag {
    public let text: String
    public let confidence: Double
    public let category: String
    public let color: String
}

/// 感情分析結果
public struct SentimentResult {
    public let score: Double
    public let emotion: String
    public let confidence: Double
}

/// NLP エラー
public enum NLPError: Error {
    case invalidInput
    case processingFailed
}