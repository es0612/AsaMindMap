import Foundation
import Testing
@testable import MindMapCore

struct SearchFilterTests {
    
    @Test("タグフィルターの作成")
    func testTagFilterCreation() {
        // Given
        let tagName = "重要"
        
        // When
        let filter = SearchFilter.tag(tagName)
        
        // Then
        #expect(filter.type == .tag)
        #expect(filter.value == tagName)
        #expect(filter.isValid)
    }
    
    @Test("日付範囲フィルターの作成")
    func testDateRangeFilterCreation() {
        // Given
        let startDate = Date().addingTimeInterval(-86400) // 1日前
        let endDate = Date()
        
        // When
        let filter = SearchFilter.dateRange(startDate, endDate)
        
        // Then
        #expect(filter.type == .dateRange)
        #expect(filter.startDate == startDate)
        #expect(filter.endDate == endDate)
        #expect(filter.isValid)
    }
    
    @Test("ノードタイプフィルターの作成")
    func testNodeTypeFilterCreation() {
        // Given
        let nodeType = NodeType.task
        
        // When
        let filter = SearchFilter.nodeType(nodeType)
        
        // Then
        #expect(filter.type == .nodeType)
        #expect(filter.nodeType == nodeType)
        #expect(filter.isValid)
    }
    
    @Test("作成者フィルターの作成")
    func testCreatorFilterCreation() {
        // Given
        let creatorId = UUID()
        
        // When
        let filter = SearchFilter.creator(creatorId)
        
        // Then
        #expect(filter.type == .creator)
        #expect(filter.creatorId == creatorId)
        #expect(filter.isValid)
    }
    
    @Test("フィルターの組み合わせ")
    func testFilterCombination() {
        // Given
        let tagFilter = SearchFilter.tag("プロジェクト")
        let dateFilter = SearchFilter.dateRange(Date().addingTimeInterval(-86400), Date())
        let typeFilter = SearchFilter.nodeType(.task)
        
        let filters = [tagFilter, dateFilter, typeFilter]
        
        // Then
        #expect(filters.count == 3)
        #expect(filters.allSatisfy { $0.isValid })
        #expect(filters.contains(tagFilter))
        #expect(filters.contains(dateFilter))
        #expect(filters.contains(typeFilter))
    }
    
    @Test("無効なフィルターの検証")
    func testInvalidFilterValidation() {
        // Given & When
        let emptyTagFilter = SearchFilter.tag("")
        let invalidDateFilter = SearchFilter.dateRange(Date(), Date().addingTimeInterval(-86400))
        
        // Then
        #expect(!emptyTagFilter.isValid)
        #expect(!invalidDateFilter.isValid)
    }
    
    @Test("フィルターの等価性")
    func testFilterEquality() {
        // Given
        let tagName = "テスト"
        let filter1 = SearchFilter.tag(tagName)
        let filter2 = SearchFilter.tag(tagName)
        let filter3 = SearchFilter.tag("別のタグ")
        
        // Then
        #expect(filter1 == filter2)
        #expect(filter1 != filter3)
    }
}