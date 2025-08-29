import Foundation
import Testing
@testable import MindMapCore

struct SavedSearchTests {
    
    @Test("保存済み検索の作成と基本プロパティ")
    func testSavedSearchCreation() async throws {
        // Given
        let name = "重要なプロジェクト検索"
        let description = "重要タグが付いたプロジェクト関連のノードを検索"
        let query = "プロジェクト"
        let searchType = SearchType.fullText
        let filters: [SearchFilter] = [.tag("重要")]
        
        // When
        let savedSearch = SavedSearch(
            name: name,
            description: description,
            query: query,
            searchType: searchType,
            filters: filters
        )
        
        // Then
        #expect(savedSearch.id != UUID())
        #expect(savedSearch.name == name)
        #expect(savedSearch.description == description)
        #expect(savedSearch.query == query)
        #expect(savedSearch.searchType == searchType)
        #expect(savedSearch.filters == filters)
        #expect(savedSearch.createdAt <= Date())
        #expect(savedSearch.updatedAt <= Date())
        #expect(savedSearch.useCount == 0)
        #expect(!savedSearch.isShared)
    }
    
    @Test("保存済み検索の名前検証")
    func testSavedSearchNameValidation() async throws {
        // Given
        let validName = "有効な検索名"
        let emptyName = ""
        let whitespaceOnlyName = "   "
        let longName = String(repeating: "a", count: 101)
        
        // When
        let validSearch = SavedSearch(name: validName, description: "", query: "test", searchType: .fullText, filters: [])
        let emptyNameSearch = SavedSearch(name: emptyName, description: "", query: "test", searchType: .fullText, filters: [])
        let whitespaceSearch = SavedSearch(name: whitespaceOnlyName, description: "", query: "test", searchType: .fullText, filters: [])
        let longNameSearch = SavedSearch(name: longName, description: "", query: "test", searchType: .fullText, filters: [])
        
        // Then
        #expect(validSearch.isValidName)
        #expect(!emptyNameSearch.isValidName)
        #expect(!whitespaceSearch.isValidName)
        #expect(!longNameSearch.isValidName)
    }
    
    @Test("保存済み検索のクエリ検証")
    func testSavedSearchQueryValidation() async throws {
        // Given
        let validQuery = "有効なクエリ"
        let emptyQuery = ""
        let whitespaceQuery = "  "
        
        // When
        let validSearch = SavedSearch(name: "テスト", description: "", query: validQuery, searchType: .fullText, filters: [])
        let emptyQuerySearch = SavedSearch(name: "テスト", description: "", query: emptyQuery, searchType: .fullText, filters: [])
        let whitespaceQuerySearch = SavedSearch(name: "テスト", description: "", query: whitespaceQuery, searchType: .fullText, filters: [])
        
        // Then
        #expect(validSearch.isValidQuery)
        #expect(!emptyQuerySearch.isValidQuery)
        #expect(!whitespaceQuerySearch.isValidQuery)
    }
    
    @Test("保存済み検索の使用回数追跡")
    func testSavedSearchUsageTracking() async throws {
        // Given
        var savedSearch = SavedSearch(
            name: "テスト検索",
            description: "",
            query: "テスト",
            searchType: .fullText,
            filters: []
        )
        
        let initialUseCount = savedSearch.useCount
        let initialUsedAt = savedSearch.lastUsedAt
        
        // When
        savedSearch.incrementUseCount()
        
        // Then
        #expect(savedSearch.useCount == initialUseCount + 1)
        #expect(savedSearch.lastUsedAt != initialUsedAt)
        #expect(savedSearch.lastUsedAt != nil)
        
        // When - 複数回使用
        for _ in 1...5 {
            savedSearch.incrementUseCount()
        }
        
        // Then
        #expect(savedSearch.useCount == 6)
    }
    
    @Test("保存済み検索の更新")
    func testSavedSearchUpdate() async throws {
        // Given
        var savedSearch = SavedSearch(
            name: "元の名前",
            description: "元の説明",
            query: "元のクエリ",
            searchType: .fullText,
            filters: [.tag("古いタグ")]
        )
        
        let originalUpdatedAt = savedSearch.updatedAt
        
        // When
        savedSearch.updateSearch(
            name: "新しい名前",
            description: "新しい説明",
            query: "新しいクエリ",
            searchType: .exactMatch,
            filters: [.tag("新しいタグ")]
        )
        
        // Then
        #expect(savedSearch.name == "新しい名前")
        #expect(savedSearch.description == "新しい説明")
        #expect(savedSearch.query == "新しいクエリ")
        #expect(savedSearch.searchType == .exactMatch)
        #expect(savedSearch.filters == [.tag("新しいタグ")])
        #expect(savedSearch.updatedAt > originalUpdatedAt)
    }
    
    @Test("保存済み検索の共有設定")
    func testSavedSearchSharing() async throws {
        // Given
        var savedSearch = SavedSearch(
            name: "共有テスト",
            description: "",
            query: "テスト",
            searchType: .fullText,
            filters: []
        )
        
        #expect(!savedSearch.isShared)
        #expect(savedSearch.sharedAt == nil)
        
        // When
        savedSearch.markAsShared()
        
        // Then
        #expect(savedSearch.isShared)
        #expect(savedSearch.sharedAt != nil)
        
        // When - 共有を解除
        savedSearch.markAsPrivate()
        
        // Then
        #expect(!savedSearch.isShared)
        #expect(savedSearch.sharedAt == nil)
    }
    
    @Test("保存済み検索のSearchRequestへの変換")
    func testSavedSearchToSearchRequest() async throws {
        // Given
        let savedSearch = SavedSearch(
            name: "テスト検索",
            description: "",
            query: "重要なアイデア",
            searchType: .exactMatch,
            filters: [.tag("プロジェクト"), .nodeType(.task)]
        )
        
        // When
        let searchRequest = savedSearch.toSearchRequest()
        
        // Then
        #expect(searchRequest.query == savedSearch.query)
        #expect(searchRequest.type == savedSearch.searchType)
        #expect(searchRequest.filters == savedSearch.filters)
        #expect(searchRequest.isValid)
    }
    
    @Test("保存済み検索コレクションの作成")
    func testSavedSearchCollectionCreation() async throws {
        // Given
        let searches = [
            SavedSearch(name: "検索1", description: "", query: "クエリ1", searchType: .fullText, filters: []),
            SavedSearch(name: "検索2", description: "", query: "クエリ2", searchType: .exactMatch, filters: [.tag("重要")])
        ]
        
        // When
        let collection = SavedSearchCollection(searches: searches)
        
        // Then
        #expect(collection.id != UUID())
        #expect(collection.searches.count == 2)
        #expect(collection.totalCount == 2)
        #expect(collection.sharedCount == 0)
    }
    
    @Test("保存済み検索コレクションの検索追加")
    func testSavedSearchCollectionAddSearch() async throws {
        // Given
        var collection = SavedSearchCollection()
        let newSearch = SavedSearch(name: "新しい検索", description: "", query: "新しいクエリ", searchType: .fullText, filters: [])
        
        #expect(collection.searches.isEmpty)
        
        // When
        collection.addSearch(newSearch)
        
        // Then
        #expect(collection.searches.count == 1)
        #expect(collection.searches.first?.name == "新しい検索")
    }
    
    @Test("保存済み検索コレクションの重複チェック")
    func testSavedSearchCollectionDuplicateCheck() async throws {
        // Given
        var collection = SavedSearchCollection()
        let search1 = SavedSearch(name: "テスト", description: "", query: "同じクエリ", searchType: .fullText, filters: [])
        let search2 = SavedSearch(name: "別の名前", description: "", query: "同じクエリ", searchType: .fullText, filters: [])
        
        collection.addSearch(search1)
        
        // When
        let hasDuplicate = collection.hasDuplicateQuery(search2.query, searchType: search2.searchType, filters: search2.filters)
        
        // Then
        #expect(hasDuplicate)
    }
    
    @Test("保存済み検索コレクションの人気検索")
    func testSavedSearchCollectionPopularSearches() async throws {
        // Given
        var collection = SavedSearchCollection()
        
        var search1 = SavedSearch(name: "人気検索", description: "", query: "人気", searchType: .fullText, filters: [])
        var search2 = SavedSearch(name: "普通検索", description: "", query: "普通", searchType: .fullText, filters: [])
        
        // 使用回数を設定
        for _ in 1...10 {
            search1.incrementUseCount()
        }
        for _ in 1...5 {
            search2.incrementUseCount()
        }
        
        collection.addSearch(search1)
        collection.addSearch(search2)
        
        // When
        let popularSearches = collection.getPopularSearches(limit: 1)
        
        // Then
        #expect(popularSearches.count == 1)
        #expect(popularSearches.first?.name == "人気検索")
    }
    
    @Test("保存済み検索コレクションの検索と削除")
    func testSavedSearchCollectionFindAndRemove() async throws {
        // Given
        var collection = SavedSearchCollection()
        let search = SavedSearch(name: "削除テスト", description: "", query: "テスト", searchType: .fullText, filters: [])
        collection.addSearch(search)
        
        #expect(collection.searches.count == 1)
        
        // When - 検索を見つける
        let foundSearch = collection.findSearchById(search.id)
        
        // Then
        #expect(foundSearch?.name == search.name)
        
        // When - 検索を削除
        let removed = collection.removeSearch(id: search.id)
        
        // Then
        #expect(removed)
        #expect(collection.searches.isEmpty)
    }
}