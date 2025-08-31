import Testing
import Foundation
@testable import MindMapCore

/// Webコンテンツ統合テストスイート
/// Webクリップ・ブックマーク・外部ツール連携機能のTDDテスト
@Suite("Webコンテンツ統合テスト")
struct WebContentIntegrationTests {
    
    // MARK: - Web Clipping Tests
    
    @Test("Webクリッピング: URLからコンテンツ抽出")
    func testWebClippingExtraction() async throws {
        // Given
        let webClipper = WebContentClipper()
        let url = URL(string: "https://example.com/article")!
        let clippingRequest = WebClippingRequest(
            url: url,
            extractionMode: .fullContent,
            includeImages: true
        )
        
        // When
        let result = try await webClipper.extractContent(clippingRequest)
        
        // Then
        #expect(result.title != nil)
        #expect(result.content.isEmpty == false)
        #expect(result.metadata.author != nil)
        #expect(result.metadata.publishDate != nil)
        #expect(result.images.count > 0)
        #expect(result.extractedAt != nil)
    }
    
    @Test("Webクリッピング: メタデータとOGPタグ解析")
    func testWebClippingMetadataExtraction() async throws {
        // Given
        let webClipper = WebContentClipper()
        let url = URL(string: "https://blog.example.com/mindmapping-guide")!
        let clippingRequest = WebClippingRequest(
            url: url,
            extractionMode: .metadataOnly,
            includeImages: false
        )
        
        // When
        let result = try await webClipper.extractContent(clippingRequest)
        
        // Then
        #expect(result.metadata.ogTitle != nil)
        #expect(result.metadata.ogDescription != nil)
        #expect(result.metadata.ogImage != nil)
        #expect(result.metadata.twitterCard != nil)
        #expect(result.keywords.count > 0)
    }
    
    @Test("Webクリッピング: PDFドキュメント処理")
    func testWebClippingPDFExtraction() async throws {
        // Given
        let webClipper = WebContentClipper()
        let pdfUrl = URL(string: "https://example.com/document.pdf")!
        let clippingRequest = WebClippingRequest(
            url: pdfUrl,
            extractionMode: .textOnly,
            includeImages: false
        )
        
        // When
        let result = try await webClipper.extractContent(clippingRequest)
        
        // Then
        #expect(result.contentType == .pdf)
        #expect(result.textContent.isEmpty == false)
        #expect(result.pageCount > 0)
        #expect(result.metadata.fileSize > 0)
    }
    
    // MARK: - Bookmark Management Tests
    
    @Test("ブックマーク管理: URLブックマーク作成")
    func testBookmarkCreation() async throws {
        // Given
        let bookmarkManager = BookmarkManager()
        let url = URL(string: "https://mindmapping.com/tutorial")!
        let bookmarkRequest = CreateBookmarkRequest(
            url: url,
            title: "マインドマップ作成チュートリアル",
            tags: ["tutorial", "mindmap", "learning"],
            category: .educational
        )
        
        // When
        let bookmark = try await bookmarkManager.createBookmark(bookmarkRequest)
        
        // Then
        #expect(bookmark.id != nil)
        #expect(bookmark.url == url)
        #expect(bookmark.title == "マインドマップ作成チュートリアル")
        #expect(bookmark.tags.contains("tutorial"))
        #expect(bookmark.category == .educational)
        #expect(bookmark.createdAt != nil)
    }
    
    @Test("ブックマーク管理: 自動分類とタグ付け")
    func testBookmarkAutoCategorizationAndTagging() async throws {
        // Given
        let bookmarkManager = BookmarkManager()
        let aiCategorizer = AIBookmarkCategorizer()
        let url = URL(string: "https://developer.apple.com/swiftui")!
        let bookmarkRequest = CreateBookmarkRequest(
            url: url,
            title: nil, // 自動取得
            tags: [], // AI自動生成
            category: nil // AI分類
        )
        
        // When
        let bookmark = try await bookmarkManager.createBookmarkWithAI(bookmarkRequest, categorizer: aiCategorizer)
        
        // Then
        #expect(bookmark.title?.isEmpty == false)
        #expect(bookmark.tags.contains("development"))
        #expect(bookmark.tags.contains("swiftui"))
        #expect(bookmark.category == .development)
        #expect(bookmark.aiGenerated == true)
    }
    
    @Test("ブックマーク管理: コレクション管理")
    func testBookmarkCollectionManagement() async throws {
        // Given
        let bookmarkManager = BookmarkManager()
        let collection = try await bookmarkManager.createCollection(
            name: "iOS Development Resources",
            description: "Useful resources for iOS development",
            isPublic: false
        )
        
        let bookmark1 = createTestBookmark(title: "Swift Guide", url: "https://swift.org")
        let bookmark2 = createTestBookmark(title: "UIKit Documentation", url: "https://developer.apple.com/uikit")
        
        // When
        try await bookmarkManager.addToCollection(collection.id, bookmarks: [bookmark1, bookmark2])
        let retrievedCollection = try await bookmarkManager.getCollection(collection.id)
        
        // Then
        #expect(retrievedCollection.bookmarks.count == 2)
        #expect(retrievedCollection.name == "iOS Development Resources")
        #expect(retrievedCollection.isPublic == false)
    }
    
    // MARK: - External Tool Integration Tests
    
    @Test("外部ツール統合: Zapier Webhook統合")
    func testZapierWebhookIntegration() async throws {
        // Given
        let zapierIntegration = ZapierIntegration()
        let mindMap = createTestMindMap()
        let triggerRequest = ZapierTriggerRequest(
            webhookUrl: "https://hooks.zapier.com/hooks/catch/123456/test",
            mindMap: mindMap,
            triggerEvent: .mindMapCreated,
            customFields: ["project": "TestProject", "priority": "high"]
        )
        
        // When
        let result = try await zapierIntegration.triggerWebhook(triggerRequest)
        
        // Then
        #expect(result.status == .success)
        #expect(result.webhookId != nil)
        #expect(result.responseTime < 5.0) // 5秒以内
    }
    
    @Test("外部ツール統合: IFTTT連携")
    func testIFTTTIntegration() async throws {
        // Given
        let iftttIntegration = IFTTTIntegration(apiKey: "test-ifttt-key")
        let mindMap = createTestMindMap()
        let triggerRequest = IFTTTTriggerRequest(
            eventName: "mindmap_completed",
            mindMap: mindMap,
            values: ["map_title": mindMap.title, "node_count": "\(mindMap.nodes.count)"]
        )
        
        // When
        let result = try await iftttIntegration.triggerEvent(triggerRequest)
        
        // Then
        #expect(result.success == true)
        #expect(result.eventId != nil)
        #expect(result.triggeredAt != nil)
    }
    
    @Test("外部ツール統合: Airtable データベース連携")
    func testAirtableIntegration() async throws {
        // Given
        let airtableIntegration = AirtableIntegration(apiKey: "test-airtable-key")
        let mindMap = createTestMindMap()
        let syncRequest = AirtableSyncRequest(
            baseId: "app123456789",
            tableId: "tbl987654321",
            mindMap: mindMap,
            fieldMapping: [
                "Title": "title",
                "Created": "createdAt",
                "Nodes": "nodeCount"
            ]
        )
        
        // When
        let result = try await airtableIntegration.syncMindMap(syncRequest)
        
        // Then
        #expect(result.recordId != nil)
        #expect(result.fieldsUpdated.count == 3)
        #expect(result.success == true)
    }
    
    // MARK: - Content Analysis Tests
    
    @Test("コンテンツ分析: 自動キーワード抽出")
    func testAutomaticKeywordExtraction() async throws {
        // Given
        let contentAnalyzer = ContentAnalyzer()
        let webContent = WebContent(
            title: "Getting Started with Mind Mapping",
            content: "Mind mapping is a powerful technique for organizing thoughts and ideas. It helps visualize connections between concepts and improves creative thinking.",
            url: URL(string: "https://example.com")!
        )
        
        // When
        let analysis = try await contentAnalyzer.analyzeContent(webContent)
        
        // Then
        #expect(analysis.keywords.contains("mind mapping"))
        #expect(analysis.keywords.contains("organize"))
        #expect(analysis.keywords.contains("creative thinking"))
        #expect(analysis.sentiment > 0.5) // ポジティブ
        #expect(analysis.readingTime > 0)
        #expect(analysis.topics.contains(.productivity))
    }
    
    @Test("コンテンツ分析: 言語検出と翻訳")
    func testLanguageDetectionAndTranslation() async throws {
        // Given
        let contentAnalyzer = ContentAnalyzer()
        let multilingualContent = WebContent(
            title: "Mapas Mentales: Una Guía Completa",
            content: "Los mapas mentales son una herramienta poderosa para organizar información y estimular la creatividad.",
            url: URL(string: "https://ejemplo.com")!
        )
        
        // When
        let analysis = try await contentAnalyzer.analyzeContent(multilingualContent)
        
        // Then
        #expect(analysis.detectedLanguage == "es")
        #expect(analysis.translatedTitle?.isEmpty == false)
        #expect(analysis.translatedContent?.isEmpty == false)
        #expect(analysis.confidence > 0.8)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Webクリッピングエラー: 無効なURL処理")
    func testWebClippingInvalidURL() async throws {
        // Given
        let webClipper = WebContentClipper()
        let invalidUrl = URL(string: "https://nonexistent-domain-12345.com")!
        let clippingRequest = WebClippingRequest(
            url: invalidUrl,
            extractionMode: .fullContent,
            includeImages: false
        )
        
        // When & Then
        await #expect(throws: WebClippingError.urlNotAccessible) {
            try await webClipper.extractContent(clippingRequest)
        }
    }
    
    @Test("外部API統合エラー: タイムアウト処理")
    func testExternalAPITimeout() async throws {
        // Given
        let slowApiIntegration = SlowAPIIntegration(timeout: 1.0) // 1秒タイムアウト
        let request = ExternalAPIRequest(data: ["test": "data"])
        
        // When & Then
        await #expect(throws: APIIntegrationError.timeout) {
            try await slowApiIntegration.sendRequest(request)
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestMindMap() -> MindMap {
        let rootNode = Node(
            id: UUID(),
            text: "Web統合テスト",
            position: CGPoint(x: 0, y: 0)
        )
        
        return MindMap(
            id: UUID(),
            title: "Web統合テストマップ",
            rootNode: rootNode,
            nodes: [rootNode],
            tags: ["test", "web-integration"],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestBookmark(title: String, url: String) -> Bookmark {
        return Bookmark(
            id: UUID(),
            url: URL(string: url)!,
            title: title,
            tags: ["test"],
            category: .development,
            createdAt: Date()
        )
    }
}