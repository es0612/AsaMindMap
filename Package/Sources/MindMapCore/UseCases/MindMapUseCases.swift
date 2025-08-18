import Foundation
import CoreGraphics

// MARK: - MindMap Use Case Protocols

// MARK: - Create MindMap Use Case
public protocol CreateMindMapUseCaseProtocol {
    func execute(_ request: CreateMindMapRequest) async throws -> CreateMindMapResponse
}

public struct CreateMindMapRequest {
    public let title: String
    public let rootNodeText: String?
    public let rootNodePosition: CGPoint
    
    public init(
        title: String,
        rootNodeText: String? = nil,
        rootNodePosition: CGPoint = CGPoint(x: 0, y: 0)
    ) {
        self.title = title
        self.rootNodeText = rootNodeText
        self.rootNodePosition = rootNodePosition
    }
}

public struct CreateMindMapResponse {
    public let mindMap: MindMap
    public let rootNode: Node?
    
    public init(mindMap: MindMap, rootNode: Node? = nil) {
        self.mindMap = mindMap
        self.rootNode = rootNode
    }
}

// MARK: - Update MindMap Use Case
public protocol UpdateMindMapUseCaseProtocol {
    func execute(_ request: UpdateMindMapRequest) async throws -> UpdateMindMapResponse
}

public struct UpdateMindMapRequest {
    public let mindMapID: UUID
    public let title: String?
    public let sharePermissions: SharePermissions?
    
    public init(
        mindMapID: UUID,
        title: String? = nil,
        sharePermissions: SharePermissions? = nil
    ) {
        self.mindMapID = mindMapID
        self.title = title
        self.sharePermissions = sharePermissions
    }
}

public struct UpdateMindMapResponse {
    public let mindMap: MindMap
    
    public init(mindMap: MindMap) {
        self.mindMap = mindMap
    }
}

// MARK: - Delete MindMap Use Case
public protocol DeleteMindMapUseCaseProtocol {
    func execute(_ request: DeleteMindMapRequest) async throws -> DeleteMindMapResponse
}

public struct DeleteMindMapRequest {
    public let mindMapID: UUID
    
    public init(mindMapID: UUID) {
        self.mindMapID = mindMapID
    }
}

public struct DeleteMindMapResponse {
    public let deletedMindMapID: UUID
    public let deletedNodeIDs: Set<UUID>
    public let deletedMediaIDs: Set<UUID>
    
    public init(
        deletedMindMapID: UUID,
        deletedNodeIDs: Set<UUID>,
        deletedMediaIDs: Set<UUID>
    ) {
        self.deletedMindMapID = deletedMindMapID
        self.deletedNodeIDs = deletedNodeIDs
        self.deletedMediaIDs = deletedMediaIDs
    }
}

// MARK: - Share MindMap Use Case
public protocol ShareMindMapUseCaseProtocol {
    func execute(_ request: ShareMindMapRequest) async throws -> ShareMindMapResponse
}

public struct ShareMindMapRequest {
    public let mindMapID: UUID
    public let permissions: SharePermissions
    
    public init(mindMapID: UUID, permissions: SharePermissions) {
        self.mindMapID = mindMapID
        self.permissions = permissions
    }
}

public struct ShareMindMapResponse {
    public let mindMap: MindMap
    public let shareURL: String
    
    public init(mindMap: MindMap, shareURL: String) {
        self.mindMap = mindMap
        self.shareURL = shareURL
    }
}

// MARK: - Get MindMap Use Case
public protocol GetMindMapUseCaseProtocol {
    func execute(_ request: GetMindMapRequest) async throws -> GetMindMapResponse
}

public struct GetMindMapRequest {
    public let mindMapID: UUID
    public let includeNodes: Bool
    
    public init(mindMapID: UUID, includeNodes: Bool = true) {
        self.mindMapID = mindMapID
        self.includeNodes = includeNodes
    }
}

public struct GetMindMapResponse {
    public let mindMap: MindMap
    public let nodes: [Node]
    
    public init(mindMap: MindMap, nodes: [Node] = []) {
        self.mindMap = mindMap
        self.nodes = nodes
    }
}

// MARK: - List MindMaps Use Case
public protocol ListMindMapsUseCaseProtocol {
    func execute(_ request: ListMindMapsRequest) async throws -> ListMindMapsResponse
}

public struct ListMindMapsRequest {
    public let sortBy: MindMapSortOption
    public let limit: Int?
    public let includeShared: Bool
    
    public init(
        sortBy: MindMapSortOption = .updatedAt,
        limit: Int? = nil,
        includeShared: Bool = true
    ) {
        self.sortBy = sortBy
        self.limit = limit
        self.includeShared = includeShared
    }
}

public struct ListMindMapsResponse {
    public let mindMaps: [MindMap]
    
    public init(mindMaps: [MindMap]) {
        self.mindMaps = mindMaps
    }
}

public enum MindMapSortOption {
    case createdAt
    case updatedAt
    case title
    case nodeCount
}