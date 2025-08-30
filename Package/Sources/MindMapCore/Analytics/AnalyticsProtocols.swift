import Foundation

// MARK: - StatisticsStorageProtocol

public protocol StatisticsStorageProtocol {
    func saveUserStatistics(_ statistics: UserStatistics) async throws
    func loadUserStatistics(for userId: UUID) async throws -> UserStatistics?
    func saveMindMapStatistics(_ statistics: MindMapStatistics) async throws
    func loadMindMapStatistics(for mindMapId: UUID) async throws -> MindMapStatistics?
    func saveUsageMetrics(_ metrics: UsageMetrics, for userId: UUID) async throws
    func loadUsageMetrics(for userId: UUID) async throws -> UsageMetrics?
    func deleteStatistics(for userId: UUID) async throws
    func deleteOldStatistics(olderThan date: Date) async throws
    func getAllUserIds() async throws -> [UUID]
}

// MARK: - PrivacyManagerProtocol

public protocol PrivacyManagerProtocol {
    func requestAnalyticsConsent(for userId: UUID) async
    func hasAnalyticsConsent(for userId: UUID) async -> Bool
    func revokeAnalyticsConsent(for userId: UUID) async
    func anonymizeUserData<T: Anonymizable>(_ data: T) async throws -> T
    func canCollectAnalytics(for userId: UUID) async -> Bool
    func enforceDataRetentionPolicy() async throws
}

// MARK: - AnalyticsServiceProtocol

public protocol AnalyticsServiceProtocol {
    func generateDashboard(for userId: UUID) async throws -> AnalyticsDashboard
    func generateReport(for userId: UUID, configuration: ReportConfiguration) async throws -> AnalyticsReport
    func collectUserStatistics(userId: UUID, mindMaps: [MindMap]) async throws -> UserAnalytics
}

// MARK: - AnalyticsCollectorProtocol

public protocol AnalyticsCollectorProtocol {
    func startCollection() async
    func stopCollection() async
    func recordEvent(_ event: AnalyticsEvent) async
    func flush() async throws
}

// MARK: - Supporting Types

public struct ReportConfiguration {
    public let type: ReportType
    public let timeRange: TimeRange
    public let metrics: [AnalyticsMetric]
    public let format: ReportFormat
    public let includeComparisons: Bool
    
    public init(
        type: ReportType,
        timeRange: TimeRange,
        metrics: [AnalyticsMetric] = [],
        format: ReportFormat = .summary,
        includeComparisons: Bool = false
    ) {
        self.type = type
        self.timeRange = timeRange
        self.metrics = metrics
        self.format = format
        self.includeComparisons = includeComparisons
    }
}

public enum TimeRange: Codable {
    case lastWeek
    case lastMonth
    case lastThreeMonths
    case lastYear
    case custom(from: Date, to: Date)
}

public struct UserAnalytics: Codable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let mindMapCount: Int
    public let nodeCount: Int
    public let productivityMetrics: ProductivityMetrics?
    public let usagePatterns: UsagePatterns?
    
    public init(
        userId: UUID,
        mindMapCount: Int,
        nodeCount: Int,
        productivityMetrics: ProductivityMetrics? = nil,
        usagePatterns: UsagePatterns? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.mindMapCount = mindMapCount
        self.nodeCount = nodeCount
        self.productivityMetrics = productivityMetrics
        self.usagePatterns = usagePatterns
    }
}

public struct ProductivityMetrics: Codable {
    public let averageNodesPerSession: Double
    public let sessionProductivity: Double
    public let creationVelocity: Double
    
    public init(averageNodesPerSession: Double, sessionProductivity: Double, creationVelocity: Double) {
        self.averageNodesPerSession = averageNodesPerSession
        self.sessionProductivity = sessionProductivity
        self.creationVelocity = creationVelocity
    }
}

public struct UsagePatterns: Codable {
    public let totalActions: Int
    public let mostFrequentActions: [UserAction]
    public let peakUsageTime: PeakTime
    public let productivityScore: Double
    
    public init(totalActions: Int, mostFrequentActions: [UserAction], peakUsageTime: PeakTime, productivityScore: Double) {
        self.totalActions = totalActions
        self.mostFrequentActions = mostFrequentActions
        self.peakUsageTime = peakUsageTime
        self.productivityScore = productivityScore
    }
}

public enum PeakTime: String, Codable, CaseIterable {
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
}

public struct AnalyticsEvent: Codable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let action: UserAction
    public let timestamp: Date
    public let metadata: [String: String]?
    
    public init(userId: UUID, action: UserAction, timestamp: Date = Date(), metadata: [String: String]? = nil) {
        self.id = UUID()
        self.userId = userId
        self.action = action
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

public struct AnalyticsReportRequest {
    public let userId: UUID
    public let type: ReportType
    public let timeRange: TimeRange
    public let metrics: [AnalyticsMetric]?
    public let includeComparisons: Bool
    
    public init(
        userId: UUID,
        type: ReportType,
        timeRange: TimeRange,
        metrics: [AnalyticsMetric]? = nil,
        includeComparisons: Bool = false
    ) {
        self.userId = userId
        self.type = type
        self.timeRange = timeRange
        self.metrics = metrics
        self.includeComparisons = includeComparisons
    }
}

// MARK: - AnalyticsError

public enum AnalyticsError: Error, LocalizedError {
    case userNotFound
    case consentRequired
    case reportGenerationFailed
    case dataCorrupted
    case privacyViolation
    case storageError(String)
    
    public var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found in analytics system"
        case .consentRequired:
            return "User consent required for analytics collection"
        case .reportGenerationFailed:
            return "Failed to generate analytics report"
        case .dataCorrupted:
            return "Analytics data is corrupted"
        case .privacyViolation:
            return "Operation violates privacy policy"
        case .storageError(let message):
            return "Analytics storage error: \(message)"
        }
    }
}