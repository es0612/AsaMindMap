import Foundation

// MARK: - Get Branch Progress Use Case Implementation
public final class GetBranchProgressUseCase: GetBranchProgressUseCaseProtocol {
    
    // MARK: - Dependencies
    private let nodeRepository: NodeRepositoryProtocol
    
    // MARK: - Initialization
    public init(nodeRepository: NodeRepositoryProtocol) {
        self.nodeRepository = nodeRepository
    }
    
    // MARK: - Public Methods
    public func execute(_ request: GetBranchProgressRequest) async throws -> GetBranchProgressResponse {
        // Get all nodes in the branch hierarchy
        let allNodes = try await nodeRepository.getNodeHierarchy(request.rootNodeID)
        
        // Filter task nodes
        let taskNodes = allNodes.filter { $0.isTask }
        let completedTasks = taskNodes.filter { $0.isCompleted }
        
        let totalTasks = taskNodes.count
        let completedTasksCount = completedTasks.count
        
        // Calculate progress percentage
        let progressPercentage: Double
        if totalTasks > 0 {
            progressPercentage = (Double(completedTasksCount) / Double(totalTasks)) * 100.0
        } else {
            progressPercentage = 0.0
        }
        
        return GetBranchProgressResponse(
            totalTasks: totalTasks,
            completedTasks: completedTasksCount,
            progressPercentage: progressPercentage
        )
    }
}