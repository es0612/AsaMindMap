import Testing
import Foundation
@testable import MindMapCore

/// API統合セキュリティテストスイート
/// 認証、権限管理、データ保護、セキュリティ制限のTDDテスト
@Suite("API統合セキュリティテスト")
struct APISecurityTests {
    
    // MARK: - Authentication Security Tests
    
    @Test("認証セキュリティ: OAuth2.0フロー完全性")
    func testOAuth2FlowIntegrity() async throws {
        // Given
        let oauthProvider = SecureOAuthProvider()
        let clientId = "secure-client-123"
        let clientSecret = "super-secret-key"
        let redirectUri = "asamindmap://oauth/callback"
        let state = "secure-random-state-123"
        
        // When
        let authUrl = try oauthProvider.generateAuthorizationURL(
            clientId: clientId,
            redirectUri: redirectUri,
            scopes: ["read", "write"],
            state: state
        )
        
        let authCode = "mock-auth-code-456"
        let tokenResponse = try await oauthProvider.exchangeCodeForToken(
            code: authCode,
            clientId: clientId,
            clientSecret: clientSecret,
            redirectUri: redirectUri
        )
        
        // Then
        #expect(authUrl.absoluteString.contains("state=\(state)"))
        #expect(tokenResponse.accessToken.isEmpty == false)
        #expect(tokenResponse.refreshToken.isEmpty == false)
        #expect(tokenResponse.expiresIn > 0)
        #expect(tokenResponse.tokenType == "Bearer")
    }
    
    @Test("認証セキュリティ: JWTトークン検証")
    func testJWTTokenValidation() async throws {
        // Given
        let jwtValidator = APIJWTTokenValidator()
        let validToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEyMyIsImV4cCI6MTY5OTk5OTk5OSwiaWF0IjoxNjk5OTk5MDAwfQ.mock-signature"
        let expiredToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyLTEyMyIsImV4cCI6MTYwMDAwMDAwMCwiaWF0IjoxNTk5OTk5MDAwfQ.mock-expired-signature"
        let malformedToken = "invalid.jwt.token"
        
        // When & Then
        let validResult = try await jwtValidator.validateToken(validToken)
        #expect(validResult.isValid == true)
        #expect(validResult.userId == "user-123")
        #expect(validResult.expiresAt != nil)
        
        await #expect(throws: APIJWTValidationError.tokenExpired) {
            try await jwtValidator.validateToken(expiredToken)
        }
        
        await #expect(throws: APIJWTValidationError.malformedToken) {
            try await jwtValidator.validateToken(malformedToken)
        }
    }
    
    @Test("認証セキュリティ: Multi-Factor Authentication (MFA)")
    func testMultiFactorAuthentication() async throws {
        // Given
        let mfaProvider = MFAProvider()
        let userId = "user-123"
        let primaryCredentials = Credentials(username: "testuser", password: "secure-password-123")
        
        // When
        let primaryResult = try await mfaProvider.authenticateUser(primaryCredentials)
        #expect(primaryResult.requiresMFA == true)
        #expect(primaryResult.challengeId != nil)
        
        let mfaCode = "123456" // TOTPコード
        let finalResult = try await mfaProvider.completeMFAChallenge(
            challengeId: primaryResult.challengeId!,
            mfaCode: mfaCode,
            userId: userId
        )
        
        // Then
        #expect(finalResult.authenticated == true)
        #expect(finalResult.accessToken.isEmpty == false)
        #expect(finalResult.mfaVerified == true)
    }
    
    // MARK: - Data Encryption Tests
    
    @Test("データ暗号化: API通信の暗号化")
    func testAPIDataEncryption() async throws {
        // Given
        let encryptionManager = APIEncryptionManager()
        let sensitiveData = SensitiveAPIData(
            mindMapContent: "機密プロジェクトのマインドマップ",
            userNotes: "社内情報を含むメモ",
            apiKey: "secret-api-key-789"
        )
        
        // When
        let encryptedPayload = try encryptionManager.encryptPayload(sensitiveData)
        let decryptedPayload = try encryptionManager.decryptPayload(encryptedPayload, type: SensitiveAPIData.self)
        
        // Then
        #expect(encryptedPayload.encryptedData.isEmpty == false)
        #expect(encryptedPayload.iv.isEmpty == false)
        #expect(encryptedPayload.authTag.isEmpty == false)
        #expect(decryptedPayload.mindMapContent == sensitiveData.mindMapContent)
        #expect(decryptedPayload.apiKey == sensitiveData.apiKey)
    }
    
    @Test("データ暗号化: エンドツーエンド暗号化")
    func testEndToEndEncryption() async throws {
        // Given
        let e2eEncryption = EndToEndEncryption()
        let sender = User(id: "sender-123", publicKey: generateTestPublicKey())
        let receiver = User(id: "receiver-456", publicKey: generateTestPublicKey())
        let message = "Confidential mind map shared between users"
        
        // When
        let encryptedMessage = try e2eEncryption.encryptForUser(
            message: message,
            senderPrivateKey: generateTestPrivateKey(),
            receiverPublicKey: receiver.publicKey
        )
        
        let decryptedMessage = try e2eEncryption.decryptFromUser(
            encryptedMessage: encryptedMessage,
            receiverPrivateKey: generateTestPrivateKey(),
            senderPublicKey: sender.publicKey
        )
        
        // Then
        #expect(encryptedMessage.ciphertext.isEmpty == false)
        #expect(encryptedMessage.signature.isEmpty == false)
        #expect(decryptedMessage == message)
    }
    
    // MARK: - Access Control Tests
    
    @Test("アクセス制御: ロールベースアクセス制御（RBAC）")
    func testRoleBasedAccessControl() async throws {
        // Given
        let rbacManager = RBACManager()
        let adminRole = Role(
            id: "admin",
            name: "管理者",
            permissions: [.read, .write, .delete, .admin, .userManagement]
        )
        let userRole = Role(
            id: "user",
            name: "一般ユーザー",
            permissions: [.read, .write]
        )
        let viewerRole = Role(
            id: "viewer",
            name: "閲覧者",
            permissions: [.read]
        )
        
        let adminUser = User(id: "admin-1", roles: [adminRole])
        let regularUser = User(id: "user-1", roles: [userRole])
        let viewerUser = User(id: "viewer-1", roles: [viewerRole])
        
        // When & Then
        let adminCanDelete = try await rbacManager.checkPermission(
            user: adminUser,
            permission: .delete,
            resource: "mindmap-123"
        )
        #expect(adminCanDelete == true)
        
        let userCanWrite = try await rbacManager.checkPermission(
            user: regularUser,
            permission: .write,
            resource: "mindmap-123"
        )
        #expect(userCanWrite == true)
        
        await #expect(throws: AccessControlError.insufficientPermissions) {
            try await rbacManager.checkPermission(
                user: viewerUser,
                permission: .write,
                resource: "mindmap-123"
            )
        }
    }
    
    @Test("アクセス制御: リソースレベル権限")
    func testResourceLevelPermissions() async throws {
        // Given
        let resourceManager = ResourcePermissionManager()
        let mindMapResource = Resource(
            id: "mindmap-456",
            type: .mindMap,
            ownerId: "owner-123"
        )
        
        let owner = User(id: "owner-123")
        let collaborator = User(id: "collaborator-456")
        let stranger = User(id: "stranger-789")
        
        // リソース権限設定
        try await resourceManager.grantPermission(
            resource: mindMapResource,
            user: collaborator,
            permission: .read
        )
        
        // When & Then
        let ownerAccess = try await resourceManager.hasAccess(
            user: owner,
            resource: mindMapResource,
            permission: .write
        )
        #expect(ownerAccess == true)
        
        let collaboratorRead = try await resourceManager.hasAccess(
            user: collaborator,
            resource: mindMapResource,
            permission: .read
        )
        #expect(collaboratorRead == true)
        
        let collaboratorWrite = try await resourceManager.hasAccess(
            user: collaborator,
            resource: mindMapResource,
            permission: .write
        )
        #expect(collaboratorWrite == false)
        
        let strangerAccess = try await resourceManager.hasAccess(
            user: stranger,
            resource: mindMapResource,
            permission: .read
        )
        #expect(strangerAccess == false)
    }
    
    // MARK: - Security Monitoring Tests
    
    @Test("セキュリティ監視: 異常検知システム")
    func testSecurityAnomalyDetection() async throws {
        // Given
        let anomalyDetector = SecurityAnomalyDetector()
        let normalBehavior = [
            APIRequest(userId: "user-1", endpoint: "/api/mindmaps", method: "GET", timestamp: Date()),
            APIRequest(userId: "user-1", endpoint: "/api/mindmaps/123", method: "PUT", timestamp: Date().addingTimeInterval(60)),
            APIRequest(userId: "user-1", endpoint: "/api/mindmaps", method: "POST", timestamp: Date().addingTimeInterval(120))
        ]
        
        let suspiciousBehavior = [
            APIRequest(userId: "user-1", endpoint: "/api/admin/users", method: "GET", timestamp: Date()),
            APIRequest(userId: "user-1", endpoint: "/api/admin/users", method: "DELETE", timestamp: Date().addingTimeInterval(1)),
            APIRequest(userId: "user-1", endpoint: "/api/admin/logs", method: "DELETE", timestamp: Date().addingTimeInterval(2))
        ]
        
        // When
        try await anomalyDetector.trainBaseline(requests: normalBehavior)
        
        let normalAnalysis = try await anomalyDetector.analyzeRequests(normalBehavior)
        let suspiciousAnalysis = try await anomalyDetector.analyzeRequests(suspiciousBehavior)
        
        // Then
        #expect(normalAnalysis.anomalyScore < 0.3)
        #expect(normalAnalysis.isAnomalous == false)
        
        #expect(suspiciousAnalysis.anomalyScore > 0.7)
        #expect(suspiciousAnalysis.isAnomalous == true)
        #expect(suspiciousAnalysis.suspiciousPatterns.contains(.rapidPrivilegeEscalation))
    }
    
    @Test("セキュリティ監視: ブルートフォース攻撃検知")
    func testBruteForceAttackDetection() async throws {
        // Given
        let bruteForceDetector = BruteForceDetector(
            maxAttempts: 5,
            timeWindow: TimeInterval(300) // 5分
        )
        
        let userId = "target-user"
        let attackerIP = "192.168.1.100"
        
        // When
        var loginAttempts: [LoginAttemptResult] = []
        
        for i in 1...7 {
            let result = try await bruteForceDetector.recordLoginAttempt(
                userId: userId,
                ipAddress: attackerIP,
                success: false,
                timestamp: Date().addingTimeInterval(Double(i * 10))
            )
            loginAttempts.append(result)
        }
        
        // Then
        #expect(loginAttempts[0...4].allSatisfy { !$0.isBlocked })
        #expect(loginAttempts[5].isBlocked == true)
        #expect(loginAttempts[6].isBlocked == true)
        
        let blockStatus = try await bruteForceDetector.getBlockStatus(
            userId: userId,
            ipAddress: attackerIP
        )
        #expect(blockStatus.isBlocked == true)
        #expect(blockStatus.remainingBlockTime > 0)
    }
    
    // MARK: - Compliance Tests
    
    @Test("コンプライアンス: GDPR データ削除要求")
    func testGDPRDataDeletionRequest() async throws {
        // Given
        let gdprCompliance = GDPRComplianceManager()
        let userId = "user-gdpr-123"
        let deletionRequest = DataDeletionRequest(
            userId: userId,
            requestId: UUID(),
            requestedAt: Date(),
            includeBackups: true
        )
        
        // When
        let deletionResult = try await gdprCompliance.processDataDeletion(deletionRequest)
        
        // Then
        #expect(deletionResult.success == true)
        #expect(deletionResult.deletedItems.contains(.mindMaps))
        #expect(deletionResult.deletedItems.contains(.userProfile))
        #expect(deletionResult.deletedItems.contains(.apiLogs))
        #expect(deletionResult.completedAt != nil)
        
        // Verify data is actually deleted
        let userData = try await gdprCompliance.getUserData(userId: userId)
        #expect(userData == nil)
    }
    
    @Test("コンプライアンス: データポータビリティ")
    func testGDPRDataPortability() async throws {
        // Given
        let gdprCompliance = GDPRComplianceManager()
        let userId = "user-portability-123"
        let portabilityRequest = DataPortabilityRequest(
            userId: userId,
            requestId: UUID(),
            format: .json,
            includeMetadata: true
        )
        
        // When
        let exportResult = try await gdprCompliance.exportUserData(portabilityRequest)
        
        // Then
        #expect(exportResult.success == true)
        #expect(exportResult.dataPackage != nil)
        #expect(exportResult.dataPackage!.mindMaps.isEmpty == false)
        #expect(exportResult.dataPackage!.userProfile != nil)
        #expect(exportResult.dataPackage!.exportedAt != nil)
        #expect(exportResult.downloadUrl.absoluteString.contains("https://"))
    }
    
    // MARK: - Helper Methods
    
    private func generateTestPublicKey() -> PublicKey {
        return PublicKey(data: "mock-public-key-data".data(using: .utf8)!)
    }
    
    private func generateTestPrivateKey() -> PrivateKey {
        return PrivateKey(data: "mock-private-key-data".data(using: .utf8)!)
    }
    
    private func createTestMindMap() -> MindMap {
        let rootNode = Node(
            id: UUID(),
            text: "Security Test Map",
            position: CGPoint(x: 0, y: 0)
        )
        
        return MindMap(
            id: UUID(),
            title: "Security Test Map",
            rootNode: rootNode,
            nodes: [rootNode],
            tags: ["security", "test"],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}