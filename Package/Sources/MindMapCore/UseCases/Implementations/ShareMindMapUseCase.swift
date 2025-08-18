import Foundation

// MARK: - Share MindMap Use Case Implementation
public final class ShareMindMapUseCase: ShareMindMapUseCaseProtocol {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let mindMapValidator: MindMapValidator
    private let shareURLGenerator: ShareURLGeneratorProtocol
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        mindMapValidator: MindMapValidator = MindMapValidator(),
        shareURLGenerator: ShareURLGeneratorProtocol
    ) {
        self.mindMapRepository = mindMapRepository
        self.mindMapValidator = mindMapValidator
        self.shareURLGenerator = shareURLGenerator
    }
    
    public func execute(_ request: ShareMindMapRequest) async throws -> ShareMindMapResponse {
        // 1. MindMapの存在確認
        guard var mindMap = try await mindMapRepository.findByID(request.mindMapID) else {
            throw MindMapError.validationError("指定されたマインドマップが見つかりません")
        }
        
        // 2. 共有可能かどうかのバリデーション
        let validationResult = mindMapValidator.validateForSharing(mindMap)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "マインドマップを共有できません")
        }
        
        // 3. 共有URLの生成
        let shareURL = try await shareURLGenerator.generateShareURL(
            mindMapID: request.mindMapID,
            permissions: request.permissions
        )
        
        // 4. MindMapの共有設定を更新
        mindMap.enableSharing(url: shareURL, permissions: request.permissions)
        
        // 5. データの保存
        try await mindMapRepository.save(mindMap)
        
        return ShareMindMapResponse(mindMap: mindMap, shareURL: shareURL)
    }
}

// MARK: - Share URL Generator Protocol
public protocol ShareURLGeneratorProtocol {
    func generateShareURL(mindMapID: UUID, permissions: SharePermissions) async throws -> String
}

// MARK: - Default Share URL Generator
public final class DefaultShareURLGenerator: ShareURLGeneratorProtocol {
    private let baseURL: String
    
    public init(baseURL: String = "https://asamindmap.app/shared") {
        self.baseURL = baseURL
    }
    
    public func generateShareURL(mindMapID: UUID, permissions: SharePermissions) async throws -> String {
        // 共有トークンの生成（実際の実装では暗号化されたトークンを使用）
        let shareToken = generateShareToken(mindMapID: mindMapID, permissions: permissions)
        return "\(baseURL)/\(shareToken)"
    }
    
    private func generateShareToken(mindMapID: UUID, permissions: SharePermissions) -> String {
        // 簡単な実装例（実際にはより安全な方法を使用）
        let timestamp = Date().timeIntervalSince1970
        let tokenData = "\(mindMapID.uuidString):\(permissions.rawValue):\(timestamp)"
        return tokenData.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
    }
}