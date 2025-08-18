import Foundation

// MARK: - Delete MindMap Use Case Implementation
public final class DeleteMindMapUseCase: DeleteMindMapUseCaseProtocol {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.mediaRepository = mediaRepository
    }
    
    public func execute(_ request: DeleteMindMapRequest) async throws -> DeleteMindMapResponse {
        // 1. MindMapの存在確認
        guard try await mindMapRepository.exists(request.mindMapID) else {
            throw MindMapError.validationError("指定されたマインドマップが見つかりません")
        }
        
        // 2. 関連するノードを取得
        let nodes = try await nodeRepository.findByMindMapID(request.mindMapID)
        let nodeIDs = Set(nodes.map { $0.id })
        
        // 3. 関連するメディアを収集
        var mediaIDs: Set<UUID> = []
        for node in nodes {
            mediaIDs.formUnion(node.mediaIDs)
        }
        
        // 4. メディアの削除
        for mediaID in mediaIDs {
            try await mediaRepository.delete(mediaID)
        }
        
        // 5. ノードの削除
        try await nodeRepository.deleteAll(Array(nodeIDs))
        
        // 6. MindMapの削除
        try await mindMapRepository.delete(request.mindMapID)
        
        return DeleteMindMapResponse(
            deletedMindMapID: request.mindMapID,
            deletedNodeIDs: nodeIDs,
            deletedMediaIDs: mediaIDs
        )
    }
}