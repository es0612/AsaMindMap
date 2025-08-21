import Foundation

// MARK: - Get All Tags Use Case Implementation
public final class GetAllTagsUseCase: GetAllTagsUseCaseProtocol {
    
    // MARK: - Dependencies
    private let tagRepository: TagRepositoryProtocol
    
    // MARK: - Initialization
    public init(tagRepository: TagRepositoryProtocol) {
        self.tagRepository = tagRepository
    }
    
    // MARK: - Public Methods
    public func execute() async throws -> GetAllTagsResponse {
        let tags = try await tagRepository.findAll()
        return GetAllTagsResponse(tags: tags)
    }
}