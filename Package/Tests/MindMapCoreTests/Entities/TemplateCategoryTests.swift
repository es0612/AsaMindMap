import Foundation
import Testing
@testable import MindMapCore

struct TemplateCategoryTests {
    
    @Test("全てのテンプレートカテゴリが適切な表示名を持つ")
    func testTemplateCategoryDisplayNames() {
        let categories: [(TemplateCategory, String)] = [
            (.business, "ビジネス"),
            (.education, "教育・学習"),
            (.creative, "クリエイティブ"),
            (.personal, "個人"),
            (.planning, "企画・計画"),
            (.research, "研究・調査")
        ]
        
        for (category, expectedName) in categories {
            #expect(category.displayName == expectedName)
            #expect(!category.displayName.isEmpty)
        }
    }
    
    @Test("全てのテンプレートカテゴリが適切なシステムアイコンを持つ")
    func testTemplateCategorySystemImages() {
        let categories: [(TemplateCategory, String)] = [
            (.business, "briefcase.fill"),
            (.education, "book.fill"),
            (.creative, "paintbrush.fill"),
            (.personal, "person.fill"),
            (.planning, "calendar.badge.plus"),
            (.research, "magnifyingglass")
        ]
        
        for (category, expectedIcon) in categories {
            #expect(category.systemImage == expectedIcon)
            #expect(!category.systemImage.isEmpty)
        }
    }
    
    @Test("カテゴリの色設定が適切に機能する")
    func testTemplateCategoryColors() {
        let allCategories = TemplateCategory.allCases
        
        for category in allCategories {
            let color = category.color
            #expect(color != nil)
            // 色が設定されていることを確認
        }
    }
    
    @Test("カテゴリの並び順が論理的である")
    func testTemplateCategorySortOrder() {
        let categories = TemplateCategory.allCases
        let expectedOrder: [TemplateCategory] = [
            .business, .education, .creative, .personal, .planning, .research
        ]
        
        #expect(categories.count == expectedOrder.count)
        for (index, category) in categories.enumerated() {
            #expect(category == expectedOrder[index])
        }
    }
    
    @Test("カテゴリ別テンプレート数のカウント")
    func testCategoryTemplateCount() {
        // Given
        let category = TemplateCategory.business
        
        // When
        let count = category.templateCount
        
        // Then
        #expect(count >= 0)
    }
}