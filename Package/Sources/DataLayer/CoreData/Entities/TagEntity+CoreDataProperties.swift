import Foundation
import CoreData

extension TagEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
        return NSFetchRequest<TagEntity>(entityName: "TagEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var color: String?
    @NSManaged public var tagDescription: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var mindMaps: NSSet?
    @NSManaged public var nodes: NSSet?

}

// MARK: Generated accessors for mindMaps
extension TagEntity {

    @objc(addMindMapsObject:)
    @NSManaged public func addToMindMaps(_ value: MindMapEntity)

    @objc(removeMindMapsObject:)
    @NSManaged public func removeFromMindMaps(_ value: MindMapEntity)

    @objc(addMindMaps:)
    @NSManaged public func addToMindMaps(_ values: NSSet)

    @objc(removeMindMaps:)
    @NSManaged public func removeFromMindMaps(_ values: NSSet)

}

// MARK: Generated accessors for nodes
extension TagEntity {

    @objc(addNodesObject:)
    @NSManaged public func addToNodes(_ value: NodeEntity)

    @objc(removeNodesObject:)
    @NSManaged public func removeFromNodes(_ value: NodeEntity)

    @objc(addNodes:)
    @NSManaged public func addToNodes(_ values: NSSet)

    @objc(removeNodes:)
    @NSManaged public func removeFromNodes(_ values: NSSet)

}