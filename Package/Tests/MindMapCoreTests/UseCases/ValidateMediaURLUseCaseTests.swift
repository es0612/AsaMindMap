import Testing
import Foundation
@testable import MindMapCore

// MARK: - Validate Media URL Use Case Tests
@Suite("Validate Media URL Use Case Tests")
struct ValidateMediaURLUseCaseTests {
    
    // MARK: - Test Properties
    private let useCase = ValidateMediaURLUseCase()
    
    // MARK: - Valid URL Tests
    
    @Test("Should validate HTTPS URL")
    func testValidHTTPSURL() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "https://example.com",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.normalizedURL == "https://example.com")
        #expect(response.errorMessage == nil)
    }
    
    @Test("Should validate HTTP URL")
    func testValidHTTPURL() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "http://example.com",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.normalizedURL == "http://example.com")
    }
    
    @Test("Should normalize URL without scheme")
    func testNormalizeURLWithoutScheme() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "example.com",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.normalizedURL == "https://example.com")
    }
    
    @Test("Should validate FTP URL")
    func testValidFTPURL() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "ftp://files.example.com/file.txt",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.normalizedURL == "ftp://files.example.com/file.txt")
    }
    
    // MARK: - Invalid URL Tests
    
    @Test("Should reject empty URL")
    func testEmptyURL() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == false)
        #expect(response.errorMessage == "URLが空です")
    }
    
    @Test("Should reject whitespace-only URL")
    func testWhitespaceOnlyURL() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "   ",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == false)
        #expect(response.errorMessage == "URLが空です")
    }
    
    @Test("Should reject invalid URL format")
    func testInvalidURLFormat() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "not-a-url",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == false)
        #expect(response.errorMessage == "無効なURL形式です")
    }
    
    @Test("Should reject unsupported scheme")
    func testUnsupportedScheme() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "file:///local/file.txt",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == false)
        #expect(response.errorMessage == "サポートされていないプロトコルです (http, https, ftp, ftps のみ対応)")
    }
    
    @Test("Should reject URL without host")
    func testURLWithoutHost() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "https://",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == false)
        #expect(response.errorMessage == "ホスト名が指定されていません")
    }
    
    // MARK: - Image URL Tests
    
    @Test("Should validate image URL with valid extension")
    func testValidImageURL() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "https://example.com/image.jpg",
            mediaType: .image
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.normalizedURL == "https://example.com/image.jpg")
    }
    
    @Test("Should reject image URL with invalid extension")
    func testInvalidImageExtension() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "https://example.com/document.pdf",
            mediaType: .image
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == false)
        #expect(response.errorMessage == "画像ファイルの拡張子ではありません")
    }
    
    @Test("Should validate image URL without extension")
    func testImageURLWithoutExtension() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "https://example.com/api/image",
            mediaType: .image
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.normalizedURL == "https://example.com/api/image")
    }
    
    // MARK: - URL Trimming Tests
    
    @Test("Should trim whitespace from URL")
    func testTrimWhitespace() async throws {
        // Given
        let request = ValidateMediaURLRequest(
            url: "  https://example.com  ",
            mediaType: .link
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.isValid == true)
        #expect(response.normalizedURL == "https://example.com")
    }
}