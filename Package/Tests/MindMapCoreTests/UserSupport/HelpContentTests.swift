import Testing
import Foundation
@testable import MindMapCore

struct HelpContentTests {
    
    @Test("ヘルプコンテンツ作成テスト")
    func testHelpContentCreation() {
        // Given
        let id = UUID()
        let title = "マインドマップの作成方法"
        let content = "新しいマインドマップを作成するには..."
        let category = HelpCategory.gettingStarted
        
        // When
        let helpContent = HelpContent(
            id: id,
            title: title,
            content: content,
            category: category,
            steps: []
        )
        
        // Then
        #expect(helpContent.id == id)
        #expect(helpContent.title == title)
        #expect(helpContent.content == content)
        #expect(helpContent.category == category)
        #expect(helpContent.steps.isEmpty)
    }
    
    @Test("ヘルプコンテンツにステップ追加テスト")
    func testAddStepToHelpContent() {
        // Given
        var helpContent = HelpContent(
            id: UUID(),
            title: "テストタイトル",
            content: "テストコンテンツ",
            category: .basic,
            steps: []
        )
        
        let step = HelpStep(
            order: 1,
            title: "ステップ1",
            description: "最初のステップです",
            imageName: "step1_image"
        )
        
        // When
        helpContent.addStep(step)
        
        // Then
        #expect(helpContent.steps.count == 1)
        #expect(helpContent.steps.first?.title == "ステップ1")
    }
    
    @Test("ヘルプカテゴリー検索テスト")
    func testHelpContentFilterByCategory() {
        // Given
        let contents = [
            HelpContent(id: UUID(), title: "基本1", content: "内容1", category: .basic, steps: []),
            HelpContent(id: UUID(), title: "上級1", content: "内容2", category: .advanced, steps: []),
            HelpContent(id: UUID(), title: "基本2", content: "内容3", category: .basic, steps: [])
        ]
        
        // When
        let basicContents = contents.filter { $0.category == .basic }
        
        // Then
        #expect(basicContents.count == 2)
        #expect(basicContents.allSatisfy { $0.category == .basic })
    }
}