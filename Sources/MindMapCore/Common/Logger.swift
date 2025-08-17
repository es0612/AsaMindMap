import Foundation
import os.log

// MARK: - Logger Protocol
public protocol LoggerProtocol {
    func log(level: LogLevel, message: String, category: String)
    func log(error: Error, category: String)
}

// MARK: - Log Level
public enum LogLevel: String, CaseIterable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

// MARK: - Logger Implementation
public final class Logger: LoggerProtocol {
    public static let shared = Logger()
    
    private let osLog: OSLog
    
    private init() {
        self.osLog = OSLog(subsystem: "com.asamindmap.app", category: "general")
    }
    
    public func log(level: LogLevel, message: String, category: String = "general") {
        let logMessage = "[\(level.rawValue)] [\(category)] \(message)"
        
        switch level {
        case .debug:
            os_log("%{public}@", log: osLog, type: .debug, logMessage)
        case .info:
            os_log("%{public}@", log: osLog, type: .info, logMessage)
        case .warning:
            os_log("%{public}@", log: osLog, type: .default, logMessage)
        case .error:
            os_log("%{public}@", log: osLog, type: .error, logMessage)
        case .critical:
            os_log("%{public}@", log: osLog, type: .fault, logMessage)
        }
    }
    
    public func log(error: Error, category: String = "error") {
        let errorMessage = "Error: \(error.localizedDescription)"
        log(level: .error, message: errorMessage, category: category)
    }
}

// MARK: - Logger Extensions
extension Logger {
    public func debug(_ message: String, category: String = "general") {
        log(level: .debug, message: message, category: category)
    }
    
    public func info(_ message: String, category: String = "general") {
        log(level: .info, message: message, category: category)
    }
    
    public func warning(_ message: String, category: String = "general") {
        log(level: .warning, message: message, category: category)
    }
    
    public func error(_ message: String, category: String = "general") {
        log(level: .error, message: message, category: category)
    }
    
    public func critical(_ message: String, category: String = "general") {
        log(level: .critical, message: message, category: category)
    }
}