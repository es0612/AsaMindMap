import Foundation
import CryptoKit

// MARK: - Core Data Encryption Manager

public class CoreDataEncryptionManager {
    private let keychain = SecureKeychain.shared
    private let masterKeyIdentifier = "CoreDataMasterKey"
    private var cachedMasterKey: SymmetricKey?
    
    public init() {}
    
    // MARK: - Public Interface
    
    public func encrypt<T: Codable>(_ data: T) async throws -> EncryptedEntity {
        let masterKey = try await getMasterKey()
        let jsonData = try JSONEncoder().encode(data)
        
        // AES-GCM暗号化
        let nonce = AES.GCM.Nonce()
        guard let sealedBox = try? AES.GCM.seal(jsonData, using: masterKey, nonce: nonce) else {
            throw EncryptionError.encryptionFailed
        }
        
        return EncryptedEntity(
            ciphertext: sealedBox.ciphertext,
            nonce: Data(nonce),
            tag: sealedBox.tag,
            encryptedAt: Date()
        )
    }
    
    public func decrypt<T: Codable>(_ entity: EncryptedEntity, type: T.Type) async throws -> T {
        let masterKey = try await getMasterKey()
        
        // AES-GCM復号化
        guard let nonce = try? AES.GCM.Nonce(data: entity.nonce) else {
            throw EncryptionError.decryptionFailed
        }
        
        guard let sealedBox = try? AES.GCM.SealedBox(
            nonce: nonce,
            ciphertext: entity.ciphertext,
            tag: entity.tag
        ) else {
            throw EncryptionError.decryptionFailed
        }
        
        guard let decryptedData = try? AES.GCM.open(sealedBox, using: masterKey) else {
            throw EncryptionError.decryptionFailed
        }
        
        do {
            return try JSONDecoder().decode(type, from: decryptedData)
        } catch {
            throw EncryptionError.invalidData
        }
    }
    
    // MARK: - Master Key Management
    
    private func getMasterKey() async throws -> SymmetricKey {
        if let cachedKey = cachedMasterKey {
            return cachedKey
        }
        
        do {
            let keyData = try await keychain.retrieve(key: masterKeyIdentifier)
            let masterKey = SymmetricKey(data: keyData)
            cachedMasterKey = masterKey
            return masterKey
        } catch KeychainError.itemNotFound {
            // 新しいマスターキーを生成
            return try await generateAndStoreMasterKey()
        } catch {
            throw EncryptionError.keyGenerationFailed
        }
    }
    
    private func generateAndStoreMasterKey() async throws -> SymmetricKey {
        let masterKey = SymmetricKey(size: .bits256)
        let keyData = masterKey.withUnsafeBytes { Data($0) }
        
        try await keychain.store(key: masterKeyIdentifier, data: keyData)
        cachedMasterKey = masterKey
        
        return masterKey
    }
    
    // MARK: - Key Rotation
    
    public func rotateMasterKey() async throws {
        // 新しいキーを生成
        let newMasterKey = SymmetricKey(size: .bits256)
        let keyData = newMasterKey.withUnsafeBytes { Data($0) }
        
        // キーチェーンを更新
        try await keychain.update(key: masterKeyIdentifier, data: keyData)
        cachedMasterKey = newMasterKey
    }
    
    public func deleteMasterKey() async throws {
        try await keychain.delete(key: masterKeyIdentifier)
        cachedMasterKey = nil
    }
}

// MARK: - Encrypted Entity Model

public struct EncryptedEntity: Codable {
    public let ciphertext: Data
    public let nonce: Data
    public let tag: Data
    public let encryptedAt: Date
    
    public init(ciphertext: Data, nonce: Data, tag: Data, encryptedAt: Date) {
        self.ciphertext = ciphertext
        self.nonce = nonce
        self.tag = tag
        self.encryptedAt = encryptedAt
    }
}

// MARK: - Encryption Errors

public enum EncryptionError: Error, LocalizedError {
    case keyGenerationFailed
    case encryptionFailed
    case decryptionFailed
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .keyGenerationFailed:
            return "暗号化キーの生成に失敗しました"
        case .encryptionFailed:
            return "データの暗号化に失敗しました"
        case .decryptionFailed:
            return "データの復号化に失敗しました"
        case .invalidData:
            return "無効なデータ形式です"
        }
    }
}