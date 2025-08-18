import Foundation
import CoreGraphics

// MARK: - Move Node Use Case Implementation
public final class MoveNodeUseCase: MoveNodeUseCaseProtocol {
    private let nodeRepository: NodeRepositoryProtocol
    private let nodeValidator: NodeValidator
    
    public init(
        nodeRepository: NodeRepositoryProtocol,
        nodeValidator: NodeValidator = NodeValidator()
    ) {
        self.nodeRepository = nodeRepository
        self.nodeValidator = nodeValidator
    }
    
    public func execute(_ request: MoveNodeRequest) async throws -> MoveNodeResponse {
        // 1. ノードの存在確認
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw MindMapError.validationError("指定されたノードが見つかりません")
        }
        
        // 2. 新しい親ノードの存在確認（指定されている場合）
        var newParent: Node?
        if let newParentID = request.newParentID {
            guard let parent = try await nodeRepository.findByID(newParentID) else {
                throw MindMapError.validationError("指定された新しい親ノードが見つかりません")
            }
            newParent = parent
            
            // 3. 循環参照のチェック
            if try await wouldCreateCycle(nodeID: request.nodeID, newParentID: newParentID) {
                throw MindMapError.validationError("循環参照が発生するため移動できません")
            }
        }
        
        var affectedNodes: [Node] = []
        
        // 4. 現在の親ノードから除去
        if let currentParentID = node.parentID,
           var currentParent = try await nodeRepository.findByID(currentParentID) {
            currentParent.removeChild(request.nodeID)
            try await nodeRepository.save(currentParent)
            affectedNodes.append(currentParent)
        }
        
        // 5. 新しい親ノードに追加
        if var parent = newParent {
            parent.addChild(request.nodeID)
            try await nodeRepository.save(parent)
            affectedNodes.append(parent)
        }
        
        // 6. ノードの更新
        node.parentID = request.newParentID
        node.updatePosition(request.newPosition)
        
        // 7. バリデーション
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "ノードの移動に失敗しました")
        }
        
        // 8. ノードの保存
        try await nodeRepository.save(node)
        
        return MoveNodeResponse(node: node, affectedNodes: affectedNodes)
    }
    
    // MARK: - Private Methods
    private func wouldCreateCycle(nodeID: UUID, newParentID: UUID) async throws -> Bool {
        // 新しい親ノードが移動対象ノードの子孫かどうかをチェック
        return try await isDescendant(ancestorID: nodeID, descendantID: newParentID)
    }
    
    private func isDescendant(ancestorID: UUID, descendantID: UUID) async throws -> Bool {
        let children = try await nodeRepository.findChildren(of: ancestorID)
        
        for child in children {
            if child.id == descendantID {
                return true
            }
            
            if try await isDescendant(ancestorID: child.id, descendantID: descendantID) {
                return true
            }
        }
        
        return false
    }
}