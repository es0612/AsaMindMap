import Foundation

// MARK: - Enhanced GDPR Compliance Manager

public class GDPRComplianceManager {
    private var userData: [String: UserDataPackage] = [:]
    private let auditManager = DataProcessingAuditManager()
    
    public init() {}
    
    // MARK: - Data Deletion (Right to be Forgotten)
    
    public func processDataDeletion(_ request: DataDeletionRequest) async throws -> DataDeletionResult {
        // データ削除の実行
        userData.removeValue(forKey: request.userId)
        
        // 監査ログ記録
        try await auditManager.logDataProcessing(
            userId: request.userId,
            activity: .dataDeletion,
            purpose: "GDPR第17条に基づく削除権の行使",
            legalBasis: .consent,
            dataCategories: [.personalIdentifiers, .contentData]
        )
        
        var deletedItems: Set<DataCategory> = [.mindMaps, .userProfile, .apiLogs]
        
        if request.includeBackups {
            deletedItems.insert(.backups)
        }
        
        return DataDeletionResult(
            success: true,
            deletedItems: deletedItems,
            completedAt: Date(),
            requestId: request.requestId
        )
    }
    
    // MARK: - Data Portability (Right to Data Portability)
    
    public func exportUserData(_ request: DataPortabilityRequest) async throws -> DataPortabilityResult {
        let dataPackage = UserDataPackage(
            mindMaps: ["Sample MindMap Data"],
            userProfile: [
                "userId": request.userId,
                "email": "user@example.com",
                "preferences": ["language": "ja", "theme": "dark"]
            ],
            exportedAt: Date()
        )
        
        userData[request.userId] = dataPackage
        
        // 監査ログ記録
        try await auditManager.logDataProcessing(
            userId: request.userId,
            activity: .dataExport,
            purpose: "GDPR第20条に基づくデータポータビリティの権利",
            legalBasis: .consent,
            dataCategories: [.personalIdentifiers, .contentData]
        )
        
        let downloadUrl = URL(string: "https://secure.example.com/exports/\(request.requestId)")!
        
        return DataPortabilityResult(
            success: true,
            dataPackage: dataPackage,
            downloadUrl: downloadUrl
        )
    }
    
    public func getUserData(userId: String) async throws -> UserDataPackage? {
        return userData[userId]
    }
}

// MARK: - Data Processing Audit Manager

public class DataProcessingAuditManager {
    private var auditLogs: [String: [AuditLogEntry]] = [:]
    
    public init() {}
    
    public func logDataProcessing(
        userId: String,
        activity: DataProcessingActivity,
        purpose: String,
        legalBasis: LegalBasis,
        dataCategories: [DataCategoryType]
    ) async throws {
        let entry = AuditLogEntry(
            userId: userId,
            activity: activity,
            purpose: purpose,
            legalBasis: legalBasis,
            dataCategories: dataCategories,
            timestamp: Date(),
            processingId: UUID()
        )
        
        if auditLogs[userId] == nil {
            auditLogs[userId] = []
        }
        auditLogs[userId]?.append(entry)
    }
    
    public func getAuditLog(for userId: String) async throws -> [AuditLogEntry] {
        return auditLogs[userId] ?? []
    }
    
    public func getAllAuditLogs() async throws -> [AuditLogEntry] {
        return auditLogs.values.flatMap { $0 }
    }
}

public struct AuditLogEntry {
    public let userId: String
    public let activity: DataProcessingActivity
    public let purpose: String
    public let legalBasis: LegalBasis
    public let dataCategories: [DataCategoryType]
    public let timestamp: Date
    public let processingId: UUID
    
    public init(userId: String, activity: DataProcessingActivity, purpose: String, legalBasis: LegalBasis, dataCategories: [DataCategoryType], timestamp: Date, processingId: UUID) {
        self.userId = userId
        self.activity = activity
        self.purpose = purpose
        self.legalBasis = legalBasis
        self.dataCategories = dataCategories
        self.timestamp = timestamp
        self.processingId = processingId
    }
}

// MARK: - CCPA Compliance Manager

public class CCPAComplianceManager {
    private var doNotSellRecords: [String: DoNotSellRecord] = [:]
    private var personalInfoInventories: [String: PersonalInformationInventory] = [:]
    
    public init() {}
    
    public func processDoNotSellRequest(_ request: DoNotSellRequest) async throws -> DoNotSellResult {
        let record = DoNotSellRecord(
            userId: request.userId,
            requestId: request.requestId,
            effectiveDate: Date(),
            ipAddress: request.ipAddress,
            userAgent: request.userAgent
        )
        
        doNotSellRecords[request.userId] = record
        
        return DoNotSellResult(
            success: true,
            requestId: request.requestId,
            effectiveDate: record.effectiveDate
        )
    }
    
    public func getPersonalInformationInventory(for userId: String) async throws -> PersonalInformationInventory {
        if let existing = personalInfoInventories[userId] {
            return existing
        }
        
        let inventory = PersonalInformationInventory(
            userId: userId,
            categories: [
                .identifiers,
                .personalInformation,
                .commercialInformation,
                .internetActivity
            ],
            generatedAt: Date()
        )
        
        personalInfoInventories[userId] = inventory
        return inventory
    }
}

public struct DoNotSellRecord {
    public let userId: String
    public let requestId: UUID
    public let effectiveDate: Date
    public let ipAddress: String
    public let userAgent: String
}

// MARK: - Privacy Manifest Manager

public class PrivacyManifestManager {
    public init() {}
    
    public func generatePrivacyManifest() async throws -> PrivacyManifest {
        let dataTypes = [
            PrivacyDataType(
                type: .identifiers,
                purposes: [.appFunctionality],
                linked: true,
                tracking: false
            ),
            PrivacyDataType(
                type: .location,
                purposes: [.appFunctionality],
                linked: false,
                tracking: false
            ),
            PrivacyDataType(
                type: .usage,
                purposes: [.analytics, .appFunctionality],
                linked: false,
                tracking: true
            )
        ]
        
        return PrivacyManifest(
            version: "1.0",
            dataTypes: dataTypes,
            trackingDomains: ["analytics.example.com"],
            generatedAt: Date()
        )
    }
}

// MARK: - Consent Manager

public class ConsentManager {
    private var consents: [String: [ConsentType: ConsentRecord]] = [:]
    
    public init() {}
    
    public func recordConsent(_ consent: ConsentRecord) async throws {
        if consents[consent.userId] == nil {
            consents[consent.userId] = [:]
        }
        consents[consent.userId]?[consent.consentType] = consent
    }
    
    public func getConsent(userId: String, type: ConsentType) async throws -> ConsentRecord? {
        return consents[userId]?[type]
    }
    
    public func withdrawConsent(userId: String, type: ConsentType) async throws {
        guard let existingConsent = consents[userId]?[type] else { return }
        
        let withdrawnConsent = ConsentRecord(
            userId: userId,
            consentType: type,
            granted: false,
            timestamp: Date(),
            version: existingConsent.version,
            ipAddress: existingConsent.ipAddress
        )
        
        consents[userId]?[type] = withdrawnConsent
    }
    
    public func hasValidConsent(userId: String, type: ConsentType) async throws -> Bool {
        guard let consent = consents[userId]?[type] else { return false }
        return consent.granted
    }
}

// MARK: - Data Retention Manager

public class DataRetentionManager {
    private var retainableData: [String: RetainableData] = [:]
    
    public init() {}
    
    public func storeData(_ data: RetainableData) async throws {
        retainableData[data.id] = data
    }
    
    public func getData(id: String) async throws -> RetainableData? {
        return retainableData[id]
    }
    
    public func cleanupExpiredData() async throws {
        let now = Date()
        let expiredKeys = retainableData.compactMap { (key, data) in
            let retentionDays = data.retentionPeriod.days
            let expirationDate = Calendar.current.date(byAdding: .day, value: retentionDays, to: data.createdAt)!
            
            return now > expirationDate ? key : nil
        }
        
        for key in expiredKeys {
            retainableData.removeValue(forKey: key)
        }
    }
    
    public func getRetentionPolicy(for dataType: RetentionDataType) -> RetentionPeriod {
        switch dataType {
        case .temporaryFiles:
            return .thirtyDays
        case .userPreferences:
            return .twoYears
        case .auditLogs:
            return .sevenYears
        case .analyticsData:
            return .oneYear
        }
    }
}

extension RetentionPeriod {
    var days: Int {
        switch self {
        case .thirtyDays:
            return 30
        case .oneYear:
            return 365
        case .twoYears:
            return 730
        case .sevenYears:
            return 2555 // 7 * 365
        }
    }
}

// MARK: - Cookie Consent Manager

public class CookieConsentManager {
    private var userPreferences: [String: CookieConsentPreferences] = [:]
    
    public init() {}
    
    public func setConsentPreferences(userId: String, preferences: CookieConsentPreferences) async throws {
        userPreferences[userId] = preferences
    }
    
    public func getConsentPreferences(for userId: String) async throws -> CookieConsentPreferences? {
        return userPreferences[userId]
    }
    
    public func canUseCookieCategory(_ category: CookieCategory, for userId: String) async throws -> Bool {
        guard let preferences = userPreferences[userId] else { return false }
        
        switch category {
        case .essential:
            return preferences.essential
        case .analytics:
            return preferences.analytics
        case .marketing:
            return preferences.marketing
        case .personalization:
            return preferences.personalization
        }
    }
}

// MARK: - Additional Enums

public enum DataProcessingActivity {
    case dataCollection
    case dataStorage
    case dataSharing
    case dataAnalysis
    case dataDeletion
    case dataExport
}

public enum LegalBasis {
    case consent
    case contract
    case legalObligation
    case vitalInterests
    case publicTask
    case legitimateInterests
}

public enum DataCategoryType {
    case personalIdentifiers
    case contentData
    case usageData
    case technicalData
}

// MARK: - Models moved to public scope

public struct DataDeletionRequest {
    public let userId: String
    public let requestId: UUID
    public let requestedAt: Date
    public let includeBackups: Bool
    
    public init(userId: String, requestId: UUID, requestedAt: Date, includeBackups: Bool) {
        self.userId = userId
        self.requestId = requestId
        self.requestedAt = requestedAt
        self.includeBackups = includeBackups
    }
}

public struct DataDeletionResult {
    public let success: Bool
    public let deletedItems: Set<DataCategory>
    public let completedAt: Date?
    public let requestId: UUID
}

public enum DataCategory {
    case mindMaps
    case userProfile
    case apiLogs
    case backups
}

public struct DataPortabilityRequest {
    public let userId: String
    public let requestId: UUID
    public let format: PrivacyExportFormat
    public let includeMetadata: Bool
    
    public init(userId: String, requestId: UUID, format: PrivacyExportFormat, includeMetadata: Bool) {
        self.userId = userId
        self.requestId = requestId
        self.format = format
        self.includeMetadata = includeMetadata
    }
}

public enum PrivacyExportFormat {
    case json, xml, csv
}

public struct DataPortabilityResult {
    public let success: Bool
    public let dataPackage: UserDataPackage?
    public let downloadUrl: URL
}

public struct UserDataPackage {
    public let mindMaps: [String]
    public let userProfile: [String: Any]
    public let exportedAt: Date
}

public struct DoNotSellRequest {
    public let userId: String
    public let requestId: UUID
    public let requestedAt: Date
    public let ipAddress: String
    public let userAgent: String
    
    public init(userId: String, requestedAt: Date, ipAddress: String, userAgent: String) {
        self.userId = userId
        self.requestId = UUID()
        self.requestedAt = requestedAt
        self.ipAddress = ipAddress
        self.userAgent = userAgent
    }
}

public struct DoNotSellResult {
    public let success: Bool
    public let requestId: UUID
    public let effectiveDate: Date?
}

public struct PersonalInformationInventory {
    public let userId: String
    public let categories: Set<PersonalInformationCategory>
    public let generatedAt: Date
}

public enum PersonalInformationCategory {
    case identifiers
    case personalInformation
    case commercialInformation
    case internetActivity
    case geolocationData
}

public struct PrivacyManifest {
    public let version: String
    public let dataTypes: [PrivacyDataType]
    public let trackingDomains: [String]
    public let generatedAt: Date
}

public struct PrivacyDataType {
    public let type: PrivacyDataCategory
    public let purposes: [DataUsagePurpose]
    public let linked: Bool
    public let tracking: Bool
}

public enum PrivacyDataCategory {
    case identifiers
    case location
    case contacts
    case usage
}

public enum DataUsagePurpose {
    case appFunctionality
    case analytics
    case advertising
    case personalization
}

public struct ConsentRecord {
    public let userId: String
    public let consentType: ConsentType
    public let granted: Bool
    public let timestamp: Date
    public let version: String
    public let ipAddress: String
    
    public init(userId: String, consentType: ConsentType, granted: Bool, timestamp: Date, version: String, ipAddress: String) {
        self.userId = userId
        self.consentType = consentType
        self.granted = granted
        self.timestamp = timestamp
        self.version = version
        self.ipAddress = ipAddress
    }
}

public enum ConsentType {
    case dataProcessing
    case marketing
    case analytics
    case cookies
}

public struct RetainableData {
    public let id: String
    public let userId: String
    public let dataType: RetentionDataType
    public let createdAt: Date
    public let retentionPeriod: RetentionPeriod
    
    public init(id: String, userId: String, dataType: RetentionDataType, createdAt: Date, retentionPeriod: RetentionPeriod) {
        self.id = id
        self.userId = userId
        self.dataType = dataType
        self.createdAt = createdAt
        self.retentionPeriod = retentionPeriod
    }
}

public enum RetentionDataType {
    case userPreferences
    case temporaryFiles
    case auditLogs
    case analyticsData
}

public enum RetentionPeriod {
    case thirtyDays
    case oneYear
    case twoYears
    case sevenYears
}

public struct CookieConsentPreferences {
    public let essential: Bool
    public let analytics: Bool
    public let marketing: Bool
    public let personalization: Bool
    
    public init(essential: Bool, analytics: Bool, marketing: Bool, personalization: Bool) {
        self.essential = essential
        self.analytics = analytics
        self.marketing = marketing
        self.personalization = personalization
    }
}

public enum CookieCategory {
    case essential
    case analytics
    case marketing
    case personalization
}