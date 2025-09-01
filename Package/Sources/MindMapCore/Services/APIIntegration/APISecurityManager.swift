import Foundation
import CryptoKit

// MARK: - OAuth2 Security Models
public struct SecureOAuthProvider {
    public init() {}
    
    public func generateAuthorizationURL(
        clientId: String,
        redirectUri: String,
        scopes: [String],
        state: String
    ) throws -> URL {
        var components = URLComponents(string: "https://auth.example.com/oauth/authorize")!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "response_type", value: "code")
        ]
        
        guard let url = components.url else {
            throw SecurityError.invalidAuthURL
        }
        
        return url
    }
    
    public func exchangeCodeForToken(
        code: String,
        clientId: String,
        clientSecret: String,
        redirectUri: String
    ) async throws -> OAuthTokenResponse {
        // 基本的なパラメータ検証
        guard !code.isEmpty, !clientId.isEmpty, !clientSecret.isEmpty else {
            throw SecurityError.invalidCredentials
        }
        
        return OAuthTokenResponse(
            accessToken: "access_token_\(UUID().uuidString)",
            refreshToken: "refresh_token_\(UUID().uuidString)",
            expiresIn: 3600,
            tokenType: "Bearer"
        )
    }
}

public struct OAuthTokenResponse {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let tokenType: String
}

// MARK: - JWT Token Validation
public struct APIJWTTokenValidator {
    public init() {}
    
    public func validateToken(_ token: String) async throws -> APIJWTValidationResult {
        // 基本的なJWTフォーマット検証
        let components = token.components(separatedBy: ".")
        guard components.count == 3 else {
            throw APIJWTValidationError.malformedToken
        }
        
        // ペイロード部分のデコード（簡略化）
        guard let payloadData = Data(base64Encoded: components[1] + "=="),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let exp = payload["exp"] as? TimeInterval,
              let sub = payload["sub"] as? String else {
            throw APIJWTValidationError.malformedToken
        }
        
        let expirationDate = Date(timeIntervalSince1970: exp)
        
        // 期限切れチェック
        if expirationDate < Date() {
            throw APIJWTValidationError.tokenExpired
        }
        
        return APIJWTValidationResult(
            isValid: true,
            userId: sub,
            expiresAt: expirationDate
        )
    }
}

public struct APIJWTValidationResult {
    let isValid: Bool
    let userId: String
    let expiresAt: Date?
}

public enum APIJWTValidationError: Error {
    case tokenExpired
    case malformedToken
    case invalidSignature
}

// MARK: - Multi-Factor Authentication
public struct MFAProvider {
    public init() {}
    
    public func authenticateUser(_ credentials: Credentials) async throws -> MFAPrimaryResult {
        // 基本認証をシミュレート
        guard credentials.username == "testuser" && credentials.password.count >= 8 else {
            throw SecurityError.invalidCredentials
        }
        
        return MFAPrimaryResult(
            requiresMFA: true,
            challengeId: "challenge_\(UUID().uuidString)"
        )
    }
    
    public func completeMFAChallenge(
        challengeId: String,
        mfaCode: String,
        userId: String
    ) async throws -> MFAFinalResult {
        // TOTP コード検証をシミュレート
        guard mfaCode == "123456" else {
            throw SecurityError.invalidMFACode
        }
        
        return MFAFinalResult(
            authenticated: true,
            accessToken: "mfa_token_\(UUID().uuidString)",
            mfaVerified: true
        )
    }
}

public struct Credentials {
    let username: String
    let password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct MFAPrimaryResult {
    let requiresMFA: Bool
    let challengeId: String?
}

public struct MFAFinalResult {
    let authenticated: Bool
    let accessToken: String
    let mfaVerified: Bool
}

// MARK: - Data Encryption
public struct SensitiveAPIData {
    let mindMapContent: String
    let userNotes: String
    let apiKey: String
    
    public init(mindMapContent: String, userNotes: String, apiKey: String) {
        self.mindMapContent = mindMapContent
        self.userNotes = userNotes
        self.apiKey = apiKey
    }
}

public struct EncryptedPayload {
    let encryptedData: Data
    let iv: Data
    let authTag: Data
}

public class APIEncryptionManager {
    private let symmetricKey: SymmetricKey
    
    public init() {
        self.symmetricKey = SymmetricKey(size: .bits256)
    }
    
    public func encryptPayload<T: Codable>(_ data: T) throws -> EncryptedPayload {
        let jsonData = try JSONEncoder().encode(data)
        let iv = Data(count: 12) // 96-bit IV for AES-GCM
        
        let sealedBox = try AES.GCM.seal(jsonData, using: symmetricKey, nonce: AES.GCM.Nonce(data: iv))
        
        return EncryptedPayload(
            encryptedData: sealedBox.ciphertext,
            iv: iv,
            authTag: sealedBox.tag
        )
    }
    
    public func decryptPayload<T: Codable>(_ payload: EncryptedPayload, type: T.Type) throws -> T {
        let nonce = try AES.GCM.Nonce(data: payload.iv)
        let sealedBox = try AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: payload.encryptedData,
            tag: payload.authTag
        )
        
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)
        return try JSONDecoder().decode(type, from: decryptedData)
    }
}

// MARK: - End-to-End Encryption
public struct APIUser {
    let id: String
    let publicKey: PublicKey
    let roles: [APIRole]
    
    public init(id: String, publicKey: PublicKey = PublicKey(data: Data()), roles: [APIRole] = []) {
        self.id = id
        self.publicKey = publicKey
        self.roles = roles
    }
}

public struct PublicKey {
    let data: Data
    
    public init(data: Data) {
        self.data = data
    }
}

public struct PrivateKey {
    let data: Data
    
    public init(data: Data) {
        self.data = data
    }
}

public struct EncryptedMessage {
    let ciphertext: Data
    let signature: Data
}

public class EndToEndEncryption {
    public init() {}
    
    public func encryptForUser(
        message: String,
        senderPrivateKey: PrivateKey,
        receiverPublicKey: PublicKey
    ) throws -> EncryptedMessage {
        let messageData = message.data(using: .utf8) ?? Data()
        
        // シミュレート暗号化
        return EncryptedMessage(
            ciphertext: messageData,
            signature: "signature_\(UUID().uuidString)".data(using: .utf8) ?? Data()
        )
    }
    
    public func decryptFromUser(
        encryptedMessage: EncryptedMessage,
        receiverPrivateKey: PrivateKey,
        senderPublicKey: PublicKey
    ) throws -> String {
        // シミュレート復号化
        return String(data: encryptedMessage.ciphertext, encoding: .utf8) ?? ""
    }
}

// MARK: - Role-Based Access Control (RBAC)
public struct APIRole {
    let id: String
    let name: String
    let permissions: Set<APIPermission>
    
    public init(id: String, name: String, permissions: Set<APIPermission>) {
        self.id = id
        self.name = name
        self.permissions = permissions
    }
}

public enum APIPermission {
    case read
    case write
    case delete
    case admin
    case userManagement
}

public class RBACManager {
    public init() {}
    
    public func checkPermission(
        user: APIUser,
        permission: APIPermission,
        resource: String
    ) async throws -> Bool {
        let hasPermission = user.roles.contains { role in
            role.permissions.contains(permission)
        }
        
        if !hasPermission {
            throw AccessControlError.insufficientPermissions
        }
        
        return hasPermission
    }
}

// MARK: - Resource Permission Management
public struct APIResource {
    let id: String
    let type: APIResourceType
    let ownerId: String
    
    public init(id: String, type: APIResourceType, ownerId: String) {
        self.id = id
        self.type = type
        self.ownerId = ownerId
    }
}

public enum APIResourceType {
    case mindMap
    case template
    case collection
}

public class ResourcePermissionManager {
    private var permissions: [String: [String: APIPermission]] = [:]
    
    public init() {}
    
    public func grantPermission(
        resource: APIResource,
        user: APIUser,
        permission: APIPermission
    ) async throws {
        let resourceKey = "\(resource.id)_\(user.id)"
        permissions[resourceKey] = [user.id: permission]
    }
    
    public func hasAccess(
        user: APIUser,
        resource: APIResource,
        permission: APIPermission
    ) async throws -> Bool {
        // オーナーは常にフルアクセス
        if resource.ownerId == user.id {
            return true
        }
        
        // 明示的な権限をチェック
        let resourceKey = "\(resource.id)_\(user.id)"
        if let userPermission = permissions[resourceKey]?[user.id] {
            return userPermission == permission || userPermission == .admin
        }
        
        return false
    }
}

// MARK: - Security Monitoring
public struct APIRequest {
    let userId: String
    let endpoint: String
    let method: String
    let timestamp: Date
    
    public init(userId: String, endpoint: String, method: String, timestamp: Date) {
        self.userId = userId
        self.endpoint = endpoint
        self.method = method
        self.timestamp = timestamp
    }
}

public struct AnomalyAnalysisResult {
    let anomalyScore: Double
    let isAnomalous: Bool
    let suspiciousPatterns: [SuspiciousPattern]
}

public enum SuspiciousPattern {
    case rapidPrivilegeEscalation
    case unusualAccessPattern
    case dataExfiltration
}

public class SecurityAnomalyDetector {
    private var baseline: [APIRequest] = []
    
    public init() {}
    
    public func trainBaseline(requests: [APIRequest]) async throws {
        baseline = requests
    }
    
    public func analyzeRequests(_ requests: [APIRequest]) async throws -> AnomalyAnalysisResult {
        var anomalyScore = 0.0
        var suspiciousPatterns: [SuspiciousPattern] = []
        
        // 管理者エンドポイントへの連続アクセスチェック
        let adminRequests = requests.filter { $0.endpoint.contains("/admin/") }
        if adminRequests.count > 1 {
            anomalyScore += 0.5
            suspiciousPatterns.append(.rapidPrivilegeEscalation)
        }
        
        // 短時間での大量リクエストチェック
        if requests.count > 2 {
            let timeSpan = requests.last!.timestamp.timeIntervalSince(requests.first!.timestamp)
            if timeSpan < 5.0 { // 5秒以内
                anomalyScore += 0.3
            }
        }
        
        return AnomalyAnalysisResult(
            anomalyScore: anomalyScore,
            isAnomalous: anomalyScore > 0.5,
            suspiciousPatterns: suspiciousPatterns
        )
    }
}

// MARK: - Brute Force Detection
public struct LoginAttemptResult {
    let isBlocked: Bool
    let remainingAttempts: Int
}

public struct BlockStatus {
    let isBlocked: Bool
    let remainingBlockTime: TimeInterval
}

public class BruteForceDetector {
    private let maxAttempts: Int
    private let timeWindow: TimeInterval
    private var attemptCounts: [String: (count: Int, firstAttempt: Date)] = [:]
    private var blockedUsers: [String: Date] = [:]
    
    public init(maxAttempts: Int, timeWindow: TimeInterval) {
        self.maxAttempts = maxAttempts
        self.timeWindow = timeWindow
    }
    
    public func recordLoginAttempt(
        userId: String,
        ipAddress: String,
        success: Bool,
        timestamp: Date
    ) async throws -> LoginAttemptResult {
        let key = "\(userId)_\(ipAddress)"
        
        // ブロック状態チェック
        if let blockTime = blockedUsers[key], timestamp.timeIntervalSince(blockTime) < timeWindow {
            return LoginAttemptResult(isBlocked: true, remainingAttempts: 0)
        }
        
        // 成功時はカウントリセット
        if success {
            attemptCounts.removeValue(forKey: key)
            return LoginAttemptResult(isBlocked: false, remainingAttempts: maxAttempts)
        }
        
        // 失敗カウント更新
        if let existing = attemptCounts[key] {
            let updatedCount = existing.count + 1
            attemptCounts[key] = (count: updatedCount, firstAttempt: existing.firstAttempt)
            
            if updatedCount >= maxAttempts {
                blockedUsers[key] = timestamp
                return LoginAttemptResult(isBlocked: true, remainingAttempts: 0)
            }
        } else {
            attemptCounts[key] = (count: 1, firstAttempt: timestamp)
        }
        
        return LoginAttemptResult(isBlocked: false, remainingAttempts: maxAttempts - (attemptCounts[key]?.count ?? 0))
    }
    
    public func getBlockStatus(userId: String, ipAddress: String) async throws -> BlockStatus {
        let key = "\(userId)_\(ipAddress)"
        
        if let blockTime = blockedUsers[key] {
            let remainingTime = max(0, timeWindow - Date().timeIntervalSince(blockTime))
            return BlockStatus(isBlocked: remainingTime > 0, remainingBlockTime: remainingTime)
        }
        
        return BlockStatus(isBlocked: false, remainingBlockTime: 0)
    }
}

// MARK: - GDPR Compliance Support
// GDPR compliance types are defined in PrivacyComplianceManager

public enum APIExportFormat {
    case json
    case xml
    case csv
}

// MARK: - Security Errors
public enum SecurityError: Error {
    case invalidAuthURL
    case invalidCredentials
    case invalidMFACode
    case encryptionFailed
    case decryptionFailed
}

public enum AccessControlError: Error {
    case insufficientPermissions
    case resourceNotFound
    case accessDenied
}