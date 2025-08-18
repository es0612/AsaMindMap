import Foundation
import CoreGraphics

// MARK: - Node Use Case Protocols

// MARK: - Create Node Use Case
public protocol CreateNodeUseCaseProtocol {
    func execute(_ request: CreateNodeRequest) async throws -> CreateNodeResponse
}

public struct CreateNodeRequest {
    public let text: String
    public let position: CGPoint
    public let parentID: UUID?
    public let mindMapID: UUID
    public let backgroundColor: NodeColor
    public let textColor: NodeColor
    public let fontSize: CGFloat
    public let isTask: Bool
    
    public init(
        text: String,
        position: CGPoint,
        parentID: UUID? = nil,
        mindMapID: UUID,
        backgroundColor: NodeColor = .default,
        textColor: NodeColor = .primary,
        fontSize: CGFloat = 16.0,
        isTask: Bool = false
    ) {
        self.text = text
        self.position = position
        self.parentID = parentID
        self.mindMapID = mindMapID
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontSize = fontSize
        self.isTask = isTask
    }
}

public struct CreateNodeResponse {
    public let node: Node
    public let updatedMindMap: MindMap
    
    public init(node: Node, updatedMindMap: MindMap) {
        self.node = node
        self.updatedMindMap = updatedMindMap
    }
}

// MARK: - Update Node Use Case
public protocol UpdateNodeUseCaseProtocol {
    func execute(_ request: UpdateNodeRequest) async throws -> UpdateNodeResponse
}

public struct UpdateNodeRequest {
    public let nodeID: UUID
    public let text: String?
    public let position: CGPoint?
    public let backgroundColor: NodeColor?
    public let textColor: NodeColor?
    public let fontSize: CGFloat?
    public let isCollapsed: Bool?
    public let isTask: Bool?
    public let isCompleted: Bool?
    
    public init(
        nodeID: UUID,
        text: String? = nil,
        position: CGPoint? = nil,
        backgroundColor: NodeColor? = nil,
        textColor: NodeColor? = nil,
        fontSize: CGFloat? = nil,
        isCollapsed: Bool? = nil,
        isTask: Bool? = nil,
        isCompleted: Bool? = nil
    ) {
        self.nodeID = nodeID
        self.text = text
        self.position = position
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontSize = fontSize
        self.isCollapsed = isCollapsed
        self.isTask = isTask
        self.isCompleted = isCompleted
    }
}

public struct UpdateNodeResponse {
    public let node: Node
    
    public init(node: Node) {
        self.node = node
    }
}

// MARK: - Delete Node Use Case
public protocol DeleteNodeUseCaseProtocol {
    func execute(_ request: DeleteNodeRequest) async throws -> DeleteNodeResponse
}

public struct DeleteNodeRequest {
    public let nodeID: UUID
    public let mindMapID: UUID
    public let deleteChildren: Bool
    
    public init(nodeID: UUID, mindMapID: UUID, deleteChildren: Bool = true) {
        self.nodeID = nodeID
        self.mindMapID = mindMapID
        self.deleteChildren = deleteChildren
    }
}

public struct DeleteNodeResponse {
    public let deletedNodeIDs: Set<UUID>
    public let updatedMindMap: MindMap
    
    public init(deletedNodeIDs: Set<UUID>, updatedMindMap: MindMap) {
        self.deletedNodeIDs = deletedNodeIDs
        self.updatedMindMap = updatedMindMap
    }
}

// MARK: - Move Node Use Case
public protocol MoveNodeUseCaseProtocol {
    func execute(_ request: MoveNodeRequest) async throws -> MoveNodeResponse
}

public struct MoveNodeRequest {
    public let nodeID: UUID
    public let newParentID: UUID?
    public let newPosition: CGPoint
    
    public init(nodeID: UUID, newParentID: UUID?, newPosition: CGPoint) {
        self.nodeID = nodeID
        self.newParentID = newParentID
        self.newPosition = newPosition
    }
}

public struct MoveNodeResponse {
    public let node: Node
    public let affectedNodes: [Node]
    
    public init(node: Node, affectedNodes: [Node]) {
        self.node = node
        self.affectedNodes = affectedNodes
    }
}