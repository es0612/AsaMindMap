import Foundation
import MetricKit

/// パフォーマンスメトリクス種別
public enum PerformanceMetricType {
    case memoryUsage
    case cpuUsage
    case batteryUsage
    case diskUsage
    case networkUsage
    case appLaunchTime
    case hitchRate
    case frameRate
}

/// パフォーマンスアラート重要度
public enum PerformanceAlertSeverity {
    case info
    case warning
    case critical
}

/// パフォーマンスメトリクス
public struct PerformanceMetric {
    public let type: PerformanceMetricType
    public let value: Double
    public let timestamp: Date
    public let metadata: [String: Any]?
    
    public init(type: PerformanceMetricType, value: Double, timestamp: Date, metadata: [String: Any]? = nil) {
        self.type = type
        self.value = value
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

/// パフォーマンスアラート
public struct PerformanceAlert {
    public let type: PerformanceMetricType
    public let severity: PerformanceAlertSeverity
    public let value: Double
    public let threshold: Double
    public let timestamp: Date
    public let message: String
    
    public init(type: PerformanceMetricType, severity: PerformanceAlertSeverity, value: Double, threshold: Double, timestamp: Date, message: String) {
        self.type = type
        self.severity = severity
        self.value = value
        self.threshold = threshold
        self.timestamp = timestamp
        self.message = message
    }
}