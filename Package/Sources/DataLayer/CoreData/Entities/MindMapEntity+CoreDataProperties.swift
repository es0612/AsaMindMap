import Foundation
import CoreData

extension MindMapEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MindMapEntity> {
        return NSFetchRequest<MindMapEntity>(entityName: "MindMapEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var rootNodeID: UUID?
    @NSManaged public var isShared: Bool
    @NSManaged public var shareURL: String?
    @NSManaged public var sharePermissions: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var lastSyncedAt: Date?
    @NSManaged public var version: Int32
    @NSManaged public var nodes: NSSet?
    @NSManaged public var tags: NSSet?
    @NSManaged public var media: NSSet?

}

// MARK: Generated accessors for nodes
extension MindMapEntity {

    @objc(addNodesObject:)
    @NSManaged public func addToNodes(_ value: NodeEntity)

    @objc(removeNodesObject:)
    @NSManaged public func removeFromNodes(_ value: NodeEntity)

    @objc(addNodes:)
    @NSManaged public func addToNodes(_ values: NSSet)

    @objc(removeNodes:)
    @NSManaged public func removeFromNodes(_ values: NSSet)

}

// MARK: Generated accessors for tags
extension MindMapEntity {

    @objc(addTagsObject:)
    @NSManaged public func addToTags(_ value: TagEntity)

    @objc(removeTagsObject:)
    @NSManaged public func removeFromTags(_ value: TagEntity)

    @objc(addTags:)
    @NSManaged public func addToTags(_ values: NSSet)

    @objc(removeTags:)
    @NSManaged public func removeFromTags(_ values: NSSet)

}

// MARK: Generated accessors for media
extension MindMapEntity {

    @objc(addMediaObject:)
    @NSManaged public func addToMedia(_ value: MediaEntity)

    @objc(removeMediaObject:)
    @NSManaged public func removeFromMedia(_ value: MediaEntity)

    @objc(addMedia:)
    @NSManaged public func addToMedia(_ values: NSSet)

    @objc(removeMedia:)
    @NSManaged public func removeFromMedia(_ values: NSSet)

}