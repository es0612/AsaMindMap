import Foundation

// MARK: - Request/Response Models

public struct CreateTemplateRequest: Sendable {
    public let title: String
    public let description: String
    public let category: TemplateCategory
    public let isPreset: Bool
    
    public init(title: String, description: String, category: TemplateCategory, isPreset: Bool = false) {
        self.title = title
        self.description = description
        self.category = category
        self.isPreset = isPreset
    }
}

public struct CreateTemplateResponse: Sendable {
    public let template: Template
    
    public init(template: Template) {
        self.template = template
    }
}

public struct FetchTemplatesRequest: Sendable {
    public let category: TemplateCategory?
    public let includePresets: Bool
    public let sortBy: TemplateSortOrder
    
    public init(category: TemplateCategory? = nil, includePresets: Bool = true, sortBy: TemplateSortOrder = .title) {
        self.category = category
        self.includePresets = includePresets
        self.sortBy = sortBy
    }
}

public enum TemplateSortOrder: String, CaseIterable, Sendable {
    case title = "title"
    case createdDate = "createdDate"
    case updatedDate = "updatedDate"
    case category = "category"
}

public struct FetchTemplatesResponse: Sendable {
    public let templates: [Template]
    
    public init(templates: [Template]) {
        self.templates = templates
    }
}

public struct ApplyTemplateRequest: Sendable {
    public let templateId: UUID
    public let mindMapTitle: String
    public let placeholderReplacements: [String: String]
    
    public init(templateId: UUID, mindMapTitle: String, placeholderReplacements: [String: String] = [:]) {
        self.templateId = templateId
        self.mindMapTitle = mindMapTitle
        self.placeholderReplacements = placeholderReplacements
    }
}

public struct ApplyTemplateResponse: Sendable {
    public let mindMap: MindMap
    
    public init(mindMap: MindMap) {
        self.mindMap = mindMap
    }
}

public struct UpdateTemplateRequest: Sendable {
    public let templateId: UUID
    public let title: String?
    public let description: String?
    public let category: TemplateCategory?
    
    public init(templateId: UUID, title: String? = nil, description: String? = nil, category: TemplateCategory? = nil) {
        self.templateId = templateId
        self.title = title
        self.description = description
        self.category = category
    }
}

public struct UpdateTemplateResponse: Sendable {
    public let template: Template
    
    public init(template: Template) {
        self.template = template
    }
}

public struct DeleteTemplateRequest: Sendable {
    public let templateId: UUID
    
    public init(templateId: UUID) {
        self.templateId = templateId
    }
}

public struct DeleteTemplateResponse: Sendable {
    public let success: Bool
    
    public init(success: Bool) {
        self.success = success
    }
}

public struct DuplicateTemplateRequest: Sendable {
    public let templateId: UUID
    public let newTitle: String
    
    public init(templateId: UUID, newTitle: String) {
        self.templateId = templateId
        self.newTitle = newTitle
    }
}

public struct DuplicateTemplateResponse: Sendable {
    public let template: Template
    
    public init(template: Template) {
        self.template = template
    }
}

// MARK: - Use Case Protocols

public protocol CreateTemplateUseCaseProtocol: Sendable {
    func execute(_ request: CreateTemplateRequest) async throws -> CreateTemplateResponse
}

public protocol FetchTemplatesUseCaseProtocol: Sendable {
    func execute(_ request: FetchTemplatesRequest) async throws -> FetchTemplatesResponse
}

public protocol ApplyTemplateUseCaseProtocol: Sendable {
    func execute(_ request: ApplyTemplateRequest) async throws -> ApplyTemplateResponse
}

public protocol UpdateTemplateUseCaseProtocol: Sendable {
    func execute(_ request: UpdateTemplateRequest) async throws -> UpdateTemplateResponse
}

public protocol DeleteTemplateUseCaseProtocol: Sendable {
    func execute(_ request: DeleteTemplateRequest) async throws -> DeleteTemplateResponse
}

public protocol DuplicateTemplateUseCaseProtocol: Sendable {
    func execute(_ request: DuplicateTemplateRequest) async throws -> DuplicateTemplateResponse
}

// MARK: - Use Case Implementations

public struct CreateTemplateUseCase: CreateTemplateUseCaseProtocol {
    private let repository: TemplateRepositoryProtocol
    
    public init(repository: TemplateRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: CreateTemplateRequest) async throws -> CreateTemplateResponse {
        let template = Template(
            title: request.title,
            description: request.description,
            category: request.category,
            isPreset: request.isPreset
        )
        
        try await repository.save(template)
        return CreateTemplateResponse(template: template)
    }
}

public struct FetchTemplatesUseCase: FetchTemplatesUseCaseProtocol {
    private let repository: TemplateRepositoryProtocol
    
    public init(repository: TemplateRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: FetchTemplatesRequest) async throws -> FetchTemplatesResponse {
        var templates: [Template]
        
        if let category = request.category {
            templates = try await repository.fetchByCategory(category)
        } else {
            templates = try await repository.fetchAll()
        }
        
        if !request.includePresets {
            templates = templates.filter { !$0.isPreset }
        }
        
        // Sort templates
        templates.sort { lhs, rhs in
            switch request.sortBy {
            case .title:
                return lhs.title < rhs.title
            case .createdDate:
                return lhs.createdAt > rhs.createdAt
            case .updatedDate:
                return lhs.updatedAt > rhs.updatedAt
            case .category:
                return lhs.category.displayName < rhs.category.displayName
            }
        }
        
        return FetchTemplatesResponse(templates: templates)
    }
}

public struct ApplyTemplateUseCase: ApplyTemplateUseCaseProtocol {
    private let templateRepository: TemplateRepositoryProtocol
    private let mindMapRepository: MindMapRepositoryProtocol
    
    public init(templateRepository: TemplateRepositoryProtocol, mindMapRepository: MindMapRepositoryProtocol) {
        self.templateRepository = templateRepository
        self.mindMapRepository = mindMapRepository
    }
    
    public func execute(_ request: ApplyTemplateRequest) async throws -> ApplyTemplateResponse {
        guard let template = try await templateRepository.fetchById(request.templateId) else {
            throw TemplateError.templateNotFound
        }
        
        let mindMap = template.createMindMap(title: request.mindMapTitle)
        try await mindMapRepository.save(mindMap)
        
        return ApplyTemplateResponse(mindMap: mindMap)
    }
}

public struct UpdateTemplateUseCase: UpdateTemplateUseCaseProtocol {
    private let repository: TemplateRepositoryProtocol
    
    public init(repository: TemplateRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: UpdateTemplateRequest) async throws -> UpdateTemplateResponse {
        guard var template = try await repository.fetchById(request.templateId) else {
            throw TemplateError.templateNotFound
        }
        
        if template.isPreset {
            throw TemplateError.cannotDeletePreset
        }
        
        if let title = request.title {
            template.title = title
        }
        
        if let description = request.description {
            template.description = description
        }
        
        if let category = request.category {
            template.category = category
        }
        
        template.updatedAt = Date()
        try await repository.update(template)
        
        return UpdateTemplateResponse(template: template)
    }
}

public struct DeleteTemplateUseCase: DeleteTemplateUseCaseProtocol {
    private let repository: TemplateRepositoryProtocol
    
    public init(repository: TemplateRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: DeleteTemplateRequest) async throws -> DeleteTemplateResponse {
        try await repository.delete(id: request.templateId)
        return DeleteTemplateResponse(success: true)
    }
}

public struct DuplicateTemplateUseCase: DuplicateTemplateUseCaseProtocol {
    private let repository: TemplateRepositoryProtocol
    
    public init(repository: TemplateRepositoryProtocol) {
        self.repository = repository
    }
    
    public func execute(_ request: DuplicateTemplateRequest) async throws -> DuplicateTemplateResponse {
        guard let originalTemplate = try await repository.fetchById(request.templateId) else {
            throw TemplateError.templateNotFound
        }
        
        let duplicatedTemplate = Template(
            title: request.newTitle,
            description: originalTemplate.description,
            category: originalTemplate.category,
            isPreset: false // Duplicates are always custom templates
        )
        
        try await repository.save(duplicatedTemplate)
        return DuplicateTemplateResponse(template: duplicatedTemplate)
    }
}