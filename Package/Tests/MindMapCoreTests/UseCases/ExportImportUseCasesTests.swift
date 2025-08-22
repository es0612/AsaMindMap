import Testing
import Foundation
@testable import MindMapCore

// MARK: - Export Use Cases Tests

@Suite("Export MindMap Use Case Tests")
struct ExportMindMapUseCaseTests {
    
    @Test("PDF形式でのエクスポート")
    func testExportToPDF() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ExportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        // テスト用マインドマップを作成
        let mindMap = createTestMindMap()
        let nodes = createTestNodes(for: mindMap)
        mockRepository.mindMaps[mindMap.id] = mindMap
        for node in nodes {
            mockNodeRepository.nodes[node.id] = node
        }
        
        let request = ExportMindMapRequest(
            mindMapID: mindMap.id,
            format: .pdf,
            options: ExportOptions(paperSize: .a4)
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mimeType == "application/pdf")
        #expect(response.filename.hasSuffix(".pdf"))
        #expect(response.fileData.count > 0)
        #expect(response.fileSize > 0)
    }
    
    @Test("PNG形式でのエクスポート（透明背景）")
    func testExportToPNGWithTransparentBackground() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ExportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let mindMap = createTestMindMap()
        let nodes = createTestNodes(for: mindMap)
        mockRepository.mindMaps[mindMap.id] = mindMap
        for node in nodes {
            mockNodeRepository.nodes[node.id] = node
        }
        
        let request = ExportMindMapRequest(
            mindMapID: mindMap.id,
            format: .png,
            options: ExportOptions(
                imageQuality: .high,
                transparentBackground: true
            )
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mimeType == "image/png")
        #expect(response.filename.hasSuffix(".png"))
        #expect(response.fileData.count > 0)
    }
    
    @Test("OPML形式でのエクスポート")
    func testExportToOPML() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ExportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let mindMap = createTestMindMap()
        let nodes = createTestNodes(for: mindMap)
        mockRepository.mindMaps[mindMap.id] = mindMap
        for node in nodes {
            mockNodeRepository.nodes[node.id] = node
        }
        
        let request = ExportMindMapRequest(
            mindMapID: mindMap.id,
            format: .opml
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mimeType == "text/x-opml")
        #expect(response.filename.hasSuffix(".opml"))
        
        // OPML形式の内容確認
        let opmlString = String(data: response.fileData, encoding: .utf8)
        #expect(opmlString?.contains("<?xml version=\"1.0\"") == true)
        #expect(opmlString?.contains("<opml version=\"2.0\">") == true)
        #expect(opmlString?.contains(mindMap.title) == true)
    }
    
    @Test("CSV形式でのエクスポート")
    func testExportToCSV() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ExportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let mindMap = createTestMindMap()
        let nodes = createTestNodes(for: mindMap)
        mockRepository.mindMaps[mindMap.id] = mindMap
        for node in nodes {
            mockNodeRepository.nodes[node.id] = node
        }
        
        let request = ExportMindMapRequest(
            mindMapID: mindMap.id,
            format: .csv
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mimeType == "text/csv")
        #expect(response.filename.hasSuffix(".csv"))
        
        // CSV形式の内容確認
        let csvString = String(data: response.fileData, encoding: .utf8)
        #expect(csvString?.contains("Node ID,Text,Level,Parent ID") == true)
    }
    
    @Test("存在しないマインドマップのエクスポートエラー")
    func testExportNonExistentMindMap() async {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ExportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let request = ExportMindMapRequest(
            mindMapID: UUID(),
            format: .pdf
        )
        
        // When & Then
        await #expect(throws: ExportError.mindMapNotFound) {
            try await useCase.execute(request)
        }
    }
}

// MARK: - Import Use Cases Tests

@Suite("Import MindMap Use Case Tests")
struct ImportMindMapUseCaseTests {
    
    @Test("OPML形式のインポート")
    func testImportFromOPML() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ImportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let opmlData = createTestOPMLData()
        let request = ImportMindMapRequest(
            fileData: opmlData,
            filename: "test.opml",
            format: .opml
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.mindMap.title == "Test MindMap")
        #expect(response.nodes.count == 6) // ルート + 5ノード
        #expect(response.importSummary.successfulImports == 6)
        #expect(response.importSummary.failedImports == 0)
        
        // ルートノードの検証
        let rootNode = response.nodes.first { $0.id == response.mindMap.rootNodeID }
        #expect(rootNode?.text == "Central Topic")
    }
    
    @Test("CSV形式のインポート")
    func testImportFromCSV() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ImportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let csvData = createTestCSVData()
        let request = ImportMindMapRequest(
            fileData: csvData,
            filename: "test.csv",
            format: .csv
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.nodes.count == 4)
        #expect(response.importSummary.successfulImports == 4)
        #expect(response.importSummary.failedImports == 0)
        
        // 階層構造の検証
        let rootNodes = response.nodes.filter { $0.parentID == nil }
        #expect(rootNodes.count == 1)
    }
    
    @Test("無効な形式のインポートエラー")
    func testImportInvalidFormat() async {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ImportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let invalidData = "invalid data".data(using: .utf8)!
        let request = ImportMindMapRequest(
            fileData: invalidData,
            filename: "test.opml",
            format: .opml
        )
        
        // When & Then
        await #expect(throws: ImportError.invalidFileFormat) {
            try await useCase.execute(request)
        }
    }
    
    @Test("構造検証失敗のインポートエラー")
    func testImportStructureValidationFailure() async {
        // Given
        let mockRepository = MockMindMapRepository()
        let mockNodeRepository = MockNodeRepository()
        let useCase = ImportMindMapUseCase(
            mindMapRepository: mockRepository,
            nodeRepository: mockNodeRepository
        )
        
        let malformedCSV = "Node ID,Text,Level,Parent ID\nInvalid,Missing".data(using: .utf8)!
        let request = ImportMindMapRequest(
            fileData: malformedCSV,
            filename: "malformed.csv",
            format: .csv,
            options: ImportOptions(validateStructure: true)
        )
        
        // When & Then
        await #expect(throws: ImportError.structureValidationFailed) {
            try await useCase.execute(request)
        }
    }
}

// MARK: - Share Export Use Cases Tests

@Suite("Share Export Use Case Tests")
struct ShareExportUseCaseTests {
    
    @Test("複数形式での共有")
    func testShareMultipleFormats() async throws {
        // Given
        let mockExportUseCase = MockExportMindMapUseCase()
        let useCase = ShareExportUseCase(
            exportUseCase: mockExportUseCase
        )
        
        let mindMapID = UUID()
        let request = ShareExportRequest(
            mindMapID: mindMapID,
            formats: [.pdf, .png, .csv]
        )
        
        // When
        let response = try await useCase.execute(request)
        
        // Then
        #expect(response.success == true)
        #expect(response.sharedFormats.count == 3)
        #expect(response.sharedFormats.contains(.pdf))
        #expect(response.sharedFormats.contains(.png))
        #expect(response.sharedFormats.contains(.csv))
        #expect(response.error == nil)
    }
}

// MARK: - Test Helpers

// Global test helper functions
func createTestMindMap() -> MindMap {
        let rootNodeID = UUID()
        return MindMap(
            id: UUID(),
            title: "Test MindMap",
            rootNodeID: rootNodeID,
            nodeIDs: Set([rootNodeID]),
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
func createTestNodes(for mindMap: MindMap) -> [Node] {
        let rootNode = Node(
            id: mindMap.rootNodeID!,
            text: "Central Topic",
            position: CGPoint(x: 0, y: 0),
            parentID: nil
        )
        
        let childNode1 = Node(
            id: UUID(),
            text: "Branch 1",
            position: CGPoint(x: 100, y: -50),
            parentID: rootNode.id
        )
        
        let childNode2 = Node(
            id: UUID(),
            text: "Branch 2",
            position: CGPoint(x: 100, y: 50),
            parentID: rootNode.id
        )
        
        return [rootNode, childNode1, childNode2]
    }
    
func createTestOPMLData() -> Data {
        let opml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>Test MindMap</title>
            </head>
            <body>
                <outline text="Central Topic">
                    <outline text="Branch 1">
                        <outline text="Sub Branch 1"/>
                        <outline text="Sub Branch 2"/>
                    </outline>
                    <outline text="Branch 2"/>
                </outline>
            </body>
        </opml>
        """
        return opml.data(using: .utf8)!
    }
    
func createTestCSVData() -> Data {
        let csv = """
        Node ID,Text,Level,Parent ID
        1,Central Topic,0,
        2,Branch 1,1,1
        3,Branch 2,1,1
        4,Sub Branch,2,2
        """
        return csv.data(using: .utf8)!
}

// MARK: - Mock Export Use Case

class MockExportMindMapUseCase: ExportMindMapUseCaseProtocol {
    func execute(_ request: ExportMindMapRequest) async throws -> ExportMindMapResponse {
        let dummyData = "Mock export data".data(using: .utf8)!
        return ExportMindMapResponse(
            fileData: dummyData,
            filename: "test.\(request.format.fileExtension)",
            mimeType: request.format.mimeType
        )
    }
}