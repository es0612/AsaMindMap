import Foundation
import CoreGraphics

// MARK: - Update Node Use Case Implementation
public final class UpdateNodeUseCase: UpdateNodeUseCaseProtocol {
    private let nodeRepository: NodeRepositoryProtocol
    private let nodeValidator: NodeValidator
    
    public init(
        nodeRepository: NodeRepositoryProtocol,
        nodeValidator: NodeValidator = NodeValidator()
    ) {
        self.nodeRepository = nodeRepository
        self.nodeValidator = nodeValidator
    }
    
    public func execute(_ request: UpdateNodeRequest) async throws -> UpdateNodeResponse {
        // 1. ノードの存在確認
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw MindMapError.validationError("指定されたノードが見つかりません")
        }
        
        // 2. ノードの更新
        var hasChanges = false
        
        if let text = request.text {
            node.updateText(text)
            hasChanges = true
        }
        
        if let position = request.position {
            node.updatePosition(position)
            hasChanges = true
        }
        
        if let backgroundColor = request.backgroundColor {
            node.backgroundColor = backgroundColor
            node.updatedAt = Date()
            hasChanges = true
        }
        
        if let textColor = request.textColor {
            node.textColor = textColor
            node.updatedAt = Date()
            hasChanges = true
        }
        
        if let fontSize = request.fontSize {
            node.fontSize = fontSize
            node.updatedAt = Date()
            hasChanges = true
        }
        
        if let isCollapsed = request.isCollapsed {
            if isCollapsed != node.isCollapsed {
                node.toggleCollapsed()
                hasChanges = true
            }
        }
        
        if let isTask = request.isTask {
            if isTask != node.isTask {
                node.toggleTask()
                hasChanges = true
            }
        }
        
        if let isCompleted = request.isCompleted {
            if isCompleted != node.isCompleted && node.isTask {
                node.toggleCompleted()
                hasChanges = true
            }
        }
        
        // 3. 変更がない場合は早期リターン
        guard hasChanges else {
            return UpdateNodeResponse(node: node)
        }
        
        // 4. バリデーション
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "ノードの更新に失敗しました")
        }
        
        // 5. データの保存
        try await nodeRepository.save(node)
        
        return UpdateNodeResponse(node: node)
    }
}