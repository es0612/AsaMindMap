import Foundation

// MARK: - DI Container Protocol
public protocol DIContainerProtocol {
    func resolve<T>(_ type: T.Type) -> T
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, instance: T)
}

// MARK: - DI Container Implementation
public final class DIContainer: DIContainerProtocol {
    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    
    public init() {}
    
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    public func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        singletons[key] = instance
    }
    
    public func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        // Check singletons first
        if let singleton = singletons[key] as? T {
            return singleton
        }
        
        // Then check factories
        guard let factory = factories[key] else {
            fatalError("Type \(type) not registered in DI container")
        }
        
        guard let instance = factory() as? T else {
            fatalError("Failed to cast resolved instance to \(type)")
        }
        
        return instance
    }
}

// MARK: - DI Container Configuration
extension DIContainer {
    public static func configure() -> DIContainer {
        let container = DIContainer()
        
        // Register validators
        container.register(NodeValidator.self) {
            NodeValidator()
        }
        
        container.register(MindMapValidator.self) {
            MindMapValidator()
        }
        
        // Register domain services (will be implemented with repositories)
        // These will be registered when repository implementations are available
        
        return container
    }
    
    // MARK: - Domain Layer Registration
    public func registerDomainServices(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        mediaRepository: MediaRepositoryProtocol,
        tagRepository: TagRepositoryProtocol
    ) {
        // Register repositories
        register(MindMapRepositoryProtocol.self, instance: mindMapRepository)
        register(NodeRepositoryProtocol.self, instance: nodeRepository)
        register(MediaRepositoryProtocol.self, instance: mediaRepository)
        register(TagRepositoryProtocol.self, instance: tagRepository)
        
        // Register domain services
        register(MindMapDomainServiceProtocol.self) {
            MindMapDomainService(
                mindMapRepository: self.resolve(MindMapRepositoryProtocol.self),
                nodeRepository: self.resolve(NodeRepositoryProtocol.self),
                mindMapValidator: self.resolve(MindMapValidator.self),
                nodeValidator: self.resolve(NodeValidator.self)
            )
        }
        
        register(NodeHierarchyServiceProtocol.self) {
            NodeHierarchyService(
                nodeRepository: self.resolve(NodeRepositoryProtocol.self)
            )
        }
        
        register(NodeManagementServiceProtocol.self) {
            NodeManagementService(
                nodeRepository: self.resolve(NodeRepositoryProtocol.self),
                nodeValidator: self.resolve(NodeValidator.self)
            )
        }
        
        register(TagManagementServiceProtocol.self) {
            TagManagementService(
                tagRepository: self.resolve(TagRepositoryProtocol.self),
                nodeRepository: self.resolve(NodeRepositoryProtocol.self)
            )
        }
        
        // Register media use cases
        register(AddMediaToNodeUseCaseProtocol.self) {
            AddMediaToNodeUseCase(
                nodeRepository: self.resolve(NodeRepositoryProtocol.self),
                mediaRepository: self.resolve(MediaRepositoryProtocol.self)
            )
        }
        
        register(RemoveMediaFromNodeUseCaseProtocol.self) {
            RemoveMediaFromNodeUseCase(
                nodeRepository: self.resolve(NodeRepositoryProtocol.self),
                mediaRepository: self.resolve(MediaRepositoryProtocol.self)
            )
        }
        
        register(GetNodeMediaUseCaseProtocol.self) {
            GetNodeMediaUseCase(
                nodeRepository: self.resolve(NodeRepositoryProtocol.self),
                mediaRepository: self.resolve(MediaRepositoryProtocol.self)
            )
        }
        
        register(ValidateMediaURLUseCaseProtocol.self) {
            ValidateMediaURLUseCase()
        }
    }
}