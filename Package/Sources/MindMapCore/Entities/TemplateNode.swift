import Foundation
import SwiftUI

public enum TemplateNodeType: String, CaseIterable, Codable, Sendable {
    case central = "central"
    case topic = "topic"
    case subtopic = "subtopic"
    case question = "question"
    case action = "action"
    case note = "note"
    
    public var displayName: String {
        switch self {
        case .central:
            return "中心"
        case .topic:
            return "トピック"
        case .subtopic:
            return "サブトピック"
        case .question:
            return "質問"
        case .action:
            return "アクション"
        case .note:
            return "ノート"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .central:
            return "circle.fill"
        case .topic:
            return "rectangle.fill"
        case .subtopic:
            return "rectangle"
        case .question:
            return "questionmark.circle.fill"
        case .action:
            return "checkmark.circle.fill"
        case .note:
            return "note.text"
        }
    }
    
    public var isCentral: Bool {
        return self == .central
    }
}

public enum NodeShape: String, CaseIterable, Codable, Sendable {
    case ellipse = "ellipse"
    case rectangle = "rectangle"
    case roundedRectangle = "roundedRectangle"
    case circle = "circle"
}

public struct NodeStyle: Codable, Equatable, Sendable {
    public var backgroundColor: NodeColor
    public var textColor: NodeColor
    public var fontSize: CGFloat
    public var shape: NodeShape
    
    public init(
        backgroundColor: NodeColor = .default,
        textColor: NodeColor = .primary,
        fontSize: CGFloat = 14,
        shape: NodeShape = .ellipse
    ) {
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontSize = fontSize
        self.shape = shape
    }
}

public struct TemplateNode: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var text: String
    public var position: CGPoint
    public var nodeType: TemplateNodeType
    public var style: NodeStyle
    public var childNodeIds: Set<UUID>
    public var parentNodeId: UUID?
    
    public init(text: String, position: CGPoint, nodeType: TemplateNodeType) {
        self.id = UUID()
        self.text = text
        self.position = position
        self.nodeType = nodeType
        self.style = NodeStyle()
        self.childNodeIds = []
        self.parentNodeId = nil
    }
    
    public var hasPlaceholder: Bool {
        return text.contains("[") && text.contains("]")
    }
    
    public var placeholders: [String] {
        let pattern = "\\[([^\\]]+)\\]"
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
        
        return matches.compactMap { match in
            if let range = Range(match.range, in: text) {
                return String(text[range])
            }
            return nil
        }
    }
    
    public func toNode(replacements: [String: String]) -> Node {
        var processedText = text
        
        // Replace placeholders
        for (placeholder, replacement) in replacements {
            processedText = processedText.replacingOccurrences(of: placeholder, with: replacement)
        }
        
        return Node(
            id: UUID(),
            text: processedText,
            position: position,
            backgroundColor: style.backgroundColor,
            textColor: style.textColor,
            fontSize: style.fontSize
        )
    }
    
    public mutating func setStyle(backgroundColor: NodeColor, textColor: NodeColor, fontSize: CGFloat, shape: NodeShape) {
        self.style = NodeStyle(
            backgroundColor: backgroundColor,
            textColor: textColor,
            fontSize: fontSize,
            shape: shape
        )
    }
    
    public mutating func addChild(_ childId: UUID) {
        childNodeIds.insert(childId)
    }
    
    public mutating func removeChild(_ childId: UUID) {
        childNodeIds.remove(childId)
    }
}

// Template management helper to work with node hierarchies
public struct TemplateNodeManager: Sendable, Equatable {
    private var nodes: [UUID: TemplateNode]
    
    public init() {
        self.nodes = [:]
    }
    
    public mutating func addNode(_ node: TemplateNode) {
        nodes[node.id] = node
    }
    
    public mutating func addChild(_ childId: UUID, to parentId: UUID) {
        nodes[parentId]?.addChild(childId)
        nodes[childId]?.parentNodeId = parentId
    }
    
    public func getNode(_ id: UUID) -> TemplateNode? {
        return nodes[id]
    }
    
    public func getChildren(of nodeId: UUID) -> [TemplateNode] {
        guard let node = nodes[nodeId] else { return [] }
        return node.childNodeIds.compactMap { nodes[$0] }
    }
    
    public var allNodes: [TemplateNode] {
        return Array(nodes.values)
    }
}