import Testing
@testable import MindMapCore

// MARK: - Mock Logger for Testing
class MockLogger: LoggerProtocol {
    var loggedMessages: [(level: LogLevel, message: String, category: String)] = []
    var loggedErrors: [(error: Error, category: String)] = []
    
    func log(level: LogLevel, message: String, category: String = "general") {
        loggedMessages.append((level: level, message: message, category: category))
    }
    
    func log(error: Error, category: String = "error") {
        loggedErrors.append((error: error, category: category))
    }
    
    func clear() {
        loggedMessages.removeAll()
        loggedErrors.removeAll()
    }
}

// MARK: - Logger Tests
struct LoggerTests {
    
    @Test("Loggerシングルトンが正常に取得できる")
    func testLoggerSingleton() {
        // Given & When
        let logger1 = Logger.shared
        let logger2 = Logger.shared
        
        // Then
        #expect(logger1 === logger2) // 同じインスタンス
    }
    
    @Test("各ログレベルでのログ出力が正常に動作する")
    func testLogLevels() {
        // Given
        let mockLogger = MockLogger()
        let testMessage = "テストメッセージ"
        let testCategory = "test"
        
        // When
        mockLogger.log(level: .debug, message: testMessage, category: testCategory)
        mockLogger.log(level: .info, message: testMessage, category: testCategory)
        mockLogger.log(level: .warning, message: testMessage, category: testCategory)
        mockLogger.log(level: .error, message: testMessage, category: testCategory)
        mockLogger.log(level: .critical, message: testMessage, category: testCategory)
        
        // Then
        #expect(mockLogger.loggedMessages.count == 5)
        #expect(mockLogger.loggedMessages[0].level == .debug)
        #expect(mockLogger.loggedMessages[1].level == .info)
        #expect(mockLogger.loggedMessages[2].level == .warning)
        #expect(mockLogger.loggedMessages[3].level == .error)
        #expect(mockLogger.loggedMessages[4].level == .critical)
        
        // すべてのメッセージが正しく記録されている
        for logEntry in mockLogger.loggedMessages {
            #expect(logEntry.message == testMessage)
            #expect(logEntry.category == testCategory)
        }
    }
    
    @Test("エラーログが正常に記録される")
    func testErrorLogging() {
        // Given
        let mockLogger = MockLogger()
        let testError = MindMapError.nodeCreationFailed
        let testCategory = "nodeError"
        
        // When
        mockLogger.log(error: testError, category: testCategory)
        
        // Then
        #expect(mockLogger.loggedErrors.count == 1)
        #expect(mockLogger.loggedErrors[0].category == testCategory)
        
        // エラーの型が正しい
        if let mindMapError = mockLogger.loggedErrors[0].error as? MindMapError {
            #expect(mindMapError == .nodeCreationFailed)
        } else {
            #expect(Bool(false), "エラーの型が正しくありません")
        }
    }
    
    @Test("便利メソッドが正常に動作する")
    func testConvenienceMethods() {
        // Given
        let mockLogger = MockLogger()
        
        // When
        mockLogger.log(level: .debug, message: "デバッグ")
        mockLogger.log(level: .info, message: "情報")
        mockLogger.log(level: .warning, message: "警告")
        mockLogger.log(level: .error, message: "エラー")
        mockLogger.log(level: .critical, message: "クリティカル")
        
        // Then
        #expect(mockLogger.loggedMessages.count == 5)
        
        let levels = mockLogger.loggedMessages.map { $0.level }
        #expect(levels == [.debug, .info, .warning, .error, .critical])
    }
    
    @Test("LogLevelの全ケースが定義されている")
    func testLogLevelCases() {
        // Given & When
        let allCases = LogLevel.allCases
        
        // Then
        #expect(allCases.count == 5)
        #expect(allCases.contains(.debug))
        #expect(allCases.contains(.info))
        #expect(allCases.contains(.warning))
        #expect(allCases.contains(.error))
        #expect(allCases.contains(.critical))
    }
}