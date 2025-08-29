import Foundation
import Testing
@testable import MindMapCore

struct SearchResultTests {
    
    @Test("検索結果の作成")
    func testSearchResultCreation() {
        // Given
        let nodeId = UUID()
        let mindMapId = UUID()
        let relevanceScore = 0.85
        let matchType = SearchMatchType.title
        let highlightedText = "重要なアイデア"
        
        // When
        let result = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: relevanceScore,
            matchType: matchType,
            highlightedText: highlightedText,
            matchPosition: 0
        )
        
        // Then
        #expect(result.nodeId == nodeId)
        #expect(result.mindMapId == mindMapId)
        #expect(result.relevanceScore == relevanceScore)
        #expect(result.matchType == matchType)
        #expect(result.highlightedText == highlightedText)
        #expect(result.id != nil)
    }
    
    @Test("関連性スコアの検証")
    func testRelevanceScoreValidation() {
        // Given
        let nodeId = UUID()
        let mindMapId = UUID()
        
        // When & Then
        let validResult = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: 0.75,
            matchType: .content,
            highlightedText: "テスト",
            matchPosition: 5
        )
        #expect(validResult.isRelevant)
        
        let lowScoreResult = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: 0.1,
            matchType: .content,
            highlightedText: "テスト",
            matchPosition: 5
        )
        #expect(!lowScoreResult.isRelevant)
    }
    
    @Test("マッチタイプによる結果分類")
    func testMatchTypeClassification() {
        // Given
        let nodeId = UUID()
        let mindMapId = UUID()
        
        let titleMatch = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: 0.9,
            matchType: .title,
            highlightedText: "タイトルマッチ",
            matchPosition: 0
        )
        
        let contentMatch = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: 0.7,
            matchType: .content,
            highlightedText: "コンテンツマッチ",
            matchPosition: 10
        )
        
        let tagMatch = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: 0.6,
            matchType: .tag,
            highlightedText: "タグマッチ",
            matchPosition: 0
        )
        
        // Then
        #expect(titleMatch.matchType == .title)
        #expect(contentMatch.matchType == .content)
        #expect(tagMatch.matchType == .tag)
        
        #expect(titleMatch.priority > contentMatch.priority)
        #expect(contentMatch.priority > tagMatch.priority)
    }
    
    @Test("検索結果のソート")
    func testSearchResultSorting() {
        // Given
        let nodeId1 = UUID()
        let nodeId2 = UUID()
        let nodeId3 = UUID()
        let mindMapId = UUID()
        
        let results = [
            SearchResult(
                nodeId: nodeId1,
                mindMapId: mindMapId,
                relevanceScore: 0.5,
                matchType: .content,
                highlightedText: "低スコア",
                matchPosition: 0
            ),
            SearchResult(
                nodeId: nodeId2,
                mindMapId: mindMapId,
                relevanceScore: 0.9,
                matchType: .title,
                highlightedText: "高スコア",
                matchPosition: 0
            ),
            SearchResult(
                nodeId: nodeId3,
                mindMapId: mindMapId,
                relevanceScore: 0.7,
                matchType: .tag,
                highlightedText: "中スコア",
                matchPosition: 0
            )
        ]
        
        // When
        let sortedResults = results.sorted()
        
        // Then
        #expect(sortedResults[0].relevanceScore == 0.9)
        #expect(sortedResults[1].relevanceScore == 0.7)
        #expect(sortedResults[2].relevanceScore == 0.5)
    }
    
    @Test("ハイライトテキストの処理")
    func testHighlightTextProcessing() {
        // Given
        let originalText = "これは重要なアイデアです"
        let searchTerm = "重要"
        let matchPosition = 2
        
        // When
        let result = SearchResult(
            nodeId: UUID(),
            mindMapId: UUID(),
            relevanceScore: 0.8,
            matchType: .content,
            highlightedText: originalText,
            matchPosition: matchPosition
        )
        
        let highlighted = result.getHighlightedText(searchTerm: searchTerm)
        
        // Then
        #expect(highlighted.contains(searchTerm))
        #expect(result.matchPosition == matchPosition)
    }
    
    @Test("検索結果の等価性")
    func testSearchResultEquality() {
        // Given
        let nodeId = UUID()
        let mindMapId = UUID()
        
        let result1 = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: 0.8,
            matchType: .title,
            highlightedText: "同じ結果",
            matchPosition: 0
        )
        
        let result2 = SearchResult(
            nodeId: nodeId,
            mindMapId: mindMapId,
            relevanceScore: 0.8,
            matchType: .title,
            highlightedText: "同じ結果",
            matchPosition: 0
        )
        
        let result3 = SearchResult(
            nodeId: UUID(),
            mindMapId: mindMapId,
            relevanceScore: 0.8,
            matchType: .title,
            highlightedText: "異なる結果",
            matchPosition: 0
        )
        
        // Then
        #expect(result1.nodeId == result2.nodeId)
        #expect(result1.nodeId != result3.nodeId)
    }
}