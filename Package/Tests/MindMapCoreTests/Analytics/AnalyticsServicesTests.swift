import XCTest
@testable import MindMapCore

final class AnalyticsServicesTests: XCTestCase {
    
    var analyticsService: AnalyticsService!
    var mockStatisticsStorage: MockStatisticsStorage!
    var mockPrivacyManager: MockPrivacyManager!
    
    override func setUp() {
        super.setUp()
        mockStatisticsStorage = MockStatisticsStorage()
        mockPrivacyManager = MockPrivacyManager()
        analyticsService = AnalyticsService(
            statisticsStorage: mockStatisticsStorage,
            privacyManager: mockPrivacyManager
        )
    }
    
    override func tearDown() {
        analyticsService = nil
        mockStatisticsStorage = nil
        mockPrivacyManager = nil
        super.tearDown()
    }
    
    // MARK: - StatisticsCollector Tests
    
    func testStatisticsCollectorUserBehaviorTracking() async throws {
        // Given
        let userId = UUID()
        let mindMaps = [
            MindMap(title: "Test Map 1"),
            MindMap(title: "Test Map 2")
        ]
        
        // When
        let userStats = try await analyticsService.collectUserStatistics(
            userId: userId,
            mindMaps: mindMaps
        )
        
        // Then
        XCTAssertEqual(userStats.userId, userId)
        XCTAssertEqual(userStats.mindMapCount, 2)
        XCTAssertGreaterThan(userStats.nodeCount, 0)
    }
    
    func testStatisticsCollectorMindMapAnalysis() async throws {
        // Given
        let mindMap = createTestMindMap(nodeCount: 25, depth: 3)
        
        // When
        let stats = try await analyticsService.analyzeMindMap(mindMap)
        
        // Then
        XCTAssertEqual(stats.mindMapId, mindMap.id)
        XCTAssertEqual(stats.nodeCount, 25)
        XCTAssertEqual(stats.maxDepth, 3)
        XCTAssertGreaterThan(stats.complexityScore, 0.0)
    }
    
    func testStatisticsCollectorUsagePatternAnalysis() async throws {
        // Given
        let metrics = UsageMetrics()
        metrics.recordAction(.nodeCreated)
        metrics.recordAction(.mindMapOpened)
        
        // When
        let patterns = try await analyticsService.analyzeUsagePatterns(metrics)
        
        // Then
        XCTAssertGreaterThan(patterns.mostFrequentActions.count, 0)
        XCTAssertNotNil(patterns.peakUsageTime)
        XCTAssertGreaterThan(patterns.productivityScore, 0.0)
    }
    
    // MARK: - AnalyticsService Tests
    
    func testAnalyticsServiceDataCollection() async throws {
        // Given
        let userId = UUID()
        
        // When
        try await analyticsService.startDataCollection(for: userId)
        
        // Then
        XCTAssertTrue(mockStatisticsStorage.isCollecting)
        XCTAssertEqual(mockStatisticsStorage.activeUserId, userId)
    }
    
    func testAnalyticsServicePrivacyCompliance() async throws {
        // Given
        let userId = UUID()
        mockPrivacyManager.isAnalyticsEnabled = false
        
        // When
        let canCollect = await analyticsService.canCollectAnalytics(for: userId)
        
        // Then
        XCTAssertFalse(canCollect)
    }
    
    func testAnalyticsServiceDataAnonymization() async throws {
        // Given
        let userStats = UserStatistics(
            userId: UUID(),
            mindMapCount: 5,
            nodeCount: 100,
            sessionCount: 20,
            averageSessionDuration: 300.0,
            lastActiveDate: Date()
        )
        
        // When
        let anonymized = try await analyticsService.anonymizeData(userStats)
        
        // Then
        XCTAssertNotEqual(anonymized.userId, userStats.userId)
        XCTAssertEqual(anonymized.mindMapCount, userStats.mindMapCount)
        XCTAssertTrue(mockPrivacyManager.anonymizationCalled)
    }
    
    // MARK: - DashboardService Tests
    
    func testDashboardServiceDataGeneration() async throws {
        // Given
        let userId = UUID()
        let userStats = UserStatistics(
            userId: userId,
            mindMapCount: 10,
            nodeCount: 250,
            sessionCount: 35,
            averageSessionDuration: 420.0,
            lastActiveDate: Date()
        )
        mockStatisticsStorage.userStatistics[userId] = userStats
        
        // When
        let dashboard = try await analyticsService.generateDashboard(for: userId)
        
        // Then
        XCTAssertNotNil(dashboard.productivityScore)
        XCTAssertNotNil(dashboard.engagementLevel)
        XCTAssertGreaterThan(dashboard.insights.count, 0)
    }
    
    func testDashboardServiceCustomReportGeneration() async throws {
        // Given
        let userId = UUID()
        let reportConfig = ReportConfiguration(
            timeRange: .lastMonth,
            metrics: [.productivity, .engagement],
            format: .detailed
        )
        
        // When
        let report = try await analyticsService.generateReport(
            for: userId,
            configuration: reportConfig
        )
        
        // Then
        XCTAssertFalse(report.title.isEmpty)
        XCTAssertFalse(report.content.isEmpty)
        XCTAssertEqual(report.format, .detailed)
        XCTAssertNotNil(report.generatedAt)
    }
    
    // MARK: - Privacy Protection Tests
    
    func testPrivacyManagerConsentHandling() async {
        // Given
        let userId = UUID()
        
        // When
        await mockPrivacyManager.requestAnalyticsConsent(for: userId)
        
        // Then
        XCTAssertTrue(mockPrivacyManager.consentRequested)
    }
    
    func testPrivacyManagerDataRetention() async throws {
        // Given
        let oldData = UserStatistics(
            userId: UUID(),
            mindMapCount: 1,
            nodeCount: 10,
            sessionCount: 5,
            averageSessionDuration: 100.0,
            lastActiveDate: Date().addingTimeInterval(-86400 * 365) // 1 year ago
        )
        
        // When
        try await analyticsService.enforceDataRetentionPolicy()
        
        // Then
        XCTAssertTrue(mockStatisticsStorage.retentionPolicyEnforced)
    }
    
    // MARK: - Helper Methods
    
    private func createTestMindMap(nodeCount: Int, depth: Int) -> MindMap {
        let mindMap = MindMap(title: "Test Mind Map")
        
        // Add nodes to simulate structure
        var nodeIds = Set<UUID>()
        for i in 0..<nodeCount {
            let nodeId = UUID()
            nodeIds.insert(nodeId)
        }
        
        var updatedMindMap = mindMap
        updatedMindMap.nodeIDs = nodeIds
        
        return updatedMindMap
    }
}