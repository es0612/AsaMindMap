import XCTest
@testable import MindMapCore

class PrivacyComplianceTests: XCTestCase {
    
    // MARK: - GDPR Compliance Tests
    
    func testGDPRShouldProcessDataDeletionRequest() async throws {
        // Given
        let gdprManager = GDPRComplianceManager()
        let userId = "test-user-123"
        let request = DataDeletionRequest(
            userId: userId,
            requestId: UUID(),
            requestedAt: Date(),
            includeBackups: true
        )
        
        // When
        let result = try await gdprManager.processDataDeletion(request)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertTrue(result.deletedItems.contains(.mindMaps))
        XCTAssertTrue(result.deletedItems.contains(.userProfile))
        XCTAssertNotNil(result.completedAt)
    }
    
    func testGDPRShouldExportUserDataInRequestedFormat() async throws {
        // Given
        let gdprManager = GDPRComplianceManager()
        let userId = "test-user-456"
        let request = DataPortabilityRequest(
            userId: userId,
            requestId: UUID(),
            format: .json,
            includeMetadata: true
        )
        
        // When
        let result = try await gdprManager.exportUserData(request)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.dataPackage)
        XCTAssertNotNil(result.downloadUrl)
    }
    
    func testGDPRShouldProvideDataProcessingAuditLog() async throws {
        // Given
        let auditManager = DataProcessingAuditManager()
        let userId = "audit-user-789"
        
        // When
        try await auditManager.logDataProcessing(
            userId: userId,
            activity: .dataCollection,
            purpose: "マインドマップ作成",
            legalBasis: .consent,
            dataCategories: [.personalIdentifiers, .contentData]
        )
        
        let auditLog = try await auditManager.getAuditLog(for: userId)
        
        // Then
        XCTAssertFalse(auditLog.isEmpty)
        XCTAssertEqual(auditLog.first?.userId, userId)
        XCTAssertEqual(auditLog.first?.activity, .dataCollection)
    }
    
    // MARK: - CCPA Compliance Tests
    
    func testCCPAShouldProcessDoNotSellRequest() async throws {
        // Given
        let ccpaManager = CCPAComplianceManager()
        let userId = "ccpa-user-123"
        let request = DoNotSellRequest(
            userId: userId,
            requestedAt: Date(),
            ipAddress: "192.168.1.1",
            userAgent: "Mozilla/5.0"
        )
        
        // When
        let result = try await ccpaManager.processDoNotSellRequest(request)
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.effectiveDate)
        XCTAssertEqual(result.requestId, request.requestId)
    }
    
    func testCCPAShouldProvidePersonalInformationInventory() async throws {
        // Given
        let ccpaManager = CCPAComplianceManager()
        let userId = "ccpa-user-456"
        
        // When
        let inventory = try await ccpaManager.getPersonalInformationInventory(for: userId)
        
        // Then
        XCTAssertFalse(inventory.categories.isEmpty)
        XCTAssertTrue(inventory.categories.contains(.identifiers))
        XCTAssertTrue(inventory.categories.contains(.personalInformation))
    }
    
    // MARK: - Privacy Manifest Tests
    
    func testPrivacyManifestShouldListDataCollectionPractices() async throws {
        // Given
        let privacyManager = PrivacyManifestManager()
        
        // When
        let manifest = try await privacyManager.generatePrivacyManifest()
        
        // Then
        XCTAssertFalse(manifest.dataTypes.isEmpty)
        XCTAssertTrue(manifest.dataTypes.contains { $0.type == .identifiers })
        XCTAssertTrue(manifest.dataTypes.contains { $0.type == .location })
        XCTAssertFalse(manifest.trackingDomains.isEmpty)
    }
    
    func testPrivacyManifestShouldDescribeDataUsagePurposes() async throws {
        // Given
        let privacyManager = PrivacyManifestManager()
        
        // When
        let manifest = try await privacyManager.generatePrivacyManifest()
        let identifierData = manifest.dataTypes.first { $0.type == .identifiers }
        
        // Then
        XCTAssertNotNil(identifierData)
        XCTAssertFalse(identifierData!.purposes.isEmpty)
        XCTAssertTrue(identifierData!.purposes.contains(.appFunctionality))
    }
    
    // MARK: - Consent Management Tests
    
    func testConsentManagerShouldRecordUserConsent() async throws {
        // Given
        let consentManager = ConsentManager()
        let userId = "consent-user-123"
        let consent = ConsentRecord(
            userId: userId,
            consentType: .dataProcessing,
            granted: true,
            timestamp: Date(),
            version: "1.0",
            ipAddress: "192.168.1.1"
        )
        
        // When
        try await consentManager.recordConsent(consent)
        let retrievedConsent = try await consentManager.getConsent(userId: userId, type: .dataProcessing)
        
        // Then
        XCTAssertNotNil(retrievedConsent)
        XCTAssertTrue(retrievedConsent!.granted)
        XCTAssertEqual(retrievedConsent!.version, "1.0")
    }
    
    func testConsentManagerShouldWithdrawConsent() async throws {
        // Given
        let consentManager = ConsentManager()
        let userId = "withdraw-user-123"
        let consent = ConsentRecord(
            userId: userId,
            consentType: .marketing,
            granted: true,
            timestamp: Date(),
            version: "1.0",
            ipAddress: "192.168.1.1"
        )
        
        // When
        try await consentManager.recordConsent(consent)
        try await consentManager.withdrawConsent(userId: userId, type: .marketing)
        let currentConsent = try await consentManager.getConsent(userId: userId, type: .marketing)
        
        // Then
        XCTAssertNotNil(currentConsent)
        XCTAssertFalse(currentConsent!.granted)
    }
    
    // MARK: - Data Retention Tests
    
    func testDataRetentionShouldAutoDeleteExpiredData() async throws {
        // Given
        let retentionManager = DataRetentionManager()
        let pastDate = Calendar.current.date(byAdding: .year, value: -2, to: Date())!
        let oldData = RetainableData(
            id: "old-data-123",
            userId: "retention-user",
            dataType: .temporaryFiles,
            createdAt: pastDate,
            retentionPeriod: .oneYear
        )
        
        // When
        try await retentionManager.storeData(oldData)
        try await retentionManager.cleanupExpiredData()
        let retrievedData = try await retentionManager.getData(id: "old-data-123")
        
        // Then
        XCTAssertNil(retrievedData) // データは削除されているべき
    }
    
    func testDataRetentionShouldKeepActiveData() async throws {
        // Given
        let retentionManager = DataRetentionManager()
        let recentData = RetainableData(
            id: "recent-data-456",
            userId: "retention-user",
            dataType: .userPreferences,
            createdAt: Date(),
            retentionPeriod: .twoYears
        )
        
        // When
        try await retentionManager.storeData(recentData)
        try await retentionManager.cleanupExpiredData()
        let retrievedData = try await retentionManager.getData(id: "recent-data-456")
        
        // Then
        XCTAssertNotNil(retrievedData) // データは保持されているべき
    }
    
    // MARK: - Cookie and Tracking Tests
    
    func testCookieManagerShouldRespectUserPreferences() async throws {
        // Given
        let cookieManager = CookieConsentManager()
        let userId = "cookie-user-123"
        
        // When
        try await cookieManager.setConsentPreferences(
            userId: userId,
            preferences: CookieConsentPreferences(
                essential: true,
                analytics: false,
                marketing: false,
                personalization: true
            )
        )
        
        let canUseAnalytics = try await cookieManager.canUseCookieCategory(.analytics, for: userId)
        let canUsePersonalization = try await cookieManager.canUseCookieCategory(.personalization, for: userId)
        
        // Then
        XCTAssertFalse(canUseAnalytics)
        XCTAssertTrue(canUsePersonalization)
    }
}

// MARK: - Test Models and Enums

struct DataDeletionRequest {
    let userId: String
    let requestId: UUID
    let requestedAt: Date
    let includeBackups: Bool
    
    init(userId: String, requestId: UUID, requestedAt: Date, includeBackups: Bool) {
        self.userId = userId
        self.requestId = requestId
        self.requestedAt = requestedAt
        self.includeBackups = includeBackups
    }
}

struct DataDeletionResult {
    let success: Bool
    let deletedItems: Set<DataCategory>
    let completedAt: Date?
    let requestId: UUID
}

enum DataCategory {
    case mindMaps
    case userProfile
    case apiLogs
    case backups
}

struct DataPortabilityRequest {
    let userId: String
    let requestId: UUID
    let format: ExportFormat
    let includeMetadata: Bool
}

enum ExportFormat {
    case json, xml, csv
}

struct DataPortabilityResult {
    let success: Bool
    let dataPackage: UserDataPackage?
    let downloadUrl: URL
}

struct UserDataPackage {
    let mindMaps: [String] // 簡略化
    let userProfile: [String: Any]
    let exportedAt: Date
}

enum DataProcessingActivity {
    case dataCollection
    case dataStorage
    case dataSharing
    case dataAnalysis
}

enum LegalBasis {
    case consent
    case contract
    case legalObligation
    case vitalInterests
    case publicTask
    case legitimateInterests
}

enum DataCategoryType {
    case personalIdentifiers
    case contentData
    case usageData
    case technicalData
}

struct DoNotSellRequest {
    let userId: String
    let requestId: UUID
    let requestedAt: Date
    let ipAddress: String
    let userAgent: String
    
    init(userId: String, requestedAt: Date, ipAddress: String, userAgent: String) {
        self.userId = userId
        self.requestId = UUID()
        self.requestedAt = requestedAt
        self.ipAddress = ipAddress
        self.userAgent = userAgent
    }
}

struct DoNotSellResult {
    let success: Bool
    let requestId: UUID
    let effectiveDate: Date?
}

struct PersonalInformationInventory {
    let userId: String
    let categories: Set<PersonalInformationCategory>
    let generatedAt: Date
}

enum PersonalInformationCategory {
    case identifiers
    case personalInformation
    case commercialInformation
    case internetActivity
    case geolocationData
}

struct PrivacyManifest {
    let version: String
    let dataTypes: [PrivacyDataType]
    let trackingDomains: [String]
    let generatedAt: Date
}

struct PrivacyDataType {
    let type: PrivacyDataCategory
    let purposes: [DataUsagePurpose]
    let linked: Bool
    let tracking: Bool
}

enum PrivacyDataCategory {
    case identifiers
    case location
    case contacts
    case usage
}

enum DataUsagePurpose {
    case appFunctionality
    case analytics
    case advertising
    case personalization
}

struct ConsentRecord {
    let userId: String
    let consentType: ConsentType
    let granted: Bool
    let timestamp: Date
    let version: String
    let ipAddress: String
}

enum ConsentType {
    case dataProcessing
    case marketing
    case analytics
    case cookies
}

struct RetainableData {
    let id: String
    let userId: String
    let dataType: RetentionDataType
    let createdAt: Date
    let retentionPeriod: RetentionPeriod
}

enum RetentionDataType {
    case userPreferences
    case temporaryFiles
    case auditLogs
    case analyticsData
}

enum RetentionPeriod {
    case thirtyDays
    case oneYear
    case twoYears
    case sevenYears
}

struct CookieConsentPreferences {
    let essential: Bool
    let analytics: Bool
    let marketing: Bool
    let personalization: Bool
}

enum CookieCategory {
    case essential
    case analytics
    case marketing
    case personalization
}