import XCTest
@testable import MindMapCore

final class AnalyticsUseCasesTests: XCTestCase {
    
    var generateAnalyticsReportUseCase: GenerateAnalyticsReportUseCase!
    var collectUserAnalyticsUseCase: CollectUserAnalyticsUseCase!
    var mockAnalyticsService: MockAnalyticsService!
    var mockMindMapRepository: MockMindMapRepository!
    
    override func setUp() {
        super.setUp()
        mockAnalyticsService = MockAnalyticsService()
        mockMindMapRepository = MockMindMapRepository()
        
        generateAnalyticsReportUseCase = GenerateAnalyticsReportUseCase(
            analyticsService: mockAnalyticsService
        )
        
        collectUserAnalyticsUseCase = CollectUserAnalyticsUseCase(
            analyticsService: mockAnalyticsService,
            mindMapRepository: mockMindMapRepository
        )
    }
    
    override func tearDown() {
        generateAnalyticsReportUseCase = nil
        collectUserAnalyticsUseCase = nil
        mockAnalyticsService = nil
        mockMindMapRepository = nil
        super.tearDown()
    }
    
    // MARK: - GenerateAnalyticsReportUseCase Tests
    
    func testGenerateProductivityReport() async throws {
        // Given
        let userId = UUID()
        let reportRequest = AnalyticsReportRequest(
            userId: userId,
            type: .productivity,
            timeRange: .lastMonth,
            includeComparisons: true
        )
        
        mockAnalyticsService.mockDashboard = AnalyticsDashboard(
            userStatistics: createMockUserStatistics(userId: userId)
        )
        
        // When
        let report = try await generateAnalyticsReportUseCase.execute(request: reportRequest)
        
        // Then
        XCTAssertEqual(report.userId, userId)
        XCTAssertEqual(report.type, .productivity)
        XCTAssertFalse(report.content.isEmpty)
        XCTAssertNotNil(report.generatedAt)
        XCTAssertTrue(mockAnalyticsService.reportGenerated)
    }
    
    func testGenerateEngagementReport() async throws {
        // Given
        let userId = UUID()
        let reportRequest = AnalyticsReportRequest(
            userId: userId,
            type: .engagement,
            timeRange: .lastWeek,
            includeComparisons: false
        )
        
        // When
        let report = try await generateAnalyticsReportUseCase.execute(request: reportRequest)
        
        // Then
        XCTAssertEqual(report.type, .engagement)
        XCTAssertNotNil(report.insights)
        XCTAssertGreaterThan(report.insights.count, 0)
    }
    
    func testGenerateCustomReport() async throws {
        // Given
        let userId = UUID()
        let reportRequest = AnalyticsReportRequest(
            userId: userId,
            type: .custom,
            timeRange: .custom(from: Date().addingTimeInterval(-86400 * 7), to: Date()),
            metrics: [.nodeCreationRate, .sessionDuration, .mindMapComplexity]
        )
        
        // When
        let report = try await generateAnalyticsReportUseCase.execute(request: reportRequest)
        
        // Then
        XCTAssertEqual(report.type, .custom)
        XCTAssertEqual(report.requestedMetrics?.count, 3)
        XCTAssertTrue(report.requestedMetrics?.contains(.nodeCreationRate) == true)
    }
    
    // MARK: - CollectUserAnalyticsUseCase Tests
    
    func testCollectUserAnalyticsBasicStats() async throws {
        // Given
        let userId = UUID()
        let mindMaps = [
            MindMap(title: "Project Planning"),
            MindMap(title: "Meeting Notes")
        ]
        mockMindMapRepository.mindMaps = mindMaps
        
        // When
        let analytics = try await collectUserAnalyticsUseCase.execute(userId: userId)
        
        // Then
        XCTAssertEqual(analytics.userId, userId)
        XCTAssertEqual(analytics.mindMapCount, 2)
        XCTAssertNotNil(analytics.productivityMetrics)
        XCTAssertTrue(mockAnalyticsService.analyticsCollected)
    }
    
    func testCollectUserAnalyticsWithUsagePatterns() async throws {
        // Given
        let userId = UUID()
        let mockUsageMetrics = UsageMetrics()
        mockUsageMetrics.recordAction(.nodeCreated)
        mockUsageMetrics.recordAction(.mindMapOpened)
        mockAnalyticsService.mockUsageMetrics = mockUsageMetrics
        
        // When
        let analytics = try await collectUserAnalyticsUseCase.execute(
            userId: userId,
            includeUsagePatterns: true
        )
        
        // Then
        XCTAssertNotNil(analytics.usagePatterns)
        XCTAssertGreaterThan(analytics.usagePatterns?.totalActions ?? 0, 0)
    }
    
    func testCollectUserAnalyticsPrivacyCompliant() async throws {
        // Given
        let userId = UUID()
        mockAnalyticsService.privacyComplianceEnabled = true
        
        // When
        let analytics = try await collectUserAnalyticsUseCase.execute(
            userId: userId,
            respectPrivacy: true
        )
        
        // Then
        XCTAssertNotEqual(analytics.userId, userId) // Should be anonymized
        XCTAssertTrue(mockAnalyticsService.privacyRespected)
    }
    
    // MARK: - Analytics Dashboard Use Case Tests
    
    func testGenerateDashboardWithInsights() async throws {
        // Given
        let userId = UUID()
        let generateDashboardUseCase = GenerateAnalyticsDashboardUseCase(
            analyticsService: mockAnalyticsService
        )
        
        mockAnalyticsService.mockDashboard = AnalyticsDashboard(
            userStatistics: createMockUserStatistics(userId: userId)
        )
        
        // When
        let dashboard = try await generateDashboardUseCase.execute(userId: userId)
        
        // Then
        XCTAssertNotNil(dashboard.productivityScore)
        XCTAssertNotNil(dashboard.engagementLevel)
        XCTAssertGreaterThan(dashboard.insights.count, 0)
        XCTAssertTrue(dashboard.insights.contains { $0.type == .productivity })
    }
    
    func testGenerateDashboardWithRecommendations() async throws {
        // Given
        let userId = UUID()
        let generateDashboardUseCase = GenerateAnalyticsDashboardUseCase(
            analyticsService: mockAnalyticsService
        )
        
        // When
        let dashboard = try await generateDashboardUseCase.execute(
            userId: userId,
            includeRecommendations: true
        )
        
        // Then
        XCTAssertNotNil(dashboard.recommendations)
        XCTAssertGreaterThan(dashboard.recommendations?.count ?? 0, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testGenerateReportWithInvalidUser() async {
        // Given
        let invalidUserId = UUID()
        let reportRequest = AnalyticsReportRequest(
            userId: invalidUserId,
            type: .productivity,
            timeRange: .lastMonth
        )
        mockAnalyticsService.shouldThrowError = true
        
        // When & Then
        do {
            _ = try await generateAnalyticsReportUseCase.execute(request: reportRequest)
            XCTFail("Should throw error for invalid user")
        } catch {
            XCTAssertTrue(error is AnalyticsError)
        }
    }
    
    func testCollectAnalyticsWithoutConsent() async {
        // Given
        let userId = UUID()
        mockAnalyticsService.hasConsent = false
        
        // When & Then
        do {
            _ = try await collectUserAnalyticsUseCase.execute(userId: userId)
            XCTFail("Should throw error without consent")
        } catch {
            if case AnalyticsError.consentRequired = error {
                // Expected error
            } else {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockUserStatistics(userId: UUID) -> UserStatistics {
        return UserStatistics(
            userId: userId,
            mindMapCount: 15,
            nodeCount: 450,
            sessionCount: 60,
            averageSessionDuration: 380.0,
            lastActiveDate: Date()
        )
    }
}

// MARK: - MockAnalyticsService

final class MockAnalyticsService: AnalyticsServiceProtocol {
    
    // MARK: - Mock Properties
    var mockDashboard: AnalyticsDashboard?
    var mockUsageMetrics: UsageMetrics?
    var reportGenerated = false
    var analyticsCollected = false
    var privacyComplianceEnabled = false
    var privacyRespected = false
    var shouldThrowError = false
    var hasConsent = true
    
    // MARK: - AnalyticsServiceProtocol Implementation
    
    func generateDashboard(for userId: UUID) async throws -> AnalyticsDashboard {
        if shouldThrowError {
            throw AnalyticsError.userNotFound
        }
        
        return mockDashboard ?? AnalyticsDashboard(
            userStatistics: UserStatistics(
                userId: userId,
                mindMapCount: 0,
                nodeCount: 0,
                sessionCount: 0,
                averageSessionDuration: 0,
                lastActiveDate: Date()
            )
        )
    }
    
    func generateReport(for userId: UUID, configuration: ReportConfiguration) async throws -> AnalyticsReport {
        if shouldThrowError {
            throw AnalyticsError.reportGenerationFailed
        }
        
        reportGenerated = true
        
        return AnalyticsReport(
            userId: userId,
            type: configuration.type,
            content: "Mock analytics report content",
            insights: [
                AnalyticsInsight(
                    type: .productivity,
                    title: "Mock Insight",
                    description: "Mock insight description",
                    value: 0.85
                )
            ],
            generatedAt: Date()
        )
    }
    
    func collectUserStatistics(userId: UUID, mindMaps: [MindMap]) async throws -> UserAnalytics {
        if !hasConsent {
            throw AnalyticsError.consentRequired
        }
        
        analyticsCollected = true
        
        let finalUserId = (privacyComplianceEnabled && privacyRespected) ? UUID() : userId
        
        return UserAnalytics(
            userId: finalUserId,
            mindMapCount: mindMaps.count,
            nodeCount: mindMaps.reduce(0) { $0 + $1.nodeIDs.count },
            productivityMetrics: ProductivityMetrics(
                averageNodesPerSession: 10.5,
                sessionProductivity: 0.75,
                creationVelocity: 2.3
            ),
            usagePatterns: mockUsageMetrics.map { metrics in
                UsagePatterns(
                    totalActions: 50,
                    mostFrequentActions: [.nodeCreated, .mindMapOpened],
                    peakUsageTime: .afternoon,
                    productivityScore: 0.80
                )
            }
        )
    }
    
    // MARK: - Mock Helper Methods
    
    func reset() {
        mockDashboard = nil
        mockUsageMetrics = nil
        reportGenerated = false
        analyticsCollected = false
        privacyComplianceEnabled = false
        privacyRespected = false
        shouldThrowError = false
        hasConsent = true
    }
}