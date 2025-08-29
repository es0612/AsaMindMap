import Foundation

// MARK: - Smart Collection Repository Protocol

public protocol SmartCollectionRepositoryProtocol {
    func save(_ smartCollection: SmartCollection) async throws
    func findById(_ id: UUID) async throws -> SmartCollection?
    func findAll() async throws -> [SmartCollection]
    func update(_ smartCollection: SmartCollection) async throws
    func delete(id: UUID) async throws
    func updateStatistics(id: UUID, matchingNodesCount: Int, lastExecutedAt: Date) async throws
    func getAutoUpdateCollections() async throws -> [SmartCollection]
    func getUsageStatistics() async throws -> SmartCollectionUsageStatistics
    func getCollectionsByColor(_ color: NodeColor) async throws -> [SmartCollection]
}

// MARK: - Request/Response Types

public struct CreateSmartCollectionRequest: Codable, Equatable {
    public let name: String
    public let description: String
    public let color: NodeColor
    public let rules: [SmartCollectionRule]
    public let matchCondition: SmartCollectionMatchCondition
    public let isAutoUpdate: Bool
    
    public init(
        name: String,
        description: String,
        color: NodeColor,
        rules: [SmartCollectionRule],
        matchCondition: SmartCollectionMatchCondition,
        isAutoUpdate: Bool
    ) {
        self.name = name
        self.description = description
        self.color = color
        self.rules = rules
        self.matchCondition = matchCondition
        self.isAutoUpdate = isAutoUpdate
    }
    
    public var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && 
               trimmedName.count <= SmartCollection.maxNameLength && 
               !rules.isEmpty &&
               rules.count <= SmartCollection.maxRules
    }
}

public struct UpdateSmartCollectionRequest: Codable, Equatable {
    public let id: UUID
    public let name: String
    public let description: String
    public let color: NodeColor
    public let rules: [SmartCollectionRule]
    public let matchCondition: SmartCollectionMatchCondition
    public let isAutoUpdate: Bool
    
    public init(
        id: UUID,
        name: String,
        description: String,
        color: NodeColor,
        rules: [SmartCollectionRule],
        matchCondition: SmartCollectionMatchCondition,
        isAutoUpdate: Bool
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.color = color
        self.rules = rules
        self.matchCondition = matchCondition
        self.isAutoUpdate = isAutoUpdate
    }
    
    public var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && 
               trimmedName.count <= SmartCollection.maxNameLength && 
               !rules.isEmpty &&
               rules.count <= SmartCollection.maxRules
    }
}

// MARK: - Error Types

public enum SmartCollectionError: Error, LocalizedError {
    case invalidRequest
    case collectionNotFound
    case duplicateName
    case saveFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    case executionFailed(String)
    
    public var errorDescription: String? {
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

// MARK: - Use Case Protocols

public protocol CreateSmartCollectionUseCaseProtocol {
    func execute(request: CreateSmartCollectionRequest) async throws -> SmartCollection
}

public protocol GetSmartCollectionsUseCaseProtocol {
    func execute() async throws -> [SmartCollection]
}

public protocol UpdateSmartCollectionUseCaseProtocol {
    func execute(request: UpdateSmartCollectionRequest) async throws
}

public protocol DeleteSmartCollectionUseCaseProtocol {
    func execute(id: UUID) async throws
}

public protocol ExecuteSmartCollectionUseCaseProtocol {
    func execute(id: UUID) async throws -> SearchResponse
}

public protocol ExecuteAutoUpdateCollectionsUseCaseProtocol {
    func execute() async throws -> Int
}

public protocol GetSmartCollectionStatisticsUseCaseProtocol {
    func execute() async throws -> SmartCollectionUsageStatistics
}

public protocol GetCollectionsByColorUseCaseProtocol {
    func execute(color: NodeColor) async throws -> [SmartCollection]
}

// MARK: - Use Case Implementations

/// スマートコレクション作成のユースケース
public final class CreateSmartCollectionUseCase: CreateSmartCollectionUseCaseProtocol {
    private let repository: SmartCollectionRepositoryProtocol
    
    public init(repository: SmartCollectionRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(request: CreateSmartCollectionRequest) async throws -> SmartCollection {
        // リクエスト検証
        guard request.isValid else {
            throw SmartCollectionError.invalidRequest
        }
        
        // 重複名チェック
        let existingCollections = try await repository.findAll()
        let trimmedRequestName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if existingCollections.contains(where: { 
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == trimmedRequestName.lowercased() 
        }) {
            throw SmartCollectionError.duplicateName
        }
        
        // SmartCollection作成
        var smartCollection = SmartCollection(
            name: request.name,
            description: request.description,
            color: request.color
        )
        
        // ルールを追加
        for rule in request.rules {
            smartCollection.addRule(rule)
        }
        
        // 設定を適用
        smartCollection.setMatchCondition(request.matchCondition)
        if request.isAutoUpdate {
            smartCollection.enableAutoUpdate()
        }
        
        do {
            try await repository.save(smartCollection)
            return smartCollection
        } catch {
            throw SmartCollectionError.saveFailed(error.localizedDescription)
        }
    }
}

/// スマートコレクション一覧取得のユースケース
public final class GetSmartCollectionsUseCase: GetSmartCollectionsUseCaseProtocol {
    private let repository: SmartCollectionRepositoryProtocol
    
    public init(repository: SmartCollectionRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> [SmartCollection] {
        return try await repository.findAll()
    }
}

/// スマートコレクション更新のユースケース
public final class UpdateSmartCollectionUseCase: UpdateSmartCollectionUseCaseProtocol {
    private let repository: SmartCollectionRepositoryProtocol
    
    public init(repository: SmartCollectionRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(request: UpdateSmartCollectionRequest) async throws {
        // リクエスト検証
        guard request.isValid else {
            throw SmartCollectionError.invalidRequest
        }
        
        // コレクション存在確認
        guard var existingCollection = try await repository.findById(request.id) else {
            throw SmartCollectionError.collectionNotFound
        }
        
        // 更新実行
        existingCollection.name = request.name
        existingCollection.description = request.description
        existingCollection.color = request.color
        existingCollection.rules = request.rules
        existingCollection.setMatchCondition(request.matchCondition)
        
        if request.isAutoUpdate {
            existingCollection.enableAutoUpdate()
        } else {
            existingCollection.disableAutoUpdate()
        }
        
        do {
            try await repository.update(existingCollection)
        } catch {
            throw SmartCollectionError.updateFailed(error.localizedDescription)
        }
    }
}

/// スマートコレクション削除のユースケース
public final class DeleteSmartCollectionUseCase: DeleteSmartCollectionUseCaseProtocol {
    private let repository: SmartCollectionRepositoryProtocol
    
    public init(repository: SmartCollectionRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(id: UUID) async throws {
        // 存在確認
        guard try await repository.findById(id) != nil else {
            throw SmartCollectionError.collectionNotFound
        }
        
        do {
            try await repository.delete(id: id)
        } catch {
            throw SmartCollectionError.deleteFailed(error.localizedDescription)
        }
    }
}

/// スマートコレクション実行のユースケース
public final class ExecuteSmartCollectionUseCase: ExecuteSmartCollectionUseCaseProtocol {
    private let smartCollectionRepository: SmartCollectionRepositoryProtocol
    private let searchRepository: SearchRepositoryProtocol
    
    public init(
        smartCollectionRepository: SmartCollectionRepositoryProtocol,
        searchRepository: SearchRepositoryProtocol
    ) {
        self.smartCollectionRepository = smartCollectionRepository
        self.searchRepository = searchRepository
    }
    
    public func execute(id: UUID) async throws -> SearchResponse {
        // スマートコレクションを取得
        guard let smartCollection = try await smartCollectionRepository.findById(id) else {
            throw SmartCollectionError.collectionNotFound
        }
        
        // SearchRequestに変換
        let searchRequest = smartCollection.generateSearchRequest()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        do {
            // 検索実行
            let results = try await searchRepository.search(searchRequest)
            let executionTime = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            
            // 統計を更新
            try await smartCollectionRepository.updateStatistics(
                id: id,
                matchingNodesCount: results.count,
                lastExecutedAt: Date()
            )
            
            // SearchResponseを作成
            return SearchResponse(
                query: searchRequest.query,
                searchType: searchRequest.type,
                results: Array(results.prefix(searchRequest.limit)),
                totalResults: results.count,
                appliedFilters: searchRequest.filters,
                executionTimeMs: executionTime
            )
        } catch {
            throw SmartCollectionError.executionFailed(error.localizedDescription)
        }
    }
}

/// 自動更新スマートコレクション実行のユースケース
public final class ExecuteAutoUpdateCollectionsUseCase: ExecuteAutoUpdateCollectionsUseCaseProtocol {
    private let smartCollectionRepository: SmartCollectionRepositoryProtocol
    private let searchRepository: SearchRepositoryProtocol
    
    public init(
        smartCollectionRepository: SmartCollectionRepositoryProtocol,
        searchRepository: SearchRepositoryProtocol
    ) {
        self.smartCollectionRepository = smartCollectionRepository
        self.searchRepository = searchRepository
    }
    
    public func execute() async throws -> Int {
        let autoUpdateCollections = try await smartCollectionRepository.getAutoUpdateCollections()
        var updateCount = 0
        
        for collection in autoUpdateCollections {
            do {
                let searchRequest = collection.generateSearchRequest()
                let results = try await searchRepository.search(searchRequest)
                
                try await smartCollectionRepository.updateStatistics(
                    id: collection.id,
                    matchingNodesCount: results.count,
                    lastExecutedAt: Date()
                )
                
                updateCount += 1
            } catch {
                // エラーをログに記録するが、処理は継続
                continue
            }
        }
        
        return updateCount
    }
}

/// スマートコレクション統計取得のユースケース
public final class GetSmartCollectionStatisticsUseCase: GetSmartCollectionStatisticsUseCaseProtocol {
    private let repository: SmartCollectionRepositoryProtocol
    
    public init(repository: SmartCollectionRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute() async throws -> SmartCollectionUsageStatistics {
        return try await repository.getUsageStatistics()
    }
}

/// 色別スマートコレクション取得のユースケース
public final class GetCollectionsByColorUseCase: GetCollectionsByColorUseCaseProtocol {
    private let repository: SmartCollectionRepositoryProtocol
    
    public init(repository: SmartCollectionRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(color: NodeColor) async throws -> [SmartCollection] {
        return try await repository.getCollectionsByColor(color)
    }
}