import Foundation

// MARK: - Update MindMap Use Case Implementation
public final class UpdateMindMapUseCase: UpdateMindMapUseCaseProtocol {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let mindMapValidator: MindMapValidator
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        mindMapValidator: MindMapValidator = MindMapValidator()
    ) {
        self.mindMapRepository = mindMapRepository
        self.mindMapValidator = mindMapValidator
    }
    
    public func execute(_ request: UpdateMindMapRequest) async throws -> UpdateMindMapResponse {
        // 1. MindMapの存在確認
        guard var mindMap = try await mindMapRepository.findByID(request.mindMapID) else {
            throw MindMapError.validationError("指定されたマインドマップが見つかりません")
        }
        
        // 2. MindMapの更新
        var hasChanges = false
        
        if let title = request.title {
            mindMap.updateTitle(title)
            hasChanges = true
        }
        
        if let sharePermissions = request.sharePermissions {
            mindMap.sharePermissions = sharePermissions
            mindMap.updatedAt = Date()
            mindMap.version += 1
            hasChanges = true
        }
        
        // 3. 変更がない場合は早期リターン
        guard hasChanges else {
            return UpdateMindMapResponse(mindMap: mindMap)
        }
        
        // 4. バリデーション
        let validationResult = mindMapValidator.validate(mindMap)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "マインドマップの更新に失敗しました")
        }
        
        // 5. データの保存
        try await mindMapRepository.save(mindMap)
        
        return UpdateMindMapResponse(mindMap: mindMap)
    }
}