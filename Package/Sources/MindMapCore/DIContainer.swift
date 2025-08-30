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
        
        // Register I18n services
        container.registerI18nServices()
        
        // Register Enterprise services
        container.registerEnterpriseServices()
        
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
    
    // MARK: - I18n Services Registration
    public func registerI18nServices() {
        // Register LocalizationManager as singleton
        register(LocalizationManager.self, instance: LocalizationManager())
        
        // Register RTLLayoutManager as singleton
        register(RTLLayoutManager.self, instance: RTLLayoutManager())
        
        // Register CulturalAdaptationService as singleton
        register(CulturalAdaptationService.self, instance: CulturalAdaptationService())
        
        // Register I18n Use Cases
        register(LocalizationUseCaseProtocol.self) {
            LocalizationUseCase(
                localizationManager: self.resolve(LocalizationManager.self)
            )
        }
        
        register(RTLLayoutUseCaseProtocol.self) {
            RTLLayoutUseCase(
                rtlLayoutManager: self.resolve(RTLLayoutManager.self),
                localizationManager: self.resolve(LocalizationManager.self)
            )
        }
        
        register(CulturalAdaptationUseCaseProtocol.self) {
            CulturalAdaptationUseCase(
                culturalAdaptationService: self.resolve(CulturalAdaptationService.self),
                localizationManager: self.resolve(LocalizationManager.self)
            )
        }
        
        register(I18nUseCaseProtocol.self) {
            I18nUseCase(
                localization: self.resolve(LocalizationUseCaseProtocol.self),
                rtlLayout: self.resolve(RTLLayoutUseCaseProtocol.self),
                culturalAdaptation: self.resolve(CulturalAdaptationUseCaseProtocol.self)
            )
        }
    }
    
    // MARK: - Enterprise Services Registration
    public func registerEnterpriseServices() {
        // Register Authentication Services
        register(SAMLAuthenticationProvider.self, instance: SAMLAuthenticationProvider())
        register(EnterpriseSessionManager.self, instance: EnterpriseSessionManager())
        register(JWTTokenValidator.self, instance: JWTTokenValidator())
        
        // Register Team and Permission Services
        register(TeamManager.self, instance: TeamManager())
        register(PermissionManager.self, instance: PermissionManager())
        register(RoleManager.self, instance: RoleManager())
        register(AccessController.self) {
            AccessController(
                permissionManager: self.resolve(PermissionManager.self),
                roleManager: self.resolve(RoleManager.self)
            )
        }
        
        // Register Audit and Compliance Services
        register(AuditLogger.self, instance: AuditLogger())
        register(SecurityEventLogger.self, instance: SecurityEventLogger())
        register(DataAccessLogger.self, instance: DataAccessLogger())
        register(ComplianceReporter.self) {
            ComplianceReporter(
                auditLogger: self.resolve(AuditLogger.self),
                securityLogger: self.resolve(SecurityEventLogger.self)
            )
        }
        register(AuditLogSearchService.self) {
            AuditLogSearchService(auditLogger: self.resolve(AuditLogger.self))
        }
        register(AuditLogExporter.self, instance: AuditLogExporter())
        register(LogRetentionManager.self, instance: LogRetentionManager())
        register(EncryptedAuditLogger.self, instance: EncryptedAuditLogger())
        register(AnomalousActivityMonitor.self, instance: AnomalousActivityMonitor())
        register(ComplianceMonitor.self, instance: ComplianceMonitor())
        
        // Register Enterprise Use Cases
        register(EnterpriseAuthenticationUseCaseProtocol.self, factory: {
            EnterpriseAuthenticationUseCase(
                samlProvider: self.resolve(SAMLAuthenticationProvider.self),
                sessionManager: self.resolve(EnterpriseSessionManager.self),
                jwtValidator: self.resolve(JWTTokenValidator.self),
                auditLogger: self.resolve(AuditLogger.self)
            )
        })
        
        register(TeamManagementUseCaseProtocol.self, factory: {
            TeamManagementUseCase(
                teamManager: self.resolve(TeamManager.self),
                accessController: self.resolve(AccessController.self),
                auditLogger: self.resolve(AuditLogger.self)
            )
        })
        
        register(PermissionManagementUseCaseProtocol.self, factory: {
            PermissionManagementUseCase(
                permissionManager: self.resolve(PermissionManager.self),
                accessController: self.resolve(AccessController.self),
                auditLogger: self.resolve(AuditLogger.self)
            )
        })
        
        register(AuditComplianceUseCaseProtocol.self, factory: {
            AuditComplianceUseCase(
                complianceReporter: self.resolve(ComplianceReporter.self),
                auditSearchService: self.resolve(AuditLogSearchService.self),
                logExporter: self.resolve(AuditLogExporter.self),
                activityMonitor: self.resolve(AnomalousActivityMonitor.self),
                complianceMonitor: self.resolve(ComplianceMonitor.self),
                auditLogger: self.resolve(AuditLogger.self)
            )
        })
        
        register(EnterpriseMasterUseCaseProtocol.self, factory: {
            EnterpriseMasterUseCase(
                authUseCase: self.resolve(EnterpriseAuthenticationUseCaseProtocol.self),
                teamUseCase: self.resolve(TeamManagementUseCaseProtocol.self),
                permissionUseCase: self.resolve(PermissionManagementUseCaseProtocol.self),
                auditUseCase: self.resolve(AuditComplianceUseCaseProtocol.self)
            )
        })
    }
}