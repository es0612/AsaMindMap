import Foundation
import Combine
#if canImport(MetricKit) && !os(macOS)
import MetricKit
#endif

/// パフォーマンスクラッシュの種類
public enum PerformanceCrashType {
    case exception
    case signal
    case outOfMemory
    case watchdog
    case unknown
}

/// パフォーマンスエラー重要度
public enum PerformanceErrorSeverity {
    case low
    case medium
    case high
    case critical
}

/// パフォーマンスクラッシュレポート
public struct PerformanceCrashReport {
    public let id: UUID
    public let timestamp: Date
    public let type: PerformanceCrashType
    public let severity: PerformanceErrorSeverity
    public let stackTrace: [String]
    public let deviceInfo: PerformanceDeviceInfo
    public let appVersion: String
    public let osVersion: String
    public let metadata: [String: Any]?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        type: PerformanceCrashType,
        severity: PerformanceErrorSeverity,
        stackTrace: [String],
        deviceInfo: PerformanceDeviceInfo,
        appVersion: String,
        osVersion: String,
        metadata: [String: Any]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.type = type
        self.severity = severity
        self.stackTrace = stackTrace
        self.deviceInfo = deviceInfo
        self.appVersion = appVersion
        self.osVersion = osVersion
        self.metadata = metadata
    }
}

/// パフォーマンスデバイス情報
public struct PerformanceDeviceInfo {
    public let model: String
    public let architecture: String
    public let memorySize: Int64
    public let diskSpace: Int64
    
    public init(model: String, architecture: String, memorySize: Int64, diskSpace: Int64) {
        self.model = model
        self.architecture = architecture
        self.memorySize = memorySize
        self.diskSpace = diskSpace
    }
}

/// エラーイベント
public struct ErrorEvent {
    public let id: UUID
    public let timestamp: Date
    public let severity: PerformanceErrorSeverity
    public let message: String
    public let stackTrace: [String]?
    public let context: [String: Any]?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        severity: PerformanceErrorSeverity,
        message: String,
        stackTrace: [String]? = nil,
        context: [String: Any]? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.severity = severity
        self.message = message
        self.stackTrace = stackTrace
        self.context = context
    }
}

/// クラッシュ解析・エラー追跡システム
@MainActor
public class CrashAnalyzer: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var crashReports: [PerformanceCrashReport] = []
    @Published public private(set) var errorEvents: [ErrorEvent] = []
    @Published public private(set) var isAnalyzing: Bool = false
    
    public var onCrashDetected: ((PerformanceCrashReport) -> Void)?
    public var onErrorDetected: ((ErrorEvent) -> Void)?
    
    private var storage: CrashStorageProtocol
    private var deviceInfo: PerformanceDeviceInfo
    
    // MARK: - Initialization
    
    public init(storage: CrashStorageProtocol = CoreDataCrashStorage()) {
        self.storage = storage
        self.deviceInfo = Self.getCurrentPerformanceDeviceInfo()
        setupCrashDetection()
    }
    
    // MARK: - Public Methods
    
    public func startAnalyzing() async throws {
        guard !isAnalyzing else { return }
        
        isAnalyzing = true
        await loadStoredReports()
        setupErrorHandling()
        
        #if canImport(MetricKit) && !os(macOS)
        if #available(iOS 14.0, *) {
            MXMetricManager.shared.add(self)
        }
        #endif
    }
    
    public func stopAnalyzing() async throws {
        guard isAnalyzing else { return }
        
        isAnalyzing = false
        
        #if canImport(MetricKit) && !os(macOS)
        if #available(iOS 14.0, *) {
            MXMetricManager.shared.remove(self)
        }
        #endif
    }
    
    public func reportError(_ error: Error, severity: PerformanceErrorSeverity = .medium, context: [String: Any]? = nil) async {
        let errorEvent = ErrorEvent(
            severity: severity,
            message: error.localizedDescription,
            stackTrace: Thread.callStackSymbols,
            context: context
        )
        
        errorEvents.append(errorEvent)
        
        do {
            try await storage.saveErrorEvent(errorEvent)
            onErrorDetected?(errorEvent)
        } catch {
            print("Failed to save error event: \(error)")
        }
    }
    
    public func reportCrash(_ crashReport: PerformanceCrashReport) async {
        crashReports.append(crashReport)
        
        do {
            try await storage.saveCrashReport(crashReport)
            onCrashDetected?(crashReport)
        } catch {
            print("Failed to save crash report: \(error)")
        }
    }
    
    public func getCrashStatistics() async throws -> PerformanceCrashStatistics {
        let allReports = try await storage.loadAllCrashReports()
        return PerformanceCrashStatistics(reports: allReports)
    }
    
    public func getErrorStatistics() async throws -> ErrorStatistics {
        let allErrors = try await storage.loadAllErrorEvents()
        return ErrorStatistics(errors: allErrors)
    }
    
    public func clearOldData() async throws {
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        try await storage.deleteCrashReportsOlderThan(thirtyDaysAgo)
        try await storage.deleteErrorEventsOlderThan(thirtyDaysAgo)
    }
    
    // MARK: - Private Methods
    
    private func setupCrashDetection() {
        // NSSetUncaughtExceptionHandler の設定
        NSSetUncaughtExceptionHandler { exception in
            // Global function to handle exception
            print("Uncaught exception: \(exception)")
        }
        
        // Signal handler の設定
        signal(SIGABRT) { signal in
            // Signal handling logic
            print("Signal \(signal) received")
        }
    }
    
    private func setupErrorHandling() {
        // Custom error handling setup
    }
    
    private func loadStoredReports() async {
        do {
            let storedCrashReports = try await storage.loadAllCrashReports()
            let storedErrorEvents = try await storage.loadAllErrorEvents()
            
            crashReports = storedCrashReports
            errorEvents = storedErrorEvents
        } catch {
            print("Failed to load stored reports: \(error)")
        }
    }
    
    private func handleUncaughtException(_ exception: NSException) async {
        let crashReport = PerformanceCrashReport(
            type: .exception,
            severity: .critical,
            stackTrace: exception.callStackSymbols,
            deviceInfo: deviceInfo,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            osVersion: ProcessInfo.processInfo.operatingSystemVersionString,
            metadata: [
                "exception_name": exception.name.rawValue,
                "exception_reason": exception.reason ?? "Unknown"
            ]
        )
        
        await reportCrash(crashReport)
    }
    
    private static func getCurrentPerformanceDeviceInfo() -> PerformanceDeviceInfo {
        let processInfo = ProcessInfo.processInfo
        
        return PerformanceDeviceInfo(
            model: processInfo.hostName,
            architecture: processInfo.processorCount.description,
            memorySize: Int64(processInfo.physicalMemory),
            diskSpace: 0 // 実際の実装では disk space を取得
        )
    }
}

// MARK: - Statistics

public struct PerformanceCrashStatistics {
    public let totalCrashes: Int
    public let crashesByType: [PerformanceCrashType: Int]
    public let crashesBySeverity: [PerformanceErrorSeverity: Int]
    public let averageCrashesPerDay: Double
    public let topCrashReasons: [String]
    
    init(reports: [PerformanceCrashReport]) {
        self.totalCrashes = reports.count
        
        var typeCount: [PerformanceCrashType: Int] = [:]
        var severityCount: [PerformanceErrorSeverity: Int] = [:]
        
        for report in reports {
            typeCount[report.type, default: 0] += 1
            severityCount[report.severity, default: 0] += 1
        }
        
        self.crashesByType = typeCount
        self.crashesBySeverity = severityCount
        
        // 30日間の平均を計算
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        let recentCrashes = reports.filter { $0.timestamp >= thirtyDaysAgo }
        self.averageCrashesPerDay = Double(recentCrashes.count) / 30.0
        
        // Top crash reasons (簡単な実装)
        self.topCrashReasons = Array(typeCount.keys.map { "\($0)" }.prefix(5))
    }
}

public struct ErrorStatistics {
    public let totalErrors: Int
    public let errorsBySeverity: [PerformanceErrorSeverity: Int]
    public let averageErrorsPerDay: Double
    public let topErrorMessages: [String]
    
    init(errors: [ErrorEvent]) {
        self.totalErrors = errors.count
        
        var severityCount: [PerformanceErrorSeverity: Int] = [:]
        var messageCount: [String: Int] = [:]
        
        for error in errors {
            severityCount[error.severity, default: 0] += 1
            messageCount[error.message, default: 0] += 1
        }
        
        self.errorsBySeverity = severityCount
        
        // 30日間の平均を計算
        let thirtyDaysAgo = Date().addingTimeInterval(-30 * 24 * 3600)
        let recentErrors = errors.filter { $0.timestamp >= thirtyDaysAgo }
        self.averageErrorsPerDay = Double(recentErrors.count) / 30.0
        
        // Top error messages
        let sortedMessages = messageCount.sorted { $0.value > $1.value }
        self.topErrorMessages = Array(sortedMessages.prefix(5).map { $0.key })
    }
}

// MARK: - MetricKit Integration

#if canImport(MetricKit) && !os(macOS)
@available(iOS 14.0, *)
extension CrashAnalyzer: MXMetricManagerSubscriber {
    
    public func didReceive(_ payloads: [MXDiagnosticPayload]) {
        Task { @MainActor in
            await processDiagnosticPayloads(payloads)
        }
    }
    
    private func processDiagnosticPayloads(_ payloads: [MXDiagnosticPayload]) async {
        for payload in payloads {
            await processCrashDiagnostics(payload.crashDiagnostics)
            await processHangDiagnostics(payload.hangDiagnostics)
            await processCPUExceptionDiagnostics(payload.cpuExceptionDiagnostics)
            await processDiskWriteExceptionDiagnostics(payload.diskWriteExceptionDiagnostics)
        }
    }
    
    private func processCrashDiagnostics(_ crashes: [MXCrashDiagnostic]?) async {
        guard let crashes = crashes else { return }
        
        for crash in crashes {
            let crashReport = PerformanceCrashReport(
                type: determineCrashType(from: crash),
                severity: .critical,
                stackTrace: extractStackTrace(from: crash),
                deviceInfo: deviceInfo,
                appVersion: crash.applicationVersion,
                osVersion: crash.osVersion,
                metadata: [
                    "signal": crash.signal?.rawValue ?? 0,
                    "exception_type": crash.exceptionType?.rawValue ?? 0,
                    "exception_code": crash.exceptionCode?.rawValue ?? 0
                ]
            )
            
            await reportCrash(crashReport)
        }
    }
    
    private func processHangDiagnostics(_ hangs: [MXHangDiagnostic]?) async {
        guard let hangs = hangs else { return }
        
        for hang in hangs {
            let errorEvent = ErrorEvent(
                severity: .high,
                message: "Application hang detected",
                stackTrace: extractStackTrace(from: hang),
                context: [
                    "hang_duration": hang.hangDuration.converted(to: .seconds).value
                ]
            )
            
            await reportError(NSError(domain: "HangDetection", code: 1, userInfo: [NSLocalizedDescriptionKey: errorEvent.message]), severity: .high, context: errorEvent.context)
        }
    }
    
    private func processCPUExceptionDiagnostics(_ cpuExceptions: [MXCPUExceptionDiagnostic]?) async {
        guard let cpuExceptions = cpuExceptions else { return }
        
        for exception in cpuExceptions {
            let errorEvent = ErrorEvent(
                severity: .medium,
                message: "CPU exception detected",
                stackTrace: extractStackTrace(from: exception),
                context: [
                    "cpu_time": exception.totalCPUTime.converted(to: .seconds).value
                ]
            )
            
            await reportError(NSError(domain: "CPUException", code: 1, userInfo: [NSLocalizedDescriptionKey: errorEvent.message]), severity: .medium, context: errorEvent.context)
        }
    }
    
    private func processDiskWriteExceptionDiagnostics(_ diskExceptions: [MXDiskWriteExceptionDiagnostic]?) async {
        guard let diskExceptions = diskExceptions else { return }
        
        for exception in diskExceptions {
            let errorEvent = ErrorEvent(
                severity: .medium,
                message: "Disk write exception detected",
                stackTrace: extractStackTrace(from: exception),
                context: [
                    "total_writes": exception.totalWritesCaused.converted(to: .bytes).value
                ]
            )
            
            await reportError(NSError(domain: "DiskWriteException", code: 1, userInfo: [NSLocalizedDescriptionKey: errorEvent.message]), severity: .medium, context: errorEvent.context)
        }
    }
    
    private func determineCrashType(from crash: MXCrashDiagnostic) -> PerformanceCrashType {
        if crash.signal != nil {
            return .signal
        } else if crash.exceptionType != nil {
            return .exception
        } else {
            return .unknown
        }
    }
    
    private func extractStackTrace(from diagnostic: Any) -> [String] {
        // MetricKit diagnostic から stack trace を抽出
        // 実際の実装では、各 diagnostic type に応じて適切に処理
        return Thread.callStackSymbols
    }
}
#endif