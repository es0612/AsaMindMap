import Foundation

// MARK: - Toggle Node Task Use Case Implementation
public final class ToggleNodeTaskUseCase: ToggleNodeTaskUseCaseProtocol {
    
    // MARK: - Dependencies
    private let nodeRepository: NodeRepositoryProtocol
    
    // MARK: - Initialization
    public init(nodeRepository: NodeRepositoryProtocol) {
        self.nodeRepository = nodeRepository
    }
    
    // MARK: - Public Methods
    public func execute(_ request: ToggleNodeTaskRequest) async throws -> ToggleNodeTaskResponse {
        // Verify node exists
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw NodeError.notFound
        }
        
        // Toggle task status
        node.toggleTask()
        
        // Save updated node
        try await nodeRepository.save(node)
        
        return ToggleNodeTaskResponse(updatedNode: node)
    }
}