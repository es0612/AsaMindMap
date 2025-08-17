import XCTest
import CoreGraphics
import MindMapCore
@testable import DataLayer

final class InMemoryRepositoryTests: XCTestCase {
    
    var mindMapRepository: InMemoryMindMapRepository!
    var nodeRepository: InMemoryNodeRepository!
    var mediaRepository: InMemoryMediaRepository!
    var tagRepository: InMemoryTagRepository!
    
    override func setUp() async throws {
        try await super.setUp()
        mindMapRepository = InMemoryMindMapRepository()
        nodeRepository = InMemoryNodeRepository()
        mediaRepository = InMemoryMediaRepository()
        tagRepository = InMemoryTagRepository()
    }
    
    override func tearDown() async throws {
        await mindMapRepository.clear()
        await nodeRepository.clear()
        await mediaRepository.clear()
        await tagRepository.clear()
        
        mindMapRepository = nil
        nodeRepository = nil
        mediaRepository = nil
        tagRepository = nil
        
        try await super.tearDown()
    }
    
    // MARK: - MindMap Repository Tests
    
    func testMindMapSaveAndFind() async throws {
        // Given
        let mindMap = MindMap(title: "テストマインドマップ")
        
        // When
        try await mindMapRepository.save(mindMap)
        let foundMindMap = try await mindMapRepository.findByID(mindMap.id)
        
        // Then
        XCTAssertNotNil(foundMindMap)
        XCTAssertEqual(foundMindMap?.id, mindMap.id)
        XCTAssertEqual(foundMindMap?.title, "テストマインドマップ")
    }
    
    func testMindMapFindAll() async throws {
        // Given
        let mindMap1 = MindMap(title: "マインドマップ1")
        let mindMap2 = MindMap(title: "マインドマップ2")
        
        // When
        try await mindMapRepository.save(mindMap1)
        try await mindMapRepository.save(mindMap2)
        let allMindMaps = try await mindMapRepository.findAll()
        
        // Then
        XCTAssertEqual(allMindMaps.count, 2)
        XCTAssertTrue(allMindMaps.contains { $0.id == mindMap1.id })
        XCTAssertTrue(allMindMaps.contains { $0.id == mindMap2.id })
    }
    
    func testMindMapDelete() async throws {
        // Given
        let mindMap = MindMap(title: "削除テスト")
        try await mindMapRepository.save(mindMap)
        
        // When
        try await mindMapRepository.delete(mindMap.id)
        let foundMindMap = try await mindMapRepository.findByID(mindMap.id)
        
        // Then
        XCTAssertNil(foundMindMap)
    }
    
    func testMindMapExists() async throws {
        // Given
        let mindMap = MindMap(title: "存在テスト")
        
        // When
        let existsBeforeSave = try await mindMapRepository.exists(mindMap.id)
        try await mindMapRepository.save(mindMap)
        let existsAfterSave = try await mindMapRepository.exists(mindMap.id)
        
        // Then
        XCTAssertFalse(existsBeforeSave)
        XCTAssertTrue(existsAfterSave)
    }
    
    // MARK: - Node Repository Tests
    
    func testNodeSaveAndFind() async throws {
        // Given
        let node = Node(
            text: "テストノード",
            position: CGPoint(x: 100, y: 200)
        )
        
        // When
        try await nodeRepository.save(node)
        let foundNode = try await nodeRepository.findByID(node.id)
        
        // Then
        XCTAssertNotNil(foundNode)
        XCTAssertEqual(foundNode?.id, node.id)
        XCTAssertEqual(foundNode?.text, "テストノード")
        XCTAssertEqual(foundNode?.position, CGPoint(x: 100, y: 200))
    }
    
    func testNodeHierarchy() async throws {
        // Given
        let parentNode = Node(text: "親ノード", position: .zero)
        let childNode = Node(
            text: "子ノード",
            position: CGPoint(x: 50, y: 50),
            parentID: parentNode.id
        )
        
        // When
        try await nodeRepository.save(parentNode)
        try await nodeRepository.save(childNode)
        
        let children = try await nodeRepository.findChildren(of: parentNode.id)
        let parent = try await nodeRepository.findParent(of: childNode.id)
        
        // Then
        XCTAssertEqual(children.count, 1)
        XCTAssertEqual(children.first?.id, childNode.id)
        XCTAssertEqual(parent?.id, parentNode.id)
    }
    
    func testNodeMoveOperation() async throws {
        // Given
        let node = Node(text: "移動テスト", position: .zero)
        let newParentID = UUID()
        
        try await nodeRepository.save(node)
        
        // When
        try await nodeRepository.moveNode(node.id, to: newParentID)
        let movedNode = try await nodeRepository.findByID(node.id)
        
        // Then
        XCTAssertEqual(movedNode?.parentID, newParentID)
    }
    
    // MARK: - Media Repository Tests
    
    func testMediaSaveAndFind() async throws {
        // Given
        let media = Media(
            type: .image,
            fileName: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        // When
        try await mediaRepository.save(media)
        let foundMedia = try await mediaRepository.findByID(media.id)
        
        // Then
        XCTAssertNotNil(foundMedia)
        XCTAssertEqual(foundMedia?.id, media.id)
        XCTAssertEqual(foundMedia?.type, .image)
        XCTAssertEqual(foundMedia?.fileName, "test.jpg")
    }
    
    func testMediaDataOperations() async throws {
        // Given
        let media = Media(type: .image)
        let testData = "test data".data(using: .utf8)!
        
        try await mediaRepository.save(media)
        
        // When
        try await mediaRepository.saveMediaData(testData, for: media.id)
        let loadedData = try await mediaRepository.loadMediaData(for: media.id)
        
        // Then
        XCTAssertEqual(loadedData, testData)
    }
    
    // MARK: - Tag Repository Tests
    
    func testTagSaveAndFind() async throws {
        // Given
        let tag = Tag(
            name: "テストタグ",
            color: .blue,
            description: "テスト用のタグです"
        )
        
        // When
        try await tagRepository.save(tag)
        let foundTag = try await tagRepository.findByID(tag.id)
        
        // Then
        XCTAssertNotNil(foundTag)
        XCTAssertEqual(foundTag?.id, tag.id)
        XCTAssertEqual(foundTag?.name, "テストタグ")
        XCTAssertEqual(foundTag?.color, .blue)
        XCTAssertEqual(foundTag?.description, "テスト用のタグです")
    }
    
    func testTagSearchByName() async throws {
        // Given
        let tag1 = Tag(name: "プロジェクト", color: .blue)
        let tag2 = Tag(name: "個人", color: .green)
        let tag3 = Tag(name: "プロトタイプ", color: .red)
        
        // When
        try await tagRepository.save(tag1)
        try await tagRepository.save(tag2)
        try await tagRepository.save(tag3)
        
        let searchResults = try await tagRepository.findByName("プロ")
        
        // Then
        XCTAssertEqual(searchResults.count, 2)
        XCTAssertTrue(searchResults.contains { $0.name == "プロジェクト" })
        XCTAssertTrue(searchResults.contains { $0.name == "プロトタイプ" })
    }
    
    func testTagSearchByColor() async throws {
        // Given
        let blueTag1 = Tag(name: "青タグ1", color: .blue)
        let blueTag2 = Tag(name: "青タグ2", color: .blue)
        let redTag = Tag(name: "赤タグ", color: .red)
        
        // When
        try await tagRepository.save(blueTag1)
        try await tagRepository.save(blueTag2)
        try await tagRepository.save(redTag)
        
        let blueResults = try await tagRepository.findByColor(.blue)
        
        // Then
        XCTAssertEqual(blueResults.count, 2)
        XCTAssertTrue(blueResults.allSatisfy { $0.color == .blue })
    }
}