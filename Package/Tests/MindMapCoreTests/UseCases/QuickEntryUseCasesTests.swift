import Testing
import Foundation
@testable import MindMapCore

// MARK: - Parse Text Use Case Tests
struct ParseTextUseCaseTests {
    
    @Test("空のテキストでのパース")
    func testParseEmptyText() async {
        // Given
        let useCase = ParseTextUseCase()
        let request = ParseTextRequest(text: "")
        
        // When & Then
        await #expect(throws: QuickEntryError.emptyText) {
            try await useCase.execute(request)
        }
    }
    
    @Test("シンプルなテキストのパース")
    func testParseSimpleText() async throws {
        // Given
        let useCase = ParseTextUseCase()
        let text = """
        メインアイデア
            サブアイデア1
            サブアイデア2
                詳細1
                詳細2
        """
        let request = ParseTextRequest(text: text)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        let rootNode = response.structure.rootNode
        #expect(rootNode.text == "メインアイデア")
        #expect(rootNode.level == 0)
        #expect(rootNode.children.count == 2)
        
        let firstChild = rootNode.children[0]
        #expect(firstChild.text == "サブアイデア1")
        #expect(firstChild.level == 1)
        
        let secondChild = rootNode.children[1]
        #expect(secondChild.text == "サブアイデア2")
        #expect(secondChild.level == 1)
        #expect(secondChild.children.count == 2)
    }
    
    @Test("複雑な階層構造のパース")
    func testParseComplexHierarchy() async throws {
        // Given
        let useCase = ParseTextUseCase()
        let text = """
        プロジェクト企画
            市場分析
                競合調査
                    直接競合
                    間接競合
                ターゲット分析
            技術選定
                フロントエンド
                バックエンド
            マーケティング
        """
        let request = ParseTextRequest(text: text)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        let rootNode = response.structure.rootNode
        #expect(rootNode.text == "プロジェクト企画")
        #expect(rootNode.children.count == 3)
        
        let marketAnalysis = rootNode.children[0]
        #expect(marketAnalysis.text == "市場分析")
        #expect(marketAnalysis.children.count == 2)
        
        let competitorResearch = marketAnalysis.children[0]
        #expect(competitorResearch.text == "競合調査")
        #expect(competitorResearch.children.count == 2)
        
        let directCompetitor = competitorResearch.children[0]
        #expect(directCompetitor.text == "直接競合")
        #expect(directCompetitor.level == 3)
    }
    
    @Test("不正なインデントでのパース")
    func testParseInvalidIndentation() async {
        // Given
        let useCase = ParseTextUseCase()
        let text = """
        メインアイデア
                無効なインデント
            正常なインデント
        """
        let request = ParseTextRequest(text: text)
        
        // When & Then
        await #expect(throws: QuickEntryError.invalidFormat) {
            try await useCase.execute(request)
        }
    }
}

// MARK: - Generate MindMap Use Case Tests
struct GenerateMindMapFromTextUseCaseTests {
    
    @Test("シンプルな構造からマインドマップ生成")
    func testGenerateSimpleMindMap() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let useCase = GenerateMindMapFromTextUseCase(repository: mockRepository)
        
        let structure = MindMapStructure(
            rootNode: ParsedNode(
                text: "メインアイデア",
                level: 0,
                children: [
                    ParsedNode(text: "サブアイデア1", level: 1),
                    ParsedNode(text: "サブアイデア2", level: 1)
                ]
            )
        )
        let request = GenerateMindMapFromTextRequest(structure: structure, title: "テストマップ")
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        let mindMap = response.mindMap
        #expect(mindMap.title == "テストマップ")
        
        let nodes = response.nodes
        #expect(nodes.count == 3) // root + 2 children
        
        let rootNode = nodes.first { $0.id == mindMap.rootNodeID }
        #expect(rootNode?.text == "メインアイデア")
        
        let childNodes = nodes.filter { $0.parentID == mindMap.rootNodeID }
        #expect(childNodes.count == 2)
        
        let preview = response.previewData
        #expect(preview.nodeCount == 3) // root + 2 children
        #expect(preview.maxDepth == 1)
        #expect(preview.estimatedSize.width > 0)
        #expect(preview.estimatedSize.height > 0)
    }
    
    @Test("複雑な階層からマインドマップ生成")
    func testGenerateComplexMindMap() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let useCase = GenerateMindMapFromTextUseCase(repository: mockRepository)
        
        let structure = MindMapStructure(
            rootNode: ParsedNode(
                text: "プロジェクト",
                level: 0,
                children: [
                    ParsedNode(
                        text: "フェーズ1",
                        level: 1,
                        children: [
                            ParsedNode(text: "タスク1-1", level: 2),
                            ParsedNode(text: "タスク1-2", level: 2)
                        ]
                    ),
                    ParsedNode(
                        text: "フェーズ2",
                        level: 1,
                        children: [
                            ParsedNode(text: "タスク2-1", level: 2)
                        ]
                    )
                ]
            )
        )
        let request = GenerateMindMapFromTextRequest(structure: structure)
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        let mindMap = response.mindMap
        let nodes = response.nodes
        
        let rootNode = nodes.first { $0.id == mindMap.rootNodeID }
        #expect(rootNode?.text == "プロジェクト")
        
        // ルートノードから子ノードへのアクセスを検証
        let childNodes = nodes.filter { $0.parentID == mindMap.rootNodeID }
        #expect(childNodes.count == 2)
        
        let preview = response.previewData
        #expect(preview.nodeCount == 6) // root + 2 phase + 3 tasks
        #expect(preview.maxDepth == 2)
    }
    
    @Test("空の構造での生成エラー")
    func testGenerateFromEmptyStructure() async {
        // Given
        let mockRepository = MockMindMapRepository()
        let useCase = GenerateMindMapFromTextUseCase(repository: mockRepository)
        
        let structure = MindMapStructure(
            rootNode: ParsedNode(text: "", level: 0)
        )
        let request = GenerateMindMapFromTextRequest(structure: structure)
        
        // When & Then
        await #expect(throws: QuickEntryError.generationFailed) {
            try await useCase.execute(request)
        }
    }
}

// MARK: - Integration Tests
struct QuickEntryIntegrationTests {
    
    @Test("テキストからマインドマップまでの完全フロー")
    func testCompleteQuickEntryFlow() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let parseUseCase = ParseTextUseCase()
        let generateUseCase = GenerateMindMapFromTextUseCase(repository: mockRepository)
        
        let inputText = """
        学習計画
            数学
                微積分
                線形代数
            物理
                力学
                電磁気学
            プログラミング
                Swift
                Python
        """
        
        // When
        // 1. テキスト解析
        let parseRequest = ParseTextRequest(text: inputText)
        let parseResponse = try await parseUseCase.execute(parseRequest)
        
        // 2. マインドマップ生成
        let generateRequest = GenerateMindMapFromTextRequest(
            structure: parseResponse.structure,
            title: "自動生成マップ"
        )
        let generateResponse = try await generateUseCase.execute(generateRequest)
        
        // Then
        let mindMap = generateResponse.mindMap
        let allNodes = generateResponse.nodes
        #expect(mindMap.title == "自動生成マップ")
        
        let rootNode = allNodes.first { $0.id == mindMap.rootNodeID }
        #expect(rootNode?.text == "学習計画")
        
        // 構造の検証
        #expect(allNodes.count == 10) // root + 3 subjects + 6 details
        
        let preview = generateResponse.previewData
        #expect(preview.nodeCount == 10)
        #expect(preview.maxDepth == 2)
        #expect(mockRepository.saveCallCount == 1)
    }
}