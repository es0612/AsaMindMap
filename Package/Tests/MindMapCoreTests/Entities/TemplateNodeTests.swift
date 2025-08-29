import Foundation
import Testing
@testable import MindMapCore

struct TemplateNodeTests {
    
    @Test("テンプレートノード作成時の基本属性設定")
    func testTemplateNodeCreation() {
        // Given
        let text = "中心テーマ"
        let position = CGPoint(x: 100, y: 200)
        let nodeType = TemplateNodeType.central
        
        // When
        let templateNode = TemplateNode(
            text: text,
            position: position,
            nodeType: nodeType
        )
        
        // Then
        #expect(templateNode.text == text)
        #expect(templateNode.position == position)
        #expect(templateNode.nodeType == nodeType)
        #expect(templateNode.id != UUID())
        #expect(templateNode.childNodeIds.isEmpty)
        #expect(templateNode.parentNodeId == nil)
    }
    
    @Test("テンプレートノードの階層構造構築")
    func testTemplateNodeHierarchy() {
        // Given
        var parentNode = TemplateNode(
            text: "親ノード",
            position: CGPoint(x: 0, y: 0),
            nodeType: .central
        )
        
        var childNode1 = TemplateNode(
            text: "子ノード1",
            position: CGPoint(x: -100, y: -50),
            nodeType: .topic
        )
        
        var childNode2 = TemplateNode(
            text: "子ノード2",
            position: CGPoint(x: 100, y: 50),
            nodeType: .topic
        )
        
        // When
        parentNode.addChild(childNode1.id)
        parentNode.addChild(childNode2.id)
        childNode1.parentNodeId = parentNode.id
        childNode2.parentNodeId = parentNode.id
        
        // Then
        #expect(parentNode.childNodeIds.count == 2)
        #expect(parentNode.childNodeIds.contains(childNode1.id))
        #expect(parentNode.childNodeIds.contains(childNode2.id))
        #expect(childNode1.parentNodeId == parentNode.id)
        #expect(childNode2.parentNodeId == parentNode.id)
    }
    
    @Test("テンプレートノードタイプの特性")
    func testTemplateNodeTypeCharacteristics() {
        let nodeTypes: [(TemplateNodeType, String, Bool)] = [
            (.central, "中心", true),
            (.topic, "トピック", false),
            (.subtopic, "サブトピック", false),
            (.question, "質問", false),
            (.action, "アクション", false),
            (.note, "ノート", false)
        ]
        
        for (nodeType, expectedDisplayName, expectedIsCentral) in nodeTypes {
            #expect(nodeType.displayName == expectedDisplayName)
            #expect(nodeType.isCentral == expectedIsCentral)
            #expect(!nodeType.systemImage.isEmpty)
        }
    }
    
    @Test("プレースホルダーテキストの処理")
    func testPlaceholderTextProcessing() {
        // Given
        let templateNode = TemplateNode(
            text: "プロジェクト名: [プロジェクト名を入力してください]",
            position: CGPoint(x: 0, y: 0),
            nodeType: .central
        )
        
        // When
        let hasPlaceholder = templateNode.hasPlaceholder
        let placeholders = templateNode.placeholders
        
        // Then
        #expect(hasPlaceholder == true)
        #expect(placeholders.count == 1)
        #expect(placeholders.first == "[プロジェクト名を入力してください]")
    }
    
    @Test("テンプレートノードのスタイル設定")
    func testTemplateNodeStyling() {
        // Given
        var templateNode = TemplateNode(
            text: "重要な決定事項",
            position: CGPoint(x: 50, y: 75),
            nodeType: .action
        )
        
        // When
        templateNode.setStyle(
            backgroundColor: .red,
            textColor: .primary,
            fontSize: 18,
            shape: .rectangle
        )
        
        // Then
        #expect(templateNode.style.backgroundColor == .red)
        #expect(templateNode.style.textColor == .primary)
        #expect(templateNode.style.fontSize == 18)
        #expect(templateNode.style.shape == .rectangle)
    }
    
    @Test("ノードの実際のマインドマップノードへの変換")
    func testConvertToActualNode() {
        // Given
        var templateNode = TemplateNode(
            text: "会議テーマ: [テーマを入力]",
            position: CGPoint(x: 0, y: 0),
            nodeType: .central
        )
        templateNode.setStyle(
            backgroundColor: .blue,
            textColor: .primary,
            fontSize: 16,
            shape: .ellipse
        )
        
        let replacements = ["[テーマを入力]": "Q3売上戦略会議"]
        
        // When
        let actualNode = templateNode.toNode(replacements: replacements)
        
        // Then
        #expect(actualNode.text == "会議テーマ: Q3売上戦略会議")
        #expect(actualNode.position == templateNode.position)
        #expect(actualNode.backgroundColor == templateNode.style.backgroundColor)
        #expect(actualNode.textColor == templateNode.style.textColor)
        #expect(actualNode.fontSize == templateNode.style.fontSize)
    }
    
    @Test("子ノードの削除")
    func testRemoveChildNode() {
        // Given
        var parentNode = TemplateNode(
            text: "親ノード",
            position: CGPoint(x: 0, y: 0),
            nodeType: .central
        )
        
        let childNode = TemplateNode(
            text: "子ノード",
            position: CGPoint(x: 100, y: 100),
            nodeType: .topic
        )
        
        parentNode.addChild(childNode.id)
        #expect(parentNode.childNodeIds.count == 1)
        
        // When
        parentNode.removeChild(childNode.id)
        
        // Then
        #expect(parentNode.childNodeIds.count == 0)
        #expect(!parentNode.childNodeIds.contains(childNode.id))
    }
}