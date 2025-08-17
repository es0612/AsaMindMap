import Foundation

// MARK: - Validation Result
public enum ValidationResult: Equatable {
    case success
    case failure(String)
    
    public var isValid: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    public var errorMessage: String? {
        switch self {
        case .success:
            return nil
        case .failure(let message):
            return message
        }
    }
}

// MARK: - Validation Rule Protocol
public protocol ValidationRule {
    associatedtype Input
    func validate(_ input: Input) -> ValidationResult
}

// MARK: - Composite Validation
public struct CompositeValidation<T> {
    private let rules: [AnyValidationRule<T>]
    
    public init(_ rules: [AnyValidationRule<T>]) {
        self.rules = rules
    }
    
    public func validate(_ input: T) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(input)
            if case .failure = result {
                return result
            }
        }
        return .success
    }
}

// MARK: - Type-Erased Validation Rule
public struct AnyValidationRule<T> {
    private let _validate: (T) -> ValidationResult
    
    public init<Rule: ValidationRule>(_ rule: Rule) where Rule.Input == T {
        _validate = rule.validate
    }
    
    public func validate(_ input: T) -> ValidationResult {
        _validate(input)
    }
}