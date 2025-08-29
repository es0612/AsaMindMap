import Foundation
import CoreGraphics

// MARK: - Tutorial Feature

public enum TutorialFeature: String, CaseIterable, Codable {
    case mindMapCreation = "mindmap_creation"
    case nodeEditing = "node_editing"
    case gestures = "gestures"
    case basic = "basic"
    case mediaAttachment = "media_attachment"
    case sharing = "sharing"
    case export = "export"
    
    public var displayName: String {
        switch self {
        case .mindMapCreation:
            return "マインドマップ作成"
        case .nodeEditing:
            return "ノード編集"
        case .gestures:
            return "ジェスチャー操作"
        case .basic:
            return "基本操作"
        case .mediaAttachment:
            return "メディア添付"
        case .sharing:
            return "共有機能"
        case .export:
            return "エクスポート機能"
        }
    }
}

// MARK: - Tutorial Action

public enum TutorialAction: String, Codable {
    case tap = "tap"
    case drag = "drag"
    case pinch = "pinch"
    case longPress = "long_press"
    case swipe = "swipe"
    case doubleTap = "double_tap"
    
    public var displayName: String {
        switch self {
        case .tap:
            return "タップ"
        case .drag:
            return "ドラッグ"
        case .pinch:
            return "ピンチ"
        case .longPress:
            return "長押し"
        case .swipe:
            return "スワイプ"
        case .doubleTap:
            return "ダブルタップ"
        }
    }
}

// MARK: - Tutorial Step

public struct TutorialStep: Identifiable, Codable {
    public let id: UUID
    public let order: Int
    public let instruction: String
    public let highlightArea: CGRect
    public let action: TutorialAction
    public private(set) var isCompleted: Bool
    
    public init(
        id: UUID = UUID(),
        order: Int,
        instruction: String,
        highlightArea: CGRect,
        action: TutorialAction,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.order = order
        self.instruction = instruction
        self.highlightArea = highlightArea
        self.action = action
        self.isCompleted = isCompleted
    }
    
    // MARK: - Public Methods
    
    public mutating func complete() {
        isCompleted = true
    }
    
    public mutating func reset() {
        isCompleted = false
    }
}

// MARK: - Tutorial

public struct Tutorial: Identifiable, Codable {
    public let id: UUID
    public let title: String
    public let description: String
    public let targetFeature: TutorialFeature
    public private(set) var steps: [TutorialStep]
    public var isCompleted: Bool { calculateCompletion() }
    
    public init(
        id: UUID = UUID(),
        title: String,
        description: String,
        targetFeature: TutorialFeature,
        steps: [TutorialStep] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.targetFeature = targetFeature
        self.steps = steps.sorted { $0.order < $1.order }
    }
    
    // MARK: - Public Methods
    
    public mutating func addStep(_ step: TutorialStep) {
        steps.append(step)
        steps.sort { $0.order < $1.order }
    }
    
    public mutating func completeStep(at index: Int) {
        guard index >= 0 && index < steps.count else { return }
        steps[index].complete()
    }
    
    public mutating func resetStep(at index: Int) {
        guard index >= 0 && index < steps.count else { return }
        steps[index].reset()
    }
    
    public var progress: Double {
        guard !steps.isEmpty else { return 1.0 }
        let completedSteps = steps.filter { $0.isCompleted }.count
        return Double(completedSteps) / Double(steps.count)
    }
    
    public var currentStepIndex: Int? {
        steps.firstIndex { !$0.isCompleted }
    }
    
    public var currentStep: TutorialStep? {
        guard let index = currentStepIndex else { return nil }
        return steps[index]
    }
    
    // MARK: - Private Methods
    
    private func calculateCompletion() -> Bool {
        steps.allSatisfy { $0.isCompleted }
    }
}

// MARK: - Tutorial Extensions

extension Tutorial: Equatable {
    public static func == (lhs: Tutorial, rhs: Tutorial) -> Bool {
        lhs.id == rhs.id
    }
}

extension Tutorial: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// Note: CGRect already conforms to Codable in iOS 16+, so no custom implementation needed