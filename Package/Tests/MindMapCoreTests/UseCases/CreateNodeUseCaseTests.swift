import Testing
import Foundation
import CoreGraphics
@testable import MindMapCore

struct CreateNodeUseCaseTests {
    
    // MARK: - Test Setup
    private func makeTestSetup() -> (
        useCase: CreateNodeUseCase,
        nodeRepository: MockNodeRepository,
        mindMapRepository: MockMindMapRepository
    ) {
        let nodeRepository = MockNodeRepository()
        let mindMapRepository = MockMindMapRepository()
        let useCase = CreateNodeUseCase(
            nodeRepository: nodeRepository,
            mindMapRepository: mindMapRepository
        )
        return (useCase, nodeRepository, mindMapRepository)
    }
    
    private func makeMindMap() -> MindMap {
        MindMap(title: "テストマインドマップ")
    }
    
    // MARK: - Success Tests
    @Test("ノード作成の正常系")
    func testCreateNodeSuccess() async throws {
        // Given
        let (useCase, nodeRepository, mindMapRepository) = makeTestSetup()
        let mindMap = makeMindMap()
        mindMapRepository.mindMaps[mindMap.id] = mindMap
        
        let request = CreateNodeRequest(
            text: "新しいノード",
            position: CGPoint(x: 100, y: 100),
            mindMapID: mindMap.id
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.text == "新しいノード")
        #expect(response.node.position == CGPoint(x: 100, y: 100))
        #expect(response.updatedMindMap.hasNodes)
        #expect(nodeRepository.saveCallCount == 1)
        #expect(mindMapRepository.saveCallCount == 1)
    }
    
    @Test("ルートノード作成時のMindMap更新")
    func testCreateRootNodeUpdatesMindMap() async throws {
        // Given
        let (useCase, _, mindMapRepository) = makeTestSetup()
        let mindMap = makeMindMap()
        mindMapRepository.mindMaps[mindMap.id] = mindMap
        
        let request = CreateNodeRequest(
            text: "ルートノード",
            position: CGPoint.zero,
            mindMapID: mindMap.id
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.updatedMindMap.hasRootNode)
        #expect(response.updatedMindMap.rootNodeID == response.node.id)
    }
    
    @Test("子ノード作成時の親ノード更新")
    func testCreateChildNodeUpdatesParent() async throws {
        // Given
        let (useCase, nodeRepository, mindMapRepository) = makeTestSetup()
        var mindMap = makeMindMap()
        let parentNode = Node(text: "親ノード", position: CGPoint.zero)
        
        // MindMapにルートノードを設定
        mindMap.setRootNode(parentNode.id)
        
        mindMapRepository.mindMaps[mindMap.id] = mindMap
        nodeRepository.nodes[parentNode.id] = parentNode
        
        let request = CreateNodeRequest(
            text: "子ノード",
            position: CGPoint(x: 50, y: 50),
            parentID: parentNode.id,
            mindMapID: mindMap.id
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        let updatedParent = nodeRepository.nodes[parentNode.id]!
        #expect(updatedParent.childIDs.contains(response.node.id))
        #expect(response.node.parentID == parentNode.id)
    }
    
    // MARK: - Error Tests
    @Test("存在しないMindMapでのノード作成")
    func testCreateNodeWithNonExistentMindMap() async {
        // Given
        let (useCase, _, _) = makeTestSetup()
        let request = CreateNodeRequest(
            text: "テストノード",
            position: CGPoint.zero,
            mindMapID: UUID()
        )
        
        // When & Then
        await expectValidationError(
            { try await useCase.execute(request) },
            expectedMessage: "指定されたマインドマップが見つかりません"
        )
    }
    
    @Test("存在しない親ノードでのノード作成")
    func testCreateNodeWithNonExistentParent() async {
        // Given
        let (useCase, _, mindMapRepository) = makeTestSetup()
        let mindMap = makeMindMap()
        mindMapRepository.mindMaps[mindMap.id] = mindMap
        
        let request = CreateNodeRequest(
            text: "テストノード",
            position: CGPoint.zero,
            parentID: UUID(),
            mindMapID: mindMap.id
        )
        
        // When & Then
        await expectValidationError(
            { try await useCase.execute(request) },
            expectedMessage: "指定された親ノードが見つかりません"
        )
    }
    
    @Test("無効なテキストでのノード作成")
    func testCreateNodeWithInvalidText() async {
        // Given
        let (useCase, _, mindMapRepository) = makeTestSetup()
        let mindMap = makeMindMap()
        mindMapRepository.mindMaps[mindMap.id] = mindMap
        
        let request = CreateNodeRequest(
            text: "",
            position: CGPoint.zero,
            mindMapID: mindMap.id
        )
        
        // When & Then
        await expectValidationError {
            try await useCase.execute(request)
        }
    }
}