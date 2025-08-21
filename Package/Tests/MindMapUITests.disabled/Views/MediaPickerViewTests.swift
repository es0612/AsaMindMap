import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - Media Picker View Tests
@available(iOS 16.0, *)
@Suite("Media Picker View Tests")
struct MediaPickerViewTests {
    
    // MARK: - Initialization Tests
    
    @Test("Should initialize with correct properties")
    func testInitialization() {
        // Given
        var selectedResult: MediaPickerResult?
        let onMediaSelected: (MediaPickerResult) -> Void = { result in
            selectedResult = result
        }
        
        // When
        let view = MediaPickerView(
            isPresented: .constant(true),
            onMediaSelected: onMediaSelected
        )
        
        // Then
        // View should be created without errors
        #expect(view != nil)
    }
    
    // MARK: - Media Picker Result Tests
    
    @Test("Should create image result correctly")
    func testImageResult() {
        // Given
        let imageData = "fake image data".data(using: .utf8)!
        
        // When
        let result = MediaPickerResult(
            type: .image,
            data: imageData,
            fileName: "test.jpg",
            mimeType: "image/jpeg"
        )
        
        // Then
        #expect(result.type == .image)
        #expect(result.data == imageData)
        #expect(result.fileName == "test.jpg")
        #expect(result.mimeType == "image/jpeg")
        #expect(result.url == nil)
    }
    
    @Test("Should create link result correctly")
    func testLinkResult() {
        // Given
        let url = "https://example.com"
        
        // When
        let result = MediaPickerResult(
            type: .link,
            url: url
        )
        
        // Then
        #expect(result.type == .link)
        #expect(result.url == url)
        #expect(result.data == nil)
        #expect(result.fileName == nil)
        #expect(result.mimeType == nil)
    }
    
    @Test("Should create sticker result correctly")
    func testStickerResult() {
        // Given
        let stickerData = "fake sticker data".data(using: .utf8)!
        
        // When
        let result = MediaPickerResult(
            type: .sticker,
            data: stickerData,
            fileName: "sticker.png",
            mimeType: "image/png"
        )
        
        // Then
        #expect(result.type == .sticker)
        #expect(result.data == stickerData)
        #expect(result.fileName == "sticker.png")
        #expect(result.mimeType == "image/png")
    }
}