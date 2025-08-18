import Testing
import Foundation
import CoreGraphics
@testable import MindMapCore

struct CreateMindMapUseCaseTests {
    
    // MARK: - Test Setup
    private func makeTestSetup() -> (
        useCase: CreateMindMapUseCase,
        mindMapRepository: MockMindMapRepository,
        nodeRepository: MockNodeRepository
    ) {
        let mindMapRepository = MockMindMapRepository()
        let nodeRepository = MockNodeRepository()
        let useCase = CreateMindMapUseCase(
            mindMapRepository: mindMapRepository,
            nodeRepository: nodeRepository
        )
        return (useCase, mindMapRepository, nodeRepository)
    }
    
    // MARK: - Success Tests
    @Test("MindMap作成の正常系（ルートノードなし）")
    func testCreateMindMapWithoutRootNode() async throws {
        // Given
        let (useCase, mindMapRepository, nodeRepository) = makeTestSetup()
        let request = CreateMindMapRequest(title: "新しいマインドマップ")
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mindMap.title == "新しいマインドマップ")
        #expect(response.mindMap.hasRootNode == false)
        #expect(response.rootNode == nil)
        #expect(mindMapRepository.saveCallCount == 1)
        #expect(nodeRepository.saveCallCount == 0)
    }
    
    @Test("MindMap作成の正常系（ルートノードあり）")
    func testCreateMindMapWithRootNode() async throws {
        // Given
        let (useCase, mindMapRepository, nodeRepository) = makeTestSetup()
        let request = CreateMindMapRequest(
            title: "新しいマインドマップ",
            rootNodeText: "メインアイデア",
            rootNodePosition: CGPoint(x: 100, y: 100)
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mindMap.title == "新しいマインドマップ")
        #expect(response.mindMap.hasRootNode == true)
        #expect(response.rootNode?.text == "メインアイデア")
        #expect(response.rootNode?.position == CGPoint(x: 100, y: 100))
        #expect(response.rootNode?.backgroundColor == NodeColor.accent)
        #expect(response.rootNode?.fontSize == 18.0)
        #expect(mindMapRepository.saveCallCount == 1)
        #expect(nodeRepository.saveCallCount == 1)
    }
    
    @Test("空のルートノードテキストでの作成")
    func testCreateMindMapWithEmptyRootNodeText() async throws {
        // Given
        let (useCase, mindMapRepository, nodeRepository) = makeTestSetup()
        let request = CreateMindMapRequest(
            title: "テストマインドマップ",
            rootNodeText: "",
            rootNodePosition: CGPoint.zero
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mindMap.hasRootNode == false)
        #expect(response.rootNode == nil)
        #expect(mindMapRepository.saveCallCount == 1)
        #expect(nodeRepository.saveCallCount == 0)
    }
    
    @Test("MindMapのデフォルト値設定")
    func testCreateMindMapDefaultValues() async throws {
        // Given
        let (useCase, _, _) = makeTestSetup()
        let request = CreateMindMapRequest(title: "テストマインドマップ")
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mindMap.isShared == false)
        #expect(response.mindMap.shareURL == nil)
        #expect(response.mindMap.sharePermissions == SharePermissions.private)
        #expect(response.mindMap.version == 1)
        #expect(response.mindMap.nodeIDs.isEmpty)
        #expect(response.mindMap.tagIDs.isEmpty)
        #expect(response.mindMap.mediaIDs.isEmpty)
    }
    
    @Test("ルートノード作成時のMindMap更新")
    func testRootNodeCreationUpdatesMindMap() async throws {
        // Given
        let (useCase, _, _) = makeTestSetup()
        let request = CreateMindMapRequest(
            title: "テストマインドマップ",
            rootNodeText: "ルートノード"
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mindMap.rootNodeID == response.rootNode?.id)
        #expect(response.mindMap.nodeIDs.contains(response.rootNode!.id))
        #expect(response.mindMap.nodeCount == 1)
    }
    
    // MARK: - Error Tests
    @Test("無効なタイトルでのMindMap作成")
    func testCreateMindMapWithInvalidTitle() async {
        // Given
        let (useCase, _, _) = makeTestSetup()
        let request = CreateMindMapRequest(title: "")
        
        // When & Then
        await expectValidationError {
            try await useCase.execute(request)
        }
    }
    
    @Test("長すぎるタイトルでのMindMap作成")
    func testCreateMindMapWithTooLongTitle() async {
        // Given
        let (useCase, _, _) = makeTestSetup()
        let longTitle = String(repeating: "a", count: 101) // 100文字制限を超える
        let request = CreateMindMapRequest(title: longTitle)
        
        // When & Then
        await expectValidationError {
            try await useCase.execute(request)
        }
    }
    
    @Test("無効なルートノードテキストでの作成")
    func testCreateMindMapWithInvalidRootNodeText() async {
        // Given
        let (useCase, _, _) = makeTestSetup()
        let longText = String(repeating: "a", count: 501) // 500文字制限を超える
        let request = CreateMindMapRequest(
            title: "テストマインドマップ",
            rootNodeText: longText
        )
        
        // When & Then
        await expectValidationError {
            try await useCase.execute(request)
        }
    }
    
    @Test("無効な位置でのルートノード作成")
    func testCreateMindMapWithInvalidRootNodePosition() async {
        // Given
        let (useCase, _, _) = makeTestSetup()
        let request = CreateMindMapRequest(
            title: "テストマインドマップ",
            rootNodeText: "ルートノード",
            rootNodePosition: CGPoint(x: CGFloat.infinity, y: 100)
        )
        
        // When & Then
        await expectValidationError {
            try await useCase.execute(request)
        }
    }
}