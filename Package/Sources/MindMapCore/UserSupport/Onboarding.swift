import Foundation
import CoreGraphics

// MARK: - Onboarding Audience

public enum OnboardingAudience: String, CaseIterable, Codable {
    case firstTimeUser = "first_time_user"
    case returningUser = "returning_user"
    case versionUpdate = "version_update"
    case featureIntroduction = "feature_introduction"
    
    public var displayName: String {
        switch self {
        case .firstTimeUser:
            return "初回利用ユーザー"
        case .returningUser:
            return "リターンユーザー"
        case .versionUpdate:
            return "バージョンアップデート"
        case .featureIntroduction:
            return "新機能紹介"
        }
    }
}

// MARK: - Animation Type

public enum AnimationType: String, CaseIterable, Codable {
    case none = "none"
    case fadeIn = "fade_in"
    case slideIn = "slide_in"
    case zoomIn = "zoom_in"
    case bounceIn = "bounce_in"
    
    public var displayName: String {
        switch self {
        case .none:
            return "アニメーションなし"
        case .fadeIn:
            return "フェードイン"
        case .slideIn:
            return "スライドイン"
        case .zoomIn:
            return "ズームイン"
        case .bounceIn:
            return "バウンスイン"
        }
    }
    
    public var duration: TimeInterval {
        switch self {
        case .none:
            return 0
        case .fadeIn:
            return 0.3
        case .slideIn:
            return 0.4
        case .zoomIn:
            return 0.3
        case .bounceIn:
            return 0.6
        }
    }
}

// MARK: - Interaction Type

public enum InteractionType: String, CaseIterable, Codable {
    case tap = "tap"
    case swipe = "swipe"
    case automatic = "automatic"
    case none = "none"
    
    public var displayName: String {
        switch self {
        case .tap:
            return "タップ"
        case .swipe:
            return "スワイプ"
        case .automatic:
            return "自動"
        case .none:
            return "手動なし"
        }
    }
}

// MARK: - Onboarding Screen

public struct OnboardingScreen: Identifiable, Codable {
    public let id: UUID
    public let order: Int
    public let title: String
    public let subtitle: String
    public let content: String
    public let imageName: String?
    public let videoURL: URL?
    public let animationType: AnimationType
    public let interactionType: InteractionType
    public let skipable: Bool
    public let autoAdvanceDelay: TimeInterval?
    public let customProperties: [String: String]?
    
    public init(
        id: UUID = UUID(),
        order: Int,
        title: String,
        subtitle: String,
        content: String,
        imageName: String? = nil,
        videoURL: URL? = nil,
        animationType: AnimationType = .fadeIn,
        interactionType: InteractionType = .tap,
        skipable: Bool = true,
        autoAdvanceDelay: TimeInterval? = nil,
        customProperties: [String: String]? = nil
    ) {
        self.id = id
        self.order = order
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.imageName = imageName
        self.videoURL = videoURL
        self.animationType = animationType
        self.interactionType = interactionType
        self.skipable = skipable
        self.autoAdvanceDelay = autoAdvanceDelay
        self.customProperties = customProperties
    }
    
    public var hasMedia: Bool {
        imageName != nil || videoURL != nil
    }
    
    public var isAutoAdvance: Bool {
        interactionType == .automatic && autoAdvanceDelay != nil
    }
}

// MARK: - Onboarding Conditions

public struct OnboardingConditions: Codable {
    public let isFirstLaunch: Bool
    public let hasCreatedMindMap: Bool
    public let hasCompletedTutorial: Bool
    public let appVersion: String
    public let previousVersion: String?
    public let lastOnboardingDate: Date?
    public let deviceType: String?
    public let locale: String?
    
    public init(
        isFirstLaunch: Bool,
        hasCreatedMindMap: Bool,
        hasCompletedTutorial: Bool,
        appVersion: String,
        previousVersion: String? = nil,
        lastOnboardingDate: Date? = nil,
        deviceType: String? = nil,
        locale: String? = nil
    ) {
        self.isFirstLaunch = isFirstLaunch
        self.hasCreatedMindMap = hasCreatedMindMap
        self.hasCompletedTutorial = hasCompletedTutorial
        self.appVersion = appVersion
        self.previousVersion = previousVersion
        self.lastOnboardingDate = lastOnboardingDate
        self.deviceType = deviceType
        self.locale = locale
    }
    
    public var isVersionUpdate: Bool {
        guard let previous = previousVersion else { return false }
        return previous != appVersion
    }
    
    public var daysSinceLastOnboarding: Int? {
        guard let lastDate = lastOnboardingDate else { return nil }
        return Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day
    }
}

// MARK: - Onboarding Analytics

public struct OnboardingAnalytics: Codable {
    public let flowId: UUID
    public let startTime: Date
    public private(set) var endTime: Date?
    public private(set) var screensViewed: [ScreenViewRecord]
    public private(set) var dropOffPoints: [Int] // Screen indices where users dropped off
    public private(set) var skipEvents: [SkipEvent]
    public private(set) var interactions: [InteractionEvent]
    
    public init(flowId: UUID, startTime: Date = Date()) {
        self.flowId = flowId
        self.startTime = startTime
        self.endTime = nil
        self.screensViewed = []
        self.dropOffPoints = []
        self.skipEvents = []
        self.interactions = []
    }
    
    public var totalTimeSpent: TimeInterval {
        guard let end = endTime else { return Date().timeIntervalSince(startTime) }
        return end.timeIntervalSince(startTime)
    }
    
    public var completionRate: Double {
        guard !screensViewed.isEmpty else { return 0.0 }
        let totalScreens = screensViewed.map { $0.screenIndex }.max() ?? 0 + 1
        let viewedScreens = Set(screensViewed.map { $0.screenIndex }).count
        return Double(viewedScreens) / Double(totalScreens)
    }
    
    public var averageTimePerScreen: TimeInterval {
        guard !screensViewed.isEmpty else { return 0 }
        let totalTime = screensViewed.reduce(0) { $0 + $1.timeSpent }
        return totalTime / Double(screensViewed.count)
    }
    
    public mutating func recordScreenView(screenIndex: Int, timeSpent: TimeInterval) {
        let record = ScreenViewRecord(
            screenIndex: screenIndex,
            timestamp: Date(),
            timeSpent: timeSpent
        )
        screensViewed.append(record)
    }
    
    public mutating func recordDropOff(at screenIndex: Int) {
        dropOffPoints.append(screenIndex)
    }
    
    public mutating func recordSkip(from screenIndex: Int, to targetIndex: Int, reason: String? = nil) {
        let skipEvent = SkipEvent(
            fromScreenIndex: screenIndex,
            toScreenIndex: targetIndex,
            timestamp: Date(),
            reason: reason
        )
        skipEvents.append(skipEvent)
    }
    
    public mutating func recordInteraction(screenIndex: Int, interactionType: String, target: String? = nil) {
        let interaction = InteractionEvent(
            screenIndex: screenIndex,
            interactionType: interactionType,
            target: target,
            timestamp: Date()
        )
        interactions.append(interaction)
    }
    
    public mutating func completeAnalytics() {
        endTime = Date()
    }
}

// MARK: - Analytics Supporting Types

public struct ScreenViewRecord: Codable {
    public let screenIndex: Int
    public let timestamp: Date
    public let timeSpent: TimeInterval
}

public struct SkipEvent: Codable {
    public let fromScreenIndex: Int
    public let toScreenIndex: Int
    public let timestamp: Date
    public let reason: String?
}

public struct InteractionEvent: Codable {
    public let screenIndex: Int
    public let interactionType: String
    public let target: String?
    public let timestamp: Date
}

// MARK: - Onboarding Flow

public struct OnboardingFlow: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let description: String
    public let targetAudience: OnboardingAudience
    public private(set) var screens: [OnboardingScreen]
    public private(set) var isCompleted: Bool
    public private(set) var currentScreenIndex: Int
    public private(set) var analytics: OnboardingAnalytics?
    
    public init(
        id: UUID = UUID(),
        name: String,
        description: String,
        targetAudience: OnboardingAudience,
        screens: [OnboardingScreen] = [],
        isCompleted: Bool = false,
        currentScreenIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.targetAudience = targetAudience
        self.screens = screens.sorted { $0.order < $1.order }
        self.isCompleted = isCompleted
        self.currentScreenIndex = max(0, min(currentScreenIndex, screens.count - 1))
        self.analytics = nil
    }
    
    // MARK: - Screen Management
    
    public mutating func addScreen(_ screen: OnboardingScreen) {
        screens.append(screen)
        screens.sort { $0.order < $1.order }
    }
    
    public mutating func removeScreen(withId id: UUID) {
        screens.removeAll { $0.id == id }
        // Adjust current index if necessary
        if currentScreenIndex >= screens.count {
            currentScreenIndex = max(0, screens.count - 1)
        }
    }
    
    // MARK: - Flow Navigation
    
    public mutating func proceedToNext() -> Bool {
        guard !screens.isEmpty, currentScreenIndex < screens.count - 1 else {
            complete()
            return true
        }
        
        recordScreenCompletion()
        currentScreenIndex += 1
        return currentScreenIndex >= screens.count - 1
    }
    
    public mutating func goToPrevious() -> Bool {
        guard currentScreenIndex > 0 else { return false }
        currentScreenIndex -= 1
        return true
    }
    
    public mutating func jumpToScreen(at index: Int) -> Bool {
        guard index >= 0, index < screens.count else { return false }
        recordScreenCompletion()
        currentScreenIndex = index
        return true
    }
    
    public mutating func complete() {
        isCompleted = true
        analytics?.completeAnalytics()
        recordAnalyticsCompletion()
    }
    
    // MARK: - Skip Functionality
    
    public func canSkipCurrent() -> Bool {
        guard currentScreenIndex < screens.count else { return false }
        return screens[currentScreenIndex].skipable
    }
    
    public mutating func skipToEnd() -> Bool {
        guard canSkipCurrent() else { return false }
        analytics?.recordSkip(from: currentScreenIndex, to: screens.count - 1, reason: "skip_to_end")
        complete()
        return true
    }
    
    public mutating func skipToScreen(at index: Int) -> Bool {
        guard canSkipCurrent(), index > currentScreenIndex, index < screens.count else { return false }
        analytics?.recordSkip(from: currentScreenIndex, to: index, reason: "skip_to_screen")
        currentScreenIndex = index
        return true
    }
    
    // MARK: - Progress Tracking
    
    public var progress: Double {
        guard !screens.isEmpty else { return 1.0 }
        return Double(currentScreenIndex + (isCompleted ? 1 : 0)) / Double(screens.count)
    }
    
    public var currentScreen: OnboardingScreen? {
        guard currentScreenIndex < screens.count else { return nil }
        return screens[currentScreenIndex]
    }
    
    public var remainingScreens: Int {
        max(0, screens.count - currentScreenIndex - 1)
    }
    
    // MARK: - Analytics
    
    public mutating func startTracking() {
        analytics = OnboardingAnalytics(flowId: id)
    }
    
    public mutating func recordScreenView(screenIndex: Int, timeSpent: TimeInterval) {
        analytics?.recordScreenView(screenIndex: screenIndex, timeSpent: timeSpent)
    }
    
    public mutating func recordInteraction(type: String, target: String? = nil) {
        analytics?.recordInteraction(
            screenIndex: currentScreenIndex,
            interactionType: type,
            target: target
        )
    }
    
    public mutating func completeTracking() {
        analytics?.completeAnalytics()
    }
    
    public func getAnalytics() -> OnboardingAnalytics? {
        analytics
    }
    
    // MARK: - Static Factory Methods
    
    public static func shouldShow(for conditions: OnboardingConditions) -> Bool {
        // First time users always see onboarding
        if conditions.isFirstLaunch {
            return true
        }
        
        // Version updates may show onboarding
        if conditions.isVersionUpdate {
            return true
        }
        
        // Users who haven't completed tutorial
        if !conditions.hasCompletedTutorial {
            return true
        }
        
        // Users who haven't seen onboarding in a while
        if let daysSince = conditions.daysSinceLastOnboarding, daysSince > 90 {
            return true
        }
        
        return false
    }
    
    public static func recommendedFlow(for conditions: OnboardingConditions) -> OnboardingAudience {
        if conditions.isFirstLaunch {
            return .firstTimeUser
        }
        
        if conditions.isVersionUpdate {
            return .versionUpdate
        }
        
        if !conditions.hasCompletedTutorial {
            return .featureIntroduction
        }
        
        return .returningUser
    }
    
    // MARK: - Private Methods
    
    private mutating func recordScreenCompletion() {
        guard currentScreen != nil else { return }
        
        // Record in analytics if tracking is enabled
        analytics?.recordScreenView(
            screenIndex: currentScreenIndex,
            timeSpent: 0 // This would be calculated by the presentation layer
        )
    }
    
    private mutating func recordAnalyticsCompletion() {
        // Final analytics recording
        analytics?.recordInteraction(
            screenIndex: currentScreenIndex,
            interactionType: "completion",
            target: "onboarding_flow"
        )
    }
}

// MARK: - Onboarding Flow Extensions

extension OnboardingFlow: Equatable {
    public static func == (lhs: OnboardingFlow, rhs: OnboardingFlow) -> Bool {
        lhs.id == rhs.id
    }
}

extension OnboardingFlow: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}