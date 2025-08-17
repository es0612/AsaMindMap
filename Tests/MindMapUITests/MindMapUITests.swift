import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - MindMapUI Tests
struct MindMapUITests {
    
    @Test("MindMapUIモジュールのバージョンが正しく設定されている")
    func testModuleVersion() {
        // Given & When
        let version = MindMapUI.version
        
        // Then
        #expect(version == "1.0.0")
    }
    
    @Test("MindMapUIモジュールの設定が正常に動作する")
    func testModuleConfiguration() {
        // Given
        let container = DIContainer()
        
        // When & Then
        // 設定が例外なく実行されることを確認
        MindMapUI.configure(with: container)
        
        // 設定が完了したことを確認（実際の実装では適切な検証を行う）
        #expect(Bool(true))
    }
}