import Foundation
import Security

// MARK: - Secure Keychain Implementation

public class SecureKeychain {
    public static let shared = SecureKeychain()
    
    private let serviceName = "AsaMindMap.SecureStorage"
    private let accessGroup: String?
    
    private init() {
        // アプリグループを使用する場合のアクセスグループ設定
        self.accessGroup = nil // 単一アプリでの使用を想定
    }
    
    // MARK: - Public Interface
    
    public func store(key: String, data: Data) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    // 既存アイテムを削除
                    try await delete(key: key)
                } catch {
                    // 削除エラーは無視（アイテムが存在しない場合）
                }
                
                let query = buildQuery(for: key)
                var attributes = query
                attributes[kSecValueData] = data
                attributes[kSecAttrAccessible] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
                
                let status = SecItemAdd(attributes as CFDictionary, nil)
                
                if status == errSecSuccess {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: KeychainError.from(status))
                }
            }
        }
    }
    
    public func retrieve(key: String) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                let query = buildQuery(for: key)
                var queryWithReturn = query
                queryWithReturn[kSecMatchLimit] = kSecMatchLimitOne
                queryWithReturn[kSecReturnData] = true
                
                var result: AnyObject?
                let status = SecItemCopyMatching(queryWithReturn as CFDictionary, &result)
                
                if status == errSecSuccess,
                   let data = result as? Data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: KeychainError.from(status))
                }
            }
        }
    }
    
    public func update(key: String, data: Data) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                let query = buildQuery(for: key)
                let attributes: [CFString: Any] = [
                    kSecValueData: data
                ]
                
                let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
                
                if status == errSecSuccess {
                    continuation.resume()
                } else if status == errSecItemNotFound {
                    // アイテムが存在しない場合は新規作成
                    do {
                        try await store(key: key, data: data)
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                } else {
                    continuation.resume(throwing: KeychainError.from(status))
                }
            }
        }
    }
    
    public func delete(key: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                let query = buildQuery(for: key)
                let status = SecItemDelete(query as CFDictionary)
                
                if status == errSecSuccess || status == errSecItemNotFound {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: KeychainError.from(status))
                }
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func buildQuery(for key: String) -> [CFString: Any] {
        var query: [CFString: Any] = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrService: serviceName,
            kSecAttrAccount: key,
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup] = accessGroup
        }
        
        return query
    }
}

// MARK: - Keychain Error Handling

public enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case duplicateItem
    case invalidData
    case unexpectedError(OSStatus)
    
    static func from(_ status: OSStatus) -> KeychainError {
        switch status {
        case errSecItemNotFound:
            return .itemNotFound
        case errSecDuplicateItem:
            return .duplicateItem
        case errSecParam:
            return .invalidData
        default:
            return .unexpectedError(status)
        }
    }
    
    public var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "キーチェーンアイテムが見つかりません"
        case .duplicateItem:
            return "キーチェーンに重複するアイテムが存在します"
        case .invalidData:
            return "無効なデータです"
        case .unexpectedError(let status):
            return "予期しないキーチェーンエラー: \(status)"
        }
    }
}