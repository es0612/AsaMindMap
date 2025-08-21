import Testing
import Foundation
@testable import MindMapCore

// MARK: - Media Demo Tests
@Suite("Media Demo Tests")
struct MediaDemoTests {
    
    @Test("Media functionality demo - complete workflow")
    func testMediaFunctionalityDemo() async throws {
        // Setup repositories
        let nodeRepository = MockNodeRepository()
        let mediaRepository = MockMediaRepository()
        
        // Create a test node
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Demo Node", position: .zero)
        nodeRepository.nodes[nodeID] = node
        
        // Create use cases
        let addMediaUseCase = AddMediaToNodeUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
        
        let validateURLUseCase = ValidateMediaURLUseCase()
        
        let getMediaUseCase = GetNodeMediaUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
        
        let removeMediaUseCase = RemoveMediaFromNodeUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
        
        print("🎯 Starting Media Functionality Demo")
        
        // 1. Validate a URL
        print("\n1️⃣ Validating URL...")
        let urlRequest = ValidateMediaURLRequest(url: "https://example.com", mediaType: .link)
        let urlResponse = try await validateURLUseCase.execute(urlRequest)
        print("   ✅ URL validation result: \(urlResponse.isValid)")
        print("   📝 Normalized URL: \(urlResponse.normalizedURL ?? "none")")
        
        // 2. Add an image to the node
        print("\n2️⃣ Adding image to node...")
        let imageData = "fake image data for demo".data(using: .utf8)!
        let addImageRequest = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .image,
            data: imageData,
            fileName: "demo.jpg",
            mimeType: "image/jpeg"
        )
        
        let addImageResponse = try await addMediaUseCase.execute(addImageRequest)
        print("   ✅ Image added with ID: \(addImageResponse.media.id)")
        print("   📝 Node now has \(addImageResponse.updatedNode.mediaIDs.count) media items")
        
        // 3. Add a link to the node
        print("\n3️⃣ Adding link to node...")
        let addLinkRequest = AddMediaToNodeRequest(
            nodeID: nodeID,
            mediaType: .link,
            url: urlResponse.normalizedURL
        )
        
        let addLinkResponse = try await addMediaUseCase.execute(addLinkRequest)
        print("   ✅ Link added with ID: \(addLinkResponse.media.id)")
        print("   📝 Node now has \(addLinkResponse.updatedNode.mediaIDs.count) media items")
        
        // 4. Get all media for the node
        print("\n4️⃣ Retrieving all media for node...")
        let getMediaRequest = GetNodeMediaRequest(nodeID: nodeID)
        let getMediaResponse = try await getMediaUseCase.execute(getMediaRequest)
        print("   ✅ Retrieved \(getMediaResponse.media.count) media items:")
        for media in getMediaResponse.media {
            print("      - \(media.type.displayName): \(media.displayName)")
        }
        
        // 5. Remove one media item
        print("\n5️⃣ Removing image from node...")
        let removeRequest = RemoveMediaFromNodeRequest(
            nodeID: nodeID,
            mediaID: addImageResponse.media.id
        )
        
        let removeResponse = try await removeMediaUseCase.execute(removeRequest)
        print("   ✅ Image removed")
        print("   📝 Node now has \(removeResponse.updatedNode.mediaIDs.count) media items")
        
        // 6. Verify final state
        print("\n6️⃣ Verifying final state...")
        let finalMediaRequest = GetNodeMediaRequest(nodeID: nodeID)
        let finalMediaResponse = try await getMediaUseCase.execute(finalMediaRequest)
        print("   ✅ Final media count: \(finalMediaResponse.media.count)")
        print("   📝 Remaining media: \(finalMediaResponse.media.first?.type.displayName ?? "none")")
        
        print("\n🎉 Media functionality demo completed successfully!")
        
        // Assertions to ensure everything worked
        #expect(urlResponse.isValid == true)
        #expect(addImageResponse.media.type == MediaType.image)
        #expect(addLinkResponse.media.type == MediaType.link)
        #expect(getMediaResponse.media.count == 2)
        #expect(finalMediaResponse.media.count == 1)
        #expect(finalMediaResponse.media.first?.type == MediaType.link)
    }
    
    @Test("Media validation edge cases")
    func testMediaValidationEdgeCases() async throws {
        let validateUseCase = ValidateMediaURLUseCase()
        
        print("\n🧪 Testing URL validation edge cases...")
        
        // Test various URL formats
        let testCases = [
            ("https://example.com", true, "Valid HTTPS URL"),
            ("http://example.com", true, "Valid HTTP URL"),
            ("example.com", true, "URL without protocol (should be normalized)"),
            ("", false, "Empty URL"),
            ("   ", false, "Whitespace-only URL"),
            ("not-a-url", false, "Invalid URL format"),
            ("file:///local/file.txt", false, "Unsupported protocol")
        ]
        
        for (url, expectedValid, description) in testCases {
            let request = ValidateMediaURLRequest(url: url, mediaType: .link)
            let response = try await validateUseCase.execute(request)
            print("   \(expectedValid ? "✅" : "❌") \(description): \(response.isValid)")
            #expect(response.isValid == expectedValid)
        }
        
        print("   🎉 All validation edge cases passed!")
    }
}

// Note: Using MockRepositories from the shared Mocks module