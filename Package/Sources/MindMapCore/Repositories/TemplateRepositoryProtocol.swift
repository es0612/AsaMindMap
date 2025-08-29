import Foundation

public protocol TemplateRepositoryProtocol: Sendable {
    func save(_ template: Template) async throws
    func fetchAll() async throws -> [Template]
    func fetchById(_ id: UUID) async throws -> Template?
    func fetchByCategory(_ category: TemplateCategory) async throws -> [Template]
    func update(_ template: Template) async throws
    func delete(id: UUID) async throws
    func fetchPresets() async throws -> [Template]
    func fetchUserTemplates() async throws -> [Template]
}