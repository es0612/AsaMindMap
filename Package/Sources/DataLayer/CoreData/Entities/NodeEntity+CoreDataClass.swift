import Foundation
import CoreData
import CoreGraphics
import MindMapCore

@objc(NodeEntity)
public class NodeEntity: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> Node {
        let childIDs = Set((childNodes?.allObjects as? [NodeEntity])?.map { $0.id! } ?? [])
        let mediaIDs = Set((media?.allObjects as? [MediaEntity])?.map { $0.id! } ?? [])
        let tagIDs = Set((tags?.allObjects as? [TagEntity])?.map { $0.id! } ?? [])
        
        return Node(
            id: id!,
            text: text!,
            position: CGPoint(x: CGFloat(positionX), y: CGFloat(positionY)),
            backgroundColor: NodeColor(rawValue: backgroundColor!) ?? .default,
            textColor: NodeColor(rawValue: textColor!) ?? .primary,
            fontSize: CGFloat(fontSize),
            isCollapsed: isCollapsed,
            isTask: isTask,
            isCompleted: isCompleted,
            parentID: parentID,
            childIDs: childIDs,
            mediaIDs: mediaIDs,
            tagIDs: tagIDs,
            createdAt: createdAt!,
            updatedAt: updatedAt!
        )
    }
    
    /// Update entity from domain model
    func updateFromDomainModel(_ node: Node) {
        id = node.id
        text = node.text
        positionX = Float(node.position.x)
        positionY = Float(node.position.y)
        backgroundColor = node.backgroundColor.rawValue
        textColor = node.textColor.rawValue
        fontSize = Float(node.fontSize)
        isCollapsed = node.isCollapsed
        isTask = node.isTask
        isCompleted = node.isCompleted
        parentID = node.parentID
        createdAt = node.createdAt
        updatedAt = node.updatedAt
    }
    
    /// Create new entity from domain model
    static func fromDomainModel(_ node: Node, context: NSManagedObjectContext) -> NodeEntity {
        let entity = NodeEntity(context: context)
        entity.updateFromDomainModel(node)
        return entity
    }
}