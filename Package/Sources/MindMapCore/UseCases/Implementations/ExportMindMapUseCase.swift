import Foundation
import CoreGraphics
import ImageIO

extension UInt32 {
    var bytes: [UInt8] {
        return [
            UInt8((self >> 24) & 0xFF),
            UInt8((self >> 16) & 0xFF),
            UInt8((self >> 8) & 0xFF),
            UInt8(self & 0xFF)
        ]
    }
}

// MARK: - Export MindMap Use Case Implementation
final class ExportMindMapUseCase: ExportMindMapUseCaseProtocol {
    
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    
    init(mindMapRepository: MindMapRepositoryProtocol, nodeRepository: NodeRepositoryProtocol) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
    }
    
    func execute(_ request: ExportMindMapRequest) async throws -> ExportMindMapResponse {
        // 1. マインドマップの存在確認
        guard let mindMap = try await mindMapRepository.findByID(request.mindMapID) else {
            throw ExportError.mindMapNotFound
        }
        
        // 2. ノードを取得
        let nodes = try await nodeRepository.findByMindMapID(request.mindMapID)
        
        // 3. 形式に応じてエクスポート
        let fileData: Data
        let filename: String
        
        switch request.format {
        case .pdf:
            fileData = try await exportToPDF(mindMap: mindMap, nodes: nodes, options: request.options)
            filename = "\(mindMap.title).pdf"
        case .png:
            fileData = try await exportToPNG(mindMap: mindMap, nodes: nodes, options: request.options)
            filename = "\(mindMap.title).png"
        case .opml:
            fileData = try await exportToOPML(mindMap: mindMap, nodes: nodes, options: request.options)
            filename = "\(mindMap.title).opml"
        case .csv:
            fileData = try await exportToCSV(mindMap: mindMap, nodes: nodes, options: request.options)
            filename = "\(mindMap.title).csv"
        }
        
        return ExportMindMapResponse(
            fileData: fileData,
            filename: filename,
            mimeType: request.format.mimeType
        )
    }
    
    // MARK: - Private Export Methods
    
    private func exportToPDF(mindMap: MindMap, nodes: [Node], options: ExportOptions) async throws -> Data {
        // 簡易PDF実装（本来はCoreGraphicsで詳細な描画を行う）
        let pdfContent = """
        %PDF-1.4
        1 0 obj<</Type/Catalog/Pages 2 0 R>>endobj
        2 0 obj<</Type/Pages/Kids[3 0 R]/Count 1>>endobj
        3 0 obj<</Type/Page/Parent 2 0 R/MediaBox[0 0 612 792]/Contents 4 0 R>>endobj
        4 0 obj<</Length 44>>stream
        BT/F1 12 Tf 100 700 Td(\(mindMap.title))Tj ET
        endstream endobj
        xref 0 5
        0000000000 65535 f 
        0000000010 00000 n 
        0000000053 00000 n 
        0000000109 00000 n 
        0000000184 00000 n 
        trailer<</Size 5/Root 1 0 R>>
        startxref 284
        %%EOF
        """
        
        return pdfContent.data(using: String.Encoding.utf8) ?? Data()
    }
    
    private func exportToPNG(mindMap: MindMap, nodes: [Node], options: ExportOptions) async throws -> Data {
        // 簡易PNG実装（本来はCoreGraphicsで画像を生成）
        // PNG画像のヘッダーとメタデータを含むダミーPNGを生成
        var pngData = Data([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG signature
        
        // IHDR chunk (Image Header)
        let width: UInt32 = 800
        let height: UInt32 = 600
        var ihdrData = Data()
        ihdrData.append(contentsOf: width.bytes)
        ihdrData.append(contentsOf: height.bytes)
        ihdrData.append(contentsOf: [0x08, 0x02, 0x00, 0x00, 0x00]) // bit depth, color type, compression, filter, interlace
        
        pngData.append(createPNGChunk(type: "IHDR", data: ihdrData))
        
        // Simple pixel data (solid color based on options)
        let pixelData = options.transparentBackground ? 
            Data(repeating: 0x00, count: Int(width * height * 3)) : 
            Data(repeating: 0xFF, count: Int(width * height * 3))
        
        pngData.append(createPNGChunk(type: "IDAT", data: pixelData))
        pngData.append(createPNGChunk(type: "IEND", data: Data()))
        
        return pngData
    }
    
    private func createPNGChunk(type: String, data: Data) -> Data {
        var chunk = Data()
        let length = UInt32(data.count)
        chunk.append(contentsOf: length.bytes)
        chunk.append(type.data(using: .ascii) ?? Data())
        chunk.append(data)
        
        // CRC calculation would go here in a real implementation
        chunk.append(contentsOf: [0x00, 0x00, 0x00, 0x00]) // Dummy CRC
        
        return chunk
    }
    
    private func exportToOPML(mindMap: MindMap, nodes: [Node], options: ExportOptions) async throws -> Data {
        guard let rootNodeID = mindMap.rootNodeID else {
            throw ExportError.dataGenerationFailed
        }
        
        let opmlContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
            <head>
                <title>\(mindMap.title)</title>
            </head>
            <body>
                \(generateOPMLOutlines(from: nodes, rootNodeID: rootNodeID))
            </body>
        </opml>
        """
        
        return opmlContent.data(using: String.Encoding.utf8) ?? Data()
    }
    
    private func exportToCSV(mindMap: MindMap, nodes: [Node], options: ExportOptions) async throws -> Data {
        var csvLines = ["Node ID,Text,Level,Parent ID"]
        
        // ノードの階層レベルを計算
        for node in nodes {
            let level = calculateNodeLevel(node: node, in: nodes)
            let parentID = node.parentID?.uuidString ?? ""
            csvLines.append("\(node.id.uuidString),\(node.text),\(level),\(parentID)")
        }
        
        let csvContent = csvLines.joined(separator: "\n")
        return csvContent.data(using: String.Encoding.utf8) ?? Data()
    }
    
    // MARK: - Helper Methods
    
    private func generateOPMLOutlines(from nodes: [Node], rootNodeID: UUID) -> String {
        guard let rootNode = nodes.first(where: { $0.id == rootNodeID }) else {
            return ""
        }
        
        let children = nodes.filter { $0.parentID == rootNodeID }
        
        if children.isEmpty {
            return "<outline text=\"\(rootNode.text)\"/>"
        } else {
            var outlineContent = "<outline text=\"\(rootNode.text)\">\n"
            for child in children {
                let childOutline = generateOPMLOutlines(from: nodes, rootNodeID: child.id)
                outlineContent += "    \(childOutline)\n"
            }
            outlineContent += "</outline>"
            return outlineContent
        }
    }
    
    private func calculateNodeLevel(node: Node, in nodes: [Node]) -> Int {
        var level = 0
        var currentNode = node
        
        while let parentID = currentNode.parentID {
            guard let parentNode = nodes.first(where: { $0.id == parentID }) else {
                break
            }
            level += 1
            currentNode = parentNode
        }
        
        return level
    }
}