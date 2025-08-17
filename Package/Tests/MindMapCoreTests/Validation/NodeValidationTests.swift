import Testing
import Foundation
import CoreGraphics
@testable import MindMapCore

struct NodeValidationTests {
    
    @Test("空のテキストバリデーション")
    func testEmptyTextValidation() {
        // Given
        let rule = NodeTextNotEmptyRule()
        let emptyNode = Node(text: "", position: .zero)
        let whitespaceNode = Node(text: "   ", position: .zero)
        let validNode = Node(text: "有効なテキスト", position: .zero)
        
        // When & Then
        #expect(rule.validate(emptyNode) == .failure("ノードのテキストが空です"))
        #expect(rule.validate(whitespaceNode) == .failure("ノードのテキストが空です"))
        #expect(rule.validate(validNode) == .success)
    }
    
    @Test("テキスト長バリデーション")
    func testTextLengthValidation() {
        // Given
        let rule = NodeTextLengthRule(maxLength: 10)
        let shortNode = Node(text: "短い", position: .zero)
        let exactNode = Node(text: "1234567890", position: .zero)
        let longNode = Node(text: "これは10文字を超える長いテキストです", position: .zero)
        
        // When & Then
        #expect(rule.validate(shortNode) == .success)
        #expect(rule.validate(exactNode) == .success)
        #expect(rule.validate(longNode) == .failure("テキストが長すぎます（最大10文字）"))
    }
    
    @Test("位置バリデーション")
    func testPositionValidation() {
        // Given
        let bounds = CGRect(x: 0, y: 0, width: 1000, height: 1000)
        let rule = NodePositionValidRule(canvasBounds: bounds)
        
        let validNode = Node(text: "テスト", position: CGPoint(x: 500, y: 500))
        let invalidNode = Node(text: "テスト", position: CGPoint(x: 1500, y: 500))
        let edgeNode = Node(text: "テスト", position: CGPoint(x: 999, y: 999)) // 境界内
        
        // When & Then
        #expect(rule.validate(validNode) == .success)
        #expect(rule.validate(invalidNode) == .failure("ノードの位置が無効です"))
        #expect(rule.validate(edgeNode) == .success)
    }
    
    @Test("有限位置バリデーション")
    func testFinitePositionValidation() {
        // Given
        let rule = NodePositionFiniteRule()
        let validNode = Node(text: "テスト", position: CGPoint(x: 100, y: 200))
        let infiniteXNode = Node(text: "テスト", position: CGPoint(x: CGFloat.infinity, y: 200))
        let nanYNode = Node(text: "テスト", position: CGPoint(x: 100, y: CGFloat.nan))
        
        // When & Then
        #expect(rule.validate(validNode) == .success)
        #expect(rule.validate(infiniteXNode) == .failure("ノードの位置に無効な値が含まれています"))
        #expect(rule.validate(nanYNode) == .failure("ノードの位置に無効な値が含まれています"))
    }
    
    @Test("フォントサイズバリデーション")
    func testFontSizeValidation() {
        // Given
        let rule = NodeFontSizeRule(minSize: 8.0, maxSize: 72.0)
        let validNode = Node(text: "テスト", position: .zero, fontSize: 16.0)
        let tooSmallNode = Node(text: "テスト", position: .zero, fontSize: 4.0)
        let tooLargeNode = Node(text: "テスト", position: .zero, fontSize: 100.0)
        let edgeMinNode = Node(text: "テスト", position: .zero, fontSize: 8.0)
        let edgeMaxNode = Node(text: "テスト", position: .zero, fontSize: 72.0)
        
        // When & Then
        #expect(rule.validate(validNode) == .success)
        #expect(rule.validate(tooSmallNode) == .failure("フォントサイズは8.0から72.0の間で設定してください"))
        #expect(rule.validate(tooLargeNode) == .failure("フォントサイズは8.0から72.0の間で設定してください"))
        #expect(rule.validate(edgeMinNode) == .success)
        #expect(rule.validate(edgeMaxNode) == .success)
    }
    
    @Test("タスク整合性バリデーション")
    func testTaskConsistencyValidation() {
        // Given
        let rule = NodeTaskConsistencyRule()
        let normalNode = Node(text: "テスト", position: .zero)
        let taskNode = Node(text: "テスト", position: .zero, isTask: true)
        let completedTaskNode = Node(text: "テスト", position: .zero, isTask: true, isCompleted: true)
        let invalidNode = Node(text: "テスト", position: .zero, isTask: false, isCompleted: true)
        
        // When & Then
        #expect(rule.validate(normalNode) == .success)
        #expect(rule.validate(taskNode) == .success)
        #expect(rule.validate(completedTaskNode) == .success)
        #expect(rule.validate(invalidNode) == .failure("タスクでないノードを完了状態にはできません"))
    }
    
    @Test("複合バリデーション")
    func testCompositeValidation() {
        // Given
        let validator = NodeValidator(
            canvasBounds: CGRect(x: 0, y: 0, width: 1000, height: 1000),
            maxTextLength: 50,
            minFontSize: 10.0,
            maxFontSize: 50.0
        )
        
        let validNode = Node(text: "有効なノード", position: CGPoint(x: 500, y: 500), fontSize: 16.0)
        let invalidTextNode = Node(text: "", position: CGPoint(x: 500, y: 500))
        let invalidPositionNode = Node(text: "テスト", position: CGPoint(x: 2000, y: 500))
        let invalidFontNode = Node(text: "テスト", position: CGPoint(x: 500, y: 500), fontSize: 5.0)
        
        // When & Then
        #expect(validator.validate(validNode) == .success)
        #expect(validator.validate(invalidTextNode).isValid == false)
        #expect(validator.validate(invalidPositionNode).isValid == false)
        #expect(validator.validate(invalidFontNode).isValid == false)
    }
    
    @Test("作成時バリデーション")
    func testCreationValidation() {
        // Given
        let validator = NodeValidator()
        let validNode = Node(text: "新しいノード", position: .zero)
        let emptyNode = Node(text: "", position: .zero)
        
        // When & Then
        #expect(validator.validateForCreation(validNode) == .success)
        // 空のテキストは基本バリデーションで失敗する
        let result = validator.validateForCreation(emptyNode)
        #expect(result.isValid == false)
        #expect(result.errorMessage == "ノードのテキストが空です")
    }
}