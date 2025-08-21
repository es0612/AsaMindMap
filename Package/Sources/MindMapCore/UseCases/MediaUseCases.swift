import Foundation

// MARK: - Media Use Case Protocols

public protocol AddMediaToNodeUseCaseProtocol {
    func execute(_ request: AddMediaToNodeRequest) async throws -> AddMediaToNodeResponse
}

public protocol RemoveMediaFromNodeUseCaseProtocol {
    func execute(_ request: RemoveMediaFromNodeRequest) async throws -> RemoveMediaFromNodeResponse
}

public protocol GetNodeMediaUseCaseProtocol {
    func execute(_ request: GetNodeMediaRequest) async throws -> GetNodeMediaResponse
}

public protocol ValidateMediaURLUseCaseProtocol {
    func execute(_ request: ValidateMediaURLRequest) async throws -> ValidateMediaURLResponse
}

// MARK: - Request/Response Models

public struct AddMediaToNodeRequest {
    public let nodeID: UUID
    public let mediaType: MediaType
    public let data: Data?
    public let url: String?
    public let fileName: String?
    public let mimeType: String?
    
    public init(
        nodeID: UUID,
        mediaType: MediaType,
        data: Data? = nil,
        url: String? = nil,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        self.nodeID = nodeID
        self.mediaType = mediaType
        self.data = data
        self.url = url
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

public struct AddMediaToNodeResponse {
    public let media: Media
    public let updatedNode: Node
    
    public init(media: Media, updatedNode: Node) {
        self.media = media
        self.updatedNode = updatedNode
    }
}

public struct RemoveMediaFromNodeRequest {
    public let nodeID: UUID
    public let mediaID: UUID
    
    public init(nodeID: UUID, mediaID: UUID) {
        self.nodeID = nodeID
        self.mediaID = mediaID
    }
}

public struct RemoveMediaFromNodeResponse {
    public let updatedNode: Node
    
    public init(updatedNode: Node) {
        self.updatedNode = updatedNode
    }
}

public struct GetNodeMediaRequest {
    public let nodeID: UUID
    
    public init(nodeID: UUID) {
        self.nodeID = nodeID
    }
}

public struct GetNodeMediaResponse {
    public let media: [Media]
    
    public init(media: [Media]) {
        self.media = media
    }
}

public struct ValidateMediaURLRequest {
    public let url: String
    public let mediaType: MediaType
    
    public init(url: String, mediaType: MediaType) {
        self.url = url
        self.mediaType = mediaType
    }
}

public struct ValidateMediaURLResponse {
    public let isValid: Bool
    public let normalizedURL: String?
    public let errorMessage: String?
    
    public init(isValid: Bool, normalizedURL: String? = nil, errorMessage: String? = nil) {
        self.isValid = isValid
        self.normalizedURL = normalizedURL
        self.errorMessage = errorMessage
    }
}