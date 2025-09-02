import Foundation
import Combine
import UserNotifications

/// アラート種別
public enum AlertType {
    case performance
    case crash
    case error
    case kpi
    case security
    case system
}

/// アラート重要度
public enum AlertSeverity {
    case info
    case warning
    case critical
    case emergency
    
    public var priority: Int {
        switch self {
        case .info: return 1
        case .warning: return 2
        case .critical: return 3
        case .emergency: return 4
        }
    }
}

/// アラート
public struct Alert {
    public let id: UUID
    public let type: AlertType
    public let severity: AlertSeverity
    public let title: String
    public let message: String
    public let timestamp: Date
    public let source: String
    public let metadata: [String: Any]?
    public let isResolved: Bool
    public let resolvedAt: Date?
    
    public init(
        id: UUID = UUID(),
        type: AlertType,
        severity: AlertSeverity,
        title: String,
        message: String,
        timestamp: Date = Date(),
        source: String,
        metadata: [String: Any]? = nil,
        isResolved: Bool = false,
        resolvedAt: Date? = nil
    ) {
        self.id = id
        self.type = type
        self.severity = severity
        self.title = title
        self.message = message
        self.timestamp = timestamp
        self.source = source
        self.metadata = metadata
        self.isResolved = isResolved
        self.resolvedAt = resolvedAt
    }
}

/// アラートルール
public struct AlertRule {
    public let id: String
    public let name: String
    public let description: String
    public let type: AlertType
    public let severity: AlertSeverity
    public let condition: AlertCondition
    public let isEnabled: Bool
    public let cooldownPeriod: TimeInterval
    public let lastTriggered: Date?
    
    public init(
        id: String,
        name: String,
        description: String,
        type: AlertType,
        severity: AlertSeverity,
        condition: AlertCondition,
        isEnabled: Bool = true,
        cooldownPeriod: TimeInterval = 300, // 5分
        lastTriggered: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.severity = severity
        self.condition = condition
        self.isEnabled = isEnabled
        self.cooldownPeriod = cooldownPeriod
        self.lastTriggered = lastTriggered
    }
}

/// アラート条件
public struct AlertCondition {
    public let metricType: String
    public let `operator`: ComparisonOperator
    public let threshold: Double
    public let windowSize: TimeInterval
    public let evaluationInterval: TimeInterval
    
    public init(
        metricType: String,
        operator: ComparisonOperator,
        threshold: Double,
        windowSize: TimeInterval = 300, // 5分
        evaluationInterval: TimeInterval = 60 // 1分
    ) {
        self.metricType = metricType
        self.`operator` = `operator`
        self.threshold = threshold
        self.windowSize = windowSize
        self.evaluationInterval = evaluationInterval
    }
}

/// 比較演算子
public enum ComparisonOperator {
    case greaterThan
    case lessThan
    case equals
    case greaterThanOrEqual
    case lessThanOrEqual
    case notEquals
    
    public func evaluate(_ value: Double, against threshold: Double) -> Bool {
        switch self {
        case .greaterThan: return value > threshold
        case .lessThan: return value < threshold
        case .equals: return abs(value - threshold) < 0.001
        case .greaterThanOrEqual: return value >= threshold
        case .lessThanOrEqual: return value <= threshold
        case .notEquals: return abs(value - threshold) >= 0.001
        }
    }
}

/// システムヘルス状態
public enum SystemHealthStatus {
    case healthy
    case warning
    case critical
    case down
}

/// システムヘルス
public struct SystemHealth {
    public let status: SystemHealthStatus
    public let timestamp: Date
    public let components: [ComponentHealth]
    public let overallScore: Double
    public let activeAlerts: [Alert]
    
    public init(components: [ComponentHealth], activeAlerts: [Alert]) {
        self.components = components
        self.activeAlerts = activeAlerts
        self.timestamp = Date()
        
        // 全体スコアを計算
        let healthyCount = components.filter { $0.status == .healthy }.count
        self.overallScore = Double(healthyCount) / Double(max(components.count, 1))
        
        // 全体ステータスを決定
        let criticalAlerts = activeAlerts.filter { $0.severity == .critical || $0.severity == .emergency }
        let warningAlerts = activeAlerts.filter { $0.severity == .warning }
        
        if !criticalAlerts.isEmpty {
            self.status = .critical
        } else if !warningAlerts.isEmpty || overallScore < 0.8 {
            self.status = .warning
        } else if overallScore < 0.5 {
            self.status = .down
        } else {
            self.status = .healthy
        }
    }
}

/// コンポーネントヘルス
public struct ComponentHealth {
    public let name: String
    public let status: SystemHealthStatus
    public let lastChecked: Date
    public let responseTime: TimeInterval?
    public let errorRate: Double?
    public let message: String?
    
    public init(
        name: String,
        status: SystemHealthStatus,
        lastChecked: Date = Date(),
        responseTime: TimeInterval? = nil,
        errorRate: Double? = nil,
        message: String? = nil
    ) {
        self.name = name
        self.status = status
        self.responseTime = responseTime
        self.errorRate = errorRate
        self.message = message
        self.lastChecked = lastChecked
    }
}

/// 統合監視・アラートシステム
@MainActor
public class MonitoringSystem: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var systemHealth: SystemHealth
    @Published public private(set) var activeAlerts: [Alert] = []
    @Published public private(set) var alertRules: [AlertRule] = []
    @Published public private(set) var isMonitoring: Bool = false
    
    private var performanceMonitor: PerformanceMonitor
    private var crashAnalyzer: CrashAnalyzer
    private var kpiTracker: KPITracker
    private var storage: MonitoringStorageProtocol
    
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    public init(
        performanceMonitor: PerformanceMonitor,
        crashAnalyzer: CrashAnalyzer,
        kpiTracker: KPITracker,
        storage: MonitoringStorageProtocol = CoreDataMonitoringStorage()
    ) {
        self.performanceMonitor = performanceMonitor
        self.crashAnalyzer = crashAnalyzer
        self.kpiTracker = kpiTracker
        self.storage = storage
        
        // 初期ヘルス状態
        self.systemHealth = SystemHealth(components: [], activeAlerts: [])
        
        setupDefaultAlertRules()
        setupMonitoring()
    }
    
    // MARK: - Public Methods
    
    public func startMonitoring() async throws {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        
        // 各コンポーネントの監視を開始
        try await performanceMonitor.startMonitoring()
        try await crashAnalyzer.startAnalyzing()
        try await kpiTracker.startTracking()
        
        // 定期的なヘルスチェックを開始
        startHealthCheck()
        
        // 通知許可を要求
        await requestNotificationPermission()
    }
    
    public func stopMonitoring() async throws {
        guard isMonitoring else { return }
        
        isMonitoring = false
        
        // 各コンポーネントの監視を停止
        try await performanceMonitor.stopMonitoring()
        try await crashAnalyzer.stopAnalyzing()
        try await kpiTracker.stopTracking()
        
        // ヘルスチェックを停止
        stopHealthCheck()
    }
    
    public func addAlertRule(_ rule: AlertRule) async throws {
        alertRules.append(rule)
        try await storage.saveAlertRule(rule)
    }
    
    public func removeAlertRule(_ ruleId: String) async throws {
        alertRules.removeAll { $0.id == ruleId }
        try await storage.deleteAlertRule(ruleId)
    }
    
    public func resolveAlert(_ alertId: UUID) async throws {
        if let index = activeAlerts.firstIndex(where: { $0.id == alertId }) {
            let resolvedAlert = Alert(
                id: activeAlerts[index].id,
                type: activeAlerts[index].type,
                severity: activeAlerts[index].severity,
                title: activeAlerts[index].title,
                message: activeAlerts[index].message,
                timestamp: activeAlerts[index].timestamp,
                source: activeAlerts[index].source,
                metadata: activeAlerts[index].metadata,
                isResolved: true,
                resolvedAt: Date()
            )
            
            activeAlerts[index] = resolvedAlert
            try await storage.saveAlert(resolvedAlert)
        }
    }
    
    public func getSystemHealthHistory(period: DateInterval) async throws -> [SystemHealth] {
        return try await storage.getHealthHistory(from: period.start, to: period.end)
    }
    
    public func getAlertHistory(period: DateInterval) async throws -> [Alert] {
        return try await storage.getAlerts(from: period.start, to: period.end)
    }
    
    public func runHealthCheck() async throws -> SystemHealth {
        let components = await checkAllComponents()
        let health = SystemHealth(components: components, activeAlerts: activeAlerts)
        
        // ヘルス状態を保存
        try await storage.saveHealthSnapshot(health)
        
        await MainActor.run {
            systemHealth = health
        }
        
        return health
    }
    
    // MARK: - Private Methods
    
    private func setupDefaultAlertRules() {
        alertRules = [
            // パフォーマンスアラート
            AlertRule(
                id: "high_memory_usage",
                name: "High Memory Usage",
                description: "Memory usage exceeds 80%",
                type: .performance,
                severity: .warning,
                condition: AlertCondition(
                    metricType: "memory_usage",
                    operator: .greaterThan,
                    threshold: 0.8
                )
            ),
            
            AlertRule(
                id: "high_cpu_usage",
                name: "High CPU Usage",
                description: "CPU usage exceeds 90%",
                type: .performance,
                severity: .critical,
                condition: AlertCondition(
                    metricType: "cpu_usage",
                    operator: .greaterThan,
                    threshold: 0.9
                )
            ),
            
            // クラッシュアラート
            AlertRule(
                id: "crash_rate_high",
                name: "High Crash Rate",
                description: "Crash rate exceeds 1%",
                type: .crash,
                severity: .critical,
                condition: AlertCondition(
                    metricType: "crash_rate",
                    operator: .greaterThan,
                    threshold: 0.01
                )
            ),
            
            // KPIアラート
            AlertRule(
                id: "low_user_retention",
                name: "Low User Retention",
                description: "User retention drops below 70%",
                type: .kpi,
                severity: .warning,
                condition: AlertCondition(
                    metricType: "user_retention",
                    operator: .lessThan,
                    threshold: 0.7
                )
            )
        ]
    }
    
    private func setupMonitoring() {
        // パフォーマンスアラートの設定
        performanceMonitor.onPerformanceAlert = { [weak self] alert in
            Task { @MainActor in
                await self?.handlePerformanceAlert(alert)
            }
        }
        
        // クラッシュアラートの設定
        crashAnalyzer.onCrashDetected = { [weak self] crashReport in
            Task { @MainActor in
                await self?.handleCrashAlert(crashReport)
            }
        }
        
        crashAnalyzer.onErrorDetected = { [weak self] errorEvent in
            Task { @MainActor in
                await self?.handleErrorAlert(errorEvent)
            }
        }
    }
    
    private func startHealthCheck() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                try await self?.runHealthCheck()
            }
        }
    }
    
    private func stopHealthCheck() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func checkAllComponents() async -> [ComponentHealth] {
        var components: [ComponentHealth] = []
        
        // Performance Monitor のヘルスチェック
        let perfHealth = await checkPerformanceMonitorHealth()
        components.append(perfHealth)
        
        // Crash Analyzer のヘルスチェック
        let crashHealth = await checkCrashAnalyzerHealth()
        components.append(crashHealth)
        
        // KPI Tracker のヘルスチェック
        let kpiHealth = await checkKPITrackerHealth()
        components.append(kpiHealth)
        
        // Database のヘルスチェック
        let dbHealth = await checkDatabaseHealth()
        components.append(dbHealth)
        
        return components
    }
    
    private func checkPerformanceMonitorHealth() async -> ComponentHealth {
        let isHealthy = performanceMonitor.isMonitoring
        return ComponentHealth(
            name: "Performance Monitor",
            status: isHealthy ? .healthy : .critical,
            message: isHealthy ? "Operating normally" : "Not monitoring"
        )
    }
    
    private func checkCrashAnalyzerHealth() async -> ComponentHealth {
        let isHealthy = crashAnalyzer.isAnalyzing
        return ComponentHealth(
            name: "Crash Analyzer",
            status: isHealthy ? .healthy : .critical,
            message: isHealthy ? "Operating normally" : "Not analyzing"
        )
    }
    
    private func checkKPITrackerHealth() async -> ComponentHealth {
        let isHealthy = kpiTracker.isTracking
        return ComponentHealth(
            name: "KPI Tracker",
            status: isHealthy ? .healthy : .critical,
            message: isHealthy ? "Operating normally" : "Not tracking"
        )
    }
    
    private func checkDatabaseHealth() async -> ComponentHealth {
        // データベース接続とレスポンス時間をテスト
        let startTime = Date()
        
        do {
            _ = try await storage.getRecentAlerts(limit: 1)
            let responseTime = Date().timeIntervalSince(startTime)
            
            let status: SystemHealthStatus
            if responseTime < 0.1 {
                status = .healthy
            } else if responseTime < 0.5 {
                status = .warning
            } else {
                status = .critical
            }
            
            return ComponentHealth(
                name: "Database",
                status: status,
                responseTime: responseTime,
                message: "Response time: \(String(format: "%.3f", responseTime))s"
            )
        } catch {
            return ComponentHealth(
                name: "Database",
                status: .critical,
                message: "Connection failed: \(error.localizedDescription)"
            )
        }
    }
    
    private func handlePerformanceAlert(_ performanceAlert: PerformanceAlert) async {
        let alert = Alert(
            type: .performance,
            severity: performanceAlert.severity == .critical ? .critical : .warning,
            title: "Performance Alert",
            message: "Performance issue detected: \(performanceAlert.type)",
            source: "PerformanceMonitor",
            metadata: [
                "metric_type": "\(performanceAlert.type)",
                "value": performanceAlert.value,
                "threshold": performanceAlert.threshold
            ]
        )
        
        await processAlert(alert)
    }
    
    private func handleCrashAlert(_ crashReport: PerformanceCrashReport) async {
        let alert = Alert(
            type: .crash,
            severity: .critical,
            title: "Application Crash Detected",
            message: "Crash of type \(crashReport.type) detected",
            source: "CrashAnalyzer",
            metadata: [
                "crash_id": crashReport.id.uuidString,
                "crash_type": "\(crashReport.type)",
                "app_version": crashReport.appVersion
            ]
        )
        
        await processAlert(alert)
    }
    
    private func handleErrorAlert(_ errorEvent: ErrorEvent) async {
        let alertSeverity: AlertSeverity
        switch errorEvent.severity {
        case .low: alertSeverity = .info
        case .medium: alertSeverity = .warning
        case .high: alertSeverity = .critical
        case .critical: alertSeverity = .emergency
        }
        
        let alert = Alert(
            type: .error,
            severity: alertSeverity,
            title: "Error Detected",
            message: errorEvent.message,
            source: "CrashAnalyzer",
            metadata: [
                "error_id": errorEvent.id.uuidString,
                "error_severity": "\(errorEvent.severity)"
            ]
        )
        
        await processAlert(alert)
    }
    
    private func processAlert(_ alert: Alert) async {
        // アラートを保存
        do {
            try await storage.saveAlert(alert)
            activeAlerts.append(alert)
            
            // 通知を送信
            await sendNotification(for: alert)
            
            // アラートの数を制限（最新100件まで）
            if activeAlerts.count > 100 {
                activeAlerts = Array(activeAlerts.suffix(100))
            }
            
        } catch {
            print("Failed to process alert: \(error)")
        }
    }
    
    private func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        } catch {
            print("Failed to request notification permission: \(error)")
        }
    }
    
    private func sendNotification(for alert: Alert) async {
        guard alert.severity.priority >= AlertSeverity.warning.priority else { return }
        
        let content = UNMutableNotificationContent()
        content.title = alert.title
        content.body = alert.message
        content.sound = alert.severity == .critical || alert.severity == .emergency ? .defaultCritical : .default
        content.userInfo = [
            "alert_id": alert.id.uuidString,
            "alert_type": "\(alert.type)",
            "alert_severity": "\(alert.severity)"
        ]
        
        let request = UNNotificationRequest(
            identifier: alert.id.uuidString,
            content: content,
            trigger: nil
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send notification: \(error)")
        }
    }
}

// MARK: - Storage Protocol

public protocol MonitoringStorageProtocol {
    func saveAlert(_ alert: Alert) async throws
    func getRecentAlerts(limit: Int) async throws -> [Alert]
    func getAlerts(from startDate: Date, to endDate: Date) async throws -> [Alert]
    func saveAlertRule(_ rule: AlertRule) async throws
    func deleteAlertRule(_ ruleId: String) async throws
    func saveHealthSnapshot(_ health: SystemHealth) async throws
    func getHealthHistory(from startDate: Date, to endDate: Date) async throws -> [SystemHealth]
}

// MARK: - Core Data Implementation

public class CoreDataMonitoringStorage: MonitoringStorageProtocol {
    
    public init() {}
    
    public func saveAlert(_ alert: Alert) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Saving alert \(alert.id)")
    }
    
    public func getRecentAlerts(limit: Int) async throws -> [Alert] {
        // CoreData実装（今回はMock実装）
        return []
    }
    
    public func getAlerts(from startDate: Date, to endDate: Date) async throws -> [Alert] {
        // CoreData実装（今回はMock実装）
        return []
    }
    
    public func saveAlertRule(_ rule: AlertRule) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Saving alert rule \(rule.id)")
    }
    
    public func deleteAlertRule(_ ruleId: String) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Deleting alert rule \(ruleId)")
    }
    
    public func saveHealthSnapshot(_ health: SystemHealth) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Saving health snapshot with status \(health.status)")
    }
    
    public func getHealthHistory(from startDate: Date, to endDate: Date) async throws -> [SystemHealth] {
        // CoreData実装（今回はMock実装）
        return []
    }
}