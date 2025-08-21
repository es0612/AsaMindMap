import Foundation

// MARK: - Get Node Tags Use Case Implementation
public final class GetNodeTagsUseCase: GetNodeTagsUseCaseProtocol {
    
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
    public func execute(_ request: GetNodeTagsRequest) async throws -> GetNodeTagsResponse {
        // Verify node exists
        guard let node = try await nodeRepository.findByID(request.nodeID) else {
            throw NodeError.notFound
        }
        
        // Get all tags for this node
        var tags: [Tag] = []
        for tagID in node.tagIDs {
            if let tag = try await tagRepository.findByID(tagID) {
                tags.append(tag)
            }
        }
        
        return GetNodeTagsResponse(tags: tags)
    }
}