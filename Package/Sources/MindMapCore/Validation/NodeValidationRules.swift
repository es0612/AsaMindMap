import Foundation
import CoreGraphics

// MARK: - Node Validation Rules

// MARK: - Text Validation
public struct NodeTextNotEmptyRule: ValidationRule {
    public typealias Input = Node
    
    public init() {}
    
    public func validate(_ input: Node) -> ValidationResult {
        guard !input.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure("ノードのテキストが空です")
        }
        return .success
    }
}

public struct NodeTextLengthRule: ValidationRule {
    public typealias Input = Node
    
    private let maxLength: Int
    
    public init(maxLength: Int = 500) {
        self.maxLength = maxLength
    }
    
    public func validate(_ input: Node) -> ValidationResult {
        guard input.text.count <= maxLength else {
            return .failure("テキストが長すぎます（最大\(maxLength)文字）")
        }
        return .success
    }
}

// MARK: - Position Validation
public struct NodePositionValidRule: ValidationRule {
    public typealias Input = Node
    
    private let canvasBounds: CGRect
    
    public init(canvasBounds: CGRect = CGRect(x: -10000, y: -10000, width: 20000, height: 20000)) {
        self.canvasBounds = canvasBounds
    }
    
    public func validate(_ input: Node) -> ValidationResult {
        guard canvasBounds.contains(input.position) else {
            return .failure("ノードの位置が無効です")
        }
        return .success
    }
}

public struct NodePositionFiniteRule: ValidationRule {
    public typealias Input = Node
    
    public init() {}
    
    public func validate(_ input: Node) -> ValidationResult {
        guard input.position.x.isFinite && input.position.y.isFinite else {
            return .failure("ノードの位置に無効な値が含まれています")
        }
        return .success
    }
}

// MARK: - Font Size Validation
public struct NodeFontSizeRule: ValidationRule {
    public typealias Input = Node
    
    private let minSize: CGFloat
    private let maxSize: CGFloat
    
    public init(minSize: CGFloat = 8.0, maxSize: CGFloat = 72.0) {
        self.minSize = minSize
        self.maxSize = maxSize
    }
    
    public func validate(_ input: Node) -> ValidationResult {
        guard input.fontSize >= minSize && input.fontSize <= maxSize else {
            return .failure("フォントサイズは\(minSize)から\(maxSize)の間で設定してください")
        }
        return .success
    }
}

// MARK: - Task Validation
public struct NodeTaskConsistencyRule: ValidationRule {
    public typealias Input = Node
    
    public init() {}
    
    public func validate(_ input: Node) -> ValidationResult {
        // タスクでない場合は完了状態にできない
        guard !(!input.isTask && input.isCompleted) else {
            return .failure("タスクでないノードを完了状態にはできません")
        }
        return .success
    }
}

// MARK: - Node Validator
public struct NodeValidator {
    private let validation: CompositeValidation<Node>
    
    public init(
        canvasBounds: CGRect = CGRect(x: -10000, y: -10000, width: 20000, height: 20000),
        maxTextLength: Int = 500,
        minFontSize: CGFloat = 8.0,
        maxFontSize: CGFloat = 72.0
    ) {
        let rules: [AnyValidationRule<Node>] = [
            AnyValidationRule(NodeTextNotEmptyRule()),
            AnyValidationRule(NodeTextLengthRule(maxLength: maxTextLength)),
            AnyValidationRule(NodePositionValidRule(canvasBounds: canvasBounds)),
            AnyValidationRule(NodePositionFiniteRule()),
            AnyValidationRule(NodeFontSizeRule(minSize: minFontSize, maxSize: maxFontSize)),
            AnyValidationRule(NodeTaskConsistencyRule())
        ]
        
        self.validation = CompositeValidation(rules)
    }
    
    public func validate(_ node: Node) -> ValidationResult {
        validation.validate(node)
    }
    
    public func validateForCreation(_ node: Node) -> ValidationResult {
        // 作成時の特別なバリデーション
        let result = validate(node)
        if case .failure = result {
            return result
        }
        
        // 追加の作成時チェック
        guard !node.text.isEmpty else {
            return .failure("新しいノードにはテキストが必要です")
        }
        
        return .success
    }
}