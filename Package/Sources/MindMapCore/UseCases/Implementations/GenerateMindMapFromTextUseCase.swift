import Foundation

// MARK: - Generate MindMap From Text Use Case Implementation
final class GenerateMindMapFromTextUseCase: GenerateMindMapFromTextUseCaseProtocol {
    
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    
    init(mindMapRepository: MindMapRepositoryProtocol, nodeRepository: NodeRepositoryProtocol) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
    }
    
    // Backward compatibility init for tests
    convenience init(repository: MindMapRepositoryProtocol) {
        // For tests, create a dummy node repository
        self.init(mindMapRepository: repository, nodeRepository: DummyNodeRepository())
    }
    
    func execute(_ request: GenerateMindMapFromTextRequest) async throws -> GenerateMindMapFromTextResponse {
        let structure = request.structure
        let title = request.title ?? structure.rootNode.text
        
        // 空の構造チェック
        guard !structure.rootNode.text.isEmpty else {
            throw QuickEntryError.generationFailed
        }
        
        // マインドマップとノードを生成
        let (mindMap, nodes) = try await generateMindMap(from: structure, title: title)
        
        // プレビューデータを生成
        let previewData = generatePreviewData(from: structure)
        
        // 保存
        try await mindMapRepository.save(mindMap)
        
        // ノードも保存
        for node in nodes {
            try await nodeRepository.save(node)
        }
        
        return GenerateMindMapFromTextResponse(
            mindMap: mindMap,
            nodes: nodes,
            previewData: previewData
        )
    }
    
    // MARK: - Private Methods
    
    private func generateMindMap(from structure: MindMapStructure, title: String) async throws -> (MindMap, [Node]) {
        let mindMapId = UUID()
        var nodes: [Node] = []
        var nodePositions: [UUID: CGPoint] = [:]
        
        // ルートノードを作成
        let rootNodeId = UUID()
        let rootNode = Node(
            id: rootNodeId,
            text: structure.rootNode.text,
            position: CGPoint(x: 0, y: 0),
            parentID: nil
        )
        nodes.append(rootNode)
        nodePositions[rootNodeId] = rootNode.position
        
        // 子ノードを再帰的に生成
        try await generateChildNodes(
            from: structure.rootNode.children,
            parentId: rootNodeId,
            nodes: &nodes,
            positions: &nodePositions,
            currentLevel: 1
        )
        
        // ノードIDセットを作成
        let nodeIDs = Set(nodes.map { $0.id })
        
        // MindMapを作成
        let mindMap = MindMap(
            id: mindMapId,
            title: title,
            rootNodeID: rootNodeId,
            nodeIDs: nodeIDs,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        return (mindMap, nodes)
    }
    
    private func generateChildNodes(
        from parsedNodes: [ParsedNode],
        parentId: UUID,
        nodes: inout [Node],
        positions: inout [UUID: CGPoint],
        currentLevel: Int
    ) async throws {
        
        let parentPosition = positions[parentId] ?? .zero
        let angleStep = 2.0 * Double.pi / Double(max(parsedNodes.count, 1))
        let radius = Double(currentLevel * 150) // レベルごとに半径を調整
        
        for (index, parsedNode) in parsedNodes.enumerated() {
            let nodeId = UUID()
            
            // ノード位置を計算（円形配置）
            let angle = angleStep * Double(index)
            let x = parentPosition.x + CGFloat(radius * cos(angle))
            let y = parentPosition.y + CGFloat(radius * sin(angle))
            let position = CGPoint(x: x, y: y)
            
            let node = Node(
                id: nodeId,
                text: parsedNode.text,
                position: position,
                parentID: parentId
            )
            
            nodes.append(node)
            positions[nodeId] = position
            
            // 子ノードを再帰的に生成
            if !parsedNode.children.isEmpty {
                try await generateChildNodes(
                    from: parsedNode.children,
                    parentId: nodeId,
                    nodes: &nodes,
                    positions: &positions,
                    currentLevel: currentLevel + 1
                )
            }
        }
    }
    
    private func generatePreviewData(from structure: MindMapStructure) -> MindMapPreview {
        let nodeCount = countNodes(structure.rootNode)
        let maxDepth = calculateMaxDepth(structure.rootNode)
        
        // 推定サイズを計算（概算）
        let baseWidth: CGFloat = 200
        let baseHeight: CGFloat = 150
        let estimatedWidth = baseWidth * CGFloat(maxDepth + 1)
        let estimatedHeight = baseHeight * CGFloat(nodeCount / max(maxDepth, 1))
        
        return MindMapPreview(
            nodeCount: nodeCount,
            maxDepth: maxDepth,
            estimatedSize: CGSize(width: estimatedWidth, height: estimatedHeight)
        )
    }
    
    private func countNodes(_ node: ParsedNode) -> Int {
        return 1 + node.children.reduce(0) { sum, child in
            sum + countNodes(child)
        }
    }
    
    private func calculateMaxDepth(_ node: ParsedNode) -> Int {
        if node.children.isEmpty {
            return node.level
        }
        
        let childDepths = node.children.map { calculateMaxDepth($0) }
        return childDepths.max() ?? node.level
    }
}

// MARK: - Dummy Node Repository for backward compatibility
private class DummyNodeRepository: NodeRepositoryProtocol {
    func save(_ node: Node) async throws {}
    func findByID(_ id: UUID) async throws -> Node? { nil }
    func findAll() async throws -> [Node] { [] }
    func delete(_ id: UUID) async throws {}
    func exists(_ id: UUID) async throws -> Bool { false }
    func findByMindMapID(_ mindMapID: UUID) async throws -> [Node] { [] }
    func findChildren(of parentID: UUID) async throws -> [Node] { [] }
    func findParent(of nodeID: UUID) async throws -> Node? { nil }
    func findRootNodes() async throws -> [Node] { [] }
    func findByText(_ text: String) async throws -> [Node] { [] }
    func findTasks(completed: Bool?) async throws -> [Node] { [] }
    func findByTag(_ tagID: UUID) async throws -> [Node] { [] }
    func saveAll(_ nodes: [Node]) async throws {}
    func deleteAll(_ ids: [UUID]) async throws {}
    func moveNode(_ nodeID: UUID, to newParentID: UUID?) async throws {}
    func getNodeHierarchy(_ rootID: UUID) async throws -> [Node] { [] }
}