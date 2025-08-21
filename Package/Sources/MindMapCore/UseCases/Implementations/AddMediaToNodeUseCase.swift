import Foundation
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Add Media to Node Use Case
public struct AddMediaToNodeUseCase: AddMediaToNodeUseCaseProtocol {
    
    // MARK: - Dependencies
    private let nodeRepository: NodeRepositoryProtocol
    private let mediaRepository: MediaRepositoryProtocol
    
    // MARK: - Initialization
    public init(
        nodeRepository: NodeRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol
    ) {
        self.nodeRepository = nodeRepository
        self.mediaRepository = mediaRepository
    }
    
    // MARK: - Execute
    public func execute(_ request: AddMediaToNodeRequest) async throws -> AddMediaToNodeResponse {
        // 1. Validate node exists
        guard var node = try await nodeRepository.findByID(request.nodeID) else {
            throw MediaError.nodeNotFound(request.nodeID)
        }
        
        // 2. Validate media data
        try validateMediaData(request)
        
        // 3. Create media entity
        let media = Media(
            type: request.mediaType,
            data: request.data,
            url: request.url,
            fileName: request.fileName,
            fileSize: request.data?.count.int64,
            mimeType: request.mimeType
        )
        
        // 4. Generate thumbnail if needed
        let mediaWithThumbnail = try await generateThumbnailIfNeeded(media)
        
        // 5. Save media
        try await mediaRepository.save(mediaWithThumbnail)
        
        // 6. Update node with media reference
        node.addMedia(mediaWithThumbnail.id)
        try await nodeRepository.save(node)
        
        return AddMediaToNodeResponse(
            media: mediaWithThumbnail,
            updatedNode: node
        )
    }
    
    // MARK: - Private Methods
    private func validateMediaData(_ request: AddMediaToNodeRequest) throws {
        switch request.mediaType {
        case .image, .sticker:
            guard request.data != nil else {
                throw MediaError.missingData(request.mediaType)
            }
            
        case .link:
            guard let url = request.url, !url.isEmpty else {
                throw MediaError.missingURL(request.mediaType)
            }
            
            guard URL(string: url) != nil else {
                throw MediaError.invalidURL(url)
            }
            
        case .document, .audio, .video:
            guard request.data != nil else {
                throw MediaError.missingData(request.mediaType)
            }
        }
        
        // Validate MIME type if provided
        if let mimeType = request.mimeType {
            guard request.mediaType.isValidMimeType(mimeType) else {
                throw MediaError.unsupportedMimeType(mimeType, request.mediaType)
            }
        }
        
        // Validate file size (10MB limit)
        if let data = request.data {
            let maxSize: Int = 10 * 1024 * 1024 // 10MB
            guard data.count <= maxSize else {
                throw MediaError.fileTooLarge(data.count, maxSize)
            }
        }
    }
    
    private func generateThumbnailIfNeeded(_ media: Media) async throws -> Media {
        guard media.type == .image, let data = media.data else {
            return media
        }
        
        var updatedMedia = media
        
        #if canImport(UIKit)
        if let image = UIImage(data: data) {
            let thumbnailSize = CGSize(width: 100, height: 100)
            let thumbnail = image.preparingThumbnail(of: thumbnailSize)
            
            if let thumbnailData = thumbnail?.jpegData(compressionQuality: 0.8) {
                updatedMedia.updateThumbnail(thumbnailData)
            }
        }
        #endif
        
        return updatedMedia
    }
}

// MARK: - Media Error
public enum MediaError: LocalizedError, Equatable {
    case nodeNotFound(UUID)
    case mediaNotFound(UUID)
    case missingData(MediaType)
    case missingURL(MediaType)
    case invalidURL(String)
    case unsupportedMimeType(String, MediaType)
    case fileTooLarge(Int, Int)
    case thumbnailGenerationFailed
    case saveFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .nodeNotFound(let id):
            return "ノードが見つかりません: \(id)"
        case .mediaNotFound(let id):
            return "メディアが見つかりません: \(id)"
        case .missingData(let type):
            return "\(type.displayName)にはデータが必要です"
        case .missingURL(let type):
            return "\(type.displayName)にはURLが必要です"
        case .invalidURL(let url):
            return "無効なURL: \(url)"
        case .unsupportedMimeType(let mimeType, let mediaType):
            return "\(mediaType.displayName)でサポートされていないファイル形式: \(mimeType)"
        case .fileTooLarge(let size, let maxSize):
            return "ファイルサイズが大きすぎます: \(size) bytes (最大: \(maxSize) bytes)"
        case .thumbnailGenerationFailed:
            return "サムネイルの生成に失敗しました"
        case .saveFailed(let reason):
            return "保存に失敗しました: \(reason)"
        }
    }
}

// MARK: - Extensions
private extension Int {
    var int64: Int64 {
        Int64(self)
    }
}

#if canImport(UIKit)
import UIKit

private extension UIImage {
    func preparingThumbnail(of size: CGSize) -> UIImage? {
        return preparingThumbnail(of: size)
    }
}
#endif