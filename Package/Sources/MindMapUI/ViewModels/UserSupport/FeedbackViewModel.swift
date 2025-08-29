import Foundation
import SwiftUI
import Combine
import MindMapCore

@MainActor
public class FeedbackViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var feedbackType: FeedbackType = .bug
    @Published public var title: String = ""
    @Published public var description: String = ""
    @Published public var userEmail: String = ""
    @Published public var attachments: [FeedbackAttachment] = []
    @Published public var isSubmitting: Bool = false
    @Published public var showSuccess: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Computed Properties
    
    public var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        description.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
    }
    
    public var totalAttachmentSize: Int {
        attachments.reduce(0) { $0 + $1.size }
    }
    
    public var canAddMoreAttachments: Bool {
        attachments.count < 5 && totalAttachmentSize < 50 * 1024 * 1024 // 50MB limit
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    public func submitFeedback() async {
        guard isFormValid else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let deviceInfo = DeviceInfo.current
            
            let feedback = Feedback(
                type: feedbackType,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                description: description.trimmingCharacters(in: .whitespacesAndNewlines),
                userEmail: userEmail.isEmpty ? nil : userEmail,
                deviceInfo: deviceInfo,
                attachments: attachments
            )
            
            // シミュレートされたフィードバック送信処理
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1秒の遅延
            
            // 送信成功のシミュレーション
            showSuccess = true
            resetForm()
            
        } catch {
            errorMessage = "フィードバックの送信に失敗しました: \(error.localizedDescription)"
        }
        
        isSubmitting = false
    }
    
    public func addAttachment(data: Data, filename: String, mimeType: String) {
        guard canAddMoreAttachments else { return }
        
        let attachment = FeedbackAttachment(
            type: determineAttachmentType(from: mimeType),
            filename: filename,
            data: data,
            mimeType: mimeType
        )
        
        guard attachment.isValidSize else {
            errorMessage = "添付ファイルのサイズが大きすぎます（最大: \(attachment.type.maxSize / 1024 / 1024)MB）"
            return
        }
        
        attachments.append(attachment)
    }
    
    public func removeAttachment(id: UUID) {
        attachments.removeAll { $0.id == id }
    }
    
    public func resetForm() {
        title = ""
        description = ""
        userEmail = ""
        attachments = []
        errorMessage = nil
        showSuccess = false
    }
    
    public func dismissSuccess() {
        showSuccess = false
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // エラーメッセージの自動クリア
        Publishers.CombineLatest3($title, $description, $userEmail)
            .sink { [weak self] _, _, _ in
                self?.errorMessage = nil
            }
            .store(in: &cancellables)
    }
    
    private func determineAttachmentType(from mimeType: String) -> FeedbackAttachmentType {
        if mimeType.starts(with: "image/") {
            return .screenshot
        } else if mimeType.starts(with: "video/") {
            return .video
        } else if mimeType.contains("text") || mimeType.contains("log") {
            return .log
        } else if mimeType.contains("document") || mimeType.contains("pdf") {
            return .document
        } else {
            return .other
        }
    }
    
    // MARK: - Sample Data for Testing
    
    public static func createSampleFeedback() -> Feedback {
        return Feedback(
            type: .bug,
            title: "サンプルバグレポート",
            description: "これはテスト用のフィードバックです。実際のバグではありません。",
            userEmail: "test@example.com",
            deviceInfo: DeviceInfo.current,
            attachments: []
        )
    }
}