import Foundation

// MARK: - Toggle Task Completion Use Case Implementation
public final class ToggleTaskCompletionUseCase: ToggleTaskCompletionUseCaseProtocol {
    
    // MARK: - Dependencies
    private let nodeRepository: NodeRepositoryProtocol
    
    // MARK: - Initialization
    public init(nodeRepository: NodeRepositoryProtocol) {
        self.nodeRepository = nodeRepository
    }
    
    // MARK: - Public Methods
    public func execute(_ request: ToggleTaskCompletionRequest) async throws -> ToggleTaskCompletionResponse {
        // Verify node exists
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw NodeError.notFound
        }
        
        // Verify node is a task
        guard node.isTask else {
            throw TaskError.notATask
        }
        
        // Toggle completion status
        node.toggleCompleted()
        
        // Save updated node
        try await nodeRepository.save(node)
        
        return ToggleTaskCompletionResponse(updatedNode: node)
    }
}