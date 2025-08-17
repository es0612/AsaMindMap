import Foundation
import CoreGraphics

// MARK: - Node Management Service
public protocol NodeManagementServiceProtocol {
    func createNode(text: String, position: CGPoint, parentID: UUID?) async throws -> Node
    func updateNodeText(_ nodeID: UUID, text: String) async throws
    func updateNodePosition(_ nodeID: UUID, position: CGPoint) async throws
    func updateNodeStyle(_ nodeID: UUID, backgroundColor: NodeColor?, textColor: NodeColor?, fontSize: CGFloat?) async throws
    func toggleNodeTask(_ nodeID: UUID) async throws
    func toggleNodeCompleted(_ nodeID: UUID) async throws
    func duplicateNode(_ nodeID: UUID) async throws -> Node
    func mergeNodes(_ sourceID: UUID, into targetID: UUID) async throws
}

public final class NodeManagementService: NodeManagementServiceProtocol {
    private let nodeRepository: NodeRepositoryProtocol
    private let nodeValidator: NodeValidator
    
    public init(
        nodeRepository: NodeRepositoryProtocol,
        nodeValidator: NodeValidator = NodeValidator()
    ) {
        self.nodeRepository = nodeRepository
        self.nodeValidator = nodeValidator
    }
    
    public func createNode(text: String, position: CGPoint, parentID: UUID?) async throws -> Node {
        let node = Node(text: text, position: position, parentID: parentID)
        
        let validationResult = nodeValidator.validateForCreation(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "ノード作成バリデーションエラー")
        }
        
        try await nodeRepository.save(node)
        
        // 親ノードに子として追加
        if let parentID = parentID {
            if var parentNode = try await nodeRepository.findByID(parentID) {
                parentNode.addChild(node.id)
                try await nodeRepository.save(parentNode)
            }
        }
        
        return node
    }
    
    public func updateNodeText(_ nodeID: UUID, text: String) async throws {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        node.updateText(text)
        
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "テキスト更新バリデーションエラー")
        }
        
        try await nodeRepository.save(node)
    }
    
    public func updateNodePosition(_ nodeID: UUID, position: CGPoint) async throws {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        node.updatePosition(position)
        
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "位置更新バリデーションエラー")
        }
        
        try await nodeRepository.save(node)
    }
    
    public func updateNodeStyle(
        _ nodeID: UUID,
        backgroundColor: NodeColor?,
        textColor: NodeColor?,
        fontSize: CGFloat?
    ) async throws {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        if let backgroundColor = backgroundColor {
            node.backgroundColor = backgroundColor
        }
        
        if let textColor = textColor {
            node.textColor = textColor
        }
        
        if let fontSize = fontSize {
            node.fontSize = fontSize
        }
        
        node.updatedAt = Date()
        
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "スタイル更新バリデーションエラー")
        }
        
        try await nodeRepository.save(node)
    }
    
    public func toggleNodeTask(_ nodeID: UUID) async throws {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        node.toggleTask()
        
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "タスク切り替えバリデーションエラー")
        }
        
        try await nodeRepository.save(node)
    }
    
    public func toggleNodeCompleted(_ nodeID: UUID) async throws {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        node.toggleCompleted()
        
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "完了切り替えバリデーションエラー")
        }
        
        try await nodeRepository.save(node)
    }
    
    public func duplicateNode(_ nodeID: UUID) async throws -> Node {
        guard let originalNode = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        // 新しい位置を計算（少しずらす）
        let newPosition = CGPoint(
            x: originalNode.position.x + 50,
            y: originalNode.position.y + 50
        )
        
        let duplicatedNode = Node(
            text: originalNode.text + " (コピー)",
            position: newPosition,
            backgroundColor: originalNode.backgroundColor,
            textColor: originalNode.textColor,
            fontSize: originalNode.fontSize,
            isTask: originalNode.isTask,
            parentID: originalNode.parentID
        )
        
        let validationResult = nodeValidator.validateForCreation(duplicatedNode)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "ノード複製バリデーションエラー")
        }
        
        try await nodeRepository.save(duplicatedNode)
        
        // 親ノードに追加
        if let parentID = originalNode.parentID {
            if var parentNode = try await nodeRepository.findByID(parentID) {
                parentNode.addChild(duplicatedNode.id)
                try await nodeRepository.save(parentNode)
            }
        }
        
        return duplicatedNode
    }
    
    public func mergeNodes(_ sourceID: UUID, into targetID: UUID) async throws {
        guard let sourceNode = try await nodeRepository.findByID(sourceID) else {
            throw MindMapError.invalidNodeData
        }
        
        guard var targetNode = try await nodeRepository.findByID(targetID) else {
            throw MindMapError.invalidNodeData
        }
        
        // テキストをマージ
        let mergedText = targetNode.text + "\n" + sourceNode.text
        targetNode.updateText(mergedText)
        
        // 子ノードを移動
        for childID in sourceNode.childIDs {
            if var childNode = try await nodeRepository.findByID(childID) {
                childNode.parentID = targetID
                try await nodeRepository.save(childNode)
                targetNode.addChild(childID)
            }
        }
        
        // メディアとタグを移動
        for mediaID in sourceNode.mediaIDs {
            targetNode.addMedia(mediaID)
        }
        
        for tagID in sourceNode.tagIDs {
            targetNode.addTag(tagID)
        }
        
        let validationResult = nodeValidator.validate(targetNode)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "ノードマージバリデーションエラー")
        }
        
        try await nodeRepository.save(targetNode)
        
        // 元のノードを削除
        try await nodeRepository.delete(sourceID)
        
        // 親ノードから削除
        if let parentID = sourceNode.parentID {
            if var parentNode = try await nodeRepository.findByID(parentID) {
                parentNode.removeChild(sourceID)
                try await nodeRepository.save(parentNode)
            }
        }
    }
}

// MARK: - Tag Management Service
public protocol TagManagementServiceProtocol {
    func createTag(name: String, color: NodeColor, description: String?) async throws -> Tag
    func updateTag(_ tagID: UUID, name: String?, color: NodeColor?, description: String?) async throws
    func deleteTag(_ tagID: UUID) async throws
    func addTagToNode(_ tagID: UUID, nodeID: UUID) async throws
    func removeTagFromNode(_ tagID: UUID, nodeID: UUID) async throws
    func findOrCreateTag(name: String, color: NodeColor) async throws -> Tag
    func getTagUsageStatistics() async throws -> [TagUsageStatistic]
}

public struct TagUsageStatistic {
    public let tag: Tag
    public let usageCount: Int
    
    public init(tag: Tag, usageCount: Int) {
        self.tag = tag
        self.usageCount = usageCount
    }
}

public final class TagManagementService: TagManagementServiceProtocol {
    private let tagRepository: TagRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    
    public init(
        tagRepository: TagRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol
    ) {
        self.tagRepository = tagRepository
        self.nodeRepository = nodeRepository
    }
    
    public func createTag(name: String, color: NodeColor, description: String?) async throws -> Tag {
        // 同名のタグが既に存在するかチェック
        let existingTags = try await tagRepository.findByName(name)
        if !existingTags.isEmpty {
            throw MindMapError.validationError("同名のタグが既に存在します")
        }
        
        let tag = Tag(name: name, color: color, description: description)
        try await tagRepository.save(tag)
        return tag
    }
    
    public func updateTag(_ tagID: UUID, name: String?, color: NodeColor?, description: String?) async throws {
        guard var tag = try await tagRepository.findByID(tagID) else {
            throw MindMapError.invalidNodeData
        }
        
        if let name = name {
            // 同名チェック（自分以外）
            let existingTags = try await tagRepository.findByName(name)
            if existingTags.contains(where: { $0.id != tagID }) {
                throw MindMapError.validationError("同名のタグが既に存在します")
            }
            tag.updateName(name)
        }
        
        if let color = color {
            tag.updateColor(color)
        }
        
        if let description = description {
            tag.updateDescription(description)
        }
        
        try await tagRepository.save(tag)
    }
    
    public func deleteTag(_ tagID: UUID) async throws {
        // タグを使用しているノードから削除
        let nodesWithTag = try await nodeRepository.findByTag(tagID)
        for var node in nodesWithTag {
            node.removeTag(tagID)
            try await nodeRepository.save(node)
        }
        
        try await tagRepository.delete(tagID)
    }
    
    public func addTagToNode(_ tagID: UUID, nodeID: UUID) async throws {
        guard try await tagRepository.exists(tagID) else {
            throw MindMapError.invalidNodeData
        }
        
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        node.addTag(tagID)
        try await nodeRepository.save(node)
    }
    
    public func removeTagFromNode(_ tagID: UUID, nodeID: UUID) async throws {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        node.removeTag(tagID)
        try await nodeRepository.save(node)
    }
    
    public func findOrCreateTag(name: String, color: NodeColor) async throws -> Tag {
        let existingTags = try await tagRepository.findByName(name)
        
        if let existingTag = existingTags.first {
            return existingTag
        }
        
        return try await createTag(name: name, color: color, description: nil)
    }
    
    public func getTagUsageStatistics() async throws -> [TagUsageStatistic] {
        let allTags = try await tagRepository.findAll()
        var statistics: [TagUsageStatistic] = []
        
        for tag in allTags {
            let usageCount = try await tagRepository.getUsageCount(for: tag.id)
            statistics.append(TagUsageStatistic(tag: tag, usageCount: usageCount))
        }
        
        return statistics.sorted { $0.usageCount > $1.usageCount }
    }
}