import Foundation

// MARK: - Parse Text Use Case Implementation
final class ParseTextUseCase: ParseTextUseCaseProtocol {
    
    func execute(_ request: ParseTextRequest) async throws -> ParseTextResponse {
        let text = request.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !text.isEmpty else {
            throw QuickEntryError.emptyText
        }
        
        let lines = text.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard !lines.isEmpty else {
            throw QuickEntryError.emptyText
        }
        
        let parsedLines = try parseLines(lines)
        let rootNode = try buildNodeHierarchy(parsedLines)
        
        let structure = MindMapStructure(rootNode: rootNode)
        return ParseTextResponse(structure: structure)
    }
    
    // MARK: - Private Methods
    
    private func parseLines(_ lines: [String]) throws -> [ParsedLine] {
        var parsedLines: [ParsedLine] = []
        
        for line in lines {
            let level = calculateIndentLevel(line)
            let text = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !text.isEmpty else { continue }
            
            parsedLines.append(ParsedLine(text: text, level: level))
        }
        
        // Validate indent hierarchy
        try validateIndentHierarchy(parsedLines)
        
        return parsedLines
    }
    
    private func calculateIndentLevel(_ line: String) -> Int {
        var level = 0
        for char in line {
            if char == " " {
                level += 1
            } else if char == "\t" {
                level += 4 // タブは4スペース相当
            } else {
                break
            }
        }
        return level / 4 // 4スペースで1レベル
    }
    
    private func validateIndentHierarchy(_ lines: [ParsedLine]) throws {
        guard let firstLine = lines.first else { return }
        
        // 最初の行は必ずレベル0でなければならない
        guard firstLine.level == 0 else {
            throw QuickEntryError.invalidFormat
        }
        
        var previousLevel = 0
        for line in lines.dropFirst() {
            // 1つ前のレベルから+1以上増加してはいけない
            if line.level > previousLevel + 1 {
                throw QuickEntryError.invalidFormat
            }
            previousLevel = line.level
        }
    }
    
    private func buildNodeHierarchy(_ lines: [ParsedLine]) throws -> ParsedNode {
        guard !lines.isEmpty else {
            throw QuickEntryError.parsingFailed
        }
        
        // 再帰的にノードを構築
        var index = 0
        let (rootNode, _) = try buildNode(lines, index: &index, expectedLevel: 0)
        return rootNode
    }
    
    private func buildNode(_ lines: [ParsedLine], index: inout Int, expectedLevel: Int) throws -> (ParsedNode, Int) {
        guard index < lines.count else {
            throw QuickEntryError.parsingFailed
        }
        
        let line = lines[index]
        guard line.level == expectedLevel else {
            throw QuickEntryError.parsingFailed
        }
        
        var children: [ParsedNode] = []
        index += 1
        
        // 子ノードを探す
        while index < lines.count && lines[index].level > expectedLevel {
            if lines[index].level == expectedLevel + 1 {
                // 直接の子ノード
                let (childNode, _) = try buildNode(lines, index: &index, expectedLevel: expectedLevel + 1)
                children.append(childNode)
            } else {
                // スキップするレベルがある場合はエラー
                throw QuickEntryError.invalidFormat
            }
        }
        
        let node = ParsedNode(text: line.text, level: line.level, children: children)
        return (node, index)
    }
}

// MARK: - Supporting Types
private struct ParsedLine {
    let text: String
    let level: Int
}