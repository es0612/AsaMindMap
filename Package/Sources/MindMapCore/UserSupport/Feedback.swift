import Foundation

// MARK: - Feedback Type

public enum FeedbackType: String, CaseIterable, Codable {
    case bug = "bug"
    case feature = "feature"
    case improvement = "improvement"
    case question = "question"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .bug:
            return "バグ報告"
        case .feature:
            return "機能リクエスト"
        case .improvement:
            return "改善提案"
        case .question:
            return "質問"
        case .other:
            return "その他"
        }
    }
    
    public var defaultPriority: FeedbackPriority {
        switch self {
        case .bug:
            return .high
        case .feature:
            return .medium
        case .improvement:
            return .medium
        case .question:
            return .low
        case .other:
            return .low
        }
    }
}

// MARK: - Feedback Priority

public enum FeedbackPriority: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low:
            return "低"
        case .medium:
            return "中"
        case .high:
            return "高"
        case .critical:
            return "緊急"
        }
    }
}

// MARK: - Feedback Status

public enum FeedbackStatus: String, CaseIterable, Codable {
    case pending = "pending"
    case inReview = "in_review"
    case resolved = "resolved"
    case closed = "closed"
    
    public var displayName: String {
        switch self {
        case .pending:
            return "受信済み"
        case .inReview:
            return "確認中"
        case .resolved:
            return "解決済み"
        case .closed:
            return "終了"
        }
    }
}

// MARK: - Device Info

public struct DeviceInfo: Codable {
    public let model: String
    public let osVersion: String
    public let appVersion: String
    public let buildNumber: String?
    public let locale: String?
    public let timezone: String?
    
    public init(
        model: String,
        osVersion: String,
        appVersion: String,
        buildNumber: String? = nil,
        locale: String? = nil,
        timezone: String? = nil
    ) {
        self.model = model
        self.osVersion = osVersion
        self.appVersion = appVersion
        self.buildNumber = buildNumber
        self.locale = locale
        self.timezone = timezone
    }
    
    public static var current: DeviceInfo {
        #if canImport(UIKit)
        return currentUIKit
        #else
        return DeviceInfo(
            model: "Unknown",
            osVersion: "Unknown",
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier
        )
        #endif
    }
}

// MARK: - Feedback Attachment Type

public enum FeedbackAttachmentType: String, CaseIterable, Codable {
    case screenshot = "screenshot"
    case video = "video"
    case log = "log"
    case document = "document"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .screenshot:
            return "スクリーンショット"
        case .video:
            return "動画"
        case .log:
            return "ログファイル"
        case .document:
            return "ドキュメント"
        case .other:
            return "その他"
        }
    }
    
    public var maxSize: Int {
        switch self {
        case .screenshot:
            return 5 * 1024 * 1024 // 5MB
        case .video:
            return 25 * 1024 * 1024 // 25MB
        case .log:
            return 1 * 1024 * 1024 // 1MB
        case .document:
            return 10 * 1024 * 1024 // 10MB
        case .other:
            return 5 * 1024 * 1024 // 5MB
        }
    }
}

// MARK: - Feedback Attachment

public struct FeedbackAttachment: Identifiable, Codable {
    public let id: UUID
    public let type: FeedbackAttachmentType
    public let filename: String
    public let data: Data
    public let mimeType: String
    public let size: Int
    
    public init(
        id: UUID = UUID(),
        type: FeedbackAttachmentType,
        filename: String,
        data: Data,
        mimeType: String
    ) {
        self.id = id
        self.type = type
        self.filename = filename
        self.data = data
        self.mimeType = mimeType
        self.size = data.count
    }
    
    public var isValidSize: Bool {
        size <= type.maxSize
    }
}

// MARK: - Feedback

public struct Feedback: Identifiable, Codable {
    public let id: UUID
    public let type: FeedbackType
    public let title: String
    public let description: String
    public let userEmail: String?
    public let deviceInfo: DeviceInfo
    public private(set) var attachments: [FeedbackAttachment]
    public let status: FeedbackStatus
    public let createdAt: Date
    
    public init(
        id: UUID = UUID(),
        type: FeedbackType,
        title: String,
        description: String,
        userEmail: String? = nil,
        deviceInfo: DeviceInfo,
        attachments: [FeedbackAttachment] = [],
        status: FeedbackStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.description = description
        self.userEmail = userEmail
        self.deviceInfo = deviceInfo
        self.attachments = attachments
        self.status = status
        self.createdAt = createdAt
    }
    
    // MARK: - Public Methods
    
    public mutating func addAttachment(_ attachment: FeedbackAttachment) {
        guard attachment.isValidSize else { return }
        attachments.append(attachment)
    }
    
    public mutating func removeAttachment(withId id: UUID) {
        attachments.removeAll { $0.id == id }
    }
    
    public var priority: FeedbackPriority {
        type.defaultPriority
    }
    
    public var isValid: Bool {
        // Basic validation
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        guard description.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10 else { return false }
        
        // Email validation (if provided)
        if let email = userEmail {
            let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
            let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
            guard emailPredicate.evaluate(with: email) else { return false }
        }
        
        // Device info validation
        guard !deviceInfo.model.isEmpty else { return false }
        guard !deviceInfo.osVersion.isEmpty else { return false }
        guard !deviceInfo.appVersion.isEmpty else { return false }
        
        return true
    }
    
    public var totalAttachmentSize: Int {
        attachments.reduce(0) { $0 + $1.size }
    }
    
    public var isAttachmentSizeValid: Bool {
        totalAttachmentSize <= 50 * 1024 * 1024 // Total limit: 50MB
    }
}

// MARK: - Feedback Extensions

extension Feedback: Equatable {
    public static func == (lhs: Feedback, rhs: Feedback) -> Bool {
        lhs.id == rhs.id
    }
}

extension Feedback: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - UIKit Compatibility

#if canImport(UIKit)
import UIKit

private extension DeviceInfo {
    static var currentUIKit: DeviceInfo {
        DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier
        )
    }
}
#endif