import Foundation

/// パフォーマンスメトリクス永続化プロトコル
public protocol PerformanceStorageProtocol {
    func save(_ metrics: [PerformanceMetric]) async throws
    func loadMetrics(from startDate: Date, to endDate: Date) async throws -> [PerformanceMetric]
    func deleteMetricsOlderThan(_ date: Date) async throws
}

/// CoreData実装のパフォーマンス永続化
public class CoreDataPerformanceStorage: PerformanceStorageProtocol {
    
    public init() {}
    
    public func save(_ metrics: [PerformanceMetric]) async throws {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data でメトリクスを保存
        print("CoreData: Saving \(metrics.count) metrics")
    }
    
    public func loadMetrics(from startDate: Date, to endDate: Date) async throws -> [PerformanceMetric] {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data から指定期間のメトリクスを取得
        return []
    }
    
    public func deleteMetricsOlderThan(_ date: Date) async throws {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data から古いメトリクスを削除
        print("CoreData: Deleting metrics older than \(date)")
    }
}