import Foundation
import CryptoKit

// MARK: - Secure Communication Manager

public class SecureCommunicationManager {
    private let keychain = SecureKeychain.shared
    private let sessionKeyIdentifier = "SecureComm.SessionKey"
    private let signingKeyIdentifier = "SecureComm.SigningKey"
    
    public init() {}
    
    // MARK: - Payload Encryption
    
    public func encryptForTransmission<T: Codable>(_ payload: T) async throws -> EncryptedTransmissionPayload {
        let sessionKey = try await getSessionKey()
        let jsonData = try JSONEncoder().encode(payload)
        
        // 暗号化
        let nonce = AES.GCM.Nonce()
        guard let sealedBox = try? AES.GCM.seal(jsonData, using: sessionKey, nonce: nonce) else {
            throw SecureCommunicationError.encryptionFailed
        }
        
        // メタデータ
        let metadata = TransmissionMetadata(
            timestamp: Date(),
            version: "1.0",
            algorithm: "AES-256-GCM"
        )
        
        return EncryptedTransmissionPayload(
            ciphertext: sealedBox.ciphertext,
            nonce: Data(nonce),
            tag: sealedBox.tag,
            metadata: metadata
        )
    }
    
    public func decryptFromTransmission<T: Codable>(
        _ payload: EncryptedTransmissionPayload,
        type: T.Type
    ) async throws -> T {
        let sessionKey = try await getSessionKey()
        
        // タイムスタンプ検証（5分以内）
        let age = Date().timeIntervalSince(payload.metadata.timestamp)
        if age > 300 { // 5分
            throw SecureCommunicationError.payloadExpired
        }
        
        // 復号化
        guard let nonce = try? AES.GCM.Nonce(data: payload.nonce) else {
            throw SecureCommunicationError.decryptionFailed
        }
        
        guard let sealedBox = try? AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: payload.ciphertext,
            tag: payload.tag
        ) else {
            throw SecureCommunicationError.decryptionFailed
        }
        
        guard let decryptedData = try? AES.GCM.open(sealedBox, using: sessionKey) else {
            throw SecureCommunicationError.decryptionFailed
        }
        
        return try JSONDecoder().decode(type, from: decryptedData)
    }
    
    // MARK: - Digital Signatures
    
    public func signData(_ data: Data) async throws -> SignedData {
        let signingKey = try await getSigningKey()
        
        // HMAC-SHA256署名
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: signingKey)
        let signatureData = Data(signature)
        
        return SignedData(
            data: data,
            signature: signatureData
        )
    }
    
    public func verifySignature(_ signedData: SignedData) async throws -> Bool {
        let signingKey = try await getSigningKey()
        
        // 署名検証
        let expectedMAC = HMAC<SHA256>.authenticationCode(for: signedData.data, using: signingKey)
        let expectedSignature = Data(expectedMAC)
        
        return expectedSignature == signedData.signature
    }
    
    // MARK: - Key Management
    
    private func getSessionKey() async throws -> SymmetricKey {
        do {
            let keyData = try await keychain.retrieve(key: sessionKeyIdentifier)
            return SymmetricKey(data: keyData)
        } catch KeychainError.itemNotFound {
            return try await generateAndStoreSessionKey()
        }
    }
    
    private func generateAndStoreSessionKey() async throws -> SymmetricKey {
        let sessionKey = SymmetricKey(size: .bits256)
        let keyData = sessionKey.withUnsafeBytes { Data($0) }
        
        try await keychain.store(key: sessionKeyIdentifier, data: keyData)
        return sessionKey
    }
    
    private func getSigningKey() async throws -> SymmetricKey {
        do {
            let keyData = try await keychain.retrieve(key: signingKeyIdentifier)
            return SymmetricKey(data: keyData)
        } catch KeychainError.itemNotFound {
            return try await generateAndStoreSigningKey()
        }
    }
    
    private func generateAndStoreSigningKey() async throws -> SymmetricKey {
        let signingKey = SymmetricKey(size: .bits256)
        let keyData = signingKey.withUnsafeBytes { Data($0) }
        
        try await keychain.store(key: signingKeyIdentifier, data: keyData)
        return signingKey
    }
    
    // MARK: - Session Management
    
    public func rotateSessionKey() async throws {
        let newKey = SymmetricKey(size: .bits256)
        let keyData = newKey.withUnsafeBytes { Data($0) }
        
        try await keychain.update(key: sessionKeyIdentifier, data: keyData)
    }
    
    public func clearSession() async throws {
        try await keychain.delete(key: sessionKeyIdentifier)
        try await keychain.delete(key: signingKeyIdentifier)
    }
}

// MARK: - Models

public struct EncryptedTransmissionPayload: Codable {
    public let ciphertext: Data
    public let nonce: Data
    public let tag: Data
    public let metadata: TransmissionMetadata
    
    public init(ciphertext: Data, nonce: Data, tag: Data, metadata: TransmissionMetadata) {
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.metadata = metadata
    }
}

public struct TransmissionMetadata: Codable {
    public let timestamp: Date
    public let version: String
    public let algorithm: String
    
    public init(timestamp: Date, version: String, algorithm: String) {
        self.timestamp = timestamp
        self.version = version
        self.algorithm = algorithm
    }
}

public struct SignedData {
    public var data: Data
    public let signature: Data
    
    public init(data: Data, signature: Data) {
        self.data = data
        self.signature = signature
    }
}

// MARK: - Errors

public enum SecureCommunicationError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case signatureFailed
    case signatureVerificationFailed
    case payloadExpired
    case invalidMetadata
    
    public var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "通信データの暗号化に失敗しました"
        case .decryptionFailed:
            return "通信データの復号化に失敗しました"
        case .signatureFailed:
            return "デジタル署名の生成に失敗しました"
        case .signatureVerificationFailed:
            return "デジタル署名の検証に失敗しました"
        case .payloadExpired:
            return "通信データの有効期限が切れています"
        case .invalidMetadata:
            return "無効なメタデータです"
        }
    }
}