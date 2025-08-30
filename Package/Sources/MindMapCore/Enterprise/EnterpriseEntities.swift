import Foundation
import Combine

// MARK: - SSO Authentication Models

public struct SAMLConfiguration {
    public let entityID: String
    public let ssoURL: String
    public let x509Certificate: String
    
    public init(entityID: String, ssoURL: String, x509Certificate: String) {
        self.entityID = entityID
        self.ssoURL = ssoURL
        self.x509Certificate = x509Certificate
    }
}

public struct SAMLAuthenticationRequest {
    public let url: URL
    public let requestID: String
    public let issuer: String
    public let timestamp: Date
    
    public init(url: URL, requestID: String, issuer: String, timestamp: Date = Date()) {
        self.url = url
        self.requestID = requestID
        self.issuer = issuer
        self.timestamp = timestamp
    }
}

public struct SAMLAuthenticationResult {
    public let isValid: Bool
    public let userID: String
    public let attributes: [String: Any]
    public let sessionIndex: String?
    
    public init(isValid: Bool, userID: String, attributes: [String: Any], sessionIndex: String? = nil) {
        self.isValid = isValid
        self.userID = userID
        self.attributes = attributes
        self.sessionIndex = sessionIndex
    }
}

public enum SSOAuthenticationError: LocalizedError {
    case configurationMissing
    case invalidResponse
    case signatureVerificationFailed
    case expired
    case invalidIssuer
    
    public var errorDescription: String? {
        switch self {
        case .configurationMissing:
            return "SSO configuration is missing"
        case .invalidResponse:
            return "Invalid SAML response"
        case .signatureVerificationFailed:
            return "SAML signature verification failed"
        case .expired:
            return "SAML response has expired"
        case .invalidIssuer:
            return "Invalid SAML issuer"
        }
    }
}

// MARK: - Enterprise Session Models

public struct EnterpriseSession: Identifiable {
    public let id = UUID()
    public let sessionID: String
    public let userID: String
    public let attributes: [String: Any]
    public let creationDate: Date
    public let expirationDate: Date
    
    public var isActive: Bool {
        Date() < expirationDate
    }
    
    public init(sessionID: String, userID: String, attributes: [String: Any], 
               creationDate: Date = Date(), expirationDate: Date) {
        self.sessionID = sessionID
        self.userID = userID
        self.attributes = attributes
        self.creationDate = creationDate
        self.expirationDate = expirationDate
    }
}

// MARK: - JWT Token Models

public struct JWTValidationResult {
    public let isValid: Bool
    public let claims: [String: Any]?
    public let expirationDate: Date?
    
    public init(isValid: Bool, claims: [String: Any]? = nil, expirationDate: Date? = nil) {
        self.isValid = isValid
        self.claims = claims
        self.expirationDate = expirationDate
    }
}

public enum JWTValidationError: LocalizedError {
    case invalidFormat
    case invalidSignature
    case expired
    case invalidIssuer
    case missingRequiredClaims
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid JWT token format"
        case .invalidSignature:
            return "Invalid JWT signature"
        case .expired:
            return "JWT token has expired"
        case .invalidIssuer:
            return "Invalid JWT issuer"
        case .missingRequiredClaims:
            return "JWT token missing required claims"
        }
    }
}

// MARK: - Team Management Models

public struct Team: Identifiable, Codable {
    public let id: UUID
    public let name: String
    public let adminUserID: String
    public var members: [TeamMember]
    public var permissions: [TeamPermission]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(id: UUID = UUID(), name: String, adminUserID: String, 
               members: [TeamMember] = [], permissions: [TeamPermission] = []) {
        self.id = id
        self.name = name
        self.adminUserID = adminUserID
        self.members = members
        self.permissions = permissions
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

public struct TeamMember: Identifiable, Codable {
    public let id: UUID
    public let userID: String
    public let role: TeamRole
    public let joinedAt: Date
    
    public init(id: UUID = UUID(), userID: String, role: TeamRole, joinedAt: Date = Date()) {
        self.id = id
        self.userID = userID
        self.role = role
        self.joinedAt = joinedAt
    }
}

public enum TeamRole: String, Codable, CaseIterable {
    case admin
    case manager
    case member
    case viewer
    
    public var permissions: [Permission] {
        switch self {
        case .admin:
            return [.admin, .readWrite, .read]
        case .manager:
            return [.readWrite, .read]
        case .member:
            return [.read]
        case .viewer:
            return [.read]
        }
    }
}

// MARK: - Permission System Models

public struct MindMapResource: Identifiable, Codable {
    public let id: UUID
    public let type: ResourceType
    public let parentID: UUID?
    
    public init(id: UUID = UUID(), type: ResourceType, parentID: UUID? = nil) {
        self.id = id
        self.type = type
        self.parentID = parentID
    }
}

public enum ResourceType: String, Codable {
    case mindMap
    case folder
    case template
    case team
}

public struct ResourcePermission: Identifiable, Codable {
    public let id: UUID
    public let userID: String
    public let resource: MindMapResource
    public let permission: Permission
    public let isTemporary: Bool
    public let expirationDate: Date?
    public let grantedAt: Date
    
    public init(id: UUID = UUID(), userID: String, resource: MindMapResource, 
               permission: Permission, isTemporary: Bool = false, 
               expirationDate: Date? = nil, grantedAt: Date = Date()) {
        self.id = id
        self.userID = userID
        self.resource = resource
        self.permission = permission
        self.isTemporary = isTemporary
        self.expirationDate = expirationDate
        self.grantedAt = grantedAt
    }
}

public enum Permission: String, Codable, CaseIterable {
    case read
    case readWrite
    case admin
    
    public var level: Int {
        switch self {
        case .read: return 1
        case .readWrite: return 2
        case .admin: return 3
        }
    }
}

public enum ResourceAction: String, Codable {
    case read
    case edit
    case delete
    case share
    case manage
    
    public var requiredPermission: Permission {
        switch self {
        case .read: return .read
        case .edit: return .readWrite
        case .delete, .share, .manage: return .admin
        }
    }
}

public struct TeamPermission: Identifiable, Codable {
    public let id: UUID
    public let teamID: UUID
    public let resource: MindMapResource
    public let permission: Permission
    
    public init(id: UUID = UUID(), teamID: UUID, resource: MindMapResource, permission: Permission) {
        self.id = id
        self.teamID = teamID
        self.resource = resource
        self.permission = permission
    }
}

// MARK: - Role System Models

public enum Role: String, Codable, CaseIterable {
    case superAdmin
    case admin
    case editor
    case viewer
    
    public var permissions: [Permission] {
        switch self {
        case .superAdmin, .admin:
            return [.admin, .readWrite, .read]
        case .editor:
            return [.readWrite, .read]
        case .viewer:
            return [.read]
        }
    }
}

public struct TeamHierarchy {
    public let rootTeam: Team
    public let subTeams: [Team]
    
    public init(rootTeam: Team, subTeams: [Team] = []) {
        self.rootTeam = rootTeam
        self.subTeams = subTeams
    }
}

// MARK: - Audit Logging Models

public enum AuditAction: String, Codable {
    case mindMapCreated
    case mindMapDeleted
    case mindMapUpdated
    case mindMapAccessed
    case userLogin
    case userLogout
    case permissionGranted
    case permissionRevoked
    case teamCreated
    case teamDeleted
    case memberAdded
    case memberRemoved
}

public struct AuditLog: Identifiable, Codable {
    public let id: UUID
    public let userID: String
    public let action: AuditAction
    public let resourceID: UUID?
    public let metadata: [String: String]
    public let timestamp: Date
    public let ipAddress: String?
    public let userAgent: String?
    
    public init(id: UUID = UUID(), userID: String, action: AuditAction, 
               resourceID: UUID? = nil, metadata: [String: String] = [:],
               timestamp: Date = Date(), ipAddress: String? = nil, userAgent: String? = nil) {
        self.id = id
        self.userID = userID
        self.action = action
        self.resourceID = resourceID
        self.metadata = metadata
        self.timestamp = timestamp
        self.ipAddress = ipAddress
        self.userAgent = userAgent
    }
}

// MARK: - Security Event Models

public enum SecurityEventType: String, Codable {
    case loginAttempt
    case unauthorizedAccess
    case dataExfiltration
    case anomalousActivity
    case configurationChange
}

public struct SecurityEvent: Identifiable, Codable {
    public let id: UUID
    public let eventType: SecurityEventType
    public let userID: String?
    public let success: Bool
    public let ipAddress: String?
    public let userAgent: String?
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(id: UUID = UUID(), eventType: SecurityEventType, userID: String? = nil,
               success: Bool, ipAddress: String? = nil, userAgent: String? = nil,
               timestamp: Date = Date(), metadata: [String: String] = [:]) {
        self.id = id
        self.eventType = eventType
        self.userID = userID
        self.success = success
        self.ipAddress = ipAddress
        self.userAgent = userAgent
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Compliance Models

public enum ComplianceReportType: String, Codable {
    case gdprCompliance
    case hipaaCompliance
    case sox404Compliance
    case iso27001Compliance
}

public struct ComplianceReport: Identifiable, Codable {
    public let id: UUID
    public let reportType: ComplianceReportType
    public let startDate: Date
    public let endDate: Date
    public let entries: [ComplianceEntry]?
    public let summary: ComplianceSummary?
    public let generatedAt: Date
    
    public init(id: UUID = UUID(), reportType: ComplianceReportType,
               startDate: Date, endDate: Date, entries: [ComplianceEntry]? = nil,
               summary: ComplianceSummary? = nil, generatedAt: Date = Date()) {
        self.id = id
        self.reportType = reportType
        self.startDate = startDate
        self.endDate = endDate
        self.entries = entries
        self.summary = summary
        self.generatedAt = generatedAt
    }
}

public struct ComplianceEntry: Identifiable, Codable {
    public let id: UUID
    public let eventType: String
    public let description: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), eventType: String, description: String, timestamp: Date = Date()) {
        self.id = id
        self.eventType = eventType
        self.description = description
        self.timestamp = timestamp
    }
}

public struct ComplianceSummary: Codable {
    public let totalEvents: Int
    public let criticalEvents: Int
    public let complianceScore: Double
    
    public init(totalEvents: Int, criticalEvents: Int, complianceScore: Double) {
        self.totalEvents = totalEvents
        self.criticalEvents = criticalEvents
        self.complianceScore = complianceScore
    }
}

// MARK: - Data Access Models

public enum DataOperation: String, Codable {
    case create
    case read
    case update
    case delete
    case export
    case `import`
}

public struct DataAccessLog: Identifiable, Codable {
    public let id: UUID
    public let userID: String
    public let operation: DataOperation
    public let dataType: String
    public let resourceID: UUID
    public let timestamp: Date
    public let metadata: [String: String]
    
    public init(id: UUID = UUID(), userID: String, operation: DataOperation,
               dataType: String, resourceID: UUID, timestamp: Date = Date(),
               metadata: [String: String] = [:]) {
        self.id = id
        self.userID = userID
        self.operation = operation
        self.dataType = dataType
        self.resourceID = resourceID
        self.timestamp = timestamp
        self.metadata = metadata
    }
}

// MARK: - Retention Policy Models

public enum LogType: String, Codable {
    case audit
    case security
    case access
    case compliance
}

public struct RetentionPolicy: Identifiable, Codable {
    public let id: UUID
    public let type: LogType
    public let retentionDays: Int
    public let archiveAfterDays: Int
    
    public init(id: UUID = UUID(), type: LogType, retentionDays: Int, archiveAfterDays: Int) {
        self.id = id
        self.type = type
        self.retentionDays = retentionDays
        self.archiveAfterDays = archiveAfterDays
    }
}

// MARK: - Search Models

public struct LogSearchCriteria {
    public let userID: String?
    public let actions: [AuditAction]?
    public let startDate: Date?
    public let endDate: Date?
    public let resourceID: UUID?
    
    public init(userID: String? = nil, actions: [AuditAction]? = nil,
               startDate: Date? = nil, endDate: Date? = nil, resourceID: UUID? = nil) {
        self.userID = userID
        self.actions = actions
        self.startDate = startDate
        self.endDate = endDate
        self.resourceID = resourceID
    }
}

// MARK: - Anomaly Detection Models

public enum AnomalyType: String, Codable {
    case unusualFrequency
    case suspiciousAccess
    case dataExfiltration
    case offHoursActivity
}

public enum SeverityLevel: String, Codable {
    case low
    case medium
    case high
    case critical
}

public struct ActivityAnomaly: Identifiable, Codable {
    public let id: UUID
    public let type: AnomalyType
    public let userID: String
    public let severity: SeverityLevel
    public let description: String
    public let timestamp: Date
    
    public init(id: UUID = UUID(), type: AnomalyType, userID: String,
               severity: SeverityLevel, description: String, timestamp: Date = Date()) {
        self.id = id
        self.type = type
        self.userID = userID
        self.severity = severity
        self.description = description
        self.timestamp = timestamp
    }
}

// MARK: - Compliance Violation Models

public enum ComplianceViolationType: String, Codable {
    case unauthorizedDataAccess
    case dataRetentionViolation
    case insufficientLogging
    case weakAuthentication
}

public struct ComplianceViolation: Identifiable, Codable {
    public let id: UUID
    public let type: ComplianceViolationType
    public let userID: String?
    public let resourceID: UUID?
    public let severity: SeverityLevel?
    public let description: String?
    public let timestamp: Date
    public var resolved: Bool
    
    public init(id: UUID = UUID(), type: ComplianceViolationType, userID: String? = nil,
               resourceID: UUID? = nil, severity: SeverityLevel? = .medium,
               description: String? = nil, timestamp: Date = Date(), resolved: Bool = false) {
        self.id = id
        self.type = type
        self.userID = userID
        self.resourceID = resourceID
        self.severity = severity
        self.description = description
        self.timestamp = timestamp
        self.resolved = resolved
    }
}

// MARK: - Export Models

public enum AuditExportFormat: String, Codable {
    case csv
    case json
    case xml
    case pdf
}

public struct LogExportRequest {
    public let format: AuditExportFormat
    public let startDate: Date
    public let endDate: Date
    public let includeMetadata: Bool
    
    public init(format: AuditExportFormat, startDate: Date, endDate: Date, includeMetadata: Bool = false) {
        self.format = format
        self.startDate = startDate
        self.endDate = endDate
        self.includeMetadata = includeMetadata
    }
}

public struct LogExportData {
    public let format: AuditExportFormat
    public let data: Data
    public let filename: String
    public let size: Int
    
    public init(format: AuditExportFormat, data: Data, filename: String, size: Int) {
        self.format = format
        self.data = data
        self.filename = filename
        self.size = size
    }
}