import Foundation

// MARK: - Create Tag Use Case Implementation
public final class CreateTagUseCase: CreateTagUseCaseProtocol {
    
    // MARK: - Dependencies
    private let tagRepository: TagRepositoryProtocol
    
    // MARK: - Initialization
    public init(tagRepository: TagRepositoryProtocol) {
        self.tagRepository = tagRepository
    }
    
    // MARK: - Public Methods
    public func execute(_ request: CreateTagRequest) async throws -> CreateTagResponse {
        // Validate tag name
        let trimmedName = request.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw TagError.invalidName
        }
        
        // Check for duplicate tag names
        let existingTags = try await tagRepository.findByName(trimmedName)
        if existingTags.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            throw TagError.duplicateTag
        }
        
        // Create new tag
        let tag = Tag(
            name: trimmedName,
            color: request.color,
            description: request.description
        )
        
        // Save tag
        try await tagRepository.save(tag)
        
        return CreateTagResponse(tag: tag)
    }
}