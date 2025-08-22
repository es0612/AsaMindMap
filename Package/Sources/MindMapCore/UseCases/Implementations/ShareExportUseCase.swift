import Foundation

final class ShareExportUseCase: ShareExportUseCaseProtocol {
    
    private let exportUseCase: ExportMindMapUseCaseProtocol
    
    init(exportUseCase: ExportMindMapUseCaseProtocol) {
        self.exportUseCase = exportUseCase
    }
    
    func execute(_ request: ShareExportRequest) async throws -> ShareExportResponse {
        var sharedFormats: [ExportFormat] = []
        var lastError: Error?
        
        for format in request.formats {
            do {
                let exportRequest = ExportMindMapRequest(
                    mindMapID: request.mindMapID,
                    format: format
                )
                
                let _ = try await exportUseCase.execute(exportRequest)
                sharedFormats.append(format)
            } catch {
                lastError = error
            }
        }
        
        let success = !sharedFormats.isEmpty
        
        return ShareExportResponse(
            success: success,
            sharedFormats: sharedFormats,
            error: lastError
        )
    }
}