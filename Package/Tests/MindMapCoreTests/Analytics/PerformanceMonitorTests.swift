import Testing
import MetricKit
@testable import MindMapCore

/// Task 29: パフォーマンス監視・メトリクステスト
/// TDD Red Phase: 失敗するテストを最初に作成
@MainActor
struct PerformanceMonitorTests {
    
    // MARK: - MetricKit統合テスト
    
    @Test("MetricKit統合でパフォーマンスデータを収集できる")
    func testMetricKitIntegrationCollectsPerformanceData() async throws {
        // Given
        let monitor = PerformanceMonitor()
        
        // When
        try await monitor.startMonitoring()
        let metrics = try await monitor.collectMetrics()
        
        // Then
        #expect(!metrics.isEmpty)
        #expect(metrics.contains { $0.type == .memoryUsage })
        #expect(metrics.contains { $0.type == .cpuUsage })
        #expect(metrics.contains { $0.type == .batteryUsage })
    }
    
    @Test("アプリ起動時のパフォーマンス監視が開始される")
    func testPerformanceMonitoringStartsOnAppLaunch() async throws {
        // Given
        let monitor = PerformanceMonitor()
        
        // When
        try await monitor.initialize()
        
        // Then
        #expect(monitor.isMonitoring)
        #expect(monitor.metricsCollectionInterval == 60.0) // 1分間隔
    }
    
    @Test("メトリクス収集間隔をカスタマイズできる")
    func testCustomMetricsCollectionInterval() async throws {
        // Given
        let monitor = PerformanceMonitor()
        let customInterval: TimeInterval = 30.0
        
        // When
        try await monitor.setMetricsCollectionInterval(customInterval)
        
        // Then
        #expect(monitor.metricsCollectionInterval == customInterval)
    }
    
    // MARK: - パフォーマンス閾値テスト
    
    @Test("メモリ使用量が閾値を超えた場合にアラートが発生する")
    func testMemoryUsageThresholdAlert() async throws {
        // Given
        let monitor = PerformanceMonitor()
        let memoryThreshold: Double = 100_000_000 // 100MB
        var alertTriggered = false
        
        monitor.onPerformanceAlert = { alert in
            alertTriggered = true
            #expect(alert.type == .memoryUsage)
            #expect(alert.severity == .warning)
        }
        
        // When
        try await monitor.setMemoryUsageThreshold(memoryThreshold)
        await monitor.simulateHighMemoryUsage(memoryThreshold + 10_000_000)
        
        // Then
        #expect(alertTriggered)
    }
    
    @Test("CPU使用率が高い場合にアラートが発生する")
    func testCPUUsageThresholdAlert() async throws {
        // Given
        let monitor = PerformanceMonitor()
        let cpuThreshold: Double = 80.0 // 80%
        var alertTriggered = false
        
        monitor.onPerformanceAlert = { alert in
            alertTriggered = true
            #expect(alert.type == .cpuUsage)
            #expect(alert.severity == .critical)
        }
        
        // When
        try await monitor.setCPUUsageThreshold(cpuThreshold)
        await monitor.simulateHighCPUUsage(cpuThreshold + 10.0)
        
        // Then
        #expect(alertTriggered)
    }
    
    // MARK: - データ永続化テスト
    
    @Test("パフォーマンスメトリクスをローカルに保存できる")
    func testPerformanceMetricsLocalStorage() async throws {
        // Given
        let monitor = PerformanceMonitor()
        let mockStorage = MockPerformanceStorage()
        monitor.storage = mockStorage
        
        // When
        let metrics = [
            PerformanceMetric(type: .memoryUsage, value: 75_000_000, timestamp: Date()),
            PerformanceMetric(type: .cpuUsage, value: 45.5, timestamp: Date())
        ]
        
        try await monitor.saveMetrics(metrics)
        
        // Then
        #expect(mockStorage.savedMetrics.count == 2)
        #expect(mockStorage.savedMetrics.first?.type == .memoryUsage)
    }
    
    @Test("古いパフォーマンスデータを自動削除する")
    func testOldPerformanceDataCleanup() async throws {
        // Given
        let monitor = PerformanceMonitor()
        let mockStorage = MockPerformanceStorage()
        monitor.storage = mockStorage
        
        // 7日前のデータを追加
        let oldMetric = PerformanceMetric(
            type: .memoryUsage,
            value: 50_000_000,
            timestamp: Date().addingTimeInterval(-7 * 24 * 3600)
        )
        mockStorage.savedMetrics = [oldMetric]
        
        // When
        try await monitor.cleanupOldData()
        
        // Then
        #expect(mockStorage.savedMetrics.isEmpty)
    }
}

// MARK: - Mock Objects

class MockPerformanceStorage: PerformanceStorageProtocol {
    var savedMetrics: [PerformanceMetric] = []
    
    func save(_ metrics: [PerformanceMetric]) async throws {
        savedMetrics.append(contentsOf: metrics)
    }
    
    func loadMetrics(from startDate: Date, to endDate: Date) async throws -> [PerformanceMetric] {
        return savedMetrics.filter { metric in
            metric.timestamp >= startDate && metric.timestamp <= endDate
        }
    }
    
    func deleteMetricsOlderThan(_ date: Date) async throws {
        savedMetrics.removeAll { $0.timestamp < date }
    }
}