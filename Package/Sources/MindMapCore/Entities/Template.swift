import Foundation
import SwiftUI

public struct Template: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String
    public var category: TemplateCategory
    public let isPreset: Bool
    public let createdAt: Date
    public var updatedAt: Date
    
    private var _rootNodeId: UUID?
    private var _nodeManager: TemplateNodeManager = TemplateNodeManager()
    
    public init(title: String, description: String, category: TemplateCategory, isPreset: Bool) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.category = category
        self.isPreset = isPreset
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public static func createPreset(title: String, description: String, category: TemplateCategory) -> Template {
        return Template(title: title, description: description, category: category, isPreset: true)
    }
    
    public var canEdit: Bool {
        return !isPreset
    }
    
    public var rootNode: TemplateNode? {
        guard let rootId = _rootNodeId else { return nil }
        return _nodeManager.getNode(rootId)
    }
    
    public var nodes: [TemplateNode] {
        return _nodeManager.allNodes
    }
    
    public mutating func setRootNode(_ node: TemplateNode) {
        _rootNodeId = node.id
        _nodeManager.addNode(node)
        updatedAt = Date()
    }
    
    public mutating func addNode(_ node: TemplateNode, parentId: UUID) {
        _nodeManager.addNode(node)
        _nodeManager.addChild(node.id, to: parentId)
        updatedAt = Date()
    }
    
    public func createMindMap(title: String) -> MindMap {
        var mindMap = MindMap(title: title, templateId: self.id)
        
        // Convert template nodes to actual nodes if root exists
        if let templateRoot = rootNode {
            let actualRoot = templateRoot.toNode(replacements: [:])
            mindMap.rootNodeID = actualRoot.id
        }
        
        return mindMap
    }
}

extension Template: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Template, rhs: Template) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.description == rhs.description &&
               lhs.category == rhs.category &&
               lhs.isPreset == rhs.isPreset &&
               lhs._rootNodeId == rhs._rootNodeId &&
               lhs._nodeManager == rhs._nodeManager
    }
}

extension Template {
    enum CodingKeys: String, CodingKey {
        case id, title, description, category, isPreset, createdAt, updatedAt
    }
}