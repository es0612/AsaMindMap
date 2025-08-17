import Foundation

// MARK: - Tag Entity
public struct Tag: Identifiable, Equatable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var color: NodeColor
    public var description: String?
    public let createdAt: Date
    public var updatedAt: Date
    
    // MARK: - Initialization
    public init(
        id: UUID = UUID(),
        name: String,
        color: NodeColor = .accent,
        description: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.description = description
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    public var displayName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public var hasDescription: Bool {
        description != nil && !description!.isEmpty
    }
    
    // MARK: - Mutating Methods
    public mutating func updateName(_ newName: String) {
        name = newName
        updatedAt = Date()
    }
    
    public mutating func updateColor(_ newColor: NodeColor) {
        color = newColor
        updatedAt = Date()
    }
    
    public mutating func updateDescription(_ newDescription: String?) {
        description = newDescription
        updatedAt = Date()
    }
    
    // MARK: - Hashable
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}