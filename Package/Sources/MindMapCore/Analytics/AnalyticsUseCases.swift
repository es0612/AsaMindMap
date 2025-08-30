import Foundation

// MARK: - GenerateAnalyticsReportUseCase

public final class GenerateAnalyticsReportUseCase {
    
    // MARK: - Dependencies
    
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Initialization
    
    public init(analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public Methods
    
    public func execute(request: AnalyticsReportRequest) async throws -> AnalyticsReport {
        let configuration = ReportConfiguration(
            type: request.type,
            timeRange: request.timeRange,
            metrics: request.metrics ?? [],
            format: .detailed,
            includeComparisons: request.includeComparisons
        )
        
        let report = try await analyticsService.generateReport(
            for: request.userId,
            configuration: configuration
        )
        
        return report
    }
}

// MARK: - CollectUserAnalyticsUseCase

public final class CollectUserAnalyticsUseCase {
    
    // MARK: - Dependencies
    
    private let analyticsService: AnalyticsServiceProtocol
    private let mindMapRepository: MindMapRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(
        analyticsService: AnalyticsServiceProtocol,
        mindMapRepository: MindMapRepositoryProtocol
    ) {
        self.analyticsService = analyticsService
        self.mindMapRepository = mindMapRepository
    }
    
    // MARK: - Public Methods
    
    public func execute(
        userId: UUID,
        includeUsagePatterns: Bool = false,
        respectPrivacy: Bool = false
    ) async throws -> UserAnalytics {
        let mindMaps = try await mindMapRepository.findAll()
        
        var analytics = try await analyticsService.collectUserStatistics(
            userId: userId,
            mindMaps: mindMaps
        )
        
        // Apply privacy protection if requested
        if respectPrivacy {
            let anonymizedUserId = UUID() // Generate anonymous ID
            analytics = UserAnalytics(
                userId: anonymizedUserId,
                mindMapCount: analytics.mindMapCount,
                nodeCount: analytics.nodeCount,
                productivityMetrics: analytics.productivityMetrics,
                usagePatterns: analytics.usagePatterns
            )
        }
        
        return analytics
    }
}

// MARK: - GenerateAnalyticsDashboardUseCase

public final class GenerateAnalyticsDashboardUseCase {
    
    // MARK: - Dependencies
    
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Initialization
    
    public init(analyticsService: AnalyticsServiceProtocol) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public Methods
    
    public func execute(
        userId: UUID,
        includeRecommendations: Bool = false
    ) async throws -> EnhancedAnalyticsDashboard {
        let dashboard = try await analyticsService.generateDashboard(for: userId)
        
        var recommendations: [AnalyticsRecommendation]? = nil
        
        if includeRecommendations {
            recommendations = generateRecommendations(from: dashboard)
        }
        
        return EnhancedAnalyticsDashboard(
            dashboard: dashboard,
            recommendations: recommendations
        )
    }
    
    // MARK: - Private Methods
    
    private func generateRecommendations(from dashboard: AnalyticsDashboard) -> [AnalyticsRecommendation] {
        var recommendations: [AnalyticsRecommendation] = []
        
        // Productivity recommendation
        if dashboard.productivityScore < 0.5 {
            recommendations.append(
                AnalyticsRecommendation(
                    type: .productivity,
                    title: "Improve Node Creation Efficiency",
                    description: "Try creating more nodes per session to boost productivity",
                    priority: .high
                )
            )
        }
        
        // Engagement recommendation
        if dashboard.engagementLevel == .low {
            recommendations.append(
                AnalyticsRecommendation(
                    type: .engagement,
                    title: "Extend Session Duration",
                    description: "Spend more time developing your mind maps for better results",
                    priority: .medium
                )
            )
        }
        
        return recommendations
    }
}

// MARK: - Supporting Types

public struct EnhancedAnalyticsDashboard {
    public let dashboard: AnalyticsDashboard
    public let recommendations: [AnalyticsRecommendation]?
    
    public init(dashboard: AnalyticsDashboard, recommendations: [AnalyticsRecommendation]? = nil) {
        self.dashboard = dashboard
        self.recommendations = recommendations
    }
    
    // Delegate properties to underlying dashboard
    public var userStatistics: UserStatistics { dashboard.userStatistics }
    public var productivityScore: Double { dashboard.productivityScore }
    public var engagementLevel: EngagementLevel { dashboard.engagementLevel }
    public var insights: [AnalyticsInsight] { dashboard.insights }
}

public struct AnalyticsRecommendation: Codable, Identifiable {
    public let id: UUID
    public let type: RecommendationType
    public let title: String
    public let description: String
    public let priority: Priority
    
    public init(type: RecommendationType, title: String, description: String, priority: Priority) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.priority = priority
    }
}

public enum RecommendationType: String, Codable, CaseIterable {
    case productivity = "productivity"
    case engagement = "engagement"
    case organization = "organization"
    case creativity = "creativity"
}

public enum Priority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}