import Foundation
import Combine
#if canImport(MetricKit) && !os(macOS)
import MetricKit
#endif

/// パフォーマンス監視システム
@MainActor
public class PerformanceMonitor: NSObject, ObservableObject {
    
    // MARK: - Properties
    
    public var storage: PerformanceStorageProtocol
    public var onPerformanceAlert: ((PerformanceAlert) -> Void)?
    
    @Published public private(set) var isMonitoring: Bool = false
    @Published public private(set) var metricsCollectionInterval: TimeInterval = 60.0
    
    private var memoryUsageThreshold: Double = 500_000_000 // 500MB
    private var cpuUsageThreshold: Double = 80.0 // 80%
    private var batteryUsageThreshold: Double = 85.0 // 85%
    
    private var metricsCollectionTimer: Timer?
    private var collectedMetrics: [PerformanceMetric] = []
    
    // MARK: - Initialization
    
    public init(storage: PerformanceStorageProtocol = CoreDataPerformanceStorage()) {
        self.storage = storage
        super.init()
        setupMetricKit()
    }
    
    private func setupMetricKit() {
        // MetricKit MXMetricManager のセットアップ
        // 実際の実装では MXMetricManager.shared.add(self) を使用
    }
    
    // MARK: - Public Methods
    
    public func initialize() async throws {
        isMonitoring = true
        metricsCollectionInterval = 60.0
        try await startMonitoring()
    }
    
    public func startMonitoring() async throws {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        startMetricsCollection()
    }
    
    public func stopMonitoring() async throws {
        guard isMonitoring else { return }
        
        isMonitoring = false
        stopMetricsCollection()
    }
    
    public func collectMetrics() async throws -> [PerformanceMetric] {
        // 現在のシステムメトリクスを収集
        let currentMetrics = await collectCurrentSystemMetrics()
        collectedMetrics.append(contentsOf: currentMetrics)
        return collectedMetrics
    }
    
    public func setMetricsCollectionInterval(_ interval: TimeInterval) async throws {
        metricsCollectionInterval = interval
        
        if isMonitoring {
            stopMetricsCollection()
            startMetricsCollection()
        }
    }
    
    public func setMemoryUsageThreshold(_ threshold: Double) async throws {
        memoryUsageThreshold = threshold
    }
    
    public func setCPUUsageThreshold(_ threshold: Double) async throws {
        cpuUsageThreshold = threshold
    }
    
    public func saveMetrics(_ metrics: [PerformanceMetric]) async throws {
        try await storage.save(metrics)
    }
    
    public func cleanupOldData() async throws {
        let sevenDaysAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        try await storage.deleteMetricsOlderThan(sevenDaysAgo)
    }
    
    // MARK: - Testing Methods
    
    public func simulateHighMemoryUsage(_ memoryUsage: Double) async {
        let alert = PerformanceAlert(
            type: .memoryUsage,
            severity: .warning,
            value: memoryUsage,
            threshold: memoryUsageThreshold,
            timestamp: Date(),
            message: "Memory usage exceeded threshold: \(memoryUsage) > \(memoryUsageThreshold)"
        )
        
        onPerformanceAlert?(alert)
    }
    
    public func simulateHighCPUUsage(_ cpuUsage: Double) async {
        let alert = PerformanceAlert(
            type: .cpuUsage,
            severity: .critical,
            value: cpuUsage,
            threshold: cpuUsageThreshold,
            timestamp: Date(),
            message: "CPU usage exceeded threshold: \(cpuUsage)% > \(cpuUsageThreshold)%"
        )
        
        onPerformanceAlert?(alert)
    }
    
    // MARK: - Private Methods
    
    private func startMetricsCollection() {
        metricsCollectionTimer = Timer.scheduledTimer(withTimeInterval: metricsCollectionInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.collectAndProcessMetrics()
            }
        }
    }
    
    private func stopMetricsCollection() {
        metricsCollectionTimer?.invalidate()
        metricsCollectionTimer = nil
    }
    
    private func collectAndProcessMetrics() async {
        do {
            let currentMetrics = await collectCurrentSystemMetrics()
            collectedMetrics.append(contentsOf: currentMetrics)
            
            // 閾値チェック
            await checkThresholds(metrics: currentMetrics)
            
            // メトリクスを保存
            try await saveMetrics(currentMetrics)
        } catch {
            print("Error collecting metrics: \(error)")
        }
    }
    
    private func collectCurrentSystemMetrics() async -> [PerformanceMetric] {
        // 実際の実装では MetricKit や system API を使用
        // テスト用のダミーデータを返す
        let timestamp = Date()
        
        return [
            PerformanceMetric(type: .memoryUsage, value: 150_000_000, timestamp: timestamp),
            PerformanceMetric(type: .cpuUsage, value: 35.5, timestamp: timestamp),
            PerformanceMetric(type: .batteryUsage, value: 45.2, timestamp: timestamp)
        ]
    }
    
    private func checkThresholds(metrics: [PerformanceMetric]) async {
        for metric in metrics {
            switch metric.type {
            case .memoryUsage:
                if metric.value > memoryUsageThreshold {
                    let alert = PerformanceAlert(
                        type: .memoryUsage,
                        severity: .warning,
                        value: metric.value,
                        threshold: memoryUsageThreshold,
                        timestamp: metric.timestamp,
                        message: "Memory usage exceeded threshold"
                    )
                    onPerformanceAlert?(alert)
                }
                
            case .cpuUsage:
                if metric.value > cpuUsageThreshold {
                    let alert = PerformanceAlert(
                        type: .cpuUsage,
                        severity: .critical,
                        value: metric.value,
                        threshold: cpuUsageThreshold,
                        timestamp: metric.timestamp,
                        message: "CPU usage exceeded threshold"
                    )
                    onPerformanceAlert?(alert)
                }
                
            default:
                break
            }
        }
    }
}

// MARK: - MXMetricManagerSubscriber

#if canImport(MetricKit) && !os(macOS)
@available(iOS 13.0, *)
extension PerformanceMonitor: MXMetricManagerSubscriber {
    
    public func didReceive(_ payloads: [MXMetricPayload]) {
        Task { @MainActor in
            await processMetricKitPayloads(payloads)
        }
    }
    
    private func processMetricKitPayloads(_ payloads: [MXMetricPayload]) async {
        for payload in payloads {
            let metrics = await convertMetricKitPayloadToMetrics(payload)
            collectedMetrics.append(contentsOf: metrics)
        }
    }
    
    private func convertMetricKitPayloadToMetrics(_ payload: MXMetricPayload) async -> [PerformanceMetric] {
        var metrics: [PerformanceMetric] = []
        
        // CPU メトリクス
        if let cpuMetrics = payload.cpuMetrics {
            let cpuUsage = cpuMetrics.cumulativeCPUTime.doubleValue
            metrics.append(PerformanceMetric(
                type: .cpuUsage,
                value: cpuUsage,
                timestamp: payload.timeStampEnd
            ))
        }
        
        // メモリ メトリクス
        if let memoryMetrics = payload.memoryMetrics {
            let peakMemory = memoryMetrics.peakMemoryUsage.doubleValue
            metrics.append(PerformanceMetric(
                type: .memoryUsage,
                value: peakMemory,
                timestamp: payload.timeStampEnd
            ))
        }
        
        // ディスク メトリクス
        if let diskMetrics = payload.diskIOMetrics {
            let diskUsage = diskMetrics.cumulativeLogicalWrites.doubleValue
            metrics.append(PerformanceMetric(
                type: .diskUsage,
                value: diskUsage,
                timestamp: payload.timeStampEnd
            ))
        }
        
        // アプリ起動時間
        if let launchMetrics = payload.applicationLaunchMetrics {
            let launchTime = launchMetrics.histogrammedTimeToFirstDraw.totalBucketCount.doubleValue
            metrics.append(PerformanceMetric(
                type: .appLaunchTime,
                value: launchTime,
                timestamp: payload.timeStampEnd
            ))
        }
        
        return metrics
    }
}
#endif