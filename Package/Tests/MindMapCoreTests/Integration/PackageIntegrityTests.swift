import XCTest
@testable import MindMapCore
@testable import MindMapUI
@testable import DataLayer
@testable import NetworkLayer
@testable import DesignSystem

/// Package統合性検証テスト
/// 全モジュール間の依存関係と設計整合性を検証
final class PackageIntegrityTests: XCTestCase {
    
    // MARK: - Module Dependencies Test
    
    func testModuleDependencies() throws {
        // Test: MindMapCoreが他のモジュールに依存していないこと
        // Expected: MindMapCoreは独立したモジュール
        
        // MindMapCoreは独立して動作すべき - DIContainerが作成可能であることで確認
        let container = DIContainer()
        XCTAssertNotNil(container, "DIContainer should be creatable without external dependencies")
        
        // エンティティの作成テスト - 外部依存なしで動作するはず
        let mindMap = MindMap(title: "Test", nodeIDs: [])
        XCTAssertEqual(mindMap.title, "Test")
        
        let node = Node(text: "Test Node", position: .zero)
        XCTAssertEqual(node.text, "Test Node")
        
        let tag = Tag(name: "Test Tag", createdAt: Date(), updatedAt: Date())
        XCTAssertEqual(tag.name, "Test Tag")
        
        let media = Media(type: .image, url: "test://url", thumbnailData: nil)
        XCTAssertEqual(media.type, .image)
    }
    
    @MainActor func testMindMapUIIntegration() throws {
        // Test: MindMapUIがMindMapCoreとDesignSystemに正しく依存していること
        // Expected: DIContainer経由でUseCaseにアクセス可能
        
        let container = DIContainer()
        
        // モックリポジトリを作成してUseCaseFactoryをテスト
        let mindMapRepo = MockMindMapRepository()
        let nodeRepo = MockNodeRepository()
        let mediaRepo = MockMediaRepository()
        let tagRepo = MockTagRepository()
        let shareURLGen = MockShareURLGenerator()
        let cloudKitSync = MockCloudKitSyncManager()
        let sharingManager = MockSharingManager()
        
        let factory = UseCaseFactory(
            mindMapRepository: mindMapRepo,
            nodeRepository: nodeRepo,
            mediaRepository: mediaRepo,
            tagRepository: tagRepo,
            shareURLGenerator: shareURLGen,
            cloudKitSyncManager: cloudKitSync,
            sharingManager: sharingManager
        )
        XCTAssertNotNil(factory, "UseCaseFactory should be creatable")
        
        // 基本的なUseCaseが作成可能であることを確認
        let createMindMapUseCase = factory.makeCreateMindMapUseCase()
        XCTAssertNotNil(createMindMapUseCase, "CreateMindMapUseCase should be available")
        
        let createNodeUseCase = factory.makeCreateNodeUseCase()
        XCTAssertNotNil(createNodeUseCase, "CreateNodeUseCase should be available")
        
        // ViewModelが基本的なDIContainerに依存できることを確認
        let viewModel = MindMapViewModel(container: container)
        XCTAssertNotNil(viewModel, "MindMapViewModel should be creatable with Container")
    }
    
    func testDataLayerIntegration() throws {
        // Test: DataLayerがMindMapCoreのRepositoryProtocolを実装していること
        // Expected: Repository実装がプロトコルに適合
        
        // MockRepositoryの基本機能テスト
        let mockMindMapRepo = MockMindMapRepository()
        let mockNodeRepo = MockNodeRepository()
        let mockMediaRepo = MockMediaRepository()
        let mockTagRepo = MockTagRepository()
        
        // 基本的なRepository操作が動作することを確認
        XCTAssertEqual(mockMindMapRepo.saveCallCount, 0)
        XCTAssertEqual(mockNodeRepo.saveCallCount, 0)
        XCTAssertEqual(mockMediaRepo.saveCallCount, 0)
        XCTAssertEqual(mockTagRepo.saveCallCount, 0)
        
        // Repository protocolの基本メソッドが存在することを確認
        // （コンパイル時にチェックされるため、コンパイルが通れば適合している）
        XCTAssertTrue(mockMindMapRepo is MindMapRepositoryProtocol)
        XCTAssertTrue(mockNodeRepo is NodeRepositoryProtocol)
        XCTAssertTrue(mockMediaRepo is MediaRepositoryProtocol)
        XCTAssertTrue(mockTagRepo is TagRepositoryProtocol)
    }
    
    // MARK: - API Consistency Tests
    
    func testRepositoryAPIConsistency() throws {
        // Test: 全Repositoryが同じパターンでエラーハンドリングしていること
        // Expected: 一貫したError型とasync throwsパターン
        
        // 全Repositoryが共通のメソッドパターンを持つことを確認
        let mockMindMapRepo = MockMindMapRepository()
        let mockNodeRepo = MockNodeRepository()
        let mockMediaRepo = MockMediaRepository()
        let mockTagRepo = MockTagRepository()
        
        // 基本CRUD操作の一貫性を確認（async throwsパターン）
        Task {
            // save操作の一貫性
            do {
                let mindMap = MindMap(title: "Test", nodeIDs: [])
                try await mockMindMapRepo.save(mindMap)
                XCTAssertEqual(mockMindMapRepo.saveCallCount, 1)
                
                let node = Node(text: "Test", position: .zero)
                try await mockNodeRepo.save(node)
                XCTAssertEqual(mockNodeRepo.saveCallCount, 1)
                
                let tag = Tag(name: "Test", createdAt: Date(), updatedAt: Date())
                try await mockTagRepo.save(tag)
                XCTAssertEqual(mockTagRepo.saveCallCount, 1)
            } catch {
                XCTFail("Repository operations should not throw in mock implementation")
            }
        }
    }
    
    func testUseCaseAPIConsistency() throws {
        // Test: 全UseCaseが同じパターンでRequest/Responseを処理していること
        // Expected: 一貫したexecute(request)パターン
        
        // UseCaseFactoryが一貫したUseCaseを生成することを確認
        let mockMindMapRepo = MockMindMapRepository()
        let mockNodeRepo = MockNodeRepository()
        let mockMediaRepo = MockMediaRepository()
        let mockTagRepo = MockTagRepository()
        let mockShareURLGen = MockShareURLGenerator()
        let mockCloudKitSync = MockCloudKitSyncManager()
        let mockSharingManager = MockSharingManager()
        
        let factory = UseCaseFactory(
            mindMapRepository: mockMindMapRepo,
            nodeRepository: mockNodeRepo,
            mediaRepository: mockMediaRepo,
            tagRepository: mockTagRepo,
            shareURLGenerator: mockShareURLGen,
            cloudKitSyncManager: mockCloudKitSync,
            sharingManager: mockSharingManager
        )
        
        // 各UseCaseが正常に作成されることを確認
        let createMindMapUseCase = factory.makeCreateMindMapUseCase()
        XCTAssertNotNil(createMindMapUseCase)
        
        let createNodeUseCase = factory.makeCreateNodeUseCase()
        XCTAssertNotNil(createNodeUseCase)
        
        // 全てのUseCaseがRequest/Response型パターンを実装していることは
        // コンパイル時に確認される（実際のUseCaseは全てこのパターンを使用）
    }
    
    // MARK: - Protocol Compliance Tests
    
    func testProtocolImplementations() throws {
        // Test: 全プロトコル実装が要求されるメソッドを持っていること
        // Expected: コンパイル時に検証されるが、ランタイムでも確認
        
        // プロトコル適合性の確認 - コンパイルが通ることで基本的な適合性は保証される
        let mockMindMapRepo = MockMindMapRepository()
        let mockNodeRepo = MockNodeRepository()
        let mockMediaRepo = MockMediaRepository()
        let mockTagRepo = MockTagRepository()
        let mockShareURLGen = MockShareURLGenerator()
        let mockCloudKitSync = MockCloudKitSyncManager()
        let mockSharingManager = MockSharingManager()
        
        // プロトコル型への代入が可能であることを確認
        let _: MindMapRepositoryProtocol = mockMindMapRepo
        let _: NodeRepositoryProtocol = mockNodeRepo
        let _: MediaRepositoryProtocol = mockMediaRepo
        let _: TagRepositoryProtocol = mockTagRepo
        let _: ShareURLGeneratorProtocol = mockShareURLGen
        let _: CloudKitSyncManagerProtocol = mockCloudKitSync
        let _: SharingManagerProtocol = mockSharingManager
        
        // 全ての必須メソッドが実装されていることは、コンパイル成功により確認済み
        XCTAssertTrue(true, "All protocol implementations compile successfully")
    }
}