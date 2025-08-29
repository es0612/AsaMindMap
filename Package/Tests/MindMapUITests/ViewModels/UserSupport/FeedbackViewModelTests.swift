import Testing
import Foundation
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

struct FeedbackViewModelTests {
    
    @Test("フィードバックViewModelの初期化テスト")
    func testFeedbackViewModelInitialization() {
        // When
        let viewModel = FeedbackViewModel()
        
        // Then
        #expect(viewModel.feedbackType == .bug)
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.description.isEmpty)
        #expect(viewModel.userEmail.isEmpty)
        #expect(viewModel.attachments.isEmpty)
        #expect(viewModel.isSubmitting == false)
        #expect(viewModel.showSuccess == false)
    }
    
    @Test("フィードバック送信テスト")
    func testSubmitFeedback() async {
        // Given
        let viewModel = FeedbackViewModel()
        viewModel.feedbackType = .feature
        viewModel.title = "新機能のリクエスト"
        viewModel.description = "このような機能があると便利です"
        viewModel.userEmail = "user@example.com"
        
        // When
        await viewModel.submitFeedback()
        
        // Then
        #expect(viewModel.showSuccess == true)
        #expect(viewModel.isSubmitting == false)
    }
    
    @Test("フィードバックバリデーションテスト")
    func testFeedbackValidation() {
        // Given
        let viewModel = FeedbackViewModel()
        
        // When - 空の状態でバリデーション
        let isValidEmpty = viewModel.isFormValid
        
        // Then
        #expect(isValidEmpty == false)
        
        // When - 必要項目を入力
        viewModel.title = "テストタイトル"
        viewModel.description = "十分な長さの説明テキスト"
        
        let isValidFilled = viewModel.isFormValid
        
        // Then
        #expect(isValidFilled == true)
    }
    
    @Test("添付ファイル追加テスト")
    func testAddAttachment() {
        // Given
        let viewModel = FeedbackViewModel()
        let testData = Data("test image data".utf8)
        
        // When
        viewModel.addAttachment(data: testData, filename: "test.png", mimeType: "image/png")
        
        // Then
        #expect(viewModel.attachments.count == 1)
        #expect(viewModel.attachments.first?.filename == "test.png")
    }
    
    @Test("添付ファイル削除テスト")
    func testRemoveAttachment() {
        // Given
        let viewModel = FeedbackViewModel()
        let testData = Data("test image data".utf8)
        viewModel.addAttachment(data: testData, filename: "test.png", mimeType: "image/png")
        
        guard let attachmentId = viewModel.attachments.first?.id else {
            Issue.record("添付ファイルが追加されていません")
            return
        }
        
        // When
        viewModel.removeAttachment(id: attachmentId)
        
        // Then
        #expect(viewModel.attachments.isEmpty)
    }
}