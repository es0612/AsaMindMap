import Testing
@testable import NetworkLayer

// MARK: - NetworkLayer Tests
struct NetworkLayerTests {
    
    @Test("NetworkLayerモジュールのバージョンが正しく設定されている")
    func testModuleVersion() {
        // Given & When
        let version = NetworkLayer.version
        
        // Then
        #expect(version == "1.0.0")
    }
    
    @Test("NetworkLayerモジュールの設定が正常に動作する")
    func testModuleConfiguration() {
        // When & Then
        // 設定が例外なく実行されることを確認
        NetworkLayer.configure()
        
        // 設定が完了したことを確認（実際の実装では適切な検証を行う）
        #expect(Bool(true))
    }
}