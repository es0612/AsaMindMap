import Foundation
import CoreGraphics

// MARK: - Create MindMap Use Case Implementation
public final class CreateMindMapUseCase: CreateMindMapUseCaseProtocol {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    private let mindMapValidator: MindMapValidator
    private let nodeValidator: NodeValidator
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        mindMapValidator: MindMapValidator = MindMapValidator(),
        nodeValidator: NodeValidator = NodeValidator()
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.mindMapValidator = mindMapValidator
        self.nodeValidator = nodeValidator
    }
    
    public func execute(_ request: CreateMindMapRequest) async throws -> CreateMindMapResponse {
        // 1. 新しいMindMapの作成
        var mindMap = MindMap(title: request.title)
        
        // 2. MindMapのバリデーション
        let mindMapValidationResult = mindMapValidator.validateForCreation(mindMap)
        guard mindMapValidationResult.isValid else {
            throw MindMapError.validationError(mindMapValidationResult.errorMessage ?? "マインドマップの作成に失敗しました")
        }
        
        var rootNode: Node?
        
        // 3. ルートノードの作成（テキストが指定されている場合）
        if let rootNodeText = request.rootNodeText, !rootNodeText.isEmpty {
            let node = Node(
                text: rootNodeText,
                position: request.rootNodePosition,
                backgroundColor: .accent,
                textColor: .primary,
                fontSize: 18.0
            )
            
            // 4. ルートノードのバリデーション
            let nodeValidationResult = nodeValidator.validateForCreation(node)
            guard nodeValidationResult.isValid else {
                throw MindMapError.validationError(nodeValidationResult.errorMessage ?? "ルートノードの作成に失敗しました")
            }
            
            // 5. MindMapにルートノードを設定
            mindMap.setRootNode(node.id)
            rootNode = node
        }
        
        // 6. データの保存
        try await mindMapRepository.save(mindMap)
        
        if let node = rootNode {
            try await nodeRepository.save(node)
        }
        
        return CreateMindMapResponse(mindMap: mindMap, rootNode: rootNode)
    }
}