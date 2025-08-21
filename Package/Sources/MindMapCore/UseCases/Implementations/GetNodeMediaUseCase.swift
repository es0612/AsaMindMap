import Foundation

// MARK: - Get Node Media Use Case
public struct GetNodeMediaUseCase: GetNodeMediaUseCaseProtocol {
    
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
    public func execute(_ request: GetNodeMediaRequest) async throws -> GetNodeMediaResponse {
        // 1. Validate node exists
        guard let node = try await nodeRepository.findByID(request.nodeID) else {
            throw MediaError.nodeNotFound(request.nodeID)
        }
        
        // 2. Get all media for the node
        var media: [Media] = []
        
        for mediaID in node.mediaIDs {
            if let mediaItem = try await mediaRepository.findByID(mediaID) {
                media.append(mediaItem)
            }
        }
        
        // 3. Sort media by creation date (newest first)
        media.sort { $0.createdAt > $1.createdAt }
        
        return GetNodeMediaResponse(media: media)
    }
}