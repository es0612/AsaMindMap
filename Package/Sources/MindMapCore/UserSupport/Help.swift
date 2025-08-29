import Foundation

// MARK: - Help Category

public enum HelpCategory: String, CaseIterable, Codable {
    case gettingStarted = "getting_started"
    case basic = "basic"
    case advanced = "advanced"
    case troubleshooting = "troubleshooting"
    case features = "features"
    
    public var displayName: String {
        switch self {
        case .gettingStarted:
            return "はじめに"
        case .basic:
            return "基本操作"
        case .advanced:
            return "高度な機能"
        case .troubleshooting:
            return "トラブルシューティング"
        case .features:
            return "機能紹介"
        }
    }
}

// MARK: - Help Step

public struct HelpStep: Identifiable, Codable {
    public let id: UUID
    public let order: Int
    public let title: String
    public let description: String
    public let imageName: String?
    
    public init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        description: String,
        imageName: String? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.description = description
        self.imageName = imageName
    }
}

// MARK: - Help Content

public struct HelpContent: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let content: String
    public let category: HelpCategory
    public private(set) var steps: [HelpStep]
    
    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        category: HelpCategory,
        steps: [HelpStep] = []
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.steps = steps.sorted { $0.order < $1.order }
    }
    
    // MARK: - Public Methods
    
    public mutating func addStep(_ step: HelpStep) {
        steps.append(step)
        steps.sort { $0.order < $1.order }
    }
    
    public mutating func removeStep(withId id: UUID) {
        steps.removeAll { $0.id == id }
    }
    
    public var stepCount: Int {
        steps.count
    }
    
    public var isMultiStep: Bool {
        steps.count > 1
    }
}

// MARK: - Help Content Extensions

extension HelpContent: Equatable {
    public static func == (lhs: HelpContent, rhs: HelpContent) -> Bool {
        lhs.id == rhs.id
    }
}

extension HelpContent: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}