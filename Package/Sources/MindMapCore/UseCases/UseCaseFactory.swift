import Foundation
import CloudKit

// MARK: - Use Case Factory
public final class UseCaseFactory {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol
    private let shareURLGenerator: ShareURLGeneratorProtocol
    private let cloudKitSyncManager: CloudKitSyncManagerProtocol
    private let sharingManager: SharingManagerProtocol
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol,
        tagRepository: TagRepositoryProtocol,
        shareURLGenerator: ShareURLGeneratorProtocol = DefaultShareURLGenerator(),
        cloudKitSyncManager: CloudKitSyncManagerProtocol? = nil,
        sharingManager: SharingManagerProtocol? = nil
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.mediaRepository = mediaRepository
        self.tagRepository = tagRepository
        self.shareURLGenerator = shareURLGenerator
        self.cloudKitSyncManager = cloudKitSyncManager ?? CloudKitSyncManager(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
        self.sharingManager = sharingManager ?? SharingManager(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
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
    
    // MARK: - Media Use Cases
    public func makeAddMediaToNodeUseCase() -> AddMediaToNodeUseCaseProtocol {
        AddMediaToNodeUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
    }
    
    public func makeRemoveMediaFromNodeUseCase() -> RemoveMediaFromNodeUseCaseProtocol {
        RemoveMediaFromNodeUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
    }
    
    public func makeGetNodeMediaUseCase() -> GetNodeMediaUseCaseProtocol {
        GetNodeMediaUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
    }
    
    public func makeValidateMediaURLUseCase() -> ValidateMediaURLUseCaseProtocol {
        ValidateMediaURLUseCase()
    }
    
    // MARK: - Quick Entry Use Cases
    public func makeParseTextUseCase() -> ParseTextUseCaseProtocol {
        ParseTextUseCase()
    }
    
    public func makeGenerateMindMapFromTextUseCase() -> GenerateMindMapFromTextUseCaseProtocol {
        GenerateMindMapFromTextUseCase(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
    }
    
    // MARK: - Export/Import Use Cases
    public func makeExportMindMapUseCase() -> ExportMindMapUseCaseProtocol {
        ExportMindMapUseCase(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
    }
    
    public func makeImportMindMapUseCase() -> ImportMindMapUseCaseProtocol {
        ImportMindMapUseCase(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
    }
    
    public func makeShareExportUseCase() -> ShareExportUseCaseProtocol {
        ShareExportUseCase(
            exportUseCase: makeExportMindMapUseCase()
        )
    }
    
    // MARK: - CloudKit Sync
    public func makeCloudKitSyncManager() -> CloudKitSyncManagerProtocol {
        return cloudKitSyncManager
    }
    
    // MARK: - Sharing
    public func makeSharingManager() -> SharingManagerProtocol {
        return sharingManager
    }
}