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
        
        // Register core dependencies here
        // This will be expanded as we implement more modules
        
        return container
    }
}