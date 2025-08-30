import Testing
@testable import MindMapCore

@Suite("SSO Authentication Tests")
struct SSOAuthenticationTests {
    
    @Test("SAML認証プロバイダーの設定テスト")
    func testSAMLProviderConfiguration() async throws {
        // Given
        let provider = SAMLAuthenticationProvider()
        let config = SAMLConfiguration(
            entityID: "https://company.example.com",
            ssoURL: "https://company.example.com/sso",
            x509Certificate: "MIIC..."
        )
        
        // When
        try provider.configure(with: config)
        
        // Then
        #expect(provider.isConfigured)
        #expect(provider.entityID == config.entityID)
    }
    
    @Test("SAML認証リクエストの生成テスト")
    func testSAMLAuthenticationRequestGeneration() async throws {
        // Given
        let provider = SAMLAuthenticationProvider()
        let config = SAMLConfiguration(
            entityID: "https://company.example.com",
            ssoURL: "https://company.example.com/sso",
            x509Certificate: "MIIC..."
        )
        try provider.configure(with: config)
        
        // When
        let authRequest = try await provider.generateAuthenticationRequest()
        
        // Then
        #expect(authRequest.url.absoluteString.contains("SAMLRequest"))
        #expect(authRequest.requestID != nil)
        #expect(authRequest.issuer == config.entityID)
    }
    
    @Test("SAML認証レスポンスの検証テスト")
    func testSAMLResponseValidation() async throws {
        // Given
        let provider = SAMLAuthenticationProvider()
        let config = SAMLConfiguration(
            entityID: "https://company.example.com",
            ssoURL: "https://company.example.com/sso",
            x509Certificate: "MIIC..."
        )
        try provider.configure(with: config)
        
        let samlResponse = """
        <saml:Response>
            <saml:Assertion>
                <saml:Subject>
                    <saml:NameID>user@company.com</saml:NameID>
                </saml:Subject>
            </saml:Assertion>
        </saml:Response>
        """
        
        // When
        let authResult = try await provider.validateResponse(samlResponse)
        
        // Then
        #expect(authResult.isValid)
        #expect(authResult.userID == "user@company.com")
        #expect(authResult.attributes != nil)
    }
    
    @Test("SSO認証の失敗ケース")
    func testSSOAuthenticationFailure() async throws {
        // Given
        let provider = SAMLAuthenticationProvider()
        let invalidResponse = "<invalid>response</invalid>"
        
        // When & Then
        await #expect(throws: SSOAuthenticationError.invalidResponse) {
            try await provider.validateResponse(invalidResponse)
        }
    }
    
    @Test("認証セッションの管理テスト")
    func testAuthenticationSessionManagement() async throws {
        // Given
        let sessionManager = EnterpriseSessionManager()
        let userID = "user@company.com"
        let attributes = ["role": "admin", "department": "IT"]
        
        // When
        let session = try await sessionManager.createSession(
            userID: userID,
            attributes: attributes
        )
        
        // Then
        #expect(session.userID == userID)
        #expect(session.isActive)
        #expect(session.attributes["role"] as? String == "admin")
        #expect(session.expirationDate > Date())
    }
    
    @Test("セッション期限切れの処理テスト")
    func testSessionExpiration() async throws {
        // Given
        let sessionManager = EnterpriseSessionManager()
        let userID = "user@company.com"
        
        // セッションを作成（短い有効期限）
        var session = try await sessionManager.createSession(
            userID: userID,
            attributes: [:],
            duration: 1 // 1秒
        )
        
        // 少し待つ
        try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5秒
        
        // When
        session = try await sessionManager.getSession(session.sessionID)
        
        // Then
        #expect(!session.isActive)
    }
    
    @Test("JWT トークンの検証テスト")
    func testJWTTokenValidation() async throws {
        // Given
        let tokenValidator = JWTTokenValidator()
        let validToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
        
        // When
        let result = try await tokenValidator.validateToken(validToken)
        
        // Then
        #expect(result.isValid)
        #expect(result.claims != nil)
        #expect(result.expirationDate > Date())
    }
    
    @Test("無効なJWTトークンの拒否テスト")
    func testInvalidJWTTokenRejection() async throws {
        // Given
        let tokenValidator = JWTTokenValidator()
        let invalidToken = "invalid.jwt.token"
        
        // When & Then
        await #expect(throws: JWTValidationError.invalidFormat) {
            try await tokenValidator.validateToken(invalidToken)
        }
    }
}