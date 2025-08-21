import Testing
import Foundation
@testable import MindMapCore

// MARK: - Add Media to Node Use Case Tests
@Suite("Add Media to Node Use Case Tests")
struct AddMediaToNodeUseCaseTests {
    
    // MARK: - Test Properties
    private let mockNodeRepository = MockNodeRepository()
    private let mockMediaRepository = MockMediaRepository()
    private lazy var useCase = AddMediaToNodeUseCase(
        nodeRepository: mockNodeRepository,
        mediaRepository: mockMediaRepository
    )
    
    // MARK: - Success Tests
    
    @Test("Should successfully add image media to node")
    mutating func testAddImageMediaSuccess() async throws {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        let imageData = "fake image data".data(using: .utf8)!
        
        mockNodeRepository.nodes[nodeID] = node
        
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: imageData,
            fileName: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.media.type == MediaType.image)
        #expect(response.media.data == imageData)
        #expect(response.media.fileName == "test.jpg")
        #expect(response.media.mimeType == "image/jpeg")
        #expect(response.updatedNode.mediaIDs.contains(response.media.id))
        #expect(mockMediaRepository.saveCallCount == 1)
        #expect(mockNodeRepository.saveCallCount == 1)
    }
    
    @Test("Should successfully add link media to node")
    mutating func testAddLinkMediaSuccess() async throws {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        let url = "https://example.com"
        
        mockNodeRepository.nodes[nodeID] = node
        
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .link,
            url: url
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.media.type == MediaType.link)
        #expect(response.media.url == url)
        #expect(response.updatedNode.mediaIDs.contains(response.media.id))
    }
    
    // MARK: - Validation Tests
    
    @Test("Should throw error when node not found")
    mutating func testNodeNotFound() async {
        // Given
        let nodeID = UUID()
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: Data()
        )
        
        // When & Then
        await #expect(throws: MediaError.nodeNotFound(nodeID)) {
            try await useCase.execute(request)
        }
    }
    
    @Test("Should throw error when image data is missing")
    mutating func testMissingImageData() async {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        mockNodeRepository.nodes[nodeID] = node
        
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image
        )
        
        // When & Then
        await #expect(throws: MediaError.missingData(MediaType.image)) {
            try await useCase.execute(request)
        }
    }
    
    @Test("Should throw error when link URL is missing")
    mutating func testMissingLinkURL() async {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        mockNodeRepository.nodes[nodeID] = node
        
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .link
        )
        
        // When & Then
        await #expect(throws: MediaError.missingURL(MediaType.link)) {
            try await useCase.execute(request)
        }
    }
    
    @Test("Should throw error when URL is invalid")
    mutating func testInvalidURL() async {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        mockNodeRepository.nodes[nodeID] = node
        
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .link,
            url: "invalid-url"
        )
        
        // When & Then
        await #expect(throws: MediaError.invalidURL("invalid-url")) {
            try await useCase.execute(request)
        }
    }
    
    @Test("Should throw error when MIME type is unsupported")
    mutating func testUnsupportedMimeType() async {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        mockNodeRepository.nodes[nodeID] = node
        
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: Data(),
            mimeType: "application/pdf"
        )
        
        // When & Then
        await #expect(throws: MediaError.unsupportedMimeType("application/pdf", MediaType.image)) {
            try await useCase.execute(request)
        }
    }
    
    @Test("Should throw error when file is too large")
    mutating func testFileTooLarge() async {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        mockNodeRepository.nodes[nodeID] = node
        
        // Create data larger than 10MB
        let largeData = Data(count: 11 * 1024 * 1024)
        
        let request = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: largeData
        )
        
        // When & Then
        await #expect(throws: MediaError.fileTooLarge(largeData.count, 10 * 1024 * 1024)) {
            try await useCase.execute(request)
        }
    }
}

