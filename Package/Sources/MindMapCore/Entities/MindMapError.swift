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

// MARK: - Tag Error Types
public enum TagError: LocalizedError, Equatable {
    case invalidName
    case tagNotFound
    case duplicateTag
    
    public var errorDescription: String? {
        switch self {
        case .invalidName:
            return "無効なタグ名です"
        case .tagNotFound:
            return "タグが見つかりません"
        case .duplicateTag:
            return "同名のタグが既に存在します"
        }
    }
}

// MARK: - Node Error Types
public enum NodeError: LocalizedError, Equatable {
    case notFound
    case invalidHierarchy
    case cyclicDependency
    
    public var errorDescription: String? {
        switch self {
        case .notFound:
            return "ノードが見つかりません"
        case .invalidHierarchy:
            return "無効な階層構造です"
        case .cyclicDependency:
            return "循環依存が検出されました"
        }
    }
}

// MARK: - Task Error Types
public enum TaskError: LocalizedError, Equatable {
    case notATask
    case invalidTaskState
    
    public var errorDescription: String? {
        switch self {
        case .notATask:
            return "このノードはタスクではありません"
        case .invalidTaskState:
            return "無効なタスク状態です"
        }
    }
}