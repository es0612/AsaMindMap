import Foundation

// MARK: - MindMap Validation Rules

// MARK: - Title Validation
public struct MindMapTitleNotEmptyRule: ValidationRule {
    public typealias Input = MindMap
    
    public init() {}
    
    public func validate(_ input: MindMap) -> ValidationResult {
        guard !input.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure("マインドマップのタイトルが空です")
        }
        return .success
    }
}

public struct MindMapTitleLengthRule: ValidationRule {
    public typealias Input = MindMap
    
    private let maxLength: Int
    
    public init(maxLength: Int = 100) {
        self.maxLength = maxLength
    }
    
    public func validate(_ input: MindMap) -> ValidationResult {
        guard input.title.count <= maxLength else {
            return .failure("タイトルが長すぎます（最大\(maxLength)文字）")
        }
        return .success
    }
}

// MARK: - Node Count Validation
public struct MindMapNodeCountRule: ValidationRule {
    public typealias Input = MindMap
    
    private let maxNodes: Int
    
    public init(maxNodes: Int = 1000) {
        self.maxNodes = maxNodes
    }
    
    public func validate(_ input: MindMap) -> ValidationResult {
        guard input.nodeCount <= maxNodes else {
            return .failure("ノード数が上限を超えています（最大\(maxNodes)個）")
        }
        return .success
    }
}

// MARK: - Root Node Validation
public struct MindMapRootNodeRule: ValidationRule {
    public typealias Input = MindMap
    
    public init() {}
    
    public func validate(_ input: MindMap) -> ValidationResult {
        // ノードがある場合はルートノードが必要
        guard input.nodeIDs.isEmpty || input.hasRootNode else {
            return .failure("ノードが存在する場合はルートノードが必要です")
        }
        
        // ルートノードがノードリストに含まれている必要がある
        if let rootID = input.rootNodeID {
            guard input.nodeIDs.contains(rootID) else {
                return .failure("ルートノードがノードリストに含まれていません")
            }
        }
        
        return .success
    }
}

// MARK: - Share URL Validation
public struct MindMapShareURLRule: ValidationRule {
    public typealias Input = MindMap
    
    public init() {}
    
    public func validate(_ input: MindMap) -> ValidationResult {
        // 共有が有効な場合はURLが必要
        if input.isShared {
            guard let shareURL = input.shareURL, !shareURL.isEmpty else {
                return .failure("共有が有効な場合は共有URLが必要です")
            }
            
            // URL形式の検証
            guard URL(string: shareURL) != nil else {
                return .failure("無効な共有URL形式です")
            }
        }
        
        return .success
    }
}

// MARK: - Version Validation
public struct MindMapVersionRule: ValidationRule {
    public typealias Input = MindMap
    
    public init() {}
    
    public func validate(_ input: MindMap) -> ValidationResult {
        guard input.version > 0 else {
            return .failure("バージョンは1以上である必要があります")
        }
        return .success
    }
}

// MARK: - MindMap Validator
public struct MindMapValidator {
    private let validation: CompositeValidation<MindMap>
    
    public init(
        maxTitleLength: Int = 100,
        maxNodes: Int = 1000
    ) {
        let rules: [AnyValidationRule<MindMap>] = [
            AnyValidationRule(MindMapTitleNotEmptyRule()),
            AnyValidationRule(MindMapTitleLengthRule(maxLength: maxTitleLength)),
            AnyValidationRule(MindMapNodeCountRule(maxNodes: maxNodes)),
            AnyValidationRule(MindMapRootNodeRule()),
            AnyValidationRule(MindMapShareURLRule()),
            AnyValidationRule(MindMapVersionRule())
        ]
        
        self.validation = CompositeValidation(rules)
    }
    
    public func validate(_ mindMap: MindMap) -> ValidationResult {
        validation.validate(mindMap)
    }
    
    public func validateForCreation(_ mindMap: MindMap) -> ValidationResult {
        // 作成時の特別なバリデーション
        let result = validate(mindMap)
        if case .failure = result {
            return result
        }
        
        // 追加の作成時チェック
        guard !mindMap.title.isEmpty else {
            return .failure("新しいマインドマップにはタイトルが必要です")
        }
        
        return .success
    }
    
    public func validateForSharing(_ mindMap: MindMap) -> ValidationResult {
        // 共有時の特別なバリデーション
        let result = validate(mindMap)
        if case .failure = result {
            return result
        }
        
        // 共有に必要な条件をチェック
        guard mindMap.hasNodes else {
            return .failure("空のマインドマップは共有できません")
        }
        
        return .success
    }
}