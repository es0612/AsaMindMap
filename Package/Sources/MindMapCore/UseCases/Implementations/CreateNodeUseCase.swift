import Foundation
import CoreGraphics

// MARK: - Create Node Use Case Implementation
public final class CreateNodeUseCase: CreateNodeUseCaseProtocol {
    private let nodeRepository: NodeRepositoryProtocol
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeValidator: NodeValidator
    private let mindMapValidator: MindMapValidator
    
    public init(
        nodeRepository: NodeRepositoryProtocol,
        mindMapRepository: MindMapRepositoryProtocol,
        nodeValidator: NodeValidator = NodeValidator(),
        mindMapValidator: MindMapValidator = MindMapValidator()
    ) {
        self.nodeRepository = nodeRepository
        self.mindMapRepository = mindMapRepository
        self.nodeValidator = nodeValidator
        self.mindMapValidator = mindMapValidator
    }
    
    public func execute(_ request: CreateNodeRequest) async throws -> CreateNodeResponse {
        // 1. MindMapの存在確認
        guard var mindMap = try await mindMapRepository.findByID(request.mindMapID) else {
            throw MindMapError.validationError("指定されたマインドマップが見つかりません")
        }
        
        // 2. 親ノードの存在確認（指定されている場合）
        var parentNode: Node?
        if let parentID = request.parentID {
            guard let parent = try await nodeRepository.findByID(parentID) else {
                throw MindMapError.validationError("指定された親ノードが見つかりません")
            }
            parentNode = parent
        }
        
        // 3. 新しいノードの作成
        let newNode = Node(
            text: request.text,
            position: request.position,
            backgroundColor: request.backgroundColor,
            textColor: request.textColor,
            fontSize: request.fontSize,
            isTask: request.isTask,
            parentID: request.parentID
        )
        
        // 4. ノードのバリデーション
        let nodeValidationResult = nodeValidator.validateForCreation(newNode)
        guard nodeValidationResult.isValid else {
            throw MindMapError.validationError(nodeValidationResult.errorMessage ?? "ノードの作成に失敗しました")
        }
        
        // 5. MindMapにノードを追加
        mindMap.addNode(newNode.id)
        
        // 6. ルートノードの設定（初回ノード作成時）
        if !mindMap.hasRootNode && request.parentID == nil {
            mindMap.setRootNode(newNode.id)
        }
        
        // 7. MindMapのバリデーション
        let mindMapValidationResult = mindMapValidator.validate(mindMap)
        guard mindMapValidationResult.isValid else {
            throw MindMapError.validationError(mindMapValidationResult.errorMessage ?? "マインドマップの更新に失敗しました")
        }
        
        // 8. 親ノードの更新（子ノードの追加）
        if var parent = parentNode {
            parent.addChild(newNode.id)
            try await nodeRepository.save(parent)
        }
        
        // 9. データの保存
        try await nodeRepository.save(newNode)
        try await mindMapRepository.save(mindMap)
        
        return CreateNodeResponse(node: newNode, updatedMindMap: mindMap)
    }
}