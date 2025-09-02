import Foundation
import Combine

/// KPI種別
public enum KPIType: String, CaseIterable {
    case userRetention = "user_retention"
    case sessionDuration = "session_duration"
    case featureUsage = "feature_usage"
    case userEngagement = "user_engagement"
    case crashRate = "crash_rate"
    case errorRate = "error_rate"
    case performanceScore = "performance_score"
    case conversionRate = "conversion_rate"
    case revenuePerUser = "revenue_per_user"
    case mindMapCreation = "mindmap_creation"
    case nodeCreation = "node_creation"
    case shareAction = "share_action"
    case exportAction = "export_action"
}

/// KPI値の型
public enum KPIValueType {
    case integer(Int)
    case double(Double)
    case boolean(Bool)
    case duration(TimeInterval)
    case percentage(Double)
    
    public var numericValue: Double {
        switch self {
        case .integer(let value): return Double(value)
        case .double(let value): return value
        case .boolean(let value): return value ? 1.0 : 0.0
        case .duration(let value): return value
        case .percentage(let value): return value
        }
    }
}

/// KPI測定データ
public struct KPIMeasurement {
    public let id: UUID
    public let type: KPIType
    public let value: KPIValueType
    public let timestamp: Date
    public let userId: String?
    public let sessionId: String?
    public let metadata: [String: Any]?
    
    public init(
        id: UUID = UUID(),
        type: KPIType,
        value: KPIValueType,
        timestamp: Date = Date(),
        userId: String? = nil,
        sessionId: String? = nil,
        metadata: [String: Any]? = nil
    ) {
        self.id = id
        self.type = type
        self.value = value
        self.timestamp = timestamp
        self.userId = userId
        self.sessionId = sessionId
        self.metadata = metadata
    }
}

/// KPI統計情報
public struct KPIStatistics {
    public let type: KPIType
    public let count: Int
    public let average: Double
    public let minimum: Double
    public let maximum: Double
    public let standardDeviation: Double
    public let trend: KPITrend
    public let period: DateInterval
    
    public init(type: KPIType, measurements: [KPIMeasurement], period: DateInterval) {
        self.type = type
        self.period = period
        
        let values = measurements.map { $0.value.numericValue }
        self.count = values.count
        
        if values.isEmpty {
            self.average = 0
            self.minimum = 0
            self.maximum = 0
            self.standardDeviation = 0
            self.trend = .stable
        } else {
            self.average = values.reduce(0, +) / Double(values.count)
            self.minimum = values.min() ?? 0
            self.maximum = values.max() ?? 0
            
            let mean = self.average
            let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
            self.standardDeviation = sqrt(variance)
            
            // 簡単なトレンド計算（実際にはより複雑な分析が必要）
            if values.count > 1 {
                let firstHalf = Array(values.prefix(values.count / 2))
                let secondHalf = Array(values.suffix(values.count / 2))
                let firstAverage = firstHalf.reduce(0, +) / Double(firstHalf.count)
                let secondAverage = secondHalf.reduce(0, +) / Double(secondHalf.count)
                
                if secondAverage > firstAverage * 1.05 {
                    self.trend = .increasing
                } else if secondAverage < firstAverage * 0.95 {
                    self.trend = .decreasing
                } else {
                    self.trend = .stable
                }
            } else {
                self.trend = .stable
            }
        }
    }
}

/// KPIトレンド
public enum KPITrend {
    case increasing
    case decreasing
    case stable
}

/// KPI測定・追跡システム
@MainActor
public class KPITracker: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var isTracking: Bool = false
    @Published public private(set) var measurements: [KPIMeasurement] = []
    
    private var storage: KPIStorageProtocol
    private var currentSessionId: String
    private var currentUserId: String?
    
    // MARK: - Initialization
    
    public init(storage: KPIStorageProtocol = CoreDataKPIStorage()) {
        self.storage = storage
        self.currentSessionId = UUID().uuidString
        loadStoredMeasurements()
    }
    
    // MARK: - Public Methods
    
    public func startTracking(userId: String? = nil) async throws {
        guard !isTracking else { return }
        
        isTracking = true
        currentUserId = userId
        currentSessionId = UUID().uuidString
    }
    
    public func stopTracking() async throws {
        guard isTracking else { return }
        
        isTracking = false
        
        // セッション終了のKPIを記録
        await trackKPI(.sessionDuration, value: .duration(Date().timeIntervalSince1970 - TimeInterval(currentSessionId.hash)))
    }
    
    public func trackKPI(_ type: KPIType, value: KPIValueType, metadata: [String: Any]? = nil) async {
        let measurement = KPIMeasurement(
            type: type,
            value: value,
            userId: currentUserId,
            sessionId: currentSessionId,
            metadata: metadata
        )
        
        measurements.append(measurement)
        
        do {
            try await storage.saveMeasurement(measurement)
        } catch {
            print("Failed to save KPI measurement: \(error)")
        }
    }
    
    public func getStatistics(for type: KPIType, period: DateInterval) async throws -> KPIStatistics {
        let measurements = try await storage.loadMeasurements(type: type, from: period.start, to: period.end)
        return KPIStatistics(type: type, measurements: measurements, period: period)
    }
    
    public func getAllStatistics(period: DateInterval) async throws -> [KPIStatistics] {
        var allStatistics: [KPIStatistics] = []
        
        for type in KPIType.allCases {
            let statistics = try await getStatistics(for: type, period: period)
            allStatistics.append(statistics)
        }
        
        return allStatistics
    }
    
    public func getDashboard() async throws -> KPIDashboard {
        let last30Days = DateInterval(start: Date().addingTimeInterval(-30 * 24 * 3600), end: Date())
        let statistics = try await getAllStatistics(period: last30Days)
        return KPIDashboard(statistics: statistics)
    }
    
    public func cleanupOldData() async throws {
        let threeMonthsAgo = Date().addingTimeInterval(-90 * 24 * 3600)
        try await storage.deleteMeasurementsOlderThan(threeMonthsAgo)
    }
    
    // MARK: - Convenience Methods
    
    public func trackMindMapCreated() async {
        await trackKPI(.mindMapCreation, value: .integer(1))
    }
    
    public func trackNodeCreated(count: Int = 1) async {
        await trackKPI(.nodeCreation, value: .integer(count))
    }
    
    public func trackFeatureUsed(_ featureName: String) async {
        await trackKPI(.featureUsage, value: .integer(1), metadata: ["feature": featureName])
    }
    
    public func trackUserEngagement(score: Double) async {
        await trackKPI(.userEngagement, value: .double(score))
    }
    
    public func trackSessionDuration(_ duration: TimeInterval) async {
        await trackKPI(.sessionDuration, value: .duration(duration))
    }
    
    public func trackConversion(success: Bool, conversionType: String) async {
        await trackKPI(.conversionRate, value: .boolean(success), metadata: ["conversion_type": conversionType])
    }
    
    // MARK: - Private Methods
    
    private func loadStoredMeasurements() {
        Task {
            do {
                let recent = try await storage.loadRecentMeasurements(limit: 100)
                await MainActor.run {
                    measurements = recent
                }
            } catch {
                print("Failed to load stored measurements: \(error)")
            }
        }
    }
}

/// KPIダッシュボード
public struct KPIDashboard {
    public let statistics: [KPIStatistics]
    public let totalUsers: Int
    public let totalSessions: Int
    public let averageSessionDuration: TimeInterval
    public let topFeatures: [(String, Int)]
    public let conversionRates: [String: Double]
    
    init(statistics: [KPIStatistics]) {
        self.statistics = statistics
        
        // ダッシュボード用の集計データを計算
        self.totalUsers = 0 // 実際の実装では統計から計算
        self.totalSessions = 0 // 実際の実装では統計から計算
        self.averageSessionDuration = statistics.first { $0.type == .sessionDuration }?.average ?? 0
        self.topFeatures = [] // 実際の実装では統計から計算
        self.conversionRates = [:] // 実際の実装では統計から計算
    }
}

/// KPIストレージプロトコル
public protocol KPIStorageProtocol {
    func saveMeasurement(_ measurement: KPIMeasurement) async throws
    func loadMeasurements(type: KPIType, from startDate: Date, to endDate: Date) async throws -> [KPIMeasurement]
    func loadRecentMeasurements(limit: Int) async throws -> [KPIMeasurement]
    func deleteMeasurementsOlderThan(_ date: Date) async throws
}

/// CoreData実装のKPI永続化
public class CoreDataKPIStorage: KPIStorageProtocol {
    
    public init() {}
    
    public func saveMeasurement(_ measurement: KPIMeasurement) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Saving KPI measurement \(measurement.type)")
    }
    
    public func loadMeasurements(type: KPIType, from startDate: Date, to endDate: Date) async throws -> [KPIMeasurement] {
        // CoreData実装（今回はMock実装）
        return []
    }
    
    public func loadRecentMeasurements(limit: Int) async throws -> [KPIMeasurement] {
        // CoreData実装（今回はMock実装）
        return []
    }
    
    public func deleteMeasurementsOlderThan(_ date: Date) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Deleting KPI measurements older than \(date)")
    }
}