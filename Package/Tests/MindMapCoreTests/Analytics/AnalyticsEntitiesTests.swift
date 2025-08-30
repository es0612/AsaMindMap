import XCTest
@testable import MindMapCore

final class AnalyticsEntitiesTests: XCTestCase {
    
    // MARK: - UserStatistics Tests
    
    func testUserStatisticsCreation() {
        // Given
        let userId = UUID()
        let mindMapCount = 5
        let nodeCount = 150
        let sessionCount = 25
        
        // When
        let statistics = UserStatistics(
            userId: userId,
            mindMapCount: mindMapCount,
            nodeCount: nodeCount,
            sessionCount: sessionCount,
            averageSessionDuration: 300.0,
            lastActiveDate: Date()
        )
        
        // Then
        XCTAssertEqual(statistics.userId, userId)
        XCTAssertEqual(statistics.mindMapCount, mindMapCount)
        XCTAssertEqual(statistics.nodeCount, nodeCount)
        XCTAssertEqual(statistics.sessionCount, sessionCount)
        XCTAssertEqual(statistics.averageSessionDuration, 300.0)
        XCTAssertNotNil(statistics.createdAt)
    }
    
    func testUserStatisticsProductivityMetrics() {
        // Given
        let statistics = UserStatistics(
            userId: UUID(),
            mindMapCount: 10,
            nodeCount: 250,
            sessionCount: 50,
            averageSessionDuration: 450.0,
            lastActiveDate: Date()
        )
        
        // When
        let averageNodesPerMindMap = statistics.averageNodesPerMindMap
        let averageNodesPerSession = statistics.averageNodesPerSession
        
        // Then
        XCTAssertEqual(averageNodesPerMindMap, 25.0, accuracy: 0.01)
        XCTAssertEqual(averageNodesPerSession, 5.0, accuracy: 0.01)
    }
    
    func testUserStatisticsAnonymization() {
        // Given
        let statistics = UserStatistics(
            userId: UUID(),
            mindMapCount: 3,
            nodeCount: 100,
            sessionCount: 15,
            averageSessionDuration: 200.0,
            lastActiveDate: Date()
        )
        
        // When
        let anonymized = statistics.anonymized()
        
        // Then
        XCTAssertNotEqual(anonymized.userId, statistics.userId)
        XCTAssertEqual(anonymized.mindMapCount, statistics.mindMapCount)
        XCTAssertEqual(anonymized.nodeCount, statistics.nodeCount)
        XCTAssertEqual(anonymized.sessionCount, statistics.sessionCount)
    }
    
    // MARK: - MindMapStatistics Tests
    
    func testMindMapStatisticsCreation() {
        // Given
        let mindMapId = UUID()
        let nodeCount = 45
        let depth = 4
        
        // When
        let statistics = MindMapStatistics(
            mindMapId: mindMapId,
            nodeCount: nodeCount,
            maxDepth: depth,
            creationDate: Date(),
            lastModified: Date()
        )
        
        // Then
        XCTAssertEqual(statistics.mindMapId, mindMapId)
        XCTAssertEqual(statistics.nodeCount, nodeCount)
        XCTAssertEqual(statistics.maxDepth, depth)
        XCTAssertNotNil(statistics.creationDate)
        XCTAssertNotNil(statistics.lastModified)
    }
    
    func testMindMapStatisticsComplexityCalculation() {
        // Given
        let statistics = MindMapStatistics(
            mindMapId: UUID(),
            nodeCount: 100,
            maxDepth: 5,
            creationDate: Date().addingTimeInterval(-86400), // 1 day ago
            lastModified: Date()
        )
        
        // When
        let complexity = statistics.complexityScore
        let averageWidth = statistics.averageBranchWidth
        
        // Then
        XCTAssertGreaterThan(complexity, 0.0)
        XCTAssertGreaterThan(averageWidth, 0.0)
    }
    
    // MARK: - UsageMetrics Tests
    
    func testUsageMetricsTracking() {
        // Given
        let metrics = UsageMetrics()
        
        // When
        metrics.recordAction(.nodeCreated)
        metrics.recordAction(.mindMapOpened)
        metrics.recordAction(.nodeDeleted)
        
        // Then
        XCTAssertEqual(metrics.actionCount(for: .nodeCreated), 1)
        XCTAssertEqual(metrics.actionCount(for: .mindMapOpened), 1)
        XCTAssertEqual(metrics.actionCount(for: .nodeDeleted), 1)
    }
    
    func testUsageMetricsSessionTracking() {
        // Given
        let metrics = UsageMetrics()
        let sessionStart = Date()
        
        // When
        metrics.startSession(at: sessionStart)
        // Simulate 5 minute session
        metrics.endSession(at: sessionStart.addingTimeInterval(300))
        
        // Then
        XCTAssertEqual(metrics.sessionCount, 1)
        XCTAssertEqual(metrics.totalSessionDuration, 300.0, accuracy: 1.0)
    }
    
    // MARK: - AnalyticsDashboard Tests
    
    func testAnalyticsDashboardDataGeneration() {
        // Given
        let userStats = UserStatistics(
            userId: UUID(),
            mindMapCount: 8,
            nodeCount: 200,
            sessionCount: 30,
            averageSessionDuration: 400.0,
            lastActiveDate: Date()
        )
        
        // When
        let dashboard = AnalyticsDashboard(userStatistics: userStats)
        
        // Then
        XCTAssertNotNil(dashboard.productivityScore)
        XCTAssertNotNil(dashboard.engagementLevel)
        XCTAssertGreaterThan(dashboard.insights.count, 0)
    }
    
    func testAnalyticsDashboardReportGeneration() {
        // Given
        let userStats = UserStatistics(
            userId: UUID(),
            mindMapCount: 12,
            nodeCount: 300,
            sessionCount: 40,
            averageSessionDuration: 350.0,
            lastActiveDate: Date()
        )
        let dashboard = AnalyticsDashboard(userStatistics: userStats)
        
        // When
        let report = dashboard.generateReport(format: .summary)
        
        // Then
        XCTAssertFalse(report.title.isEmpty)
        XCTAssertFalse(report.content.isEmpty)
        XCTAssertNotNil(report.generatedAt)
    }
}