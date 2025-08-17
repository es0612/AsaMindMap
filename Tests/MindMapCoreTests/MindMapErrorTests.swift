import Testing
@testable import MindMapCore

// MARK: - MindMapError Tests
struct MindMapErrorTests {
    
    @Test("エラーメッセージが正しく日本語で表示される")
    func testErrorDescriptions() {
        // Given & When & Then
        #expect(MindMapError.nodeCreationFailed.errorDescription == "ノードの作成に失敗しました")
        #expect(MindMapError.saveOperationFailed.errorDescription == "保存に失敗しました")
        #expect(MindMapError.syncConflict.errorDescription == "同期中に競合が発生しました")
        #expect(MindMapError.exportFailed(format: "PDF").errorDescription == "PDF形式でのエクスポートに失敗しました")
        #expect(MindMapError.importFailed(reason: "ファイルが見つかりません").errorDescription == "インポートに失敗しました: ファイルが見つかりません")
        #expect(MindMapError.invalidPosition.errorDescription == "無効な位置が指定されました")
        #expect(MindMapError.invalidNodeData.errorDescription == "無効なノードデータです")
        #expect(MindMapError.networkError("接続タイムアウト").errorDescription == "ネットワークエラー: 接続タイムアウト")
        #expect(MindMapError.validationError("必須項目が未入力").errorDescription == "バリデーションエラー: 必須項目が未入力")
    }
    
    @Test("回復提案が適切に提供される")
    func testRecoverySuggestions() {
        // Given & When & Then
        #expect(MindMapError.nodeCreationFailed.recoverySuggestion == "もう一度お試しください")
        #expect(MindMapError.saveOperationFailed.recoverySuggestion == "ネットワーク接続を確認してください")
        #expect(MindMapError.syncConflict.recoverySuggestion == "競合を解決してから再度同期してください")
        #expect(MindMapError.exportFailed(format: "PNG").recoverySuggestion == "別の形式でエクスポートを試してください")
        #expect(MindMapError.importFailed(reason: "形式エラー").recoverySuggestion == "ファイル形式を確認してください")
        #expect(MindMapError.invalidPosition.recoverySuggestion == "有効な位置を指定してください")
        #expect(MindMapError.invalidNodeData.recoverySuggestion == "ノードデータを確認してください")
        #expect(MindMapError.networkError("タイムアウト").recoverySuggestion == "ネットワーク接続を確認してください")
        #expect(MindMapError.validationError("入力エラー").recoverySuggestion == "入力内容を確認してください")
    }
    
    @Test("エラーの等価性比較が正常に動作する")
    func testErrorEquality() {
        // Given
        let error1 = MindMapError.nodeCreationFailed
        let error2 = MindMapError.nodeCreationFailed
        let error3 = MindMapError.saveOperationFailed
        
        let exportError1 = MindMapError.exportFailed(format: "PDF")
        let exportError2 = MindMapError.exportFailed(format: "PDF")
        let exportError3 = MindMapError.exportFailed(format: "PNG")
        
        // When & Then
        #expect(error1 == error2)
        #expect(error1 != error3)
        #expect(exportError1 == exportError2)
        #expect(exportError1 != exportError3)
    }
    
    @Test("関連値を持つエラーが正しく処理される")
    func testAssociatedValueErrors() {
        // Given
        let format = "OPML"
        let reason = "ファイルが破損しています"
        let networkMessage = "サーバーに接続できません"
        let validationMessage = "テキストが長すぎます"
        
        // When
        let exportError = MindMapError.exportFailed(format: format)
        let importError = MindMapError.importFailed(reason: reason)
        let networkError = MindMapError.networkError(networkMessage)
        let validationError = MindMapError.validationError(validationMessage)
        
        // Then
        #expect(exportError.errorDescription?.contains(format) == true)
        #expect(importError.errorDescription?.contains(reason) == true)
        #expect(networkError.errorDescription?.contains(networkMessage) == true)
        #expect(validationError.errorDescription?.contains(validationMessage) == true)
    }
    
    @Test("LocalizedErrorプロトコルに準拠している")
    func testLocalizedErrorConformance() {
        // Given
        let error = MindMapError.nodeCreationFailed
        
        // When & Then
        #expect(error.errorDescription != nil)
        #expect(error.recoverySuggestion != nil)
        
        // LocalizedErrorとして使用できることを確認
        let description = error.localizedDescription
        #expect(!description.isEmpty)
    }
}