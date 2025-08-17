import Foundation
import CoreData

extension MediaEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MediaEntity> {
        return NSFetchRequest<MediaEntity>(entityName: "MediaEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var type: String?
    @NSManaged public var data: Data?
    @NSManaged public var url: String?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var fileName: String?
    @NSManaged public var fileSize: Int64
    @NSManaged public var mimeType: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
    @NSManaged public var mindMap: MindMapEntity?
    @NSManaged public var nodes: NSSet?

}

// MARK: Generated accessors for nodes
extension MediaEntity {

    @objc(addNodesObject:)
    @NSManaged public func addToNodes(_ value: NodeEntity)

    @objc(removeNodesObject:)
    @NSManaged public func removeFromNodes(_ value: NodeEntity)

    @objc(addNodes:)
    @NSManaged public func addToNodes(_ values: NSSet)

    @objc(removeNodes:)
    @NSManaged public func removeFromNodes(_ values: NSSet)

}