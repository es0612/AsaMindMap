import Testing
@testable import MindMapCore

struct SimpleMonetizationTest {
    
    @Test("Product初期化テスト")
    func testSimpleProductCreation() throws {
        // Given & When
        let product = try Product(
            id: "test_product",
            displayName: "Test Product",
            description: "Test Description",
            price: 100.0,
            type: .subscription(.monthly)
        )
        
        // Then
        #expect(product.id == "test_product")
        #expect(product.price == 100.0)
    }
}