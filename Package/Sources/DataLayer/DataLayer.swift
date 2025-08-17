import Foundation
import CoreData
import MindMapCore
import NetworkLayer

// MARK: - DataLayer Module
public struct DataLayer {
    public static let version = "1.0.0"
    
    private init() {}
}

// MARK: - Public Interface
@available(iOS 16.0, macOS 13.0, *)
public extension DataLayer {
    /// DataLayerモジュールの初期化
    static func configure() {
        // Core Dataスタックの初期化
        _ = CoreDataStack.shared
        print("DataLayer module configured with Core Data")
    }
    
    /// Core Data リポジトリファクトリ
    @available(iOS 16.0, macOS 13.0, *)
    static func createCoreDataRepositories() -> RepositoryContainer {
        return RepositoryContainer(
            mindMapRepository: CoreDataMindMapRepository(),
            nodeRepository: CoreDataNodeRepository(),
            mediaRepository: CoreDataMediaRepository(),
            tagRepository: CoreDataTagRepository()
        )
    }
    
    /// インメモリリポジトリファクトリ（テスト用）
    @available(iOS 16.0, macOS 13.0, *)
    static func createInMemoryRepositories() -> RepositoryContainer {
        return RepositoryContainer(
            mindMapRepository: InMemoryMindMapRepository(),
            nodeRepository: InMemoryNodeRepository(),
            mediaRepository: InMemoryMediaRepository(),
            tagRepository: InMemoryTagRepository()
        )
    }
}

// MARK: - Repository Container
public struct RepositoryContainer {
    public let mindMapRepository: MindMapRepositoryProtocol
    public let nodeRepository: NodeRepositoryProtocol
    public let mediaRepository: MediaRepositoryProtocol
    public let tagRepository: TagRepositoryProtocol
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol,
        tagRepository: TagRepositoryProtocol
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.mediaRepository = mediaRepository
        self.tagRepository = tagRepository
    }
}