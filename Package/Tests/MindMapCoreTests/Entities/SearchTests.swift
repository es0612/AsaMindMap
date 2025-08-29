import Foundation
import Testing
@testable import MindMapCore

struct SearchTests {
    
    @Test("検索クエリの作成")
    func testSearchCreation() {
        // Given
        let query = "重要なアイデア"
        let searchType = SearchType.fullText
        let filters = [SearchFilter.tag("重要")]
        
        // When
        let search = Search(
            query: query,
            type: searchType,
            filters: filters,
            createdAt: Date()
        )
        
        // Then
        #expect(search.query == query)
        #expect(search.type == searchType)
        #expect(search.filters.count == 1)
        #expect(search.id != nil)
        #expect(!search.isEmpty)
    }
    
    @Test("空の検索クエリの検証")
    func testEmptySearchValidation() {
        // Given
        let emptyQuery = ""
        
        // When
        let search = Search(
            query: emptyQuery,
            type: .fullText,
            filters: [],
            createdAt: Date()
        )
        
        // Then
        #expect(search.isEmpty)
        #expect(!search.isValid)
    }
    
    @Test("検索フィルターの適用")
    func testSearchWithFilters() {
        // Given
        let query = "プロジェクト"
        let tagFilter = SearchFilter.tag("ビジネス")
        let dateFilter = SearchFilter.dateRange(Date().addingTimeInterval(-86400), Date())
        let filters = [tagFilter, dateFilter]
        
        // When
        let search = Search(
            query: query,
            type: .fullText,
            filters: filters,
            createdAt: Date()
        )
        
        // Then
        #expect(search.filters.count == 2)
        #expect(search.hasFilter(tagFilter))
        #expect(search.hasFilter(dateFilter))
        #expect(search.isValid)
    }
    
    @Test("検索タイプの指定")
    func testSearchTypes() {
        // Given
        let query = "テスト"
        let fullTextSearch = Search(query: query, type: .fullText, filters: [], createdAt: Date())
        let exactMatch = Search(query: query, type: .exactMatch, filters: [], createdAt: Date())
        let fuzzy = Search(query: query, type: .fuzzy, filters: [], createdAt: Date())
        
        // Then
        #expect(fullTextSearch.type == .fullText)
        #expect(exactMatch.type == .exactMatch)
        #expect(fuzzy.type == .fuzzy)
    }
    
    @Test("検索結果の比較")
    func testSearchEquality() {
        // Given
        let query = "同じクエリ"
        let filters = [SearchFilter.tag("テスト")]
        let date = Date()
        
        let search1 = Search(query: query, type: .fullText, filters: filters, createdAt: date)
        let search2 = Search(query: query, type: .fullText, filters: filters, createdAt: date)
        
        // Then
        #expect(search1.query == search2.query)
        #expect(search1.type == search2.type)
        #expect(search1.filters == search2.filters)
    }
}