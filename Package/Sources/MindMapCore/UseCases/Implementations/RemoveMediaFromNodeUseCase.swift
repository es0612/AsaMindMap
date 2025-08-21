import Foundation

// MARK: - Remove Media from Node Use Case
public struct RemoveMediaFromNodeUseCase: RemoveMediaFromNodeUseCaseProtocol {
    
    // MARK: - Dependencies
    private let nodeRepository: NodeRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    // MARK: - Initialization
    public init(
        nodeRepository: NodeRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol
    ) {
        self.nodeRepository = nodeRepository
        self.mediaRepository = mediaRepository
    }
    
    // MARK: - Execute
    public func execute(_ request: RemoveMediaFromNodeRequest) async throws -> RemoveMediaFromNodeResponse {
        // 1. Validate node exists
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw MediaError.nodeNotFound(request.nodeID)
        }
        
        // 2. Validate media exists
        guard try await mediaRepository.exists(request.mediaID) else {
            throw MediaError.mediaNotFound(request.mediaID)
        }
        
        // 3. Check if media is attached to node
        guard node.mediaIDs.contains(request.mediaID) else {
            throw MediaError.mediaNotAttachedToNode(request.mediaID, request.nodeID)
        }
        
        // 4. Remove media reference from node
        node.removeMedia(request.mediaID)
        try await nodeRepository.save(node)
        
        // 5. Check if media is orphaned and delete if necessary
        let isOrphaned = try await isMediaOrphaned(request.mediaID)
        if isOrphaned {
            try await mediaRepository.delete(request.mediaID)
        }
        
        return RemoveMediaFromNodeResponse(updatedNode: node)
    }
    
    // MARK: - Private Methods
    private func isMediaOrphaned(_ mediaID: UUID) async throws -> Bool {
        // Check if any other nodes reference this media
        let allNodes = try await nodeRepository.findAll()
        return !allNodes.contains { $0.mediaIDs.contains(mediaID) }
    }
}

// MARK: - Additional Media Errors
extension MediaError {
    static func mediaNotAttachedToNode(_ mediaID: UUID, _ nodeID: UUID) -> MediaError {
        return .saveFailed("メディア \(mediaID) はノード \(nodeID) に添付されていません")
    }
}