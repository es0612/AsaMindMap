import Foundation

// MARK: - Quick Entry Use Cases

// MARK: - Parse Text Use Case
public protocol ParseTextUseCaseProtocol {
    func execute(_ request: ParseTextRequest) async throws -> ParseTextResponse
}

public struct ParseTextRequest {
    public let text: String
    
    public init(text: String) {
        self.text = text
    }
}

public struct ParseTextResponse {
    public let structure: MindMapStructure
    
    public init(structure: MindMapStructure) {
        self.structure = structure
    }
}

// MARK: - Generate MindMap Use Case
public protocol GenerateMindMapFromTextUseCaseProtocol {
    func execute(_ request: GenerateMindMapFromTextRequest) async throws -> GenerateMindMapFromTextResponse
}

public struct GenerateMindMapFromTextRequest {
    public let structure: MindMapStructure
    public let title: String?
    
    public init(structure: MindMapStructure, title: String? = nil) {
        self.structure = structure
        self.title = title
    }
}

public struct GenerateMindMapFromTextResponse {
    public let mindMap: MindMap
    public let nodes: [Node]
    public let previewData: MindMapPreview
    
    public init(mindMap: MindMap, nodes: [Node], previewData: MindMapPreview) {
        self.mindMap = mindMap
        self.nodes = nodes
        self.previewData = previewData
    }
}

// MARK: - Supporting Types

public struct MindMapStructure: Equatable {
    public let rootNode: ParsedNode
    
    public init(rootNode: ParsedNode) {
        self.rootNode = rootNode
    }
}

public struct ParsedNode: Equatable {
    public let text: String
    public let level: Int
    public let children: [ParsedNode]
    
    public init(text: String, level: Int, children: [ParsedNode] = []) {
        self.text = text
        self.level = level
        self.children = children
    }
}

public struct MindMapPreview: Equatable {
    public let nodeCount: Int
    public let maxDepth: Int
    public let estimatedSize: CGSize
    
    public init(nodeCount: Int, maxDepth: Int, estimatedSize: CGSize) {
        self.nodeCount = nodeCount
        self.maxDepth = maxDepth
        self.estimatedSize = estimatedSize
    }
}

// MARK: - Quick Entry Error Types
public enum QuickEntryError: LocalizedError, Equatable {
    case emptyText
    case invalidFormat
    case parsingFailed
    case generationFailed
    
    public var errorDescription: String? {
        switch self {
        case .emptyText:
            return "テキストが空です"
        case .invalidFormat:
            return "無効なフォーマットです"
        case .parsingFailed:
            return "テキストの解析に失敗しました"
        case .generationFailed:
            return "マインドマップの生成に失敗しました"
        }
    }
}