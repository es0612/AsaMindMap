import Foundation
import LocalAuthentication

// MARK: - Biometric Authenticator

@available(iOS 13.0, *)
public final class BiometricAuthenticator: @unchecked Sendable {
    private let context = LAContext()
    private let keychain = SecureKeychain.shared
    
    public init() {}
    
    // MARK: - Public Interface
    
    public var isBiometricAvailable: Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public var biometricType: LABiometryType {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return context.biometryType
    }
    
    public func authenticateWithBiometrics(
        reason: String,
        fallbackTitle: String? = nil
    ) async throws -> BiometricResult {
        // 生体認証が利用可能かチェック
        guard isBiometricAvailable else {
            throw BiometricError.notAvailable
        }
        
        // コンテキスト設定
        context.localizedFallbackTitle = fallbackTitle
        
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { [weak self] success, error in
                Task {
                    if success {
                        // 認証成功時のトークン生成
                        let authToken = try? await self?.generateAuthToken()
                        let result = BiometricResult(
                            success: true,
                            authToken: authToken
                        )
                        continuation.resume(returning: result)
                    } else if let error = error {
                        let biometricError = self?.mapLAError(error) ?? BiometricError.authenticationFailed
                        continuation.resume(throwing: biometricError)
                    } else {
                        continuation.resume(throwing: BiometricError.authenticationFailed)
                    }
                }
            }
        }
    }
    
    public func authenticateWithPasscode(
        reason: String
    ) async throws -> BiometricResult {
        return try await withCheckedThrowingContinuation { continuation in
            context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            ) { [weak self] success, error in
                Task {
                    if success {
                        let authToken = try? await self?.generateAuthToken()
                        let result = BiometricResult(
                            success: true,
                            authToken: authToken
                        )
                        continuation.resume(returning: result)
                    } else if let error = error {
                        let biometricError = self?.mapLAError(error) ?? BiometricError.authenticationFailed
                        continuation.resume(throwing: biometricError)
                    } else {
                        continuation.resume(throwing: BiometricError.authenticationFailed)
                    }
                }
            }
        }
    }
    
    // MARK: - Token Management
    
    private func generateAuthToken() async throws -> String {
        let tokenData = UUID().uuidString + "_" + Date().timeIntervalSince1970.description
        let token = tokenData.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        
        // トークンを一時的にキーチェーンに保存
        let tokenKey = "BiometricAuthToken_\(Date().timeIntervalSince1970)"
        if let tokenData = token.data(using: .utf8) {
            try await keychain.store(key: tokenKey, data: tokenData)
            
            // 30分後にトークンを削除
            Task {
                try await Task.sleep(nanoseconds: 30 * 60 * 1_000_000_000) // 30分
                try? await keychain.delete(key: tokenKey)
            }
        }
        
        return token
    }
    
    public func validateAuthToken(_ token: String) async throws -> Bool {
        // 実際の実装では、トークンの有効性とタイムスタンプを検証
        // 簡略化された実装
        return !token.isEmpty && token.contains("_")
    }
    
    // MARK: - Error Mapping
    
    private func mapLAError(_ error: Error) -> BiometricError {
        guard let laError = error as? LAError else {
            return .authenticationFailed
        }
        
        switch laError.code {
        case .biometryNotAvailable:
            return .notAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        case .userCancel:
            return .userCancel
        case .systemCancel:
            return .systemCancel
        case .authenticationFailed:
            return .authenticationFailed
        default:
            return .authenticationFailed
        }
    }
}

// MARK: - Models

public struct BiometricResult {
    public let success: Bool
    public let authToken: String?
    
    public init(success: Bool, authToken: String?) {
        self.success = success
        self.authToken = authToken
    }
}

// MARK: - Errors

public enum BiometricError: Error, LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancel
    case systemCancel
    
    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "生体認証が利用できません"
        case .notEnrolled:
            return "生体認証が設定されていません"
        case .authenticationFailed:
            return "認証に失敗しました"
        case .userCancel:
            return "ユーザーによってキャンセルされました"
        case .systemCancel:
            return "システムによってキャンセルされました"
        }
    }
}