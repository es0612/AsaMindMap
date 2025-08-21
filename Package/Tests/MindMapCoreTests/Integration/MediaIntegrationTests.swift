import Testing
import Foundation
@testable import MindMapCore

// MARK: - Media Integration Tests
@Suite("Media Integration Tests")
struct MediaIntegrationTests {
    
    // MARK: - Test Properties
    private let mockNodeRepository = MockNodeRepository()
    private let mockMediaRepository = MockMediaRepository()
    
    // MARK: - Integration Tests
    
    @Test("Complete media workflow - add image to node")
    mutating func testCompleteImageWorkflow() async throws {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        let imageData = "fake image data".data(using: .utf8)!
        
        mockNodeRepository.nodes[nodeID] = node
        
        let addMediaUseCase = AddMediaToNodeUseCase(
            nodeRepository: mockNodeRepository,
            mediaRepository: mockMediaRepository
        )
        
        let getMediaUseCase = GetNodeMediaUseCase(
            nodeRepository: mockNodeRepository,
            mediaRepository: mockMediaRepository
        )
        
        // When - Add media
        let addRequest = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: imageData,
            fileName: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        let addResponse = try await addMediaUseCase.execute(addRequest)
        
        // Then - Verify media was added
        #expect(addResponse.media.type == MediaType.image)
        #expect(addResponse.updatedNode.mediaIDs.contains(addResponse.media.id))
        
        // When - Get media for node
        let getRequest = GetNodeMediaRequest(nodeID: nodeID)
        let getResponse = try await getMediaUseCase.execute(getRequest)
        
        // Then - Verify media can be retrieved
        #expect(getResponse.media.count == 1)
        #expect(getResponse.media.first?.id == addResponse.media.id)
        #expect(getResponse.media.first?.type == MediaType.image)
    }
    
    @Test("Complete media workflow - add link to node")
    mutating func testCompleteLinkWorkflow() async throws {
        // Given
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        let url = "https://example.com"
        
        mockNodeRepository.nodes[nodeID] = node
        
        let addMediaUseCase = AddMediaToNodeUseCase(
            nodeRepository: mockNodeRepository,
            mediaRepository: mockMediaRepository
        )
        
        let validateURLUseCase = ValidateMediaURLUseCase()
        
        // When - Validate URL first
        let validateRequest = ValidateMediaURLRequest(url: url, mediaType: .link)
        let validateResponse = try await validateURLUseCase.execute(validateRequest)
        
        // Then - URL should be valid
        #expect(validateResponse.isValid == true)
        #expect(validateResponse.normalizedURL == url)
        
        // When - Add media
        let addRequest = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .link,
            url: validateResponse.normalizedURL
        )
        
        let addResponse = try await addMediaUseCase.execute(addRequest)
        
        // Then - Verify link was added
        #expect(addResponse.media.type == MediaType.link)
        #expect(addResponse.media.url == url)
        #expect(addResponse.updatedNode.mediaIDs.contains(addResponse.media.id))
    }
    
    @Test("Complete media workflow - remove media from node")
    mutating func testCompleteRemoveWorkflow() async throws {
        // Given
        let nodeID = UUID()
        var node = Node(id: nodeID, text: "Test Node", position: .zero)
        let imageData = "fake image data".data(using: .utf8)!
        
        // Add media first
        let media = Media(
            type: .image,
            data: imageData,
            fileName: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        node.addMedia(media.id)
        mockNodeRepository.nodes[nodeID] = node
        mockMediaRepository.media[media.id] = media
        
        let removeMediaUseCase = RemoveMediaFromNodeUseCase(
            nodeRepository: mockNodeRepository,
            mediaRepository: mockMediaRepository
        )
        
        // When - Remove media
        let removeRequest = RemoveMediaFromNodeRequest(
            nodeID: nodeID,
            mediaID: media.id
        )
        
        let removeResponse = try await removeMediaUseCase.execute(removeRequest)
        
        // Then - Verify media was removed
        #expect(!removeResponse.updatedNode.mediaIDs.contains(media.id))
        #expect(removeResponse.updatedNode.mediaIDs.isEmpty)
    }
    
    @Test("URL validation handles various formats")
    func testURLValidationFormats() async throws {
        let validateUseCase = ValidateMediaURLUseCase()
        
        // Test valid URLs
        let validURLs = [
            "https://example.com",
            "http://example.com",
            "ftp://files.example.com",
            "example.com" // Should be normalized to https://example.com
        ]
        
        for url in validURLs {
            let request = ValidateMediaURLRequest(url: url, mediaType: .link)
            let response = try await validateUseCase.execute(request)
            #expect(response.isValid == true)
        }
        
        // Test invalid URLs
        let invalidURLs = [
            "",
            "   ",
            "not-a-url",
            "file:///local/file.txt"
        ]
        
        for url in invalidURLs {
            let request = ValidateMediaURLRequest(url: url, mediaType: .link)
            let response = try await validateUseCase.execute(request)
            #expect(response.isValid == false)
        }
    }
    
    @Test("Media type validation works correctly")
    mutating func testMediaTypeValidation() async throws {
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Test Node", position: .zero)
        mockNodeRepository.nodes[nodeID] = node
        
        let addMediaUseCase = AddMediaToNodeUseCase(
            nodeRepository: mockNodeRepository,
            mediaRepository: mockMediaRepository
        )
        
        // Test valid image MIME type
        let validImageRequest = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: Data(),
            mimeType: "image/jpeg"
        )
        
        let validResponse = try await addMediaUseCase.execute(validImageRequest)
        #expect(validResponse.media.mimeType == "image/jpeg")
        
        // Test invalid MIME type for image
        let invalidImageRequest = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: Data(),
            mimeType: "application/pdf"
        )
        
        await #expect(throws: MediaError.unsupportedMimeType("application/pdf", MediaType.image)) {
            try await addMediaUseCase.execute(invalidImageRequest)
        }
    }
}