import Foundation
import CoreGraphics

// MARK: - Export Use Cases

/// エクスポート形式の定義
public enum ExportFormat: String, CaseIterable {
    case pdf = "pdf"
    case png = "png"  
    case opml = "opml"
    case csv = "csv"
    
    var fileExtension: String { rawValue }
    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .png: return "image/png"
        case .opml: return "text/x-opml"
        case .csv: return "text/csv"
        }
    }
}

/// エクスポート要求
public struct ExportMindMapRequest {
    public let mindMapID: UUID
    public let format: ExportFormat
    public let options: ExportOptions
    
    public init(mindMapID: UUID, format: ExportFormat, options: ExportOptions = ExportOptions()) {
        self.mindMapID = mindMapID
        self.format = format
        self.options = options
    }
}

/// エクスポートオプション
public struct ExportOptions {
    public let includeImages: Bool
    public let paperSize: PaperSize
    public let imageQuality: ImageQuality
    public let transparentBackground: Bool
    
    public init(
        includeImages: Bool = true,
        paperSize: PaperSize = .a4,
        imageQuality: ImageQuality = .high,
        transparentBackground: Bool = false
    ) {
        self.includeImages = includeImages
        self.paperSize = paperSize
        self.imageQuality = imageQuality
        self.transparentBackground = transparentBackground
    }
}

public enum PaperSize: CaseIterable {
    case a4, a3, letter
    
    var size: CGSize {
        switch self {
        case .a4: return CGSize(width: 595, height: 842)
        case .a3: return CGSize(width: 842, height: 1191)
        case .letter: return CGSize(width: 612, height: 792)
        }
    }
}

public enum ImageQuality: CaseIterable {
    case low, medium, high
    
    var compressionQuality: CGFloat {
        switch self {
        case .low: return 0.3
        case .medium: return 0.7
        case .high: return 0.9
        }
    }
}

/// エクスポート結果
public struct ExportMindMapResponse {
    public let fileData: Data
    public let filename: String
    public let mimeType: String
    public let fileSize: Int64
    
    public init(fileData: Data, filename: String, mimeType: String) {
        self.fileData = fileData
        self.filename = filename
        self.mimeType = mimeType
        self.fileSize = Int64(fileData.count)
    }
}

/// エクスポートエラー
public enum ExportError: LocalizedError {
    case mindMapNotFound
    case unsupportedFormat
    case renderingFailed
    case dataGenerationFailed
    case fileSizeExceeded
    
    public var errorDescription: String? {
        switch self {
        case .mindMapNotFound:
            return "マインドマップが見つかりません"
        case .unsupportedFormat:
            return "サポートされていない形式です"
        case .renderingFailed:
            return "レンダリングに失敗しました"
        case .dataGenerationFailed:
            return "データの生成に失敗しました"
        case .fileSizeExceeded:
            return "ファイルサイズが上限を超えています"
        }
    }
}

// MARK: - Import Use Cases

/// インポート形式の定義
public enum ImportFormat: String, CaseIterable {
    case opml = "opml"
    case csv = "csv"
    case mindMap = "asa"  // 独自形式
    
    var fileExtension: String { rawValue }
}

/// インポート要求
public struct ImportMindMapRequest {
    public let fileData: Data
    public let filename: String
    public let format: ImportFormat
    public let options: ImportOptions
    
    public init(fileData: Data, filename: String, format: ImportFormat, options: ImportOptions = ImportOptions()) {
        self.fileData = fileData
        self.filename = filename
        self.format = format
        self.options = options
    }
}

/// インポートオプション
public struct ImportOptions {
    public let mergeWithExisting: Bool
    public let preserveIDs: Bool
    public let validateStructure: Bool
    
    public init(
        mergeWithExisting: Bool = false,
        preserveIDs: Bool = false,
        validateStructure: Bool = true
    ) {
        self.mergeWithExisting = mergeWithExisting
        self.preserveIDs = preserveIDs
        self.validateStructure = validateStructure
    }
}

/// インポート結果  
public struct ImportMindMapResponse {
    public let mindMap: MindMap
    public let nodes: [Node]
    public let importSummary: ImportSummary
    
    public init(mindMap: MindMap, nodes: [Node], importSummary: ImportSummary) {
        self.mindMap = mindMap
        self.nodes = nodes
        self.importSummary = importSummary
    }
}

/// インポート概要
public struct ImportSummary {
    public let totalNodes: Int
    public let successfulImports: Int
    public let failedImports: Int
    public let warnings: [String]
    
    public init(totalNodes: Int, successfulImports: Int, failedImports: Int, warnings: [String] = []) {
        self.totalNodes = totalNodes
        self.successfulImports = successfulImports
        self.failedImports = failedImports
        self.warnings = warnings
    }
}

/// インポートエラー
public enum ImportError: LocalizedError {
    case invalidFileFormat
    case corruptedData
    case unsupportedVersion
    case structureValidationFailed
    case fileSizeTooLarge
    
    public var errorDescription: String? {
        switch self {
        case .invalidFileFormat:
            return "無効なファイル形式です"
        case .corruptedData:
            return "ファイルが破損しています"
        case .unsupportedVersion:
            return "サポートされていないバージョンです"
        case .structureValidationFailed:
            return "ファイル構造の検証に失敗しました"
        case .fileSizeTooLarge:
            return "ファイルサイズが大きすぎます"
        }
    }
}

// MARK: - Use Case Protocols

/// エクスポートユースケース
public protocol ExportMindMapUseCaseProtocol {
    func execute(_ request: ExportMindMapRequest) async throws -> ExportMindMapResponse
}

/// インポートユースケース
public protocol ImportMindMapUseCaseProtocol {
    func execute(_ request: ImportMindMapRequest) async throws -> ImportMindMapResponse
}

// MARK: - Share Sheet Integration

/// iOS共有シート統合（エクスポート用）
public struct ShareExportRequest {
    public let mindMapID: UUID
    public let formats: [ExportFormat]
    public let presentingViewController: Any? // UIViewController
    
    public init(mindMapID: UUID, formats: [ExportFormat], presentingViewController: Any? = nil) {
        self.mindMapID = mindMapID
        self.formats = formats
        self.presentingViewController = presentingViewController
    }
}

/// 共有結果（エクスポート用）
public struct ShareExportResponse {
    public let success: Bool
    public let sharedFormats: [ExportFormat]
    public let error: Error?
    
    public init(success: Bool, sharedFormats: [ExportFormat], error: Error? = nil) {
        self.success = success
        self.sharedFormats = sharedFormats
        self.error = error
    }
}

/// 共有ユースケース（エクスポート用）
public protocol ShareExportUseCaseProtocol {
    func execute(_ request: ShareExportRequest) async throws -> ShareExportResponse
}