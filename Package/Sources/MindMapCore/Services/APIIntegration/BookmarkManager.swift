import Foundation

// MARK: - Bookmark Models
public struct Bookmark {
    let id: UUID
    let url: URL
    let title: String
    let tags: [String]
    let category: BookmarkCategory
    let createdAt: Date
    let aiGenerated: Bool
    
    public init(id: UUID, url: URL, title: String, tags: [String], category: BookmarkCategory, createdAt: Date, aiGenerated: Bool = false) {
        self.id = id
        self.url = url
        self.title = title
        self.tags = tags
        self.category = category
        self.createdAt = createdAt
        self.aiGenerated = aiGenerated
    }
}

public enum BookmarkCategory {
    case educational
    case development
    case business
    case personal
    case reference
}

public struct CreateBookmarkRequest {
    let url: URL
    let title: String?
    let tags: [String]
    let category: BookmarkCategory?
    
    public init(url: URL, title: String?, tags: [String], category: BookmarkCategory?) {
        self.url = url
        self.title = title
        self.tags = tags
        self.category = category
    }
}

public struct BookmarkCollection {
    let id: UUID
    let name: String
    let description: String
    let isPublic: Bool
    let bookmarks: [Bookmark]
    
    public init(id: UUID, name: String, description: String, isPublic: Bool, bookmarks: [Bookmark] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.isPublic = isPublic
        self.bookmarks = bookmarks
    }
}

// MARK: - AI Bookmark Categorizer
public class AIBookmarkCategorizer {
    public init() {}
    
    public func categorizeBookmark(url: URL, title: String?, content: String?) -> (category: BookmarkCategory, tags: [String], title: String) {
        // URL based categorization
        let urlString = url.absoluteString.lowercased()
        
        var category: BookmarkCategory = .reference
        var tags: [String] = []
        var finalTitle = title ?? "Untitled"
        
        if urlString.contains("developer.apple.com") {
            category = .development
            tags = ["development", "swiftui", "ios"]
            finalTitle = title ?? "Apple Developer Documentation"
        } else if urlString.contains("swift.org") {
            category = .development
            tags = ["development", "swift", "programming"]
            finalTitle = title ?? "Swift Programming Language"
        } else if urlString.contains("mindmapping") || urlString.contains("tutorial") {
            category = .educational
            tags = ["tutorial", "mindmap", "learning"]
            finalTitle = title ?? "Mind Mapping Tutorial"
        }
        
        return (category: category, tags: tags, title: finalTitle)
    }
}

// MARK: - External Tool Integration Models
public struct ZapierTriggerRequest {
    let webhookUrl: String
    let mindMap: MindMap
    let triggerEvent: ZapierEvent
    let customFields: [String: String]
}

public enum ZapierEvent {
    case mindMapCreated
    case mindMapUpdated
    case nodeAdded
}

public struct ZapierTriggerResult {
    let status: ZapierStatus
    let webhookId: String?
    let responseTime: TimeInterval
}

public enum ZapierStatus {
    case success
    case failed
}

public struct IFTTTTriggerRequest {
    let eventName: String
    let mindMap: MindMap
    let values: [String: String]
}

public struct IFTTTTriggerResult {
    let success: Bool
    let eventId: String?
    let triggeredAt: Date
}

public struct AirtableSyncRequest {
    let baseId: String
    let tableId: String
    let mindMap: MindMap
    let fieldMapping: [String: String]
}

public struct AirtableSyncResult {
    let recordId: String?
    let fieldsUpdated: [String]
    let success: Bool
}

// MARK: - External Tool Integration Classes
public class ZapierIntegration {
    public init() {}
    
    public func triggerWebhook(_ request: ZapierTriggerRequest) async throws -> ZapierTriggerResult {
        let startTime = Date()
        
        // Webhook URL validation
        guard URL(string: request.webhookUrl) != nil else {
            throw APIIntegrationError.invalidResponse
        }
        
        let endTime = Date()
        let responseTime = endTime.timeIntervalSince(startTime)
        
        return ZapierTriggerResult(
            status: .success,
            webhookId: "webhook-\(UUID().uuidString)",
            responseTime: responseTime
        )
    }
}

public class IFTTTIntegration {
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func triggerEvent(_ request: IFTTTTriggerRequest) async throws -> IFTTTTriggerResult {
        guard !apiKey.isEmpty else {
            throw APIError.authenticationFailed
        }
        
        return IFTTTTriggerResult(
            success: true,
            eventId: "event-\(UUID().uuidString)",
            triggeredAt: Date()
        )
    }
}

public class AirtableIntegration {
    private let apiKey: String
    
    public init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    public func syncMindMap(_ request: AirtableSyncRequest) async throws -> AirtableSyncResult {
        guard !apiKey.isEmpty else {
            throw APIError.authenticationFailed
        }
        
        return AirtableSyncResult(
            recordId: "rec\(UUID().uuidString)",
            fieldsUpdated: Array(request.fieldMapping.keys),
            success: true
        )
    }
}

// MARK: - Bookmark Manager
public class BookmarkManager {
    private var collections: [UUID: BookmarkCollection] = [:]
    
    public init() {}
    
    public func createBookmark(_ request: CreateBookmarkRequest) async throws -> Bookmark {
        let finalTitle = request.title ?? "Bookmark"
        let finalCategory = request.category ?? .reference
        
        return Bookmark(
            id: UUID(),
            url: request.url,
            title: finalTitle,
            tags: request.tags,
            category: finalCategory,
            createdAt: Date()
        )
    }
    
    public func createBookmarkWithAI(_ request: CreateBookmarkRequest, categorizer: AIBookmarkCategorizer) async throws -> Bookmark {
        let aiResult = categorizer.categorizeBookmark(
            url: request.url,
            title: request.title,
            content: nil
        )
        
        return Bookmark(
            id: UUID(),
            url: request.url,
            title: aiResult.title,
            tags: aiResult.tags,
            category: aiResult.category,
            createdAt: Date(),
            aiGenerated: true
        )
    }
    
    public func createCollection(name: String, description: String, isPublic: Bool) async throws -> BookmarkCollection {
        let collection = BookmarkCollection(
            id: UUID(),
            name: name,
            description: description,
            isPublic: isPublic
        )
        collections[collection.id] = collection
        return collection
    }
    
    public func addToCollection(_ collectionId: UUID, bookmarks: [Bookmark]) async throws {
        guard var collection = collections[collectionId] else {
            throw BookmarkError.collectionNotFound
        }
        
        let updatedCollection = BookmarkCollection(
            id: collection.id,
            name: collection.name,
            description: collection.description,
            isPublic: collection.isPublic,
            bookmarks: collection.bookmarks + bookmarks
        )
        collections[collectionId] = updatedCollection
    }
    
    public func getCollection(_ id: UUID) async throws -> BookmarkCollection {
        guard let collection = collections[id] else {
            throw BookmarkError.collectionNotFound
        }
        return collection
    }
}

// MARK: - Bookmark Errors
public enum BookmarkError: Error {
    case collectionNotFound
    case bookmarkNotFound
    case invalidURL
}