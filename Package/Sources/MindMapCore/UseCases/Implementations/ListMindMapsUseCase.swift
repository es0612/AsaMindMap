import Foundation

// MARK: - List MindMaps Use Case Implementation
public final class ListMindMapsUseCase: ListMindMapsUseCaseProtocol {
    private let mindMapRepository: MindMapRepositoryProtocol
    
    public init(mindMapRepository: MindMapRepositoryProtocol) {
        self.mindMapRepository = mindMapRepository
    }
    
    public func execute(_ request: ListMindMapsRequest) async throws -> ListMindMapsResponse {
        // 1. 全てのMindMapを取得
        var mindMaps = try await mindMapRepository.findAll()
        
        // 2. 共有マインドマップのフィルタリング
        if !request.includeShared {
            mindMaps = mindMaps.filter { !$0.isShared }
        }
        
        // 3. ソート
        mindMaps = sortMindMaps(mindMaps, by: request.sortBy)
        
        // 4. 制限の適用
        if let limit = request.limit {
            mindMaps = Array(mindMaps.prefix(limit))
        }
        
        return ListMindMapsResponse(mindMaps: mindMaps)
    }
    
    // MARK: - Private Methods
    private func sortMindMaps(_ mindMaps: [MindMap], by sortOption: MindMapSortOption) -> [MindMap] {
        switch sortOption {
        case .createdAt:
            return mindMaps.sorted { $0.createdAt > $1.createdAt }
        case .updatedAt:
            return mindMaps.sorted { $0.updatedAt > $1.updatedAt }
        case .title:
            return mindMaps.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .nodeCount:
            return mindMaps.sorted { $0.nodeCount > $1.nodeCount }
        }
    }
}