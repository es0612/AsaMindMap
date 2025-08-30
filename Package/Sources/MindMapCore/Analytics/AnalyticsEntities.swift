import Foundation

// MARK: - UserStatistics

public struct UserStatistics: Codable, Identifiable, Anonymizable {
    public let id: UUID
    public let userId: UUID
    public let mindMapCount: Int
    public let nodeCount: Int
    public let sessionCount: Int
    public let averageSessionDuration: Double
    public let lastActiveDate: Date
    public let createdAt: Date
    
    public init(
        userId: UUID,
        mindMapCount: Int,
        nodeCount: Int,
        sessionCount: Int,
        averageSessionDuration: Double,
        lastActiveDate: Date
    ) {
        self.id = UUID()
        self.userId = userId
        self.mindMapCount = mindMapCount
        self.nodeCount = nodeCount
        self.sessionCount = sessionCount
        self.averageSessionDuration = averageSessionDuration
        self.lastActiveDate = lastActiveDate
        self.createdAt = Date()
    }
    
    // MARK: - Computed Properties
    
    public var averageNodesPerMindMap: Double {
        guard mindMapCount > 0 else { return 0.0 }
        return Double(nodeCount) / Double(mindMapCount)
    }
    
    public var averageNodesPerSession: Double {
        guard sessionCount > 0 else { return 0.0 }
        return Double(nodeCount) / Double(sessionCount)
    }
    
    // MARK: - Anonymizable
    
    public func anonymized() -> UserStatistics {
        return UserStatistics(
            userId: UUID(), // Generate new anonymous ID
            mindMapCount: self.mindMapCount,
            nodeCount: self.nodeCount,
            sessionCount: self.sessionCount,
            averageSessionDuration: self.averageSessionDuration,
            lastActiveDate: self.lastActiveDate
        )
    }
}

// MARK: - MindMapStatistics

public struct MindMapStatistics: Codable, Identifiable {
    public let id: UUID
    public let mindMapId: UUID
    public let nodeCount: Int
    public let maxDepth: Int
    public let creationDate: Date
    public let lastModified: Date
    
    public init(
        mindMapId: UUID,
        nodeCount: Int,
        maxDepth: Int,
        creationDate: Date,
        lastModified: Date
    ) {
        self.id = UUID()
        self.mindMapId = mindMapId
        self.nodeCount = nodeCount
        self.maxDepth = maxDepth
        self.creationDate = creationDate
        self.lastModified = lastModified
    }
    
    // MARK: - Computed Properties
    
    public var complexityScore: Double {
        // Simple complexity calculation based on nodes and depth
        return Double(nodeCount) * (Double(maxDepth) / 10.0) + 1.0
    }
    
    public var averageBranchWidth: Double {
        guard maxDepth > 0 else { return 0.0 }
        return Double(nodeCount) / Double(maxDepth)
    }
}

// MARK: - UsageMetrics

public final class UsageMetrics: Codable {
    private var actions: [UserAction: Int] = [:]
    private var sessions: [SessionData] = []
    
    public init() {}
    
    // MARK: - Action Tracking
    
    public func recordAction(_ action: UserAction) {
        actions[action, default: 0] += 1
    }
    
    public func actionCount(for action: UserAction) -> Int {
        return actions[action] ?? 0
    }
    
    // MARK: - Session Tracking
    
    public func startSession(at date: Date = Date()) {
        let session = SessionData(startTime: date, endTime: nil)
        sessions.append(session)
    }
    
    public func endSession(at date: Date = Date()) {
        guard let lastIndex = sessions.lastIndex(where: { $0.endTime == nil }) else { return }
        sessions[lastIndex].endTime = date
    }
    
    public var sessionCount: Int {
        return sessions.count
    }
    
    public var totalSessionDuration: Double {
        return sessions.compactMap { session in
            guard let endTime = session.endTime else { return nil }
            return endTime.timeIntervalSince(session.startTime)
        }.reduce(0, +)
    }
    
    // MARK: - Session Data
    
    private struct SessionData: Codable {
        let startTime: Date
        var endTime: Date?
    }
}

// MARK: - UserAction

public enum UserAction: String, CaseIterable, Codable {
    case nodeCreated = "node_created"
    case nodeDeleted = "node_deleted"
    case nodeEdited = "node_edited"
    case mindMapCreated = "mindmap_created"
    case mindMapOpened = "mindmap_opened"
    case mindMapShared = "mindmap_shared"
    case mediaAttached = "media_attached"
    case tagAdded = "tag_added"
    case taskCompleted = "task_completed"
}

// MARK: - AnalyticsDashboard

public struct AnalyticsDashboard: Codable {
    public let userStatistics: UserStatistics
    public let productivityScore: Double
    public let engagementLevel: EngagementLevel
    public let insights: [AnalyticsInsight]
    
    public init(userStatistics: UserStatistics) {
        self.userStatistics = userStatistics
        self.productivityScore = Self.calculateProductivityScore(userStatistics)
        self.engagementLevel = Self.calculateEngagementLevel(userStatistics)
        self.insights = Self.generateInsights(userStatistics)
    }
    
    // MARK: - Report Generation
    
    public func generateReport(format: ReportFormat) -> AnalyticsReport {
        let content = generateReportContent(format: format)
        
        return AnalyticsReport(
            userId: userStatistics.userId,
            type: .productivity,
            title: "Analytics Report",
            content: content,
            format: format,
            insights: insights,
            generatedAt: Date()
        )
    }
    
    // MARK: - Private Calculation Methods
    
    private static func calculateProductivityScore(_ stats: UserStatistics) -> Double {
        let nodeEfficiency = stats.averageNodesPerSession / 10.0 // Normalize
        let consistencyBonus = stats.sessionCount > 10 ? 0.1 : 0.0
        return min(nodeEfficiency + consistencyBonus, 1.0)
    }
    
    private static func calculateEngagementLevel(_ stats: UserStatistics) -> EngagementLevel {
        let avgDuration = stats.averageSessionDuration
        
        if avgDuration > 600 { // 10+ minutes
            return .high
        } else if avgDuration > 180 { // 3-10 minutes
            return .medium
        } else {
            return .low
        }
    }
    
    private static func generateInsights(_ stats: UserStatistics) -> [AnalyticsInsight] {
        var insights: [AnalyticsInsight] = []
        
        // Productivity insight
        let productivityValue = stats.averageNodesPerSession
        let productivityInsight = AnalyticsInsight(
            type: .productivity,
            title: "Node Creation Rate",
            description: "Average nodes created per session",
            value: productivityValue
        )
        insights.append(productivityInsight)
        
        // Engagement insight
        let engagementValue = stats.averageSessionDuration / 60.0 // Convert to minutes
        let engagementInsight = AnalyticsInsight(
            type: .engagement,
            title: "Session Duration",
            description: "Average time spent per session",
            value: engagementValue
        )
        insights.append(engagementInsight)
        
        return insights
    }
    
    private func generateReportContent(format: ReportFormat) -> String {
        switch format {
        case .summary:
            return generateSummaryContent()
        case .detailed:
            return generateDetailedContent()
        }
    }
    
    private func generateSummaryContent() -> String {
        return """
        Analytics Summary
        =================
        
        Total Mind Maps: \(userStatistics.mindMapCount)
        Total Nodes: \(userStatistics.nodeCount)
        Sessions: \(userStatistics.sessionCount)
        Productivity Score: \(String(format: "%.2f", productivityScore))
        Engagement Level: \(engagementLevel.rawValue)
        """
    }
    
    private func generateDetailedContent() -> String {
        return """
        Detailed Analytics Report
        =========================
        
        User Statistics:
        - Mind Maps Created: \(userStatistics.mindMapCount)
        - Total Nodes: \(userStatistics.nodeCount)
        - Sessions: \(userStatistics.sessionCount)
        - Average Session Duration: \(String(format: "%.1f", userStatistics.averageSessionDuration)) seconds
        - Average Nodes per Mind Map: \(String(format: "%.1f", userStatistics.averageNodesPerMindMap))
        - Average Nodes per Session: \(String(format: "%.1f", userStatistics.averageNodesPerSession))
        
        Performance Metrics:
        - Productivity Score: \(String(format: "%.2f", productivityScore))
        - Engagement Level: \(engagementLevel.rawValue)
        
        Key Insights:
        \(insights.map { "• \($0.title): \($0.description)" }.joined(separator: "\n"))
        """
    }
}

// MARK: - Supporting Types

public enum EngagementLevel: String, Codable, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

public enum ReportFormat: String, Codable, CaseIterable {
    case summary = "summary"
    case detailed = "detailed"
}

public struct AnalyticsInsight: Codable, Identifiable {
    public let id: UUID
    public let type: InsightType
    public let title: String
    public let description: String
    public let value: Double
    
    public init(type: InsightType, title: String, description: String, value: Double) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.description = description
        self.value = value
    }
}

public enum InsightType: String, Codable, CaseIterable {
    case productivity = "productivity"
    case engagement = "engagement"
    case usage = "usage"
    case performance = "performance"
}

public struct AnalyticsReport: Codable, Identifiable {
    public let id: UUID
    public let userId: UUID
    public let type: ReportType
    public let title: String
    public let content: String
    public let format: ReportFormat
    public let insights: [AnalyticsInsight]
    public let generatedAt: Date
    public let requestedMetrics: [AnalyticsMetric]?
    
    public init(
        userId: UUID,
        type: ReportType,
        title: String = "Analytics Report",
        content: String,
        format: ReportFormat = .summary,
        insights: [AnalyticsInsight] = [],
        generatedAt: Date = Date(),
        requestedMetrics: [AnalyticsMetric]? = nil
    ) {
        self.id = UUID()
        self.userId = userId
        self.type = type
        self.title = title
        self.content = content
        self.format = format
        self.insights = insights
        self.generatedAt = generatedAt
        self.requestedMetrics = requestedMetrics
    }
}

public enum ReportType: String, Codable, CaseIterable {
    case productivity = "productivity"
    case engagement = "engagement"
    case custom = "custom"
}

public enum AnalyticsMetric: String, Codable, CaseIterable {
    case nodeCreationRate = "node_creation_rate"
    case sessionDuration = "session_duration"
    case mindMapComplexity = "mindmap_complexity"
    case productivity = "productivity"
    case engagement = "engagement"
}

// MARK: - Anonymizable Protocol

public protocol Anonymizable {
    func anonymized() -> Self
}