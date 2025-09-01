import XCTest
@testable import MindMapCore

class SecureStorageTests: XCTestCase {
    
    // MARK: - Keychain Storage Tests
    
    func testKeychainShouldStoreAndRetrieveSecretKey() async throws {
        // Given
        let keychain = SecureKeychain.shared
        let key = "test_encryption_key"
        let secretData = "super_secret_key_data".data(using: .utf8)!
        
        // When
        try await keychain.store(key: key, data: secretData)
        let retrievedData = try await keychain.retrieve(key: key)
        
        // Then
        XCTAssertEqual(retrievedData, secretData)
    }
    
    func testKeychainShouldThrowErrorForNonExistentKey() async throws {
        // Given
        let keychain = SecureKeychain.shared
        let key = "non_existent_key"
        
        // When & Then
        await XCTAssertThrowsError(try await keychain.retrieve(key: key)) { error in
            XCTAssertTrue(error is KeychainError)
        }
    }
    
    func testKeychainShouldUpdateExistingKey() async throws {
        // Given
        let keychain = SecureKeychain.shared
        let key = "test_update_key"
        let originalData = "original_data".data(using: .utf8)!
        let updatedData = "updated_data".data(using: .utf8)!
        
        // When
        try await keychain.store(key: key, data: originalData)
        try await keychain.update(key: key, data: updatedData)
        let retrievedData = try await keychain.retrieve(key: key)
        
        // Then
        XCTAssertEqual(retrievedData, updatedData)
    }
    
    func testKeychainShouldDeleteKey() async throws {
        // Given
        let keychain = SecureKeychain.shared
        let key = "test_delete_key"
        let data = "test_data".data(using: .utf8)!
        
        // When
        try await keychain.store(key: key, data: data)
        try await keychain.delete(key: key)
        
        // Then
        await XCTAssertThrowsError(try await keychain.retrieve(key: key))
    }
    
    // MARK: - Core Data Encryption Tests
    
    func testCoreDataShouldEncryptSensitiveFields() async throws {
        // Given
        let encryptionManager = CoreDataEncryptionManager()
        let sensitiveData = SensitiveUserData(
            id: UUID(),
            email: "user@example.com",
            personalNotes: "私的なメモ",
            apiTokens: ["notion": "secret_token"]
        )
        
        // When
        let encryptedEntity = try await encryptionManager.encrypt(sensitiveData)
        let decryptedData = try await encryptionManager.decrypt(encryptedEntity, type: SensitiveUserData.self)
        
        // Then
        XCTAssertEqual(decryptedData.email, sensitiveData.email)
        XCTAssertEqual(decryptedData.personalNotes, sensitiveData.personalNotes)
        XCTAssertEqual(decryptedData.apiTokens, sensitiveData.apiTokens)
    }
    
    func testCoreDataShouldHandleEncryptionFailure() async throws {
        // Given
        let encryptionManager = CoreDataEncryptionManager()
        let invalidData = CorruptedData()
        
        // When & Then
        await XCTAssertThrowsError(try await encryptionManager.encrypt(invalidData)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    // MARK: - Secure Communication Tests
    
    func testSecureCommunicationShouldEncryptAPIPayloads() async throws {
        // Given
        let secureComm = SecureCommunicationManager()
        let payload = MindMapSyncPayload(
            mindMapId: UUID(),
            content: "センシティブなマインドマップコンテンツ",
            lastModified: Date()
        )
        
        // When
        let encryptedPayload = try await secureComm.encryptForTransmission(payload)
        let decryptedPayload = try await secureComm.decryptFromTransmission(encryptedPayload, type: MindMapSyncPayload.self)
        
        // Then
        XCTAssertEqual(decryptedPayload.content, payload.content)
        XCTAssertEqual(decryptedPayload.mindMapId, payload.mindMapId)
    }
    
    func testSecureCommunicationShouldValidateIntegrity() async throws {
        // Given
        let secureComm = SecureCommunicationManager()
        let payload = "重要なデータ".data(using: .utf8)!
        
        // When
        let signed = try await secureComm.signData(payload)
        let isValid = try await secureComm.verifySignature(signed)
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testSecureCommunicationShouldDetectTamperedData() async throws {
        // Given
        let secureComm = SecureCommunicationManager()
        let payload = "重要なデータ".data(using: .utf8)!
        
        // When
        var signed = try await secureComm.signData(payload)
        // データを改ざん
        signed.data = "改ざんされたデータ".data(using: .utf8)!
        
        let isValid = try await secureComm.verifySignature(signed)
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    // MARK: - Biometric Authentication Tests
    
    func testBiometricAuthShouldAuthenticateWithTouchID() async throws {
        // Given
        let biometricAuth = BiometricAuthenticator()
        
        // When
        let result = try await biometricAuth.authenticateWithBiometrics(
            reason: "マインドマップへのアクセス認証",
            fallbackTitle: "パスワードを使用"
        )
        
        // Then
        XCTAssertTrue(result.success)
        XCTAssertNotNil(result.authToken)
    }
    
    func testBiometricAuthShouldHandleUnavailableBiometrics() async throws {
        // Given
        let biometricAuth = BiometricAuthenticator()
        
        // When & Then
        // 生体認証が利用不可の場合
        if !biometricAuth.isBiometricAvailable {
            await XCTAssertThrowsError(try await biometricAuth.authenticateWithBiometrics(
                reason: "認証が必要",
                fallbackTitle: "パスワード"
            )) { error in
                XCTAssertTrue(error is BiometricError)
            }
        }
    }
    
    // MARK: - Memory Protection Tests
    
    func testMemoryProtectionShouldClearSensitiveData() async throws {
        // Given
        let memoryProtector = MemoryProtectionManager()
        let sensitiveString = SecureString("機密データ")
        
        // When
        try await memoryProtector.protectInMemory(sensitiveString)
        try await memoryProtector.clearFromMemory(sensitiveString)
        
        // Then
        XCTAssertTrue(sensitiveString.isCleared)
    }
    
    func testMemoryProtectionShouldPreventSwapping() async throws {
        // Given
        let memoryProtector = MemoryProtectionManager()
        let sensitiveData = "極秘データ".data(using: .utf8)!
        
        // When
        let protectedData = try await memoryProtector.lockMemory(sensitiveData)
        
        // Then
        XCTAssertNotNil(protectedData)
        XCTAssertTrue(protectedData.isLocked)
    }
}

// MARK: - Test Models

struct SensitiveUserData: Codable {
    let id: UUID
    let email: String
    let personalNotes: String
    let apiTokens: [String: String]
}

struct CorruptedData: Codable {
    // 意図的に不正なデータ構造
}

struct MindMapSyncPayload: Codable {
    let mindMapId: UUID
    let content: String
    let lastModified: Date
}

struct SignedData {
    var data: Data
    let signature: Data
}

struct BiometricResult {
    let success: Bool
    let authToken: String?
}

class SecureString {
    private var value: String?
    var isCleared: Bool = false
    
    init(_ value: String) {
        self.value = value
    }
    
    func clear() {
        value = nil
        isCleared = true
    }
}

struct ProtectedMemory {
    let data: Data
    let isLocked: Bool
}

// MARK: - Error Types

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedError(OSStatus)
}

enum EncryptionError: Error {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidData
}

enum BiometricError: Error {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancel
    case systemCancel
}

enum MemoryProtectionError: Error {
    case lockFailed
    case unlockFailed
    case clearFailed
}