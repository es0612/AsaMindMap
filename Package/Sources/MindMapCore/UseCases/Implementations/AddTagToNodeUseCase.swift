import Foundation

// MARK: - Add Tag to Node Use Case Implementation
public final class AddTagToNodeUseCase: AddTagToNodeUseCaseProtocol {
    
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
    public func execute(_ request: AddTagToNodeRequest) async throws -> AddTagToNodeResponse {
        // Verify node exists
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw NodeError.notFound
        }
        
        // Verify tag exists
        guard let tag = try await tagRepository.findByID(request.tagID) else {
            throw TagError.tagNotFound
        }
        
        // Add tag to node if not already present
        node.addTag(request.tagID)
        
        // Save updated node
        try await nodeRepository.save(node)
        
        return AddTagToNodeResponse(updatedNode: node, tag: tag)
    }
}