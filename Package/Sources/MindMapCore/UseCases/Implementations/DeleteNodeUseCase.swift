import Foundation

// MARK: - Delete Node Use Case Implementation
public final class DeleteNodeUseCase: DeleteNodeUseCaseProtocol {
    private let nodeRepository: NodeRepositoryProtocol
    private let mindMapRepository: MindMapRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    public init(
        nodeRepository: NodeRepositoryProtocol,
        mindMapRepository: MindMapRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol
    ) {
        self.nodeRepository = nodeRepository
        self.mindMapRepository = mindMapRepository
        self.mediaRepository = mediaRepository
    }
    
    public func execute(_ request: DeleteNodeRequest) async throws -> DeleteNodeResponse {
        // 1. MindMapの存在確認
        guard var mindMap = try await mindMapRepository.findByID(request.mindMapID) else {
            throw MindMapError.validationError("指定されたマインドマップが見つかりません")
        }
        
        // 2. ノードの存在確認
        guard let nodeToDelete = try await nodeRepository.findByID(request.nodeID) else {
            throw MindMapError.validationError("指定されたノードが見つかりません")
        }
        
        // 3. 削除対象ノードのIDを収集
        var nodesToDelete: Set<UUID> = [request.nodeID]
        
        if request.deleteChildren {
            // 子ノードを再帰的に収集
            let childNodes = try await collectChildNodes(nodeID: request.nodeID)
            nodesToDelete.formUnion(childNodes)
        } else {
            // 子ノードの親を更新（親ノードの親に移動）
            let children = try await nodeRepository.findChildren(of: request.nodeID)
            for var child in children {
                child.parentID = nodeToDelete.parentID
                try await nodeRepository.save(child)
                
                // 親ノードがある場合は子リストを更新
                if let parentID = nodeToDelete.parentID,
                   var parent = try await nodeRepository.findByID(parentID) {
                    parent.addChild(child.id)
                    try await nodeRepository.save(parent)
                }
            }
        }
        
        // 4. 親ノードから削除対象ノードを除去
        if let parentID = nodeToDelete.parentID,
           var parent = try await nodeRepository.findByID(parentID) {
            parent.removeChild(request.nodeID)
            try await nodeRepository.save(parent)
        }
        
        // 5. ルートノードの処理
        if mindMap.rootNodeID == request.nodeID {
            // 子ノードがある場合は最初の子をルートに設定
            if !request.deleteChildren {
                let children = try await nodeRepository.findChildren(of: request.nodeID)
                mindMap.rootNodeID = children.first?.id
            } else {
                mindMap.rootNodeID = nil
            }
        }
        
        // 6. MindMapからノードを除去
        for nodeID in nodesToDelete {
            mindMap.removeNode(nodeID)
        }
        
        // 7. 関連メディアの削除
        var deletedMediaIDs: Set<UUID> = []
        for nodeID in nodesToDelete {
            if let node = try await nodeRepository.findByID(nodeID) {
                for mediaID in node.mediaIDs {
                    try await mediaRepository.delete(mediaID)
                    deletedMediaIDs.insert(mediaID)
                    mindMap.removeMedia(mediaID)
                }
            }
        }
        
        // 8. ノードの削除
        try await nodeRepository.deleteAll(Array(nodesToDelete))
        
        // 9. MindMapの保存
        try await mindMapRepository.save(mindMap)
        
        return DeleteNodeResponse(
            deletedNodeIDs: nodesToDelete,
            updatedMindMap: mindMap
        )
    }
    
    // MARK: - Private Methods
    private func collectChildNodes(nodeID: UUID) async throws -> Set<UUID> {
        var allChildren: Set<UUID> = []
        let directChildren = try await nodeRepository.findChildren(of: nodeID)
        
        for child in directChildren {
            allChildren.insert(child.id)
            let grandChildren = try await collectChildNodes(nodeID: child.id)
            allChildren.formUnion(grandChildren)
        }
        
        return allChildren
    }
}