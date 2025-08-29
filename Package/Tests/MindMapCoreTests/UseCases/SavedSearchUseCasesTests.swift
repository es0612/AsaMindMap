import Foundation
import Testing
@testable import MindMapCore

struct SavedSearchUseCasesTests {
    
    @Test("保存済み検索作成のユースケース")
    func testCreateSavedSearchUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = CreateSavedSearchUseCase(repository: mockRepository)
        
        let request = CreateSavedSearchRequest(
            name: "重要タスク検索",
            description: "重要タグが付いたタスクを検索",
            query: "プロジェクト",
            searchType: .fullText,
            filters: [.tag("重要"), .nodeType(.task)]
        )
        
        // When
        let savedSearch = try await useCase.execute(request: request)
        
        // Then
        #expect(savedSearch.name == request.name)
        #expect(savedSearch.description == request.description)
        #expect(savedSearch.query == request.query)
        #expect(savedSearch.searchType == request.searchType)
        #expect(savedSearch.filters == request.filters)
        #expect(mockRepository.saveCallCount == 1)
    }
    
    @Test("保存済み検索作成の無効なリクエスト")
    func testCreateSavedSearchWithInvalidRequest() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = CreateSavedSearchUseCase(repository: mockRepository)
        
        let invalidRequest = CreateSavedSearchRequest(
            name: "",
            description: "",
            query: "",
            searchType: .fullText,
            filters: []
        )
        
        // When & Then
        await #expect(throws: SavedSearchError.invalidRequest) {
            try await useCase.execute(request: invalidRequest)
        }
        
        #expect(mockRepository.saveCallCount == 0)
    }
    
    @Test("保存済み検索一覧取得のユースケース")
    func testGetSavedSearchesUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = GetSavedSearchesUseCase(repository: mockRepository)
        mockRepository.setupMockSavedSearches()
        
        // When
        let searches = try await useCase.execute()
        
        // Then
        #expect(searches.count > 0)
        #expect(mockRepository.getAllCallCount == 1)
    }
    
    @Test("保存済み検索更新のユースケース")
    func testUpdateSavedSearchUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = UpdateSavedSearchUseCase(repository: mockRepository)
        mockRepository.setupMockSavedSearches()
        
        let searchId = UUID()
        let updateRequest = UpdateSavedSearchRequest(
            id: searchId,
            name: "更新された検索",
            description: "更新された説明",
            query: "更新クエリ",
            searchType: .exactMatch,
            filters: [.tag("更新")]
        )
        
        // When
        try await useCase.execute(request: updateRequest)
        
        // Then
        #expect(mockRepository.updateCallCount == 1)
    }
    
    @Test("保存済み検索削除のユースケース")
    func testDeleteSavedSearchUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = DeleteSavedSearchUseCase(repository: mockRepository)
        
        let searchId = UUID()
        
        // When
        try await useCase.execute(id: searchId)
        
        // Then
        #expect(mockRepository.deleteCallCount == 1)
    }
    
    @Test("保存済み検索実行のユースケース")
    func testExecuteSavedSearchUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let mockSearchRepository = MockMindMapRepository()
        let useCase = ExecuteSavedSearchUseCase(
            savedSearchRepository: mockRepository,
            searchRepository: mockSearchRepository
        )
        
        mockRepository.setupMockSavedSearches()
        let searchId = UUID()
        
        // When
        let results = try await useCase.execute(id: searchId)
        
        // Then
        #expect(mockRepository.findByIdCallCount == 1)
        #expect(mockRepository.incrementUseCountCallCount == 1)
        #expect(!results.results.isEmpty)
    }
    
    @Test("人気の保存済み検索取得のユースケース")
    func testGetPopularSavedSearchesUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = GetPopularSavedSearchesUseCase(repository: mockRepository)
        mockRepository.setupMockSavedSearches()
        
        let limit = 5
        
        // When
        let popularSearches = try await useCase.execute(limit: limit)
        
        // Then
        #expect(popularSearches.count <= limit)
        #expect(mockRepository.getPopularCallCount == 1)
    }
    
    @Test("保存済み検索共有のユースケース")
    func testShareSavedSearchUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = ShareSavedSearchUseCase(repository: mockRepository)
        
        let searchId = UUID()
        
        // When
        try await useCase.shareSearch(id: searchId)
        
        // Then
        #expect(mockRepository.markAsSharedCallCount == 1)
        
        // When - 共有解除
        try await useCase.unshareSearch(id: searchId)
        
        // Then
        #expect(mockRepository.markAsPrivateCallCount == 1)
    }
    
    @Test("保存済み検索統計取得のユースケース")
    func testGetSavedSearchStatisticsUseCase() async throws {
        // Given
        let mockRepository = MockSavedSearchRepository()
        let useCase = GetSavedSearchStatisticsUseCase(repository: mockRepository)
        mockRepository.setupMockSavedSearches()
        
        // When
        let statistics = try await useCase.execute()
        
        // Then
        #expect(statistics.totalSavedSearches >= 0)
        #expect(statistics.totalUses >= 0)
        #expect(statistics.averageUsesPerSearch >= 0)
        #expect(mockRepository.getStatisticsCallCount == 1)
    }
}

// MARK: - Request/Response Types

struct CreateSavedSearchRequest: Equatable {
    let name: String
    let description: String
    let query: String
    let searchType: SearchType
    let filters: [SearchFilter]
}

struct UpdateSavedSearchRequest: Equatable {
    let id: UUID
    let name: String
    let description: String
    let query: String
    let searchType: SearchType
    let filters: [SearchFilter]
}

enum SavedSearchError: Error, LocalizedError {
    case invalidRequest
    case searchNotFound
    case duplicateName
    case saveFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "無効なリクエストです"
        case .searchNotFound:
            return "保存済み検索が見つかりません"
        case .duplicateName:
            return "同じ名前の保存済み検索が既に存在します"
        case .saveFailed(let reason):
            return "保存に失敗しました: \(reason)"
        }
    }
}

// MARK: - Mock Repository for Saved Search

class MockSavedSearchRepository: SavedSearchRepositoryProtocol {
    var savedSearchCollection = SavedSearchCollection()
    var saveCallCount = 0
    var getAllCallCount = 0
    var findByIdCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var incrementUseCountCallCount = 0
    var getPopularCallCount = 0
    var markAsSharedCallCount = 0
    var markAsPrivateCallCount = 0
    var getStatisticsCallCount = 0
    
    func save(_ savedSearch: SavedSearch) async throws {
        saveCallCount += 1
        savedSearchCollection.addSearch(savedSearch)
    }
    
    func findById(_ id: UUID) async throws -> SavedSearch? {
        findByIdCallCount += 1
        return savedSearchCollection.findSearchById(id)
    }
    
    func findAll() async throws -> [SavedSearch] {
        getAllCallCount += 1
        return savedSearchCollection.searches
    }
    
    func update(_ savedSearch: SavedSearch) async throws {
        updateCallCount += 1
        // Mock implementation
    }
    
    func delete(id: UUID) async throws {
        deleteCallCount += 1
        savedSearchCollection.removeSearch(id: id)
    }
    
    func incrementUseCount(id: UUID) async throws {
        incrementUseCountCallCount += 1
        // Mock implementation
    }
    
    func getPopularSearches(limit: Int) async throws -> [SavedSearch] {
        getPopularCallCount += 1
        return savedSearchCollection.getPopularSearches(limit: limit)
    }
    
    func markAsShared(id: UUID) async throws {
        markAsSharedCallCount += 1
        // Mock implementation
    }
    
    func markAsPrivate(id: UUID) async throws {
        markAsPrivateCallCount += 1
        // Mock implementation
    }
    
    func getUsageStatistics() async throws -> SavedSearchUsageStatistics {
        getStatisticsCallCount += 1
        return savedSearchCollection.getUsageStatistics()
    }
    
    func setupMockSavedSearches() {
        let searches = [
            SavedSearch(
                name: "重要タスク",
                description: "重要なタスクを検索",
                query: "タスク",
                searchType: .fullText,
                filters: [.tag("重要"), .nodeType(.task)]
            ),
            SavedSearch(
                name: "プロジェクト検索",
                description: "プロジェクト関連のノード",
                query: "プロジェクト",
                searchType: .exactMatch,
                filters: [.tag("プロジェクト")]
            )
        ]
        
        for search in searches {
            savedSearchCollection.addSearch(search)
        }
    }
}