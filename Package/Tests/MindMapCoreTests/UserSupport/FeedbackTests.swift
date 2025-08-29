import Testing
import Foundation
@testable import MindMapCore

struct FeedbackTests {
    
    @Test("フィードバック作成テスト")
    func testFeedbackCreation() {
        // Given
        let id = UUID()
        let type = FeedbackType.bug
        let title = "ノード作成時のクラッシュ"
        let description = "新しいノードを作成しようとするとアプリがクラッシュします"
        let userEmail = "test@example.com"
        let appVersion = "1.0.0"
        let deviceInfo = DeviceInfo(
            model: "iPhone 14 Pro",
            osVersion: "iOS 17.0",
            appVersion: "1.0.0"
        )
        
        // When
        let feedback = Feedback(
            id: id,
            type: type,
            title: title,
            description: description,
            userEmail: userEmail,
            deviceInfo: deviceInfo,
            attachments: [],
            status: .pending,
            createdAt: Date()
        )
        
        // Then
        #expect(feedback.id == id)
        #expect(feedback.type == type)
        #expect(feedback.title == title)
        #expect(feedback.description == description)
        #expect(feedback.userEmail == userEmail)
        #expect(feedback.deviceInfo.model == "iPhone 14 Pro")
        #expect(feedback.status == .pending)
        #expect(feedback.attachments.isEmpty)
    }
    
    @Test("フィードバック添付ファイル追加テスト")
    func testFeedbackWithAttachment() {
        // Given
        var feedback = Feedback(
            id: UUID(),
            type: .feature,
            title: "新機能提案",
            description: "新しい機能の提案です",
            userEmail: "user@example.com",
            deviceInfo: DeviceInfo(model: "iPad Pro", osVersion: "iOS 17.1", appVersion: "1.0.0"),
            attachments: [],
            status: .pending,
            createdAt: Date()
        )
        
        let attachment = FeedbackAttachment(
            id: UUID(),
            type: .screenshot,
            filename: "screenshot.png",
            data: Data("mock image data".utf8),
            mimeType: "image/png"
        )
        
        // When
        feedback.addAttachment(attachment)
        
        // Then
        #expect(feedback.attachments.count == 1)
        #expect(feedback.attachments.first?.filename == "screenshot.png")
        #expect(feedback.attachments.first?.type == .screenshot)
    }
    
    @Test("フィードバックバリデーションテスト")
    func testFeedbackValidation() {
        // Given - Valid feedback
        let validFeedback = Feedback(
            id: UUID(),
            type: .bug,
            title: "有効なフィードバック",
            description: "これは有効な説明です。十分な詳細が含まれています。",
            userEmail: "valid@example.com",
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            attachments: [],
            status: .pending,
            createdAt: Date()
        )
        
        // Then
        #expect(validFeedback.isValid == true)
        
        // Given - Invalid feedback (too short description)
        let invalidFeedback = Feedback(
            id: UUID(),
            type: .bug,
            title: "短い",
            description: "短い",  // Too short
            userEmail: "invalid-email",  // Invalid email format
            deviceInfo: DeviceInfo(model: "", osVersion: "", appVersion: ""),  // Empty device info
            attachments: [],
            status: .pending,
            createdAt: Date()
        )
        
        // Then
        #expect(invalidFeedback.isValid == false)
    }
    
    @Test("フィードバック優先度判定テスト")
    func testFeedbackPriorityAssignment() {
        // Given - Bug feedback
        let bugFeedback = Feedback(
            id: UUID(),
            type: .bug,
            title: "クラッシュバグ",
            description: "アプリがクラッシュする重要な問題です。",
            userEmail: "user@example.com",
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            attachments: [],
            status: .pending,
            createdAt: Date()
        )
        
        // Then
        #expect(bugFeedback.priority == .high)
        
        // Given - Feature request
        let featureFeedback = Feedback(
            id: UUID(),
            type: .feature,
            title: "新機能提案",
            description: "新しい機能があると便利です。",
            userEmail: "user@example.com",
            deviceInfo: DeviceInfo(model: "iPhone", osVersion: "iOS 17.0", appVersion: "1.0.0"),
            attachments: [],
            status: .pending,
            createdAt: Date()
        )
        
        // Then
        #expect(featureFeedback.priority == .medium)
    }
}