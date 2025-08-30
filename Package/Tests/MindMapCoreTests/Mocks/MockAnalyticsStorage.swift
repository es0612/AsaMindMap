import Foundation
@testable import MindMapCore

// MARK: - MockStatisticsStorage

final class MockStatisticsStorage: StatisticsStorageProtocol {
    
    // MARK: - Mock Properties
    var userStatistics: [UUID: UserStatistics] = [:]
    var mindMapStatistics: [UUID: MindMapStatistics] = [:]
    var usageMetrics: [UUID: UsageMetrics] = [:]
    
    var isCollecting = false
    var activeUserId: UUID?
    var retentionPolicyEnforced = false
    
    // MARK: - StatisticsStorageProtocol Implementation
    
    func saveUserStatistics(_ statistics: UserStatistics) async throws {
        userStatistics[statistics.userId] = statistics
    }
    
    func loadUserStatistics(for userId: UUID) async throws -> UserStatistics? {
        return userStatistics[userId]
    }
    
    func saveMindMapStatistics(_ statistics: MindMapStatistics) async throws {
        mindMapStatistics[statistics.mindMapId] = statistics
    }
    
    func loadMindMapStatistics(for mindMapId: UUID) async throws -> MindMapStatistics? {
        return mindMapStatistics[mindMapId]
    }
    
    func saveUsageMetrics(_ metrics: UsageMetrics, for userId: UUID) async throws {
        usageMetrics[userId] = metrics
    }
    
    func loadUsageMetrics(for userId: UUID) async throws -> UsageMetrics? {
        return usageMetrics[userId]
    }
    
    func deleteStatistics(for userId: UUID) async throws {
        userStatistics.removeValue(forKey: userId)
        usageMetrics.removeValue(forKey: userId)
    }
    
    func deleteOldStatistics(olderThan date: Date) async throws {
        retentionPolicyEnforced = true
        
        // Remove old statistics
        userStatistics = userStatistics.filter { _, stats in
            stats.createdAt > date
        }
    }
    
    func getAllUserIds() async throws -> [UUID] {
        return Array(userStatistics.keys)
    }
    
    // MARK: - Mock Helper Methods
    
    func startCollection(for userId: UUID) {
        isCollecting = true
        activeUserId = userId
    }
    
    func stopCollection() {
        isCollecting = false
        activeUserId = nil
    }
    
    func reset() {
        userStatistics.removeAll()
        mindMapStatistics.removeAll()
        usageMetrics.removeAll()
        isCollecting = false
        activeUserId = nil
        retentionPolicyEnforced = false
    }
}

// MARK: - MockPrivacyManager

final class MockPrivacyManager: PrivacyManagerProtocol {
    
    // MARK: - Mock Properties
    var isAnalyticsEnabled = true
    var consentRequested = false
    var anonymizationCalled = false
    var userConsents: [UUID: Bool] = [:]
    
    // MARK: - PrivacyManagerProtocol Implementation
    
    func requestAnalyticsConsent(for userId: UUID) async {
        consentRequested = true
        userConsents[userId] = isAnalyticsEnabled
    }
    
    func hasAnalyticsConsent(for userId: UUID) async -> Bool {
        return userConsents[userId] ?? isAnalyticsEnabled
    }
    
    func revokeAnalyticsConsent(for userId: UUID) async {
        userConsents[userId] = false
    }
    
    func anonymizeUserData<T: Anonymizable>(_ data: T) async throws -> T {
        anonymizationCalled = true
        return data.anonymized()
    }
    
    func canCollectAnalytics(for userId: UUID) async -> Bool {
        return await hasAnalyticsConsent(for: userId)
    }
    
    func enforceDataRetentionPolicy() async throws {
        // Mock implementation - mark as enforced
        let cutoffDate = Date().addingTimeInterval(-86400 * 30) // 30 days
        // In real implementation would delete old data
    }
    
    // MARK: - Mock Helper Methods
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        isAnalyticsEnabled = enabled
    }
    
    func setConsent(for userId: UUID, granted: Bool) {
        userConsents[userId] = granted
    }
    
    func reset() {
        isAnalyticsEnabled = true
        consentRequested = false
        anonymizationCalled = false
        userConsents.removeAll()
    }
}

// MARK: - MockAnalyticsCollector

final class MockAnalyticsCollector: AnalyticsCollectorProtocol {
    
    // MARK: - Mock Properties
    var collectedEvents: [AnalyticsEvent] = []
    var isCollecting = false
    
    // MARK: - AnalyticsCollectorProtocol Implementation
    
    func startCollection() async {
        isCollecting = true
    }
    
    func stopCollection() async {
        isCollecting = false
    }
    
    func recordEvent(_ event: AnalyticsEvent) async {
        guard isCollecting else { return }
        collectedEvents.append(event)
    }
    
    func flush() async throws {
        // Mock implementation - clear events
        collectedEvents.removeAll()
    }
    
    // MARK: - Mock Helper Methods
    
    func reset() {
        collectedEvents.removeAll()
        isCollecting = false
    }
}