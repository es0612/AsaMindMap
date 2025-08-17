import Foundation
import CoreData
import MindMapCore

@objc(MediaEntity)
public class MediaEntity: NSManagedObject {
    
    // MARK: - Convenience Methods
    
    /// Convert Core Data entity to domain model
    func toDomainModel() -> Media {
        return Media(
            id: id!,
            type: MediaType(rawValue: type!) ?? .image,
            data: data,
            url: url,
            thumbnailData: thumbnailData,
            fileName: fileName,
            fileSize: fileSize > 0 ? fileSize : nil,
            mimeType: mimeType,
            createdAt: createdAt!,
            updatedAt: updatedAt!
        )
    }
    
    /// Update entity from domain model
    func updateFromDomainModel(_ media: Media) {
        id = media.id
        type = media.type.rawValue
        data = media.data
        url = media.url
        thumbnailData = media.thumbnailData
        fileName = media.fileName
        fileSize = media.fileSize ?? 0
        mimeType = media.mimeType
        createdAt = media.createdAt
        updatedAt = media.updatedAt
    }
    
    /// Create new entity from domain model
    static func fromDomainModel(_ media: Media, context: NSManagedObjectContext) -> MediaEntity {
        let entity = MediaEntity(context: context)
        entity.updateFromDomainModel(media)
        return entity
    }
}