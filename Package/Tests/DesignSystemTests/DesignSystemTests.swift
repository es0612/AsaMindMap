import Testing
import Foundation
@testable import DesignSystem

// MARK: - DesignSystem Tests
struct DesignSystemTests {
    
    @Test("DesignSystemモジュールのバージョンが正しく設定されている")
    func testModuleVersion() {
        // Given & When
        let version = DesignSystem.version
        
        // Then
        #expect(version == "1.0.0")
    }
    
    @Test("カラーシステムが正しく定義されている")
    func testColorSystem() {
        // Given & When & Then
        #expect(DesignSystem.Colors.primaryHex == "#007AFF")
        #expect(DesignSystem.Colors.secondaryHex == "#8E8E93")
        #expect(DesignSystem.Colors.backgroundHex == "#FFFFFF")
        #expect(DesignSystem.Colors.surfaceHex == "#F2F2F7")
        #expect(DesignSystem.Colors.onPrimaryHex == "#FFFFFF")
        #expect(DesignSystem.Colors.onSecondaryHex == "#000000")
    }
    
    @Test("タイポグラフィシステムが正しく定義されている")
    func testTypographySystem() {
        // Given & When & Then
        #expect(DesignSystem.Typography.titleSize == 34)
        #expect(DesignSystem.Typography.headlineSize == 17)
        #expect(DesignSystem.Typography.bodySize == 17)
        #expect(DesignSystem.Typography.captionSize == 12)
    }
    
    @Test("スペーシングシステムが正しく定義されている")
    func testSpacingSystem() {
        // Given & When & Then
        #expect(DesignSystem.Spacing.xs == 4)
        #expect(DesignSystem.Spacing.sm == 8)
        #expect(DesignSystem.Spacing.md == 16)
        #expect(DesignSystem.Spacing.lg == 24)
        #expect(DesignSystem.Spacing.xl == 32)
        #expect(DesignSystem.Spacing.xxl == 48)
    }
    
    @Test("スペーシング値が昇順になっている")
    func testSpacingOrder() {
        // Given & When & Then
        #expect(DesignSystem.Spacing.xs < DesignSystem.Spacing.sm)
        #expect(DesignSystem.Spacing.sm < DesignSystem.Spacing.md)
        #expect(DesignSystem.Spacing.md < DesignSystem.Spacing.lg)
        #expect(DesignSystem.Spacing.lg < DesignSystem.Spacing.xl)
        #expect(DesignSystem.Spacing.xl < DesignSystem.Spacing.xxl)
    }
    
    @Test("フォントサイズが適切な範囲内にある")
    func testTypographySizes() {
        // Given & When & Then
        #expect(DesignSystem.Typography.captionSize < DesignSystem.Typography.bodySize)
        #expect(DesignSystem.Typography.bodySize == DesignSystem.Typography.headlineSize)
        #expect(DesignSystem.Typography.headlineSize < DesignSystem.Typography.titleSize)
        
        // 一般的なフォントサイズの範囲内であることを確認
        #expect(DesignSystem.Typography.captionSize >= 8)
        #expect(DesignSystem.Typography.titleSize <= 50)
    }
}