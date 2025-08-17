import Foundation
import CoreData
import MindMapCore

@objc(MindMapEntity)
public class MindMapEntity: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> MindMap {
        let nodeIDs = Set((nodes?.allObjects as? [NodeEntity])?.map { $0.id! } ?? [])
        let tagIDs = Set((tags?.allObjects as? [TagEntity])?.map { $0.id! } ?? [])
        let mediaIDs = Set((media?.allObjects as? [MediaEntity])?.map { $0.id! } ?? [])
        
        return MindMap(
            id: id!,
            title: title!,
            rootNodeID: rootNodeID,
            nodeIDs: nodeIDs,
            tagIDs: tagIDs,
            mediaIDs: mediaIDs,
            isShared: isShared,
            shareURL: shareURL,
            sharePermissions: SharePermissions(rawValue: sharePermissions!) ?? .private,
            createdAt: createdAt!,
            updatedAt: updatedAt!,
            lastSyncedAt: lastSyncedAt,
            version: Int(version)
        )
    }
    
    /// Update entity from domain model
    func updateFromDomainModel(_ mindMap: MindMap) {
        id = mindMap.id
        title = mindMap.title
        rootNodeID = mindMap.rootNodeID
        isShared = mindMap.isShared
        shareURL = mindMap.shareURL
        sharePermissions = mindMap.sharePermissions.rawValue
        createdAt = mindMap.createdAt
        updatedAt = mindMap.updatedAt
        lastSyncedAt = mindMap.lastSyncedAt
        version = Int32(mindMap.version)
    }
    
    /// Create new entity from domain model
    static func fromDomainModel(_ mindMap: MindMap, context: NSManagedObjectContext) -> MindMapEntity {
        let entity = MindMapEntity(context: context)
        entity.updateFromDomainModel(mindMap)
        return entity
    }
}