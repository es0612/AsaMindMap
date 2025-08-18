import Foundation

// MARK: - Use Case Factory
public final class UseCaseFactory {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol
    private let shareURLGenerator: ShareURLGeneratorProtocol
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol,
        tagRepository: TagRepositoryProtocol,
        shareURLGenerator: ShareURLGeneratorProtocol = DefaultShareURLGenerator()
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.mediaRepository = mediaRepository
        self.tagRepository = tagRepository
        self.shareURLGenerator = shareURLGenerator
    }
    
    // MARK: - Node Use Cases
    public func makeCreateNodeUseCase() -> CreateNodeUseCaseProtocol {
        CreateNodeUseCase(
            nodeRepository: nodeRepository,
            mindMapRepository: mindMapRepository
        )
    }
    
    public func makeUpdateNodeUseCase() -> UpdateNodeUseCaseProtocol {
        UpdateNodeUseCase(nodeRepository: nodeRepository)
    }
    
    public func makeDeleteNodeUseCase() -> DeleteNodeUseCaseProtocol {
        DeleteNodeUseCase(
            nodeRepository: nodeRepository,
            mindMapRepository: mindMapRepository,
            mediaRepository: mediaRepository
        )
    }
    
    public func makeMoveNodeUseCase() -> MoveNodeUseCaseProtocol {
        MoveNodeUseCase(nodeRepository: nodeRepository)
    }
    
    // MARK: - MindMap Use Cases
    public func makeCreateMindMapUseCase() -> CreateMindMapUseCaseProtocol {
        CreateMindMapUseCase(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
    }
    
    public func makeUpdateMindMapUseCase() -> UpdateMindMapUseCaseProtocol {
        UpdateMindMapUseCase(mindMapRepository: mindMapRepository)
    }
    
    public func makeDeleteMindMapUseCase() -> DeleteMindMapUseCaseProtocol {
        DeleteMindMapUseCase(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
    }
    
    public func makeShareMindMapUseCase() -> ShareMindMapUseCaseProtocol {
        ShareMindMapUseCase(
            mindMapRepository: mindMapRepository,
            shareURLGenerator: shareURLGenerator
        )
    }
    
    public func makeGetMindMapUseCase() -> GetMindMapUseCaseProtocol {
        GetMindMapUseCase(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
    }
    
    public func makeListMindMapsUseCase() -> ListMindMapsUseCaseProtocol {
        ListMindMapsUseCase(mindMapRepository: mindMapRepository)
    }
}