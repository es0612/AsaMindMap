import Foundation
import CoreGraphics

// MARK: - Node Entity
public struct Node: Identifiable, Equatable, Codable, Sendable {
    public let id: UUID
    public var text: String
    public var position: CGPoint
    public var backgroundColor: NodeColor
    public var textColor: NodeColor
    public var fontSize: CGFloat
    public var isCollapsed: Bool
    public var isTask: Bool
    public var isCompleted: Bool
    public var parentID: UUID?
    public var childIDs: Set<UUID>
    public var mediaIDs: Set<UUID>
    public var tagIDs: Set<UUID>
    public let createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        text: String,
        position: CGPoint,
        backgroundColor: NodeColor = .default,
        textColor: NodeColor = .primary,
        fontSize: CGFloat = 16.0,
        isCollapsed: Bool = false,
        isTask: Bool = false,
        isCompleted: Bool = false,
        parentID: UUID? = nil,
        childIDs: Set<UUID> = [],
        mediaIDs: Set<UUID> = [],
        tagIDs: Set<UUID> = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.text = text
        self.position = position
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.fontSize = fontSize
        self.isCollapsed = isCollapsed
        self.isTask = isTask
        self.isCompleted = isCompleted
        self.parentID = parentID
        self.childIDs = childIDs
        self.mediaIDs = mediaIDs
        self.tagIDs = tagIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    public var hasChildren: Bool {
        !childIDs.isEmpty
    }
    
    public var hasMedia: Bool {
        !mediaIDs.isEmpty
    }
    
    public var hasTags: Bool {
        !tagIDs.isEmpty
    }
    
    public var isRoot: Bool {
        parentID == nil
    }
    
    // MARK: - Mutating Methods
    public mutating func updateText(_ newText: String) {
        text = newText
        updatedAt = Date()
    }
    
    public mutating func updatePosition(_ newPosition: CGPoint) {
        position = newPosition
        updatedAt = Date()
    }
    
    public mutating func addChild(_ childID: UUID) {
        childIDs.insert(childID)
        updatedAt = Date()
    }
    
    public mutating func removeChild(_ childID: UUID) {
        childIDs.remove(childID)
        updatedAt = Date()
    }
    
    public mutating func addMedia(_ mediaID: UUID) {
        mediaIDs.insert(mediaID)
        updatedAt = Date()
    }
    
    public mutating func removeMedia(_ mediaID: UUID) {
        mediaIDs.remove(mediaID)
        updatedAt = Date()
    }
    
    public mutating func addTag(_ tagID: UUID) {
        tagIDs.insert(tagID)
        updatedAt = Date()
    }
    
    public mutating func removeTag(_ tagID: UUID) {
        tagIDs.remove(tagID)
        updatedAt = Date()
    }
    
    public mutating func toggleTask() {
        isTask.toggle()
        if !isTask {
            isCompleted = false
        }
        updatedAt = Date()
    }
    
    public mutating func toggleCompleted() {
        guard isTask else { return }
        isCompleted.toggle()
        updatedAt = Date()
    }
    
    public mutating func toggleCollapsed() {
        isCollapsed.toggle()
        updatedAt = Date()
    }
}

// MARK: - Node Color
public enum NodeColor: String, CaseIterable, Codable, Sendable {
    case `default` = "default"
    case primary = "primary"
    case secondary = "secondary"
    case accent = "accent"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case gray = "gray"
    
    public var displayName: String {
        switch self {
        case .default: return "デフォルト"
        case .primary: return "プライマリ"
        case .secondary: return "セカンダリ"
        case .accent: return "アクセント"
        case .red: return "赤"
        case .orange: return "オレンジ"
        case .yellow: return "黄"
        case .green: return "緑"
        case .blue: return "青"
        case .purple: return "紫"
        case .pink: return "ピンク"
        case .gray: return "グレー"
        }
    }
}