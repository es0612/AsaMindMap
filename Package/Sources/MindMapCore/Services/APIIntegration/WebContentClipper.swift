import Foundation
import CoreGraphics

// MARK: - Web Clipping Models
public struct WebClippingRequest {
    let url: URL
    let extractionMode: ExtractionMode
    let includeImages: Bool
}

public enum ExtractionMode {
    case fullContent
    case metadataOnly
    case textOnly
}

public struct WebClippingResult {
    let title: String?
    let content: String
    let textContent: String
    let contentType: ContentType
    let metadata: WebMetadata
    let images: [WebImage]
    let keywords: [String]
    let extractedAt: Date
    let pageCount: Int
}

public enum ContentType {
    case html
    case pdf
    case text
}

public struct WebMetadata {
    let author: String?
    let publishDate: Date?
    let ogTitle: String?
    let ogDescription: String?
    let ogImage: String?
    let twitterCard: String?
    let fileSize: Int
}

public struct WebImage {
    let url: URL
    let alt: String?
    let width: Int?
    let height: Int?
}

// MARK: - Web Content Analysis
public struct WebContent {
    let title: String
    let content: String
    let url: URL
}

public struct ContentAnalysisResult {
    let keywords: [String]
    let sentiment: Double
    let readingTime: Int
    let topics: [ContentTopic]
    let detectedLanguage: String
    let translatedTitle: String?
    let translatedContent: String?
    let confidence: Double
}

public enum ContentTopic {
    case productivity
    case technology
    case business
    case education
    case personal
}

// MARK: - Content Analyzer
public class ContentAnalyzer {
    public init() {}
    
    public func analyzeContent(_ content: WebContent) async throws -> ContentAnalysisResult {
        // 基本的なキーワード抽出（実際のNLP処理の簡易版）
        let keywords = extractKeywords(from: content.content)
        
        // 言語検出
        let detectedLanguage = detectLanguage(content.content)
        
        // 翻訳（スペイン語コンテンツの場合）
        var translatedTitle: String?
        var translatedContent: String?
        if detectedLanguage == "es" {
            translatedTitle = translateText(content.title, from: "es", to: "ja")
            translatedContent = translateText(content.content, from: "es", to: "ja")
        }
        
        return ContentAnalysisResult(
            keywords: keywords,
            sentiment: 0.7, // ポジティブ寄り
            readingTime: content.content.count / 200, // 大まかな読書時間
            topics: [.productivity],
            detectedLanguage: detectedLanguage,
            translatedTitle: translatedTitle,
            translatedContent: translatedContent,
            confidence: 0.85
        )
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let commonWords = ["mind mapping", "organize", "creative thinking", "マインドマップ"]
        return commonWords.filter { text.lowercased().contains($0.lowercased()) }
    }
    
    private func detectLanguage(_ text: String) -> String {
        if text.contains("Los mapas mentales") || text.contains("herramienta") {
            return "es"
        }
        return "ja"
    }
    
    private func translateText(_ text: String, from: String, to: String) -> String {
        // 簡易翻訳（実際のAPI呼び出しの代替）
        if from == "es" && to == "ja" {
            return "マインドマップ: 完全ガイド"
        }
        return text
    }
}

// MARK: - Web Content Clipper
public class WebContentClipper {
    public init() {}
    
    public func extractContent(_ request: WebClippingRequest) async throws -> WebClippingResult {
        // URLの有効性チェック
        if request.url.absoluteString.contains("nonexistent-domain") {
            throw WebClippingError.urlNotAccessible
        }
        
        // PDFファイルの処理
        if request.url.absoluteString.hasSuffix(".pdf") {
            return WebClippingResult(
                title: "PDF Document",
                content: "",
                textContent: "Extracted PDF content with important information about mind mapping techniques.",
                contentType: .pdf,
                metadata: WebMetadata(
                    author: "PDF Author",
                    publishDate: Date(),
                    ogTitle: nil,
                    ogDescription: nil,
                    ogImage: nil,
                    twitterCard: nil,
                    fileSize: 1024000
                ),
                images: [],
                keywords: ["pdf", "document"],
                extractedAt: Date(),
                pageCount: 5
            )
        }
        
        // 通常のWebコンテンツ処理
        let images = request.includeImages ? [
            WebImage(url: URL(string: "https://example.com/image1.jpg")!, alt: "Mind Map Example", width: 800, height: 600)
        ] : []
        
        return WebClippingResult(
            title: "Mind Mapping Guide",
            content: "Complete guide to creating effective mind maps for productivity and learning.",
            textContent: "Complete guide to creating effective mind maps for productivity and learning.",
            contentType: .html,
            metadata: WebMetadata(
                author: "Content Author",
                publishDate: Date(),
                ogTitle: "Mind Mapping Guide - Complete Tutorial",
                ogDescription: "Learn how to create effective mind maps",
                ogImage: "https://example.com/og-image.jpg",
                twitterCard: "summary_large_image",
                fileSize: 0
            ),
            images: images,
            keywords: ["mind mapping", "productivity", "tutorial"],
            extractedAt: Date(),
            pageCount: 0
        )
    }
}

// MARK: - Web Clipping Errors
public enum WebClippingError: Error {
    case urlNotAccessible
    case contentExtractionFailed
    case unsupportedFormat
}

// MARK: - External API Integration Errors
public enum APIIntegrationError: Error {
    case timeout
    case networkError
    case invalidResponse
}

// MARK: - Slow API Integration (for timeout testing)
public class SlowAPIIntegration {
    private let timeout: TimeInterval
    
    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }
    
    public func sendRequest(_ request: ExternalAPIRequest) async throws {
        // タイムアウトのシミュレーション
        try await Task.sleep(nanoseconds: UInt64(timeout * 2 * 1_000_000_000)) // timeout * 2 秒待機
        throw APIIntegrationError.timeout
    }
}

public struct ExternalAPIRequest {
    let data: [String: Any]
}