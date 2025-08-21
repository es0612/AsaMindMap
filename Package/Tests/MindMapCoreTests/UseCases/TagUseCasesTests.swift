import Testing
import Foundation
import CoreGraphics
@testable import MindMapCore

struct TagUseCasesTests {
    
    // MARK: - Test CreateTagUseCase
    
    @Test("タグ作成の正常系")
    func testCreateTagSuccess() async throws {
        // Given
        let mockTagRepository = MockTagRepository()
        let useCase = CreateTagUseCase(tagRepository: mockTagRepository)
        let request = CreateTagRequest(
            name: "重要",
            color: .red,
            description: "重要なタスク"
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.tag.name == "重要")
        #expect(response.tag.color == .red)
        #expect(response.tag.description == "重要なタスク")
        #expect(mockTagRepository.saveCallCount == 1)
    }
    
    @Test("空のタグ名での作成エラー")
    func testCreateTagWithEmptyName() async throws {
        // Given
        let mockTagRepository = MockTagRepository()
        let useCase = CreateTagUseCase(tagRepository: mockTagRepository)
        let request = CreateTagRequest(name: "", color: .red)
        
        // When & Then
        await #expect(throws: TagError.invalidName) {
            try await useCase.execute(request)
        }
    }
    
    // MARK: - Test AddTagToNodeUseCase
    
    @Test("ノードにタグ追加の正常系")
    func testAddTagToNodeSuccess() async throws {
        // Given
        let mockNodeRepository = MockNodeRepository()
        let mockTagRepository = MockTagRepository()
        let useCase = AddTagToNodeUseCase(
            nodeRepository: mockNodeRepository,
            tagRepository: mockTagRepository
        )
        
        let node = Node(
            id: UUID(),
            text: "テストノード",
            position: CGPoint(x: 100, y: 100)
        )
        let tag = Tag(name: "重要", color: .red)
        
        mockNodeRepository.nodes[node.id] = node
        mockTagRepository.tags[tag.id] = tag
        
        let request = AddTagToNodeRequest(nodeID: node.id, tagID: tag.id)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.updatedNode.tagIDs.contains(tag.id))
        #expect(response.tag.id == tag.id)
        #expect(mockNodeRepository.saveCallCount == 1)
    }
    
    @Test("存在しないノードへのタグ追加エラー")
    func testAddTagToNonExistentNode() async throws {
        // Given
        let mockNodeRepository = MockNodeRepository()
        let mockTagRepository = MockTagRepository()
        let useCase = AddTagToNodeUseCase(
            nodeRepository: mockNodeRepository,
            tagRepository: mockTagRepository
        )
        
        let tag = Tag(name: "重要", color: .red)
        mockTagRepository.tags[tag.id] = tag
        
        let request = AddTagToNodeRequest(nodeID: UUID(), tagID: tag.id)
        
        // When & Then
        await #expect(throws: NodeError.notFound) {
            try await useCase.execute(request)
        }
    }
    
    // MARK: - Test ToggleNodeTaskUseCase
    
    @Test("ノードのタスク状態切り替え")
    func testToggleNodeTask() async throws {
        // Given
        let mockNodeRepository = MockNodeRepository()
        let useCase = ToggleNodeTaskUseCase(nodeRepository: mockNodeRepository)
        
        let node = Node(
            id: UUID(),
            text: "テストノード",
            position: CGPoint(x: 100, y: 100),
            isTask: false
        )
        
        mockNodeRepository.nodes[node.id] = node
        let request = ToggleNodeTaskRequest(nodeID: node.id)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.updatedNode.isTask == true)
        #expect(response.updatedNode.isCompleted == false)
        #expect(mockNodeRepository.saveCallCount == 1)
    }
    
    @Test("タスクノードの完了状態切り替え")
    func testToggleTaskCompletion() async throws {
        // Given
        let mockNodeRepository = MockNodeRepository()
        let useCase = ToggleTaskCompletionUseCase(nodeRepository: mockNodeRepository)
        
        let node = Node(
            id: UUID(),
            text: "テストタスク",
            position: CGPoint(x: 100, y: 100),
            isTask: true,
            isCompleted: false
        )
        
        mockNodeRepository.nodes[node.id] = node
        let request = ToggleTaskCompletionRequest(nodeID: node.id)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.updatedNode.isCompleted == true)
        #expect(mockNodeRepository.saveCallCount == 1)
    }
    
    @Test("非タスクノードの完了状態切り替えは無効")
    func testToggleCompletionForNonTask() async throws {
        // Given
        let mockNodeRepository = MockNodeRepository()
        let useCase = ToggleTaskCompletionUseCase(nodeRepository: mockNodeRepository)
        
        let node = Node(
            id: UUID(),
            text: "通常ノード",
            position: CGPoint(x: 100, y: 100),
            isTask: false
        )
        
        mockNodeRepository.nodes[node.id] = node
        let request = ToggleTaskCompletionRequest(nodeID: node.id)
        
        // When & Then
        await #expect(throws: TaskError.notATask) {
            try await useCase.execute(request)
        }
    }
    
    // MARK: - Test GetBranchProgressUseCase
    
    @Test("ブランチ進捗計算")
    func testGetBranchProgress() async throws {
        // Given
        let mockNodeRepository = MockNodeRepository()
        let useCase = GetBranchProgressUseCase(nodeRepository: mockNodeRepository)
        
        let rootNode = Node(
            id: UUID(),
            text: "ルートノード",
            position: CGPoint(x: 100, y: 100)
        )
        
        let taskNode1 = Node(
            id: UUID(),
            text: "タスク1",
            position: CGPoint(x: 150, y: 150),
            isTask: true,
            isCompleted: true,
            parentID: rootNode.id
        )
        
        let taskNode2 = Node(
            id: UUID(),
            text: "タスク2", 
            position: CGPoint(x: 150, y: 200),
            isTask: true,
            isCompleted: false,
            parentID: rootNode.id
        )
        
        let normalNode = Node(
            id: UUID(),
            text: "通常ノード",
            position: CGPoint(x: 150, y: 250),
            parentID: rootNode.id
        )
        
        mockNodeRepository.nodes[rootNode.id] = rootNode
        mockNodeRepository.nodes[taskNode1.id] = taskNode1
        mockNodeRepository.nodes[taskNode2.id] = taskNode2
        mockNodeRepository.nodes[normalNode.id] = normalNode
        
        let request = GetBranchProgressRequest(rootNodeID: rootNode.id)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.totalTasks == 2)
        #expect(response.completedTasks == 1)
        #expect(response.progressPercentage == 50.0)
    }
}