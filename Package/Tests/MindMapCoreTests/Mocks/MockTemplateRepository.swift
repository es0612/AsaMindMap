import Foundation
@testable import MindMapCore

public class MockTemplateRepository: TemplateRepositoryProtocol {
    public var templates: [UUID: Template] = [:]
    
    // Call tracking
    public var saveCallCount = 0
    public var fetchCallCount = 0
    public var fetchByIdCallCount = 0
    public var updateCallCount = 0
    public var deleteCallCount = 0
    public var fetchByCategoryCallCount = 0
    
    // Error simulation
    public var shouldThrowError = false
    public var errorToThrow: Error = TemplateError.templateNotFound
    
    public init() {}
    
    public func save(_ template: Template) async throws {
        saveCallCount += 1
        if shouldThrowError { throw errorToThrow }
        templates[template.id] = template
    }
    
    public func fetchAll() async throws -> [Template] {
        fetchCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return Array(templates.values)
    }
    
    public func fetchById(_ id: UUID) async throws -> Template? {
        fetchByIdCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return templates[id]
    }
    
    public func fetchByCategory(_ category: TemplateCategory) async throws -> [Template] {
        fetchByCategoryCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return templates.values.filter { $0.category == category }
    }
    
    public func update(_ template: Template) async throws {
        updateCallCount += 1
        if shouldThrowError { throw errorToThrow }
        guard templates[template.id] != nil else {
            throw TemplateError.templateNotFound
        }
        templates[template.id] = template
    }
    
    public func delete(id: UUID) async throws {
        deleteCallCount += 1
        if shouldThrowError { throw errorToThrow }
        guard let template = templates[id] else {
            throw TemplateError.templateNotFound
        }
        if template.isPreset {
            throw TemplateError.cannotDeletePreset
        }
        templates.removeValue(forKey: id)
    }
    
    public func fetchPresets() async throws -> [Template] {
        fetchCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return templates.values.filter { $0.isPreset }
    }
    
    public func fetchUserTemplates() async throws -> [Template] {
        fetchCallCount += 1
        if shouldThrowError { throw errorToThrow }
        return templates.values.filter { !$0.isPreset }
    }
    
    // Test helper methods
    public func setupTemplates() {
        let businessTemplate = Template(
            title: "プロジェクト企画",
            description: "新規プロジェクトの企画書作成用",
            category: .business,
            isPreset: true
        )
        
        let educationTemplate = Template(
            title: "授業ノート",
            description: "講義内容整理用テンプレート",
            category: .education,
            isPreset: true
        )
        
        let customTemplate = Template(
            title: "カスタムテンプレート",
            description: "ユーザー作成のテンプレート",
            category: .personal,
            isPreset: false
        )
        
        templates[businessTemplate.id] = businessTemplate
        templates[educationTemplate.id] = educationTemplate
        templates[customTemplate.id] = customTemplate
    }
    
    public func clearAll() {
        templates.removeAll()
        resetCallCounts()
    }
    
    public func resetCallCounts() {
        saveCallCount = 0
        fetchCallCount = 0
        fetchByIdCallCount = 0
        updateCallCount = 0
        deleteCallCount = 0
        fetchByCategoryCallCount = 0
    }
}