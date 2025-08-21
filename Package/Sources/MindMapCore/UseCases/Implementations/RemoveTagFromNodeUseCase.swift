import Foundation

// MARK: - Remove Tag from Node Use Case Implementation
public final class RemoveTagFromNodeUseCase: RemoveTagFromNodeUseCaseProtocol {
    
    // MARK: - Dependencies
    private let nodeRepository: NodeRepositoryProtocol
    private let tagRepository: TagRepositoryProtocol
    
    // MARK: - Initialization
    public init(
        nodeRepository: NodeRepositoryProtocol,
        tagRepository: TagRepositoryProtocol
    ) {
        self.nodeRepository = nodeRepository
        self.tagRepository = tagRepository
    }
    
    // MARK: - Public Methods
    public func execute(_ request: RemoveTagFromNodeRequest) async throws -> RemoveTagFromNodeResponse {
        // Verify node exists
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw NodeError.notFound
        }
        
        // Verify tag exists
        guard try await tagRepository.exists(request.tagID) else {
            throw TagError.tagNotFound
        }
        
        // Remove tag from node
        node.removeTag(request.tagID)
        
        // Save updated node
        try await nodeRepository.save(node)
        
        return RemoveTagFromNodeResponse(updatedNode: node)
    }
}