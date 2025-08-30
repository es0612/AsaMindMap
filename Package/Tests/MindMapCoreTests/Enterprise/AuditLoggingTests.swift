import Testing
@testable import MindMapCore

@Suite("Audit Logging Tests")
struct AuditLoggingTests {
    
    @Test("監査ログの記録テスト")
    func testAuditLogRecording() async throws {
        // Given
        let auditLogger = AuditLogger()
        let userID = "user@company.com"
        let action = AuditAction.mindMapCreated
        let resourceID = UUID()
        let metadata = ["name": "Test MindMap", "size": "10 nodes"]
        
        // When
        try await auditLogger.log(
            userID: userID,
            action: action,
            resourceID: resourceID,
            metadata: metadata
        )
        
        // Then
        let logs = try await auditLogger.getLogs(for: userID)
        #expect(logs.count == 1)
        #expect(logs.first?.userID == userID)
        #expect(logs.first?.action == action)
        #expect(logs.first?.resourceID == resourceID)
        #expect(logs.first?.metadata["name"] as? String == "Test MindMap")
        #expect(logs.first?.timestamp != nil)
    }
    
    @Test("セキュリティイベントのログテスト")
    func testSecurityEventLogging() async throws {
        // Given
        let securityLogger = SecurityEventLogger()
        let userID = "user@company.com"
        let ipAddress = "192.168.1.100"
        let userAgent = "AsaMindMap/1.0 iOS/17.0"
        
        // When
        try await securityLogger.logLoginAttempt(
            userID: userID,
            success: false,
            ipAddress: ipAddress,
            userAgent: userAgent
        )
        
        // Then
        let securityLogs = try await securityLogger.getSecurityLogs()
        #expect(securityLogs.count == 1)
        #expect(securityLogs.first?.eventType == .loginAttempt)
        #expect(securityLogs.first?.userID == userID)
        #expect(securityLogs.first?.success == false)
        #expect(securityLogs.first?.ipAddress == ipAddress)
    }
    
    @Test("コンプライアンスレポートの生成テスト")
    func testComplianceReportGeneration() async throws {
        // Given
        let complianceReporter = ComplianceReporter()
        let startDate = Date().addingTimeInterval(-86400 * 7) // 1週間前
        let endDate = Date()
        
        // When
        let report = try await complianceReporter.generateReport(
            startDate: startDate,
            endDate: endDate,
            type: .gdprCompliance
        )
        
        // Then
        #expect(report.reportType == .gdprCompliance)
        #expect(report.startDate == startDate)
        #expect(report.endDate == endDate)
        #expect(report.entries != nil)
        #expect(report.summary != nil)
    }
    
    @Test("データアクセスログの記録テスト")
    func testDataAccessLogging() async throws {
        // Given
        let dataAccessLogger = DataAccessLogger()
        let userID = "user@company.com"
        let operation = DataOperation.read
        let dataType = "mindmap"
        let resourceID = UUID()
        
        // When
        try await dataAccessLogger.logAccess(
            userID: userID,
            operation: operation,
            dataType: dataType,
            resourceID: resourceID
        )
        
        // Then
        let accessLogs = try await dataAccessLogger.getAccessLogs(
            for: userID,
            resourceID: resourceID
        )
        #expect(accessLogs.count == 1)
        #expect(accessLogs.first?.operation == operation)
        #expect(accessLogs.first?.dataType == dataType)
    }
    
    @Test("ログの保持期間管理テスト")
    func testLogRetentionManagement() async throws {
        // Given
        let retentionManager = LogRetentionManager()
        let policy = RetentionPolicy(
            type: .audit,
            retentionDays: 365,
            archiveAfterDays: 90
        )
        
        // When
        try await retentionManager.applyPolicy(policy)
        
        // Then
        let appliedPolicy = try await retentionManager.getPolicy(for: .audit)
        #expect(appliedPolicy?.retentionDays == 365)
        #expect(appliedPolicy?.archiveAfterDays == 90)
    }
    
    @Test("ログの検索とフィルタリングテスト")
    func testLogSearchAndFiltering() async throws {
        // Given
        let auditLogger = AuditLogger()
        let searchService = AuditLogSearchService()
        
        // 複数のログを作成
        try await auditLogger.log(
            userID: "user1@company.com",
            action: .mindMapCreated,
            resourceID: UUID()
        )
        try await auditLogger.log(
            userID: "user2@company.com",
            action: .mindMapDeleted,
            resourceID: UUID()
        )
        
        // When
        let searchCriteria = LogSearchCriteria(
            userID: "user1@company.com",
            actions: [.mindMapCreated],
            startDate: Date().addingTimeInterval(-3600),
            endDate: Date()
        )
        let results = try await searchService.search(criteria: searchCriteria)
        
        // Then
        #expect(results.count == 1)
        #expect(results.first?.userID == "user1@company.com")
        #expect(results.first?.action == .mindMapCreated)
    }
    
    @Test("ログの暗号化テスト")
    func testLogEncryption() async throws {
        // Given
        let encryptedLogger = EncryptedAuditLogger()
        let sensitiveData = "sensitive user data"
        
        // When
        try await encryptedLogger.logSensitiveData(
            userID: "user@company.com",
            data: sensitiveData
        )
        
        // Then
        let rawLogs = try await encryptedLogger.getRawLogs()
        #expect(!rawLogs.first?.encryptedData.contains(sensitiveData) ?? false)
        
        let decryptedLogs = try await encryptedLogger.getDecryptedLogs()
        #expect(decryptedLogs.first?.originalData == sensitiveData)
    }
    
    @Test("異常行動検知テスト")
    func testAnomalousActivityDetection() async throws {
        // Given
        let activityMonitor = AnomalousActivityMonitor()
        let userID = "user@company.com"
        
        // 大量のアクションを短時間で実行
        for _ in 0..<100 {
            try await activityMonitor.recordActivity(
                userID: userID,
                action: .mindMapAccessed,
                timestamp: Date()
            )
        }
        
        // When
        let anomalies = try await activityMonitor.detectAnomalies(
            for: userID,
            timeWindow: 300 // 5分
        )
        
        // Then
        #expect(!anomalies.isEmpty)
        #expect(anomalies.first?.type == .unusualFrequency)
        #expect(anomalies.first?.severity == .high)
    }
    
    @Test("コンプライアンス違反の検知テスト")
    func testComplianceViolationDetection() async throws {
        // Given
        let complianceMonitor = ComplianceMonitor()
        let violation = ComplianceViolation(
            type: .unauthorizedDataAccess,
            userID: "user@company.com",
            resourceID: UUID(),
            timestamp: Date()
        )
        
        // When
        try await complianceMonitor.reportViolation(violation)
        
        // Then
        let violations = try await complianceMonitor.getViolations()
        #expect(violations.count == 1)
        #expect(violations.first?.type == .unauthorizedDataAccess)
        #expect(violations.first?.severity != nil)
        #expect(violations.first?.resolved == false)
    }
    
    @Test("ログのエクスポート機能テスト")
    func testLogExport() async throws {
        // Given
        let logExporter = AuditLogExporter()
        let exportRequest = LogExportRequest(
            format: .csv,
            startDate: Date().addingTimeInterval(-86400),
            endDate: Date(),
            includeMetadata: true
        )
        
        // When
        let exportData = try await logExporter.export(request: exportRequest)
        
        // Then
        #expect(exportData.format == .csv)
        #expect(exportData.data != nil)
        #expect(exportData.filename.hasSuffix(".csv"))
        #expect(exportData.size > 0)
    }
}