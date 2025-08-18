import Testing
import Foundation
import CoreGraphics
@testable import MindMapCore

struct UpdateNodeUseCaseTests {
    
    // MARK: - Test Setup
    private func makeTestSetup() -> (
        useCase: UpdateNodeUseCase,
        nodeRepository: MockNodeRepository
    ) {
        let nodeRepository = MockNodeRepository()
        let useCase = UpdateNodeUseCase(nodeRepository: nodeRepository)
        return (useCase, nodeRepository)
    }
    
    private func makeTestNode() -> Node {
        Node(
            text: "テストノード",
            position: CGPoint(x: 100, y: 100),
            backgroundColor: .default,
            textColor: .primary,
            fontSize: 16.0
        )
    }
    
    // MARK: - Success Tests
    @Test("ノードテキスト更新の正常系")
    func testUpdateNodeTextSuccess() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            text: "更新されたテキスト"
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.text == "更新されたテキスト")
        #expect(nodeRepository.saveCallCount == 1)
    }
    
    @Test("ノード位置更新の正常系")
    func testUpdateNodePositionSuccess() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let newPosition = CGPoint(x: 200, y: 200)
        let request = UpdateNodeRequest(
            nodeID: node.id,
            position: newPosition
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.position == newPosition)
        #expect(nodeRepository.saveCallCount == 1)
    }
    
    @Test("ノードの色とフォントサイズ更新")
    func testUpdateNodeAppearance() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            backgroundColor: NodeColor.red,
            textColor: NodeColor.yellow,
            fontSize: 20.0
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.backgroundColor == NodeColor.red)
        #expect(response.node.textColor == NodeColor.yellow)
        #expect(response.node.fontSize == 20.0)
        #expect(nodeRepository.saveCallCount == 1)
    }
    
    @Test("タスク状態の切り替え")
    func testToggleTaskState() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            isTask: true
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.isTask == true)
        #expect(response.node.isCompleted == false)
        #expect(nodeRepository.saveCallCount == 1)
    }
    
    @Test("タスク完了状態の切り替え")
    func testToggleTaskCompletion() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        var node = makeTestNode()
        node.isTask = true
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            isCompleted: true
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.isCompleted == true)
        #expect(nodeRepository.saveCallCount == 1)
    }
    
    @Test("折りたたみ状態の切り替え")
    func testToggleCollapseState() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            isCollapsed: true
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.isCollapsed == true)
        #expect(nodeRepository.saveCallCount == 1)
    }
    
    @Test("変更がない場合の早期リターン")
    func testNoChangesEarlyReturn() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(nodeID: node.id)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.node.text == node.text)
        #expect(nodeRepository.saveCallCount == 0) // 保存されない
    }
    
    // MARK: - Error Tests
    @Test("存在しないノードの更新")
    func testUpdateNonExistentNode() async {
        // Given
        let (useCase, _) = makeTestSetup()
        let request = UpdateNodeRequest(
            nodeID: UUID(),
            text: "テスト"
        )
        
        // When & Then
        await expectValidationError(
            { try await useCase.execute(request) },
            expectedMessage: "指定されたノードが見つかりません"
        )
    }
    
    @Test("無効なテキストでの更新")
    func testUpdateWithInvalidText() async {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            text: ""
        )
        
        // When & Then
        await expectValidationError {
            try await useCase.execute(request)
        }
    }
    
    @Test("無効なフォントサイズでの更新")
    func testUpdateWithInvalidFontSize() async {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode()
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            fontSize: -1.0
        )
        
        // When & Then
        await expectValidationError {
            try await useCase.execute(request)
        }
    }
    
    @Test("タスクでないノードの完了状態変更")
    func testCompleteNonTaskNode() async throws {
        // Given
        let (useCase, nodeRepository) = makeTestSetup()
        let node = makeTestNode() // isTask = false
        nodeRepository.nodes[node.id] = node
        
        let request = UpdateNodeRequest(
            nodeID: node.id,
            isCompleted: true
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        // タスクでないノードの完了状態は変更されない
        #expect(response.node.isCompleted == false)
        #expect(nodeRepository.saveCallCount == 0)
    }
}