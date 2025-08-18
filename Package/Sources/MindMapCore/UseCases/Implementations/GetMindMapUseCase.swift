import Foundation

// MARK: - Get MindMap Use Case Implementation
public final class GetMindMapUseCase: GetMindMapUseCaseProtocol {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
    }
    
    public func execute(_ request: GetMindMapRequest) async throws -> GetMindMapResponse {
        // 1. MindMapの取得
        guard let mindMap = try await mindMapRepository.findByID(request.mindMapID) else {
            throw MindMapError.validationError("指定されたマインドマップが見つかりません")
        }
        
        var nodes: [Node] = []
        
        // 2. ノードの取得（必要な場合）
        if request.includeNodes {
            nodes = try await nodeRepository.findByMindMapID(request.mindMapID)
        }
        
        return GetMindMapResponse(mindMap: mindMap, nodes: nodes)
    }
}