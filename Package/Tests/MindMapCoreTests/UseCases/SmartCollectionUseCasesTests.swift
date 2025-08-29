import Foundation
import Testing
@testable import MindMapCore

struct SmartCollectionUseCasesTests {
    
    @Test("スマートコレクション作成のユースケース")
    func testCreateSmartCollectionUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let useCase = CreateSmartCollectionUseCase(repository: mockRepository)
        
        let request = CreateSmartCollectionRequest(
            name: "重要タスクコレクション",
            description: "重要なタスクノードを自動収集",
            color: .red,
            rules: [.nodeType(.task), .tagContains("重要")],
            matchCondition: .all,
            isAutoUpdate: true
        )
        
        // When
        let smartCollection = try await useCase.execute(request: request)
        
        // Then
        #expect(smartCollection.name == request.name)
        #expect(smartCollection.description == request.description)
        #expect(smartCollection.color == request.color)
        #expect(smartCollection.rules == request.rules)
        #expect(smartCollection.matchCondition == request.matchCondition)
        #expect(smartCollection.isAutoUpdate == request.isAutoUpdate)
        #expect(mockRepository.saveCallCount == 1)
    }
    
    @Test("スマートコレクション作成の無効なリクエスト")
    func testCreateSmartCollectionWithInvalidRequest() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let useCase = CreateSmartCollectionUseCase(repository: mockRepository)
        
        let invalidRequest = CreateSmartCollectionRequest(
            name: "",
            description: "",
            color: .blue,
            rules: [],
            matchCondition: .all,
            isAutoUpdate: false
        )
        
        // When & Then
        await #expect(throws: SmartCollectionError.invalidRequest) {
            try await useCase.execute(request: invalidRequest)
        }
        
        #expect(mockRepository.saveCallCount == 0)
    }
    
    @Test("スマートコレクション一覧取得のユースケース")
    func testGetSmartCollectionsUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let useCase = GetSmartCollectionsUseCase(repository: mockRepository)
        mockRepository.setupMockCollections()
        
        // When
        let collections = try await useCase.execute()
        
        // Then
        #expect(collections.count > 0)
        #expect(mockRepository.getAllCallCount == 1)
    }
    
    @Test("スマートコレクション更新のユースケース")
    func testUpdateSmartCollectionUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let useCase = UpdateSmartCollectionUseCase(repository: mockRepository)
        mockRepository.setupMockCollections()
        
        let collectionId = UUID()
        let updateRequest = UpdateSmartCollectionRequest(
            id: collectionId,
            name: "更新されたコレクション",
            description: "更新された説明",
            color: .green,
            rules: [.nodeType(.note)],
            matchCondition: .any,
            isAutoUpdate: false
        )
        
        // When
        try await useCase.execute(request: updateRequest)
        
        // Then
        #expect(mockRepository.updateCallCount == 1)
    }
    
    @Test("スマートコレクション削除のユースケース")
    func testDeleteSmartCollectionUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let useCase = DeleteSmartCollectionUseCase(repository: mockRepository)
        
        let collectionId = UUID()
        
        // When
        try await useCase.execute(id: collectionId)
        
        // Then
        #expect(mockRepository.deleteCallCount == 1)
    }
    
    @Test("スマートコレクション実行のユースケース")
    func testExecuteSmartCollectionUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let mockSearchRepository = MockMindMapRepository()
        let useCase = ExecuteSmartCollectionUseCase(
            smartCollectionRepository: mockRepository,
            searchRepository: mockSearchRepository
        )
        
        mockRepository.setupMockCollections()
        let collectionId = UUID()
        
        // When
        let results = try await useCase.execute(id: collectionId)
        
        // Then
        #expect(mockRepository.findByIdCallCount == 1)
        #expect(mockRepository.updateStatisticsCallCount == 1)
        #expect(!results.results.isEmpty)
    }
    
    @Test("自動更新スマートコレクションの実行")
    func testExecuteAutoUpdateCollectionsUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let mockSearchRepository = MockMindMapRepository()
        let useCase = ExecuteAutoUpdateCollectionsUseCase(
            smartCollectionRepository: mockRepository,
            searchRepository: mockSearchRepository
        )
        
        mockRepository.setupMockCollections()
        
        // When
        let updateCount = try await useCase.execute()
        
        // Then
        #expect(updateCount >= 0)
        #expect(mockRepository.getAutoUpdateCollectionsCallCount == 1)
    }
    
    @Test("スマートコレクション統計取得のユースケース")
    func testGetSmartCollectionStatisticsUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let useCase = GetSmartCollectionStatisticsUseCase(repository: mockRepository)
        mockRepository.setupMockCollections()
        
        // When
        let statistics = try await useCase.execute()
        
        // Then
        #expect(statistics.totalCollections >= 0)
        #expect(statistics.totalMatchingNodes >= 0)
        #expect(statistics.averageNodesPerCollection >= 0)
        #expect(mockRepository.getStatisticsCallCount == 1)
    }
    
    @Test("色別スマートコレクション取得のユースケース")
    func testGetCollectionsByColorUseCase() async throws {
        // Given
        let mockRepository = MockSmartCollectionRepository()
        let useCase = GetCollectionsByColorUseCase(repository: mockRepository)
        mockRepository.setupMockCollections()
        
        let color = NodeColor.red
        
        // When
        let collections = try await useCase.execute(color: color)
        
        // Then
        #expect(mockRepository.getByColorCallCount == 1)
        // すべてのコレクションが指定された色を持つことを確認
        #expect(collections.allSatisfy { $0.color == color })
    }
}

// MARK: - Request/Response Types

struct CreateSmartCollectionRequest: Equatable {
    let name: String
    let description: String
    let color: NodeColor
    let rules: [SmartCollectionRule]
    let matchCondition: SmartCollectionMatchCondition
    let isAutoUpdate: Bool
}

struct UpdateSmartCollectionRequest: Equatable {
    let id: UUID
    let name: String
    let description: String
    let color: NodeColor
    let rules: [SmartCollectionRule]
    let matchCondition: SmartCollectionMatchCondition
    let isAutoUpdate: Bool
}

enum SmartCollectionError: Error, LocalizedError {
    case invalidRequest
    case collectionNotFound
    case duplicateName
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case executionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidRequest:
            return "無効なリクエストです"
        case .collectionNotFound:
            return "スマートコレクションが見つかりません"
        case .duplicateName:
            return "同じ名前のスマートコレクションが既に存在します"
        case .saveFailed(let reason):
            return "保存に失敗しました: \(reason)"
        case .updateFailed(let reason):
            return "更新に失敗しました: \(reason)"
        case .deleteFailed(let reason):
            return "削除に失敗しました: \(reason)"
        case .executionFailed(let reason):
            return "実行に失敗しました: \(reason)"
        }
    }
}

// MARK: - Mock Repository for Smart Collection

class MockSmartCollectionRepository: SmartCollectionRepositoryProtocol {
    var smartCollectionManager = SmartCollectionManager()
    var saveCallCount = 0
    var getAllCallCount = 0
    var findByIdCallCount = 0
    var updateCallCount = 0
    var deleteCallCount = 0
    var updateStatisticsCallCount = 0
    var getAutoUpdateCollectionsCallCount = 0
    var getStatisticsCallCount = 0
    var getByColorCallCount = 0
    
    func save(_ smartCollection: SmartCollection) async throws {
        saveCallCount += 1
        smartCollectionManager.addCollection(smartCollection)
    }
    
    func findById(_ id: UUID) async throws -> SmartCollection? {
        findByIdCallCount += 1
        return smartCollectionManager.findCollectionById(id)
    }
    
    func findAll() async throws -> [SmartCollection] {
        getAllCallCount += 1
        return smartCollectionManager.collections
    }
    
    func update(_ smartCollection: SmartCollection) async throws {
        updateCallCount += 1
        smartCollectionManager.updateCollection(smartCollection)
    }
    
    func delete(id: UUID) async throws {
        deleteCallCount += 1
        smartCollectionManager.removeCollection(id: id)
    }
    
    func updateStatistics(id: UUID, matchingNodesCount: Int, lastExecutedAt: Date) async throws {
        updateStatisticsCallCount += 1
        // Mock implementation
    }
    
    func getAutoUpdateCollections() async throws -> [SmartCollection] {
        getAutoUpdateCollectionsCallCount += 1
        return smartCollectionManager.getAutoUpdateCollections()
    }
    
    func getUsageStatistics() async throws -> SmartCollectionUsageStatistics {
        getStatisticsCallCount += 1
        return smartCollectionManager.getUsageStatistics()
    }
    
    func getCollectionsByColor(_ color: NodeColor) async throws -> [SmartCollection] {
        getByColorCallCount += 1
        return smartCollectionManager.getCollectionsByColor(color)
    }
    
    func setupMockCollections() {
        let collections = [
            SmartCollection(
                name: "重要タスク",
                description: "重要なタスクノード",
                color: .red
            ),
            SmartCollection(
                name: "プロジェクトノート",
                description: "プロジェクト関連のノート",
                color: .blue
            ),
            SmartCollection(
                name: "完了タスク",
                description: "完了したタスク",
                color: .green
            )
        ]
        
        for collection in collections {
            smartCollectionManager.addCollection(collection)
        }
    }
}