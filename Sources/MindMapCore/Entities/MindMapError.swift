import Foundation

// MARK: - MindMap Error Types
public enum MindMapError: LocalizedError, Equatable {
    case nodeCreationFailed
    case saveOperationFailed
    case syncConflict
    case exportFailed(format: String)
    case importFailed(reason: String)
    case invalidPosition
    case invalidNodeData
    case networkError(String)
    case validationError(String)
    
    public var errorDescription: String? {
        switch self {
        case .nodeCreationFailed:
            return "ノードの作成に失敗しました"
        case .saveOperationFailed:
            return "保存に失敗しました"
        case .syncConflict:
            return "同期中に競合が発生しました"
        case .exportFailed(let format):
            return "\(format)形式でのエクスポートに失敗しました"
        case .importFailed(let reason):
            return "インポートに失敗しました: \(reason)"
        case .invalidPosition:
            return "無効な位置が指定されました"
        case .invalidNodeData:
            return "無効なノードデータです"
        case .networkError(let message):
            return "ネットワークエラー: \(message)"
        case .validationError(let message):
            return "バリデーションエラー: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .nodeCreationFailed:
            return "もう一度お試しください"
        case .saveOperationFailed:
            return "ネットワーク接続を確認してください"
        case .syncConflict:
            return "競合を解決してから再度同期してください"
        case .exportFailed:
            return "別の形式でエクスポートを試してください"
        case .importFailed:
            return "ファイル形式を確認してください"
        case .invalidPosition:
            return "有効な位置を指定してください"
        case .invalidNodeData:
            return "ノードデータを確認してください"
        case .networkError:
            return "ネットワーク接続を確認してください"
        case .validationError:
            return "入力内容を確認してください"
        }
    }
}