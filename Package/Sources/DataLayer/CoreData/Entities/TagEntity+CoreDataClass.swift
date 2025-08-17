import Foundation
import CoreData
import MindMapCore

@objc(TagEntity)
public class TagEntity: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> Tag {
        return Tag(
            id: id!,
            name: name!,
            color: NodeColor(rawValue: color!) ?? .accent,
            description: tagDescription,
            createdAt: createdAt!,
            updatedAt: updatedAt!
        )
    }
    
    /// Update entity from domain model
    func updateFromDomainModel(_ tag: Tag) {
        id = tag.id
        name = tag.name
        color = tag.color.rawValue
        tagDescription = tag.description
        createdAt = tag.createdAt
        updatedAt = tag.updatedAt
    }
    
    /// Create new entity from domain model
    static func fromDomainModel(_ tag: Tag, context: NSManagedObjectContext) -> TagEntity {
        let entity = TagEntity(context: context)
        entity.updateFromDomainModel(tag)
        return entity
    }
}