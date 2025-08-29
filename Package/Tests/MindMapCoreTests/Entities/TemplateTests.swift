import Foundation
import Testing
@testable import MindMapCore

struct TemplateTests {
    
    @Test("テンプレート作成時に必要な属性が設定される")
    func testTemplateCreation() {
        // Given
        let title = "プロジェクト企画テンプレート"
        let description = "新規プロジェクトの企画書作成用テンプレート"
        let category = TemplateCategory.business
        
        // When
        let template = Template(
            title: title,
            description: description,
            category: category,
            isPreset: false
        )
        
        // Then
        #expect(template.title == title)
        #expect(template.description == description)
        #expect(template.category == category)
        #expect(template.isPreset == false)
        #expect(template.id != UUID())
        #expect(template.createdAt <= Date())
        #expect(template.updatedAt <= Date())
    }
    
    @Test("プリセットテンプレート作成")
    func testPresetTemplateCreation() {
        // Given
        let title = "ブレインストーミング"
        let description = "アイデア発想用の標準テンプレート"
        let category = TemplateCategory.creative
        
        // When
        let template = Template.createPreset(
            title: title,
            description: description,
            category: category
        )
        
        // Then
        #expect(template.isPreset == true)
        #expect(template.title == title)
        #expect(template.category == category)
        #expect(!template.canEdit) // プリセットは編集不可
    }
    
    @Test("テンプレートノード構造の設定")
    func testTemplateNodeStructure() {
        // Given
        let template = Template(
            title: "学習ノート",
            description: "授業ノート作成用テンプレート",
            category: TemplateCategory.education,
            isPreset: false
        )
        
        let rootNode = TemplateNode(
            text: "授業タイトル",
            position: CGPoint(x: 0, y: 0),
            nodeType: .central
        )
        
        let childNode1 = TemplateNode(
            text: "重要ポイント",
            position: CGPoint(x: -100, y: -50),
            nodeType: .topic
        )
        
        let childNode2 = TemplateNode(
            text: "質問・疑問",
            position: CGPoint(x: 100, y: 50),
            nodeType: .question
        )
        
        // When
        template.setRootNode(rootNode)
        template.addNode(childNode1, parentId: rootNode.id)
        template.addNode(childNode2, parentId: rootNode.id)
        
        // Then
        #expect(template.rootNode == rootNode)
        #expect(template.nodes.count == 3)
        let actualRootNode = template.nodes.first { $0.id == rootNode.id }
        #expect(actualRootNode?.childNodeIds.count == 2)
        #expect(actualRootNode?.childNodeIds.contains(childNode1.id) == true)
        #expect(actualRootNode?.childNodeIds.contains(childNode2.id) == true)
    }
    
    @Test("テンプレートカテゴリの検証")
    func testTemplateCategoryValidation() {
        // Given
        let categories: [TemplateCategory] = [
            .business, .education, .creative, .personal, .planning, .research
        ]
        
        // When & Then
        for category in categories {
            let template = Template(
                title: "Test Template",
                description: "Test Description",
                category: category,
                isPreset: false
            )
            
            #expect(template.category == category)
            #expect(!template.category.displayName.isEmpty)
            #expect(!template.category.systemImage.isEmpty)
        }
    }
    
    @Test("テンプレート適用によるマインドマップ作成")
    func testApplyTemplateToMindMap() {
        // Given
        let template = Template(
            title: "会議準備",
            description: "会議のアジェンダ作成用",
            category: TemplateCategory.business,
            isPreset: true
        )
        
        let rootNode = TemplateNode(
            text: "会議タイトル: [会議名を入力]",
            position: CGPoint(x: 0, y: 0),
            nodeType: .central
        )
        template.setRootNode(rootNode)
        
        // When
        let mindMap = template.createMindMap(title: "週次定例会議")
        
        // Then
        #expect(mindMap.title == "週次定例会議")
        #expect(mindMap.templateId == template.id)
        #expect(mindMap.rootNode != nil)
        #expect(mindMap.rootNode?.text.contains("[会議名を入力]") == false)
    }
}