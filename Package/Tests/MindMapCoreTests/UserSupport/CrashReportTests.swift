import Testing
import Foundation
@testable import MindMapCore

struct CrashReportTests {
    
    @Test("クラッシュレポート作成テスト")
    func testCrashReportCreation() {
        // Given
        let id = UUID()
        let timestamp = Date()
        let crashType = CrashType.exception
        let errorMessage = "NSInvalidArgumentException"
        let stackTrace = """
        0   AsaMindMap   0x0000000100001234 -[ViewController viewDidLoad] + 123
        1   UIKitCore    0x00000001a0002345 -[UIViewController loadViewIfRequired] + 456
        """
        let deviceInfo = DeviceInfo(
            model: "iPhone 14 Pro",
            osVersion: "iOS 17.0",
            appVersion: "1.0.0"
        )
        
        // When
        let crashReport = CrashReport(
            id: id,
            timestamp: timestamp,
            crashType: crashType,
            errorMessage: errorMessage,
            stackTrace: stackTrace,
            deviceInfo: deviceInfo,
            userContext: nil,
            isReported: false
        )
        
        // Then
        #expect(crashReport.id == id)
        #expect(crashReport.timestamp == timestamp)
        #expect(crashReport.crashType == crashType)
        #expect(crashReport.errorMessage == errorMessage)
        #expect(crashReport.stackTrace == stackTrace)
        #expect(crashReport.deviceInfo.model == "iPhone 14 Pro")
        #expect(crashReport.userContext == nil)
        #expect(crashReport.isReported == false)
    }
    
    @Test("クラッシュレポートユーザーコンテキスト追加テスト")
    func testCrashReportWithUserContext() {
        // Given
        let userContext = UserContext(
            userId: UUID(),
            lastAction: "creating_node",
            mindMapId: UUID(),
            sessionDuration: 300, // 5 minutes
            memoryWarnings: 2
        )
        
        // When
        let crashReport = CrashReport(
            id: UUID(),
            timestamp: Date(),
            crashType: .memoryPressure,
            errorMessage: "Memory pressure termination",
            stackTrace: "Memory trace...",
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            userContext: userContext,
            isReported: false
        )
        
        // Then
        #expect(crashReport.userContext != nil)
        #expect(crashReport.userContext?.lastAction == "creating_node")
        #expect(crashReport.userContext?.sessionDuration == 300)
        #expect(crashReport.userContext?.memoryWarnings == 2)
    }
    
    @Test("クラッシュレポート重要度判定テスト")
    func testCrashReportSeverityAssessment() {
        // Given - High severity crash
        let criticalCrash = CrashReport(
            id: UUID(),
            timestamp: Date(),
            crashType: .exception,
            errorMessage: "SIGABRT",
            stackTrace: "Critical error trace...",
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            userContext: nil,
            isReported: false
        )
        
        // Then
        #expect(criticalCrash.severity == .critical)
        
        // Given - Medium severity crash
        let memoryPressureCrash = CrashReport(
            id: UUID(),
            timestamp: Date(),
            crashType: .memoryPressure,
            errorMessage: "Memory warning",
            stackTrace: "Memory trace...",
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            userContext: nil,
            isReported: false
        )
        
        // Then
        #expect(memoryPressureCrash.severity == .high)
    }
    
    @Test("クラッシュレポート匿名化テスト")
    func testCrashReportAnonymization() {
        // Given
        let personalUserContext = UserContext(
            userId: UUID(),
            lastAction: "personal_data_action",
            mindMapId: UUID(),
            sessionDuration: 120,
            memoryWarnings: 0
        )
        
        let crashReport = CrashReport(
            id: UUID(),
            timestamp: Date(),
            crashType: .exception,
            errorMessage: "Personal error with /Users/john/Documents/personal.txt",
            stackTrace: "Stack trace with personal path /Users/john/Documents/",
            deviceInfo: DeviceInfo(model: "iPhone 14", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            userContext: personalUserContext,
            isReported: false
        )
        
        // When
        let anonymizedReport = crashReport.anonymized()
        
        // Then
        #expect(anonymizedReport.errorMessage.contains("/Users/john/Documents/") == false)
        #expect(anonymizedReport.stackTrace.contains("/Users/john/Documents/") == false)
        #expect(anonymizedReport.userContext?.userId != personalUserContext.userId) // Should be anonymized
        #expect(anonymizedReport.userContext?.lastAction == "user_action") // Genericized
    }
    
    @Test("クラッシュレポートアーカイブ機能テスト")
    func testCrashReportArchiving() {
        // Given
        let crashReport = CrashReport(
            id: UUID(),
            timestamp: Date(),
            crashType: .exception,
            errorMessage: "Test error",
            stackTrace: "Test trace",
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            userContext: nil,
            isReported: false
        )
        
        // When
        let archivedData = crashReport.toArchiveData()
        let restoredReport = CrashReport.fromArchiveData(archivedData)
        
        // Then
        #expect(restoredReport?.id == crashReport.id)
        #expect(restoredReport?.errorMessage == crashReport.errorMessage)
        #expect(restoredReport?.crashType == crashReport.crashType)
    }
}