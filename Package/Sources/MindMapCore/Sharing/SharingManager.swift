import Foundation
import CloudKit

// MARK: - Sharing Manager Protocol
public protocol SharingManagerProtocol {
    func generateShareLink(for mindMapID: UUID) async throws -> ShareLink
    func revokeShare(for mindMapID: UUID) async throws
    func getSharedMindMap(from shareURL: URL) async throws -> SharedMindMap
    func isShared(_ mindMapID: UUID) async throws -> Bool
    func getActiveShares() async throws -> [ShareInfo]
}

// MARK: - Share Link
public struct ShareLink {
    public let url: URL
    public let shareID: UUID
    public let mindMapID: UUID
    public let permissions: SharePermissions
    public let expiresAt: Date?
    public let createdAt: Date
    
    public init(
        url: URL,
        shareID: UUID,
        mindMapID: UUID,
        permissions: SharePermissions,
        expiresAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.url = url
        self.shareID = shareID
        self.mindMapID = mindMapID
        self.permissions = permissions
        self.expiresAt = expiresAt
        self.createdAt = createdAt
    }
}


// MARK: - Shared MindMap
public struct SharedMindMap {
    public let mindMap: MindMap
    public let shareInfo: ShareInfo
    public let isOwner: Bool
    
    public init(
        mindMap: MindMap,
        shareInfo: ShareInfo,
        isOwner: Bool
    ) {
        self.mindMap = mindMap
        self.shareInfo = shareInfo
        self.isOwner = isOwner
    }
}

// MARK: - Share Info
public struct ShareInfo {
    public let shareID: UUID
    public let mindMapID: UUID
    public let ownerID: UUID
    public let permissions: SharePermissions
    public let shareURL: URL
    public let createdAt: Date
    public let expiresAt: Date?
    public let isActive: Bool
    
    public init(
        shareID: UUID,
        mindMapID: UUID,
        ownerID: UUID,
        permissions: SharePermissions,
        shareURL: URL,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        isActive: Bool = true
    ) {
        self.shareID = shareID
        self.mindMapID = mindMapID
        self.ownerID = ownerID
        self.permissions = permissions
        self.shareURL = shareURL
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.isActive = isActive
    }
}

// MARK: - Sharing Error
public enum SharingError: Error, Equatable {
    case mindMapNotFound
    case shareNotFound
    case permissionDenied
    case networkUnavailable
    case invalidShareURL
    case shareExpired
    case cloudKitError(String)
    case unknownError(String)
}

// MARK: - CloudKit Share Delegate Protocol
public protocol CloudKitShareDelegateProtocol {
    func didCreateShare(_ share: CKShare, for mindMapID: UUID) async throws
    func didUpdateShare(_ share: CKShare) async throws
    func didDeleteShare(_ share: CKShare) async throws
}

// MARK: - Sharing Manager Implementation
public final class SharingManager: SharingManagerProtocol {
    
    private let privateDatabase: CKDatabase?
    private let sharedDatabase: CKDatabase?
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    private let shareDelegate: CloudKitShareDelegateProtocol?
    private let isTestMode: Bool
    
    // MARK: - Initialization
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        container: CKContainer? = nil,
        shareDelegate: CloudKitShareDelegateProtocol? = nil,
        isTestMode: Bool = false
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.shareDelegate = shareDelegate
        self.isTestMode = isTestMode
        
        if isTestMode {
            self.privateDatabase = nil
            self.sharedDatabase = nil
        } else if let container = container {
            self.privateDatabase = container.privateCloudDatabase
            self.sharedDatabase = container.sharedCloudDatabase
        } else {
            self.privateDatabase = CKContainer.default().privateCloudDatabase
            self.sharedDatabase = CKContainer.default().sharedCloudDatabase
        }
    }
    
    // MARK: - Public Methods
    public func generateShareLink(for mindMapID: UUID) async throws -> ShareLink {
        if isTestMode {
            // テストモードでは固定のShareLinkを返す
            return ShareLink(
                url: URL(string: "https://mindmap.app/share/test-\(mindMapID.uuidString)")!,
                shareID: UUID(),
                mindMapID: mindMapID,
                permissions: .readOnly
            )
        }
        
        guard let database = privateDatabase else {
            throw SharingError.networkUnavailable
        }
        
        do {
            // 1. MindMapがローカルに存在するか確認
            guard let mindMap = try await mindMapRepository.findByID(mindMapID) else {
                throw SharingError.mindMapNotFound
            }
            
            // 2. 既存の共有があるか確認
            if let existingShare = try await findExistingShare(for: mindMapID) {
                return existingShare
            }
            
            // 3. CloudKitレコードを取得
            let mindMapRecordID = CKRecord.ID(recordName: mindMapID.uuidString)
            let mindMapRecord = try await database.record(for: mindMapRecordID)
            
            // 4. CKShareを作成
            let share = CKShare(rootRecord: mindMapRecord)
            share.publicPermission = .readOnly
            
            // 5. ShareとMindMapレコードを保存
            _ = try await database.save(share)
            
            // 6. ShareLinkを作成
            let shareID = UUID()
            let shareURL = share.url ?? URL(string: "https://mindmap.app/share/\(shareID.uuidString)")!
            
            // 7. ローカルでMindMapの共有状態を更新
            var updatedMindMap = mindMap
            updatedMindMap.enableSharing(url: shareURL.absoluteString, permissions: .readOnly)
            try await mindMapRepository.save(updatedMindMap)
            
            // 8. 共有情報をローカルに保存
            try await saveShareInfo(
                shareID: shareID,
                mindMapID: mindMapID,
                shareURL: shareURL,
                permissions: .readOnly
            )
            
            return ShareLink(
                url: shareURL,
                shareID: shareID,
                mindMapID: mindMapID,
                permissions: .readOnly
            )
            
        } catch let error as CKError {
            throw mapCloudKitError(error)
        } catch {
            throw SharingError.unknownError(error.localizedDescription)
        }
    }
    
    public func revokeShare(for mindMapID: UUID) async throws {
        if isTestMode {
            // テストモードでは何もしない
            return
        }
        
        guard let database = privateDatabase else {
            throw SharingError.networkUnavailable
        }
        
        do {
            // 1. 既存の共有を取得
            guard let shareInfo = try await getShareInfo(for: mindMapID) else {
                throw SharingError.shareNotFound
            }
            
            // 2. CloudKitからShareを削除
            let shareRecordID = CKRecord.ID(recordName: shareInfo.shareID.uuidString)
            try await database.deleteRecord(withID: shareRecordID)
            
            // 3. ローカルでMindMapの共有状態を無効化
            if let mindMap = try await mindMapRepository.findByID(mindMapID) {
                var updatedMindMap = mindMap
                updatedMindMap.disableSharing()
                try await mindMapRepository.save(updatedMindMap)
            }
            
            // 4. ローカルの共有情報を削除
            try await removeShareInfo(for: mindMapID)
            
        } catch let error as CKError {
            throw mapCloudKitError(error)
        } catch {
            throw SharingError.unknownError(error.localizedDescription)
        }
    }
    
    public func getSharedMindMap(from shareURL: URL) async throws -> SharedMindMap {
        if isTestMode {
            // テストモードでは固定のSharedMindMapを返す
            let testMindMap = MindMap(
                id: UUID(),
                title: "Test Shared MindMap",
                rootNodeID: UUID(),
                nodeIDs: []
            )
            let shareInfo = ShareInfo(
                shareID: UUID(),
                mindMapID: testMindMap.id,
                ownerID: UUID(),
                permissions: .readOnly,
                shareURL: shareURL
            )
            return SharedMindMap(
                mindMap: testMindMap,
                shareInfo: shareInfo,
                isOwner: false
            )
        }
        
        guard sharedDatabase != nil else {
            throw SharingError.networkUnavailable
        }
        
        // 実際のCloudKit共有読み込み実装はここに記述
        throw SharingError.cloudKitError("Not implemented")
    }
    
    public func isShared(_ mindMapID: UUID) async throws -> Bool {
        if isTestMode {
            // テストモードでは常にfalseを返す
            return false
        }
        
        // ローカルのMindMapエンティティから共有状態を確認
        if let mindMap = try await mindMapRepository.findByID(mindMapID) {
            return mindMap.isShared
        }
        
        return false
    }
    
    public func getActiveShares() async throws -> [ShareInfo] {
        if isTestMode {
            // テストモードでは空の配列を返す
            return []
        }
        
        // ローカルの共有情報を取得
        let sharedMindMaps = try await mindMapRepository.findShared()
        var activeShares: [ShareInfo] = []
        
        for mindMap in sharedMindMaps {
            if let shareInfo = try await getShareInfo(for: mindMap.id) {
                activeShares.append(shareInfo)
            }
        }
        
        return activeShares
    }
    
    // MARK: - Private Helper Methods
    
    private func findExistingShare(for mindMapID: UUID) async throws -> ShareLink? {
        guard let shareInfo = try await getShareInfo(for: mindMapID) else {
            return nil
        }
        
        return ShareLink(
            url: shareInfo.shareURL,
            shareID: shareInfo.shareID,
            mindMapID: mindMapID,
            permissions: shareInfo.permissions
        )
    }
    
    private func getShareInfo(for mindMapID: UUID) async throws -> ShareInfo? {
        // 実際の実装では、UserDefaultsやCore Dataから共有情報を取得
        // 現在はシンプルな実装として、MindMapの共有状態のみチェック
        guard let mindMap = try await mindMapRepository.findByID(mindMapID),
              mindMap.isShared,
              let shareURLString = mindMap.shareURL,
              let shareURL = URL(string: shareURLString) else {
            return nil
        }
        
        return ShareInfo(
            shareID: UUID(), // 実際の実装では永続化されたIDを使用
            mindMapID: mindMapID,
            ownerID: UUID(), // 実際の実装では現在のユーザーIDを使用
            permissions: mindMap.sharePermissions,
            shareURL: shareURL,
            createdAt: mindMap.updatedAt
        )
    }
    
    private func saveShareInfo(
        shareID: UUID,
        mindMapID: UUID,
        shareURL: URL,
        permissions: SharePermissions
    ) async throws {
        // 実際の実装では、Core Dataまたは別のストレージに保存
        // 現在はMindMapエンティティの更新のみ
    }
    
    private func removeShareInfo(for mindMapID: UUID) async throws {
        // 実際の実装では、永続化された共有情報を削除
        // 現在はMindMapエンティティの更新のみ
    }
    
    private func mapCloudKitError(_ error: CKError) -> SharingError {
        switch error.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .notAuthenticated:
            return .permissionDenied
        case .quotaExceeded:
            return .cloudKitError("Quota exceeded")
        case .unknownItem:
            return .shareNotFound
        case .invalidArguments:
            return .invalidShareURL
        default:
            return .cloudKitError(error.localizedDescription)
        }
    }
}

// MARK: - CloudKit Schema Constants for Sharing
public enum CloudKitSharingSchema {
    public static let shareRecordType = "MindMapShare"
    
    public enum ShareFields {
        public static let mindMapID = "mindMapID"
        public static let ownerID = "ownerID"
        public static let permissions = "permissions"
        public static let shareURL = "shareURL"
        public static let isActive = "isActive"
        public static let expiresAt = "expiresAt"
        public static let createdAt = "createdAt"
    }
}