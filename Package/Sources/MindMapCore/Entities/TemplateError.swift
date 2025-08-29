import Foundation

public enum TemplateError: LocalizedError, Equatable {
    case templateNotFound
    case cannotDeletePreset
    case invalidTemplateData
    case duplicateTemplate
    case templateCreationFailed
    case templateUpdateFailed
    case missingRequiredFields
    case invalidCategory
    case templateInUse
    
    public var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "指定されたテンプレートが見つかりません"
        case .cannotDeletePreset:
            return "プリセットテンプレートは削除できません"
        case .invalidTemplateData:
            return "テンプレートデータが無効です"
        case .duplicateTemplate:
            return "同じ名前のテンプレートが既に存在します"
        case .templateCreationFailed:
            return "テンプレートの作成に失敗しました"
        case .templateUpdateFailed:
            return "テンプレートの更新に失敗しました"
        case .missingRequiredFields:
            return "必須フィールドが不足しています"
        case .invalidCategory:
            return "無効なカテゴリが指定されています"
        case .templateInUse:
            return "このテンプレートは使用中のため削除できません"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .templateNotFound:
            return "テンプレート一覧を確認して、正しいテンプレートを選択してください"
        case .cannotDeletePreset:
            return "カスタムテンプレートのみ削除が可能です"
        case .invalidTemplateData:
            return "テンプレートデータを再作成してください"
        case .duplicateTemplate:
            return "異なる名前を使用してください"
        case .templateCreationFailed:
            return "入力内容を確認して再度お試しください"
        case .templateUpdateFailed:
            return "変更内容を確認して再度お試しください"
        case .missingRequiredFields:
            return "タイトルとカテゴリは必須項目です"
        case .invalidCategory:
            return "有効なカテゴリを選択してください"
        case .templateInUse:
            return "使用中のマインドマップからテンプレート参照を解除してください"
        }
    }
}