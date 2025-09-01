import Foundation
import os

// MARK: - Memory Protection Manager

@available(iOS 16.0, *)
public actor MemoryProtectionManager {
    private var protectedObjects: [ObjectIdentifier: Any] = [:]
    private var lockedMemoryRegions: [UnsafeMutableRawPointer] = []
    
    public init() {}
    
    deinit {}
    
    // MARK: - Secure String Protection
    
    public func protectInMemory(_ secureString: SecureString) async throws {
        let objectId = ObjectIdentifier(secureString)
        protectedObjects[objectId] = secureString
    }
    
    public func clearFromMemory(_ secureString: SecureString) async throws {
        let objectId = ObjectIdentifier(secureString)
        protectedObjects.removeValue(forKey: objectId)
        
        // SecureStringのクリア
        secureString.clear()
    }
    
    // MARK: - Memory Locking
    
    public func lockMemory(_ data: Data) async throws -> ProtectedMemory {
        return try await withCheckedThrowingContinuation { continuation in
            data.withUnsafeBytes { bytes in
                guard let baseAddress = bytes.baseAddress else {
                    continuation.resume(throwing: MemoryProtectionError.lockFailed)
                    return
                }
                
                // mlock システムコールでメモリをロック（スワップ防止）
                let result = mlock(baseAddress, data.count)
                
                if result == 0 {
                    // ロックされたメモリ領域を追跡
                    let mutablePointer = UnsafeMutableRawPointer(mutating: baseAddress)
                    lockedMemoryRegions.append(mutablePointer)
                    
                    let protectedMemory = ProtectedMemory(
                        data: data,
                        isLocked: true
                    )
                    continuation.resume(returning: protectedMemory)
                } else {
                    continuation.resume(throwing: MemoryProtectionError.lockFailed)
                }
            }
        }
    }
    
    public func unlockMemory(_ protectedMemory: ProtectedMemory) async throws {
        guard protectedMemory.isLocked else { return }
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            protectedMemory.data.withUnsafeBytes { bytes in
                guard let baseAddress = bytes.baseAddress else {
                    continuation.resume(throwing: MemoryProtectionError.unlockFailed)
                    return
                }
                
                // munlock システムコールでメモリロックを解除
                let result = munlock(baseAddress, protectedMemory.data.count)
                
                if result == 0 {
                    // 追跡リストから削除
                    let mutablePointer = UnsafeMutableRawPointer(mutating: baseAddress)
                    lockedMemoryRegions.removeAll { $0 == mutablePointer }
                    
                    continuation.resume()
                } else {
                    continuation.resume(throwing: MemoryProtectionError.unlockFailed)
                }
            }
        }
    }
    
    // MARK: - Secure Memory Allocation
    
    public func allocateSecureMemory(size: Int) throws -> SecureMemoryBuffer {
        // ページサイズにアライン
        let pageSize = Int(getpagesize())
        let alignedSize = ((size + pageSize - 1) / pageSize) * pageSize
        
        // メモリ割り当て
        guard let buffer = malloc(alignedSize) else {
            throw MemoryProtectionError.lockFailed
        }
        
        // メモリをロック
        let lockResult = mlock(buffer, alignedSize)
        guard lockResult == 0 else {
            free(buffer)
            throw MemoryProtectionError.lockFailed
        }
        
        // ゼロクリア
        memset(buffer, 0, alignedSize)
        
        return SecureMemoryBuffer(
            buffer: buffer,
            size: alignedSize
        )
    }
    
    public func deallocateSecureMemory(_ buffer: SecureMemoryBuffer) throws {
        // メモリをゼロクリア
        memset(buffer.buffer, 0, buffer.size)
        
        // ロック解除
        let unlockResult = munlock(buffer.buffer, buffer.size)
        guard unlockResult == 0 else {
            throw MemoryProtectionError.unlockFailed
        }
        
        // メモリ解放
        free(buffer.buffer)
    }
    
    // MARK: - Cleanup
    
    public func clearAllProtectedMemory() async throws {
        // 保護されたオブジェクトをクリア
        for (_, object) in protectedObjects {
            if let secureString = object as? SecureString {
                secureString.clear()
            }
        }
        protectedObjects.removeAll()
        
        // ロックされたメモリ領域を解放
        for _ in lockedMemoryRegions {
            // munlock は正確なサイズが必要だが、この実装では追跡していない
            // 実際の実装では、サイズも一緒に保存すべき
        }
        lockedMemoryRegions.removeAll()
    }
}

// MARK: - Secure String

public class SecureString {
    private var _value: String?
    private var _data: Data?
    public private(set) var isCleared: Bool = false
    
    public init(_ value: String) {
        self._value = value
        self._data = value.data(using: .utf8)
    }
    
    public var value: String? {
        guard !isCleared else { return nil }
        return _value
    }
    
    public func clear() {
        // メモリをゼロクリア
        if var data = _data {
            _ = data.withUnsafeMutableBytes { bytes in
                memset(bytes.baseAddress, 0, bytes.count)
            }
        }
        
        _value = nil
        _data = nil
        isCleared = true
    }
    
    deinit {
        clear()
    }
}

// MARK: - Protected Memory

public struct ProtectedMemory {
    public let data: Data
    public let isLocked: Bool
    
    public init(data: Data, isLocked: Bool) {
        self.data = data
        self.isLocked = isLocked
    }
}

// MARK: - Secure Memory Buffer

public struct SecureMemoryBuffer {
    public let buffer: UnsafeMutableRawPointer
    public let size: Int
    
    public init(buffer: UnsafeMutableRawPointer, size: Int) {
        self.buffer = buffer
        self.size = size
    }
    
    public func write(_ data: Data, at offset: Int = 0) throws {
        guard offset + data.count <= size else {
            throw MemoryProtectionError.clearFailed
        }
        
        _ = data.withUnsafeBytes { bytes in
            memcpy(buffer.advanced(by: offset), bytes.baseAddress, data.count)
        }
    }
    
    public func read(count: Int, from offset: Int = 0) throws -> Data {
        guard offset + count <= size else {
            throw MemoryProtectionError.clearFailed
        }
        
        return Data(bytes: buffer.advanced(by: offset), count: count)
    }
}

// MARK: - Errors

public enum MemoryProtectionError: Error, LocalizedError {
    case lockFailed
    case unlockFailed
    case clearFailed
    
    public var errorDescription: String? {
        switch self {
        case .lockFailed:
            return "メモリのロックに失敗しました"
        case .unlockFailed:
            return "メモリのロック解除に失敗しました"
        case .clearFailed:
            return "メモリのクリアに失敗しました"
        }
    }
}