import Foundation

// MARK: - Media Entity
public struct Media: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public let type: MediaType
    public var data: Data?
    public var url: String?
    public var thumbnailData: Data?
    public var fileName: String?
    public var fileSize: Int64?
    public var mimeType: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        type: MediaType,
        data: Data? = nil,
        url: String? = nil,
        thumbnailData: Data? = nil,
        fileName: String? = nil,
        fileSize: Int64? = nil,
        mimeType: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.data = data
        self.url = url
        self.thumbnailData = thumbnailData
        self.fileName = fileName
        self.fileSize = fileSize
        self.mimeType = mimeType
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    public var hasData: Bool {
        data != nil
    }
    
    public var hasURL: Bool {
        url != nil && !url!.isEmpty
    }
    
    public var hasThumbnail: Bool {
        thumbnailData != nil
    }
    
    public var displayName: String {
        fileName ?? type.displayName
    }
    
    public var fileSizeFormatted: String {
        guard let size = fileSize else { return "不明" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    // MARK: - Mutating Methods
    public mutating func updateData(_ newData: Data) {
        data = newData
        fileSize = Int64(newData.count)
        updatedAt = Date()
    }
    
    public mutating func updateURL(_ newURL: String) {
        url = newURL
        updatedAt = Date()
    }
    
    public mutating func updateThumbnail(_ thumbnailData: Data) {
        self.thumbnailData = thumbnailData
        updatedAt = Date()
    }
    
    public mutating func updateFileName(_ name: String) {
        fileName = name
        updatedAt = Date()
    }
}

// MARK: - Media Type
public enum MediaType: String, CaseIterable, Codable, Sendable {
    case image = "image"
    case link = "link"
    case sticker = "sticker"
    case document = "document"
    case audio = "audio"
    case video = "video"
    
    public var displayName: String {
        switch self {
        case .image: return "画像"
        case .link: return "リンク"
        case .sticker: return "ステッカー"
        case .document: return "ドキュメント"
        case .audio: return "音声"
        case .video: return "動画"
        }
    }
    
    public var supportedMimeTypes: [String] {
        switch self {
        case .image:
            return ["image/jpeg", "image/png", "image/gif", "image/webp", "image/heic"]
        case .link:
            return ["text/uri-list"]
        case .sticker:
            return ["image/png", "image/gif"]
        case .document:
            return ["application/pdf", "text/plain", "application/msword"]
        case .audio:
            return ["audio/mpeg", "audio/wav", "audio/aac", "audio/m4a"]
        case .video:
            return ["video/mp4", "video/quicktime", "video/mov"]
        }
    }
    
    public func isValidMimeType(_ mimeType: String) -> Bool {
        supportedMimeTypes.contains(mimeType.lowercased())
    }
}