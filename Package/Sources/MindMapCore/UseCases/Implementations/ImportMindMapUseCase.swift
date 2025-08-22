import Foundation

// MARK: - Import MindMap Use Case Implementation
final class ImportMindMapUseCase: ImportMindMapUseCaseProtocol {
    
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    
    init(mindMapRepository: MindMapRepositoryProtocol, nodeRepository: NodeRepositoryProtocol) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
    }
    
    func execute(_ request: ImportMindMapRequest) async throws -> ImportMindMapResponse {
        // 1. ファイル形式の検証
        try validateFileFormat(request: request)
        
        // 2. データの解析
        let (mindMap, nodes) = try await parseImportData(request: request)
        
        // 3. データの保存
        try await mindMapRepository.save(mindMap)
        for node in nodes {
            try await nodeRepository.save(node)
        }
        
        // 4. インポート概要の生成
        let importSummary = ImportSummary(
            totalNodes: nodes.count,
            successfulImports: nodes.count,
            failedImports: 0,
            warnings: []
        )
        
        return ImportMindMapResponse(
            mindMap: mindMap,
            nodes: nodes,
            importSummary: importSummary
        )
    }
    
    // MARK: - Private Methods
    
    private func validateFileFormat(request: ImportMindMapRequest) throws {
        guard !request.fileData.isEmpty else {
            throw ImportError.corruptedData
        }
        
        // 基本的な形式検証
        let fileString = String(data: request.fileData, encoding: String.Encoding.utf8)
        
        switch request.format {
        case .opml:
            guard let content = fileString,
                  content.contains("<?xml") && content.contains("<opml") else {
                throw ImportError.invalidFileFormat
            }
        case .csv:
            guard let content = fileString,
                  content.contains("Node ID") || content.contains("Text") else {
                throw ImportError.invalidFileFormat
            }
        case .mindMap:
            // 独自形式の検証（将来実装）
            break
        }
    }
    
    private func parseImportData(request: ImportMindMapRequest) async throws -> (MindMap, [Node]) {
        switch request.format {
        case .opml:
            return try await parseOPMLData(request: request)
        case .csv:
            return try await parseCSVData(request: request)
        case .mindMap:
            return try await parseMindMapData(request: request)
        }
    }
    
    private func parseOPMLData(request: ImportMindMapRequest) async throws -> (MindMap, [Node]) {
        guard let xmlString = String(data: request.fileData, encoding: String.Encoding.utf8) else {
            throw ImportError.corruptedData
        }
        
        // 簡易的なXML解析（実際にはXMLParserを使用）
        let title = extractOPMLTitle(from: xmlString) ?? "Imported MindMap"
        
        // ルートノードの作成
        let rootNodeID = UUID()
        let rootNode = Node(
            id: rootNodeID,
            text: "Central Topic",
            position: CGPoint(x: 0, y: 0),
            parentID: nil
        )
        
        // 子ノードの作成（簡易実装）
        var nodes = [rootNode]
        let outlines = extractOPMLOutlines(from: xmlString)
        
        for (index, outline) in outlines.enumerated() {
            let childNode = Node(
                id: UUID(),
                text: outline,
                position: CGPoint(x: 100 + index * 50, y: index * 50),
                parentID: rootNodeID
            )
            nodes.append(childNode)
        }
        
        // マインドマップの作成
        let mindMap = MindMap(
            id: UUID(),
            title: title,
            rootNodeID: rootNodeID,
            nodeIDs: Set(nodes.map { $0.id })
        )
        
        return (mindMap, nodes)
    }
    
    private func parseCSVData(request: ImportMindMapRequest) async throws -> (MindMap, [Node]) {
        guard let csvString = String(data: request.fileData, encoding: String.Encoding.utf8) else {
            throw ImportError.corruptedData
        }
        
        let lines = csvString.components(separatedBy: .newlines)
        guard lines.count > 1 else {
            throw ImportError.structureValidationFailed
        }
        
        // ヘッダーをスキップ
        let dataLines = Array(lines.dropFirst())
        var nodes: [Node] = []
        var nodeMapping: [String: UUID] = [:]
        
        // ノードの作成
        for line in dataLines {
            guard !line.isEmpty else { continue }
            
            let components = line.components(separatedBy: ",")
            guard components.count >= 4 else {
                if request.options.validateStructure {
                    throw ImportError.structureValidationFailed
                }
                continue
            }
            
            let nodeIDString = components[0]
            let text = components[1]
            let level = Int(components[2]) ?? 0
            let parentIDString = components[3]
            
            let nodeID = UUID()
            nodeMapping[nodeIDString] = nodeID
            
            let parentID = parentIDString.isEmpty ? nil : nodeMapping[parentIDString]
            
            let node = Node(
                id: nodeID,
                text: text,
                position: CGPoint(x: level * 100, y: nodes.count * 50),
                parentID: parentID
            )
            
            nodes.append(node)
        }
        
        // ルートノードを特定
        let rootNodes = nodes.filter { $0.parentID == nil }
        guard let rootNode = rootNodes.first else {
            throw ImportError.structureValidationFailed
        }
        
        // マインドマップの作成
        let mindMap = MindMap(
            id: UUID(),
            title: "Imported from CSV",
            rootNodeID: rootNode.id,
            nodeIDs: Set(nodes.map { $0.id })
        )
        
        return (mindMap, nodes)
    }
    
    private func parseMindMapData(request: ImportMindMapRequest) async throws -> (MindMap, [Node]) {
        // 独自形式の実装（将来）
        throw ImportError.unsupportedVersion
    }
    
    // MARK: - Helper Methods
    
    private func extractOPMLTitle(from xmlString: String) -> String? {
        // 簡易的なタイトル抽出
        let titlePattern = "<title>(.*?)</title>"
        let regex = try? NSRegularExpression(pattern: titlePattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: xmlString.count)
        
        guard let match = regex?.firstMatch(in: xmlString, options: [], range: range),
              let titleRange = Range(match.range(at: 1), in: xmlString) else {
            return nil
        }
        
        return String(xmlString[titleRange])
    }
    
    private func extractOPMLOutlines(from xmlString: String) -> [String] {
        // 簡易的なアウトライン抽出
        let outlinePattern = "<outline text=\"(.*?)\""
        let regex = try? NSRegularExpression(pattern: outlinePattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: xmlString.count)
        
        var outlines: [String] = []
        regex?.enumerateMatches(in: xmlString, options: [], range: range) { match, _, _ in
            guard let match = match,
                  let textRange = Range(match.range(at: 1), in: xmlString) else {
                return
            }
            
            let text = String(xmlString[textRange])
            outlines.append(text)
        }
        
        return outlines
    }
}