import Foundation

// MARK: - Validate Media URL Use Case
public struct ValidateMediaURLUseCase: ValidateMediaURLUseCaseProtocol {
    
    // MARK: - Execute
    public func execute(_ request: ValidateMediaURLRequest) async throws -> ValidateMediaURLResponse {
        let url = request.url.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 1. Basic URL validation
        guard !url.isEmpty else {
            return ValidateMediaURLResponse(
                isValid: false,
                errorMessage: "URLが空です"
            )
        }
        
        // 2. URL format validation
        guard let urlComponents = URLComponents(string: url) else {
            return ValidateMediaURLResponse(
                isValid: false,
                errorMessage: "無効なURL形式です"
            )
        }
        
        // 3. Scheme validation
        let validSchemes = ["http", "https", "ftp", "ftps"]
        guard let scheme = urlComponents.scheme?.lowercased(),
              validSchemes.contains(scheme) else {
            return ValidateMediaURLResponse(
                isValid: false,
                errorMessage: "サポートされていないプロトコルです (http, https, ftp, ftps のみ対応)"
            )
        }
        
        // 4. Host validation
        guard let host = urlComponents.host, !host.isEmpty else {
            return ValidateMediaURLResponse(
                isValid: false,
                errorMessage: "ホスト名が指定されていません"
            )
        }
        
        // 5. Normalize URL
        var normalizedURL = url
        
        // Add https:// if no scheme is provided
        if !url.hasPrefix("http://") && !url.hasPrefix("https://") && 
           !url.hasPrefix("ftp://") && !url.hasPrefix("ftps://") {
            normalizedURL = "https://" + url
        }
        
        // 6. Media type specific validation
        switch request.mediaType {
        case .link:
            // Additional validation for links
            if let validatedURL = await validateLinkAccessibility(normalizedURL) {
                return ValidateMediaURLResponse(
                    isValid: true,
                    normalizedURL: validatedURL
                )
            } else {
                return ValidateMediaURLResponse(
                    isValid: true,
                    normalizedURL: normalizedURL,
                    errorMessage: "URLにアクセスできませんが、リンクとして保存されます"
                )
            }
            
        case .image:
            // Validate image URL extensions
            let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "svg", "bmp", "tiff"]
            let pathExtension = URL(string: normalizedURL)?.pathExtension.lowercased() ?? ""
            
            if !pathExtension.isEmpty && !imageExtensions.contains(pathExtension) {
                return ValidateMediaURLResponse(
                    isValid: false,
                    errorMessage: "画像ファイルの拡張子ではありません"
                )
            }
            
        default:
            break
        }
        
        return ValidateMediaURLResponse(
            isValid: true,
            normalizedURL: normalizedURL
        )
    }
    
    // MARK: - Private Methods
    private func validateLinkAccessibility(_ urlString: String) async -> String? {
        guard let url = URL(string: urlString) else { return nil }
        
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            
            if let httpResponse = response as? HTTPURLResponse {
                // Consider 2xx and 3xx status codes as valid
                if (200...399).contains(httpResponse.statusCode) {
                    return urlString
                }
            }
            
            return nil
        } catch {
            // Network error - URL might still be valid but not accessible
            return nil
        }
    }
}