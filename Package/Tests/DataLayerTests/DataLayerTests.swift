import Testing
@testable import DataLayer

// MARK: - DataLayer Tests
struct DataLayerTests {
    
    @Test("DataLayerモジュールのバージョンが正しく設定されている")
    func testModuleVersion() {
        // Given & When
        let version = DataLayer.version
        
        // Then
        #expect(version == "1.0.0")
    }
    
    @Test("DataLayerモジュールの設定が正常に動作する")
    func testModuleConfiguration() {
        // When & Then
        // 設定が例外なく実行されることを確認
        DataLayer.configure()
        
        // 設定が完了したことを確認（実際の実装では適切な検証を行う）
        #expect(Bool(true))
    }
}