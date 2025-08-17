import Foundation
import CoreData

extension NodeEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<NodeEntity> {
        return NSFetchRequest<NodeEntity>(entityName: "NodeEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var text: String?
    @NSManaged public var positionX: Float
    @NSManaged public var positionY: Float
    @NSManaged public var backgroundColor: String?
    @NSManaged public var textColor: String?
    @NSManaged public var fontSize: Float
    @NSManaged public var isCollapsed: Bool
    @NSManaged public var isTask: Bool
    @NSManaged public var isCompleted: Bool
    @NSManaged public var parentID: UUID?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var mindMap: MindMapEntity?
    @NSManaged public var parentNode: NodeEntity?
    @NSManaged public var childNodes: NSSet?
    @NSManaged public var media: NSSet?
    @NSManaged public var tags: NSSet?

}

// MARK: Generated accessors for childNodes
extension NodeEntity {

    @objc(addChildNodesObject:)
    @NSManaged public func addToChildNodes(_ value: NodeEntity)

    @objc(removeChildNodesObject:)
    @NSManaged public func removeFromChildNodes(_ value: NodeEntity)

    @objc(addChildNodes:)
    @NSManaged public func addToChildNodes(_ values: NSSet)

    @objc(removeChildNodes:)
    @NSManaged public func removeFromChildNodes(_ values: NSSet)

}

// MARK: Generated accessors for media
extension NodeEntity {

    @objc(addMediaObject:)
    @NSManaged public func addToMedia(_ value: MediaEntity)

    @objc(removeMediaObject:)
    @NSManaged public func removeFromMedia(_ value: MediaEntity)

    @objc(addMedia:)
    @NSManaged public func addToMedia(_ values: NSSet)

    @objc(removeMedia:)
    @NSManaged public func removeFromMedia(_ values: NSSet)

}

// MARK: Generated accessors for tags
extension NodeEntity {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: TagEntity)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: TagEntity)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}