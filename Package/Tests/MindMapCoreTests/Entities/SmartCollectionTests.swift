import Foundation
import Testing
@testable import MindMapCore

struct SmartCollectionTests {
    
    @Test("スマートコレクションの作成と基本プロパティ")
    func testSmartCollectionCreation() async throws {
        // Given
        let name = "重要タスク"
        let description = "重要タグが付いたタスクノードのコレクション"
        let color = NodeColor.red
        
        // When
        let smartCollection = SmartCollection(
            name: name,
            description: description,
            color: color
        )
        
        // Then
        #expect(smartCollection.id != UUID())
        #expect(smartCollection.name == name)
        #expect(smartCollection.description == description)
        #expect(smartCollection.color == color)
        #expect(smartCollection.createdAt <= Date())
        #expect(smartCollection.updatedAt <= Date())
        #expect(smartCollection.rules.isEmpty)
        #expect(smartCollection.matchCondition == .all)
        #expect(!smartCollection.isAutoUpdate)
    }
    
    @Test("スマートコレクションの名前検証")
    func testSmartCollectionNameValidation() async throws {
        // Given
        let validName = "有効なコレクション名"
        let emptyName = ""
        let longName = String(repeating: "a", count: 101)
        
        // When
        let validCollection = SmartCollection(name: validName, description: "", color: .blue)
        let emptyCollection = SmartCollection(name: emptyName, description: "", color: .blue)
        let longCollection = SmartCollection(name: longName, description: "", color: .blue)
        
        // Then
        #expect(validCollection.isValidName)
        #expect(!emptyCollection.isValidName)
        #expect(!longCollection.isValidName)
    }
    
    @Test("スマートコレクションルールの追加")
    func testSmartCollectionRuleAddition() async throws {
        // Given
        var smartCollection = SmartCollection(name: "テストコレクション", description: "", color: .green)
        let tagRule = SmartCollectionRule.tagContains("重要")
        let nodeTypeRule = SmartCollectionRule.nodeType(.task)
        let contentRule = SmartCollectionRule.contentContains("プロジェクト")
        
        #expect(smartCollection.rules.isEmpty)
        
        // When
        smartCollection.addRule(tagRule)
        smartCollection.addRule(nodeTypeRule)
        smartCollection.addRule(contentRule)
        
        // Then
        #expect(smartCollection.rules.count == 3)
        #expect(smartCollection.rules.contains(tagRule))
        #expect(smartCollection.rules.contains(nodeTypeRule))
        #expect(smartCollection.rules.contains(contentRule))
    }
    
    @Test("スマートコレクションルールの削除")
    func testSmartCollectionRuleRemoval() async throws {
        // Given
        var smartCollection = SmartCollection(name: "テストコレクション", description: "", color: .yellow)
        let rule1 = SmartCollectionRule.tagContains("タグ1")
        let rule2 = SmartCollectionRule.tagContains("タグ2")
        
        smartCollection.addRule(rule1)
        smartCollection.addRule(rule2)
        #expect(smartCollection.rules.count == 2)
        
        // When
        let removed = smartCollection.removeRule(rule1)
        
        // Then
        #expect(removed)
        #expect(smartCollection.rules.count == 1)
        #expect(!smartCollection.rules.contains(rule1))
        #expect(smartCollection.rules.contains(rule2))
    }
    
    @Test("スマートコレクションの条件マッチ設定")
    func testSmartCollectionMatchCondition() async throws {
        // Given
        var smartCollection = SmartCollection(name: "テスト", description: "", color: .purple)
        
        #expect(smartCollection.matchCondition == .all)
        
        // When
        smartCollection.setMatchCondition(.any)
        
        // Then
        #expect(smartCollection.matchCondition == .any)
        
        // When
        smartCollection.setMatchCondition(.all)
        
        // Then
        #expect(smartCollection.matchCondition == .all)
    }
    
    @Test("スマートコレクションの自動更新設定")
    func testSmartCollectionAutoUpdate() async throws {
        // Given
        var smartCollection = SmartCollection(name: "自動更新テスト", description: "", color: .orange)
        
        #expect(!smartCollection.isAutoUpdate)
        
        // When
        smartCollection.enableAutoUpdate()
        
        // Then
        #expect(smartCollection.isAutoUpdate)
        
        // When
        smartCollection.disableAutoUpdate()
        
        // Then
        #expect(!smartCollection.isAutoUpdate)
    }
    
    @Test("スマートコレクションのノードマッチング")
    func testSmartCollectionNodeMatching() async throws {
        // Given
        let smartCollection = createTaskSmartCollection()
        
        let taskNode = createTestNode(
            text: "重要なタスク",
            nodeType: .task,
            tags: ["重要", "プロジェクト"],
            isCompleted: false
        )
        
        let regularNode = createTestNode(
            text: "普通のノート",
            nodeType: .regular,
            tags: ["メモ"],
            isCompleted: false
        )
        
        let completedTask = createTestNode(
            text: "完了したタスク",
            nodeType: .task,
            tags: ["重要"],
            isCompleted: true
        )
        
        // When & Then
        #expect(smartCollection.matchesNode(taskNode))
        #expect(!smartCollection.matchesNode(regularNode))
        #expect(!smartCollection.matchesNode(completedTask))
    }
    
    @Test("スマートコレクションのANY条件マッチング")
    func testSmartCollectionAnyMatching() async throws {
        // Given
        var smartCollection = SmartCollection(name: "ANY条件テスト", description: "", color: .cyan)
        smartCollection.addRule(.tagContains("重要"))
        smartCollection.addRule(.tagContains("緊急"))
        smartCollection.setMatchCondition(.any)
        
        let importantNode = createTestNode(
            text: "重要なノート",
            nodeType: .regular,
            tags: ["重要"],
            isCompleted: false
        )
        
        let urgentNode = createTestNode(
            text: "緊急なノート",
            nodeType: .regular,
            tags: ["緊急"],
            isCompleted: false
        )
        
        let normalNode = createTestNode(
            text: "普通のノート",
            nodeType: .regular,
            tags: ["普通"],
            isCompleted: false
        )
        
        // When & Then
        #expect(smartCollection.matchesNode(importantNode))
        #expect(smartCollection.matchesNode(urgentNode))
        #expect(!smartCollection.matchesNode(normalNode))
    }
    
    @Test("スマートコレクションの検索クエリ生成")
    func testSmartCollectionSearchQueryGeneration() async throws {
        // Given
        let smartCollection = createTaskSmartCollection()
        
        // When
        let searchRequest = smartCollection.generateSearchRequest()
        
        // Then
        #expect(searchRequest.isValid)
        #expect(searchRequest.type == .fullText)
        #expect(!searchRequest.filters.isEmpty)
    }
    
    @Test("スマートコレクションの統計更新")
    func testSmartCollectionStatisticsUpdate() async throws {
        // Given
        var smartCollection = SmartCollection(name: "統計テスト", description: "", color: .red)
        let initialLastUpdated = smartCollection.lastResultsUpdate
        
        // When
        smartCollection.updateStatistics(matchingNodesCount: 15, lastExecutedAt: Date())
        
        // Then
        #expect(smartCollection.matchingNodesCount == 15)
        #expect(smartCollection.lastResultsUpdate != initialLastUpdated)
    }
    
    @Test("スマートコレクション管理システム")
    func testSmartCollectionManager() async throws {
        // Given
        var manager = SmartCollectionManager()
        let collection1 = SmartCollection(name: "コレクション1", description: "", color: .blue)
        let collection2 = SmartCollection(name: "コレクション2", description: "", color: .green)
        
        #expect(manager.collections.isEmpty)
        
        // When
        manager.addCollection(collection1)
        manager.addCollection(collection2)
        
        // Then
        #expect(manager.collections.count == 2)
        #expect(manager.totalCollections == 2)
    }
    
    @Test("スマートコレクション管理システムの削除")
    func testSmartCollectionManagerRemoval() async throws {
        // Given
        var manager = SmartCollectionManager()
        let collection = SmartCollection(name: "削除テスト", description: "", color: .red)
        manager.addCollection(collection)
        
        #expect(manager.collections.count == 1)
        
        // When
        let removed = manager.removeCollection(id: collection.id)
        
        // Then
        #expect(removed)
        #expect(manager.collections.isEmpty)
    }
    
    @Test("スマートコレクション管理システムの検索")
    func testSmartCollectionManagerSearch() async throws {
        // Given
        var manager = SmartCollectionManager()
        let collection1 = SmartCollection(name: "重要タスク", description: "重要なタスク", color: .red)
        let collection2 = SmartCollection(name: "プロジェクト", description: "プロジェクト関連", color: .blue)
        
        manager.addCollection(collection1)
        manager.addCollection(collection2)
        
        // When
        let foundById = manager.findCollectionById(collection1.id)
        let foundByName = manager.findCollectionsByName("タスク")
        
        // Then
        #expect(foundById?.name == "重要タスク")
        #expect(foundByName.count == 1)
        #expect(foundByName.first?.name == "重要タスク")
    }
    
    // MARK: - Helper Methods
    
    private func createTaskSmartCollection() -> SmartCollection {
        var smartCollection = SmartCollection(
            name: "未完了の重要タスク",
            description: "重要タグが付いた未完了のタスクノード",
            color: .red
        )
        
        smartCollection.addRule(.nodeType(.task))
        smartCollection.addRule(.tagContains("重要"))
        smartCollection.addRule(.isCompleted(false))
        smartCollection.setMatchCondition(.all)
        
        return smartCollection
    }
    
    private func createTestNode(
        text: String,
        nodeType: NodeType,
        tags: [String],
        isCompleted: Bool
    ) -> MockNode {
        return MockNode(
            id: UUID(),
            text: text,
            nodeType: nodeType,
            tags: tags,
            isCompleted: isCompleted
        )
    }
}

// MARK: - Mock Node for Testing

private struct MockNode {
    let id: UUID
    let text: String
    let nodeType: NodeType
    let tags: [String]
    let isCompleted: Bool
}