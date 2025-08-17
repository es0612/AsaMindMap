import XCTest
import CoreGraphics
import MindMapCore
@testable import DataLayer

@available(iOS 16.0, macOS 13.0, *)
final class BasicDataLayerTests: XCTestCase {
    
    func testDataLayerConfiguration() {
        // Given & When & Then
        XCTAssertNoThrow(DataLayer.configure())
    }
    
    func testRepositoryContainerCreation() async throws {
        // Given & When
        let repositories = DataLayer.createInMemoryRepositories()
        
        // Then
        XCTAssertNotNil(repositories.mindMapRepository)
        XCTAssertNotNil(repositories.nodeRepository)
        XCTAssertNotNil(repositories.mediaRepository)
        XCTAssertNotNil(repositories.tagRepository)
    }
    
    func testBasicMindMapOperations() async throws {
        // Given
        let repositories = DataLayer.createInMemoryRepositories()
        let mindMap = MindMap(title: "テストマインドマップ")
        
        // When
        try await repositories.mindMapRepository.save(mindMap)
        let foundMindMap = try await repositories.mindMapRepository.findByID(mindMap.id)
        
        // Then
        XCTAssertNotNil(foundMindMap)
        XCTAssertEqual(foundMindMap?.id, mindMap.id)
        XCTAssertEqual(foundMindMap?.title, "テストマインドマップ")
    }
    
    func testBasicNodeOperations() async throws {
        // Given
        let repositories = DataLayer.createInMemoryRepositories()
        let node = Node(
            text: "テストノード",
            position: CGPoint(x: 100, y: 200)
        )
        
        // When
        try await repositories.nodeRepository.save(node)
        let foundNode = try await repositories.nodeRepository.findByID(node.id)
        
        // Then
        XCTAssertNotNil(foundNode)
        XCTAssertEqual(foundNode?.id, node.id)
        XCTAssertEqual(foundNode?.text, "テストノード")
        XCTAssertEqual(foundNode?.position, CGPoint(x: 100, y: 200))
    }
}