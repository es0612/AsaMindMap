import Foundation

// MARK: - Crash Type

public enum CrashType: String, CaseIterable, Codable {
    case exception = "exception"
    case signal = "signal"
    case memoryPressure = "memory_pressure"
    case watchdog = "watchdog"
    case backgroundTask = "background_task"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .exception:
            return "例外エラー"
        case .signal:
            return "シグナルエラー"
        case .memoryPressure:
            return "メモリ不足"
        case .watchdog:
            return "ウォッチドッグ"
        case .backgroundTask:
            return "バックグラウンドタスク"
        case .other:
            return "その他"
        }
    }
    
    public var defaultSeverity: CrashSeverity {
        switch self {
        case .exception:
            return .critical
        case .signal:
            return .critical
        case .memoryPressure:
            return .high
        case .watchdog:
            return .high
        case .backgroundTask:
            return .medium
        case .other:
            return .medium
        }
    }
}

// MARK: - Crash Severity

public enum CrashSeverity: String, CaseIterable, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    public var displayName: String {
        switch self {
        case .low:
            return "軽微"
        case .medium:
            return "中程度"
        case .high:
            return "重大"
        case .critical:
            return "致命的"
        }
    }
    
    public var priority: Int {
        switch self {
        case .low:
            return 1
        case .medium:
            return 2
        case .high:
            return 3
        case .critical:
            return 4
        }
    }
}

// MARK: - User Context

public struct UserContext: Codable {
    public let userId: UUID
    public let lastAction: String
    public let mindMapId: UUID?
    public let sessionDuration: TimeInterval
    public let memoryWarnings: Int
    public let batterLevel: Float?
    public let networkStatus: String?
    
    public init(
        userId: UUID,
        lastAction: String,
        mindMapId: UUID? = nil,
        sessionDuration: TimeInterval,
        memoryWarnings: Int,
        batterLevel: Float? = nil,
        networkStatus: String? = nil
    ) {
        self.userId = userId
        self.lastAction = lastAction
        self.mindMapId = mindMapId
        self.sessionDuration = sessionDuration
        self.memoryWarnings = memoryWarnings
        self.batterLevel = batterLevel
        self.networkStatus = networkStatus
    }
    
    public func anonymized() -> UserContext {
        UserContext(
            userId: UUID(), // Generate new anonymous ID
            lastAction: "user_action", // Generalize action
            mindMapId: mindMapId != nil ? UUID() : nil, // Anonymize but keep structure
            sessionDuration: sessionDuration,
            memoryWarnings: memoryWarnings,
            batterLevel: batterLevel,
            networkStatus: networkStatus
        )
    }
}

// MARK: - Crash Report

public struct CrashReport: Identifiable, Codable {
    public let id: UUID
    public let timestamp: Date
    public let crashType: CrashType
    public let errorMessage: String
    public let stackTrace: String
    public let deviceInfo: DeviceInfo
    public let userContext: UserContext?
    public private(set) var isReported: Bool
    
    public init(
        id: UUID = UUID(),
        timestamp: Date,
        crashType: CrashType,
        errorMessage: String,
        stackTrace: String,
        deviceInfo: DeviceInfo,
        userContext: UserContext? = nil,
        isReported: Bool = false
    ) {
        self.id = id
        self.timestamp = timestamp
        self.crashType = crashType
        self.errorMessage = errorMessage
        self.stackTrace = stackTrace
        self.deviceInfo = deviceInfo
        self.userContext = userContext
        self.isReported = isReported
    }
    
    // MARK: - Public Methods
    
    public var severity: CrashSeverity {
        crashType.defaultSeverity
    }
    
    public mutating func markAsReported() {
        isReported = true
    }
    
    public func anonymized() -> CrashReport {
        // Remove personal information from error messages and stack traces
        let cleanedErrorMessage = cleanPersonalInfo(from: errorMessage)
        let cleanedStackTrace = cleanPersonalInfo(from: stackTrace)
        let anonymizedUserContext = userContext?.anonymized()
        
        return CrashReport(
            id: id,
            timestamp: timestamp,
            crashType: crashType,
            errorMessage: cleanedErrorMessage,
            stackTrace: cleanedStackTrace,
            deviceInfo: deviceInfo,
            userContext: anonymizedUserContext,
            isReported: isReported
        )
    }
    
    public func toArchiveData() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            return try encoder.encode(self)
        } catch {
            return Data()
        }
    }
    
    public static func fromArchiveData(_ data: Data) -> CrashReport? {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            return try decoder.decode(CrashReport.self, from: data)
        } catch {
            return nil
        }
    }
    
    public var isRecent: Bool {
        let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return timestamp > dayAgo
    }
    
    public var shouldReport: Bool {
        !isReported && isRecent && severity.priority >= CrashSeverity.medium.priority
    }
    
    // MARK: - Private Methods
    
    private func cleanPersonalInfo(from text: String) -> String {
        var cleaned = text
        
        // Remove file paths that might contain user information
        let pathPattern = #"/Users/[^/\s]+(?:/[^/\s]*)*"#
        cleaned = cleaned.replacingOccurrences(
            of: pathPattern,
            with: "/Users/[REDACTED]",
            options: .regularExpression
        )
        
        // Remove document paths
        let documentsPattern = #"/var/mobile/Containers/[^/\s]+(?:/[^/\s]*)*"#
        cleaned = cleaned.replacingOccurrences(
            of: documentsPattern,
            with: "/var/mobile/Containers/[REDACTED]",
            options: .regularExpression
        )
        
        // Remove email patterns
        let emailPattern = #"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b"#
        cleaned = cleaned.replacingOccurrences(
            of: emailPattern,
            with: "[EMAIL_REDACTED]",
            options: .regularExpression
        )
        
        // Remove UUID patterns that might be user identifiers
        let uuidPattern = #"\b[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}\b"#
        cleaned = cleaned.replacingOccurrences(
            of: uuidPattern,
            with: "[UUID_REDACTED]",
            options: .regularExpression
        )
        
        return cleaned
    }
}

// MARK: - Crash Report Extensions

extension CrashReport: Equatable {
    public static func == (lhs: CrashReport, rhs: CrashReport) -> Bool {
        lhs.id == rhs.id
    }
}

extension CrashReport: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Crash Report Collection

public struct CrashReportCollection: Codable {
    public private(set) var reports: [CrashReport]
    
    public init(reports: [CrashReport] = []) {
        self.reports = reports
    }
    
    public mutating func addReport(_ report: CrashReport) {
        reports.append(report)
        // Keep only the most recent 100 reports
        if reports.count > 100 {
            reports = Array(reports.suffix(100))
        }
    }
    
    public var unreportedCount: Int {
        reports.filter { !$0.isReported }.count
    }
    
    public var criticalReports: [CrashReport] {
        reports.filter { $0.severity == .critical }
    }
    
    public var recentReports: [CrashReport] {
        reports.filter { $0.isRecent }
    }
    
    public func reportsByType() -> [CrashType: [CrashReport]] {
        Dictionary(grouping: reports) { $0.crashType }
    }
    
    public mutating func markAllAsReported() {
        for index in reports.indices {
            reports[index].markAsReported()
        }
    }
}