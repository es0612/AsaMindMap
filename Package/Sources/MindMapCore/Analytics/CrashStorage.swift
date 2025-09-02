import Foundation

/// クラッシュデータ永続化プロトコル
public protocol CrashStorageProtocol {
    func saveCrashReport(_ crashReport: PerformanceCrashReport) async throws
    func saveErrorEvent(_ errorEvent: ErrorEvent) async throws
    func loadAllCrashReports() async throws -> [PerformanceCrashReport]
    func loadAllErrorEvents() async throws -> [ErrorEvent]
    func loadCrashReports(from startDate: Date, to endDate: Date) async throws -> [PerformanceCrashReport]
    func loadErrorEvents(from startDate: Date, to endDate: Date) async throws -> [ErrorEvent]
    func deleteCrashReportsOlderThan(_ date: Date) async throws
    func deleteErrorEventsOlderThan(_ date: Date) async throws
}

/// CoreData実装のクラッシュ永続化
public class CoreDataCrashStorage: CrashStorageProtocol {
    
    public init() {}
    
    public func saveCrashReport(_ crashReport: PerformanceCrashReport) async throws {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data でクラッシュレポートを保存
        print("CoreData: Saving crash report \(crashReport.id)")
    }
    
    public func saveErrorEvent(_ errorEvent: ErrorEvent) async throws {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data でエラーイベントを保存
        print("CoreData: Saving error event \(errorEvent.id)")
    }
    
    public func loadAllCrashReports() async throws -> [PerformanceCrashReport] {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data からクラッシュレポートを取得
        return []
    }
    
    public func loadAllErrorEvents() async throws -> [ErrorEvent] {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data からエラーイベントを取得
        return []
    }
    
    public func loadCrashReports(from startDate: Date, to endDate: Date) async throws -> [PerformanceCrashReport] {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data から指定期間のクラッシュレポートを取得
        return []
    }
    
    public func loadErrorEvents(from startDate: Date, to endDate: Date) async throws -> [ErrorEvent] {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data から指定期間のエラーイベントを取得
        return []
    }
    
    public func deleteCrashReportsOlderThan(_ date: Date) async throws {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data から古いクラッシュレポートを削除
        print("CoreData: Deleting crash reports older than \(date)")
    }
    
    public func deleteErrorEventsOlderThan(_ date: Date) async throws {
        // CoreData実装（今回はMock実装）
        // 実際の実装では Core Data から古いエラーイベントを削除
        print("CoreData: Deleting error events older than \(date)")
    }
}