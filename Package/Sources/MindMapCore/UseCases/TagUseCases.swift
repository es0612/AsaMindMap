import Foundation

// MARK: - Tag Use Case Protocols

// MARK: - Create Tag Use Case
public protocol CreateTagUseCaseProtocol {
    func execute(_ request: CreateTagRequest) async throws -> CreateTagResponse
}

public struct CreateTagRequest {
    public let name: String
    public let color: NodeColor
    public let description: String?
    
    public init(
        name: String,
        color: NodeColor = .accent,
        description: String? = nil
    ) {
        self.name = name
        self.color = color
        self.description = description
    }
}

public struct CreateTagResponse {
    public let tag: Tag
    
    public init(tag: Tag) {
        self.tag = tag
    }
}

// MARK: - Add Tag to Node Use Case
public protocol AddTagToNodeUseCaseProtocol {
    func execute(_ request: AddTagToNodeRequest) async throws -> AddTagToNodeResponse
}

public struct AddTagToNodeRequest {
    public let nodeID: UUID
    public let tagID: UUID
    
    public init(nodeID: UUID, tagID: UUID) {
        self.nodeID = nodeID
        self.tagID = tagID
    }
}

public struct AddTagToNodeResponse {
    public let updatedNode: Node
    public let tag: Tag
    
    public init(updatedNode: Node, tag: Tag) {
        self.updatedNode = updatedNode
        self.tag = tag
    }
}

// MARK: - Remove Tag from Node Use Case
public protocol RemoveTagFromNodeUseCaseProtocol {
    func execute(_ request: RemoveTagFromNodeRequest) async throws -> RemoveTagFromNodeResponse
}

public struct RemoveTagFromNodeRequest {
    public let nodeID: UUID
    public let tagID: UUID
    
    public init(nodeID: UUID, tagID: UUID) {
        self.nodeID = nodeID
        self.tagID = tagID
    }
}

public struct RemoveTagFromNodeResponse {
    public let updatedNode: Node
    
    public init(updatedNode: Node) {
        self.updatedNode = updatedNode
    }
}

// MARK: - Get Node Tags Use Case
public protocol GetNodeTagsUseCaseProtocol {
    func execute(_ request: GetNodeTagsRequest) async throws -> GetNodeTagsResponse
}

public struct GetNodeTagsRequest {
    public let nodeID: UUID
    
    public init(nodeID: UUID) {
        self.nodeID = nodeID
    }
}

public struct GetNodeTagsResponse {
    public let tags: [Tag]
    
    public init(tags: [Tag]) {
        self.tags = tags
    }
}

// MARK: - Get All Tags Use Case  
public protocol GetAllTagsUseCaseProtocol {
    func execute() async throws -> GetAllTagsResponse
}

public struct GetAllTagsResponse {
    public let tags: [Tag]
    
    public init(tags: [Tag]) {
        self.tags = tags
    }
}

// MARK: - Task Progress Use Case Protocols

// MARK: - Toggle Node Task Use Case
public protocol ToggleNodeTaskUseCaseProtocol {
    func execute(_ request: ToggleNodeTaskRequest) async throws -> ToggleNodeTaskResponse
}

public struct ToggleNodeTaskRequest {
    public let nodeID: UUID
    
    public init(nodeID: UUID) {
        self.nodeID = nodeID
    }
}

public struct ToggleNodeTaskResponse {
    public let updatedNode: Node
    
    public init(updatedNode: Node) {
        self.updatedNode = updatedNode
    }
}

// MARK: - Toggle Task Completion Use Case
public protocol ToggleTaskCompletionUseCaseProtocol {
    func execute(_ request: ToggleTaskCompletionRequest) async throws -> ToggleTaskCompletionResponse
}

public struct ToggleTaskCompletionRequest {
    public let nodeID: UUID
    
    public init(nodeID: UUID) {
        self.nodeID = nodeID
    }
}

public struct ToggleTaskCompletionResponse {
    public let updatedNode: Node
    
    public init(updatedNode: Node) {
        self.updatedNode = updatedNode
    }
}

// MARK: - Get Branch Progress Use Case
public protocol GetBranchProgressUseCaseProtocol {
    func execute(_ request: GetBranchProgressRequest) async throws -> GetBranchProgressResponse
}

public struct GetBranchProgressRequest {
    public let rootNodeID: UUID
    
    public init(rootNodeID: UUID) {
        self.rootNodeID = rootNodeID
    }
}

public struct GetBranchProgressResponse {
    public let totalTasks: Int
    public let completedTasks: Int
    public let progressPercentage: Double
    
    public init(totalTasks: Int, completedTasks: Int, progressPercentage: Double) {
        self.totalTasks = totalTasks
        self.completedTasks = completedTasks
        self.progressPercentage = progressPercentage
    }
}