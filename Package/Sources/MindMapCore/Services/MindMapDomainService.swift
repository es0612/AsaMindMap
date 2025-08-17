import Foundation
import CoreGraphics

// MARK: - MindMap Domain Service
public protocol MindMapDomainServiceProtocol {
    func createMindMap(title: String) async throws -> MindMap
    func createRootNode(for mindMapID: UUID, text: String, position: CGPoint) async throws -> Node
    func addChildNode(to parentID: UUID, text: String, position: CGPoint) async throws -> Node
    func moveNode(_ nodeID: UUID, to newPosition: CGPoint) async throws
    func deleteNode(_ nodeID: UUID) async throws
    func validateMindMapStructure(_ mindMapID: UUID) async throws -> ValidationResult
}

public final class MindMapDomainService: MindMapDomainServiceProtocol {
    private let mindMapRepository: MindMapRepositoryProtocol
    private let nodeRepository: NodeRepositoryProtocol
    private let mindMapValidator: MindMapValidator
    private let nodeValidator: NodeValidator
    
    public init(
        mindMapRepository: MindMapRepositoryProtocol,
        nodeRepository: NodeRepositoryProtocol,
        mindMapValidator: MindMapValidator = MindMapValidator(),
        nodeValidator: NodeValidator = NodeValidator()
    ) {
        self.mindMapRepository = mindMapRepository
        self.nodeRepository = nodeRepository
        self.mindMapValidator = mindMapValidator
        self.nodeValidator = nodeValidator
    }
    
    public func createMindMap(title: String) async throws -> MindMap {
        let mindMap = MindMap(title: title)
        
        let validationResult = mindMapValidator.validateForCreation(mindMap)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "バリデーションエラー")
        }
        
        try await mindMapRepository.save(mindMap)
        return mindMap
    }
    
    public func createRootNode(for mindMapID: UUID, text: String, position: CGPoint) async throws -> Node {
        guard var mindMap = try await mindMapRepository.findByID(mindMapID) else {
            throw MindMapError.invalidNodeData
        }
        
        // 既にルートノードが存在する場合はエラー
        if mindMap.hasRootNode {
            throw MindMapError.validationError("ルートノードは既に存在します")
        }
        
        let node = Node(text: text, position: position)
        
        let validationResult = nodeValidator.validateForCreation(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "ノードバリデーションエラー")
        }
        
        try await nodeRepository.save(node)
        
        mindMap.setRootNode(node.id)
        try await mindMapRepository.save(mindMap)
        
        return node
    }
    
    public func addChildNode(to parentID: UUID, text: String, position: CGPoint) async throws -> Node {
        guard var parentNode = try await nodeRepository.findByID(parentID) else {
            throw MindMapError.invalidNodeData
        }
        
        let childNode = Node(text: text, position: position, parentID: parentID)
        
        let validationResult = nodeValidator.validateForCreation(childNode)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "ノードバリデーションエラー")
        }
        
        try await nodeRepository.save(childNode)
        
        parentNode.addChild(childNode.id)
        try await nodeRepository.save(parentNode)
        
        return childNode
    }
    
    public func moveNode(_ nodeID: UUID, to newPosition: CGPoint) async throws {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        node.updatePosition(newPosition)
        
        let validationResult = nodeValidator.validate(node)
        guard validationResult.isValid else {
            throw MindMapError.validationError(validationResult.errorMessage ?? "位置バリデーションエラー")
        }
        
        try await nodeRepository.save(node)
    }
    
    public func deleteNode(_ nodeID: UUID) async throws {
        guard let node = try await nodeRepository.findByID(nodeID) else {
            throw MindMapError.invalidNodeData
        }
        
        // 子ノードも削除
        let children = try await nodeRepository.findChildren(of: nodeID)
        for child in children {
            try await deleteNode(child.id)
        }
        
        // 親ノードから削除
        if let parentID = node.parentID {
            if var parentNode = try await nodeRepository.findByID(parentID) {
                parentNode.removeChild(nodeID)
                try await nodeRepository.save(parentNode)
            }
        }
        
        try await nodeRepository.delete(nodeID)
    }
    
    public func validateMindMapStructure(_ mindMapID: UUID) async throws -> ValidationResult {
        guard let mindMap = try await mindMapRepository.findByID(mindMapID) else {
            return .failure("マインドマップが見つかりません")
        }
        
        // マインドマップ自体のバリデーション
        let mindMapResult = mindMapValidator.validate(mindMap)
        if case .failure = mindMapResult {
            return mindMapResult
        }
        
        // 全ノードのバリデーション
        let nodes = try await nodeRepository.findByMindMapID(mindMapID)
        for node in nodes {
            let nodeResult = nodeValidator.validate(node)
            if case .failure = nodeResult {
                return nodeResult
            }
        }
        
        // 構造の整合性チェック
        return try await validateStructuralIntegrity(mindMap: mindMap, nodes: nodes)
    }
    
    private func validateStructuralIntegrity(mindMap: MindMap, nodes: [Node]) async throws -> ValidationResult {
        let nodeDict = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        // ルートノードの存在確認
        if let rootID = mindMap.rootNodeID {
            guard nodeDict[rootID] != nil else {
                return .failure("ルートノードが見つかりません")
            }
        }
        
        // 親子関係の整合性チェック
        for node in nodes {
            // 親ノードの存在確認
            if let parentID = node.parentID {
                guard let parentNode = nodeDict[parentID] else {
                    return .failure("親ノード（ID: \(parentID)）が見つかりません")
                }
                
                // 親ノードの子リストに含まれているかチェック
                guard parentNode.childIDs.contains(node.id) else {
                    return .failure("親子関係の不整合が検出されました")
                }
            }
            
            // 子ノードの存在確認
            for childID in node.childIDs {
                guard let childNode = nodeDict[childID] else {
                    return .failure("子ノード（ID: \(childID)）が見つかりません")
                }
                
                // 子ノードの親IDが正しいかチェック
                guard childNode.parentID == node.id else {
                    return .failure("親子関係の不整合が検出されました")
                }
            }
        }
        
        // 循環参照のチェック
        for node in nodes {
            if try await hasCircularReference(nodeID: node.id, nodeDict: nodeDict, visited: Set()) {
                return .failure("循環参照が検出されました")
            }
        }
        
        return .success
    }
    
    private func hasCircularReference(nodeID: UUID, nodeDict: [UUID: Node], visited: Set<UUID>) async throws -> Bool {
        if visited.contains(nodeID) {
            return true
        }
        
        guard let node = nodeDict[nodeID] else {
            return false
        }
        
        var newVisited = visited
        newVisited.insert(nodeID)
        
        for childID in node.childIDs {
            if try await hasCircularReference(nodeID: childID, nodeDict: nodeDict, visited: newVisited) {
                return true
            }
        }
        
        return false
    }
}

// MARK: - Node Hierarchy Service
public protocol NodeHierarchyServiceProtocol {
    func getNodePath(from rootID: UUID, to targetID: UUID) async throws -> [Node]
    func getNodeDepth(_ nodeID: UUID) async throws -> Int
    func getSubtreeNodes(_ rootID: UUID) async throws -> [Node]
    func calculateNodePositions(for mindMapID: UUID) async throws -> [UUID: CGPoint]
}

public final class NodeHierarchyService: NodeHierarchyServiceProtocol {
    private let nodeRepository: NodeRepositoryProtocol
    
    public init(nodeRepository: NodeRepositoryProtocol) {
        self.nodeRepository = nodeRepository
    }
    
    public func getNodePath(from rootID: UUID, to targetID: UUID) async throws -> [Node] {
        let allNodes = try await nodeRepository.findAll()
        let nodeDict = Dictionary(uniqueKeysWithValues: allNodes.map { ($0.id, $0) })
        
        return findPath(from: rootID, to: targetID, in: nodeDict) ?? []
    }
    
    public func getNodeDepth(_ nodeID: UUID) async throws -> Int {
        guard var node = try await nodeRepository.findByID(nodeID) else {
            return 0
        }
        
        var depth = 0
        while let parentID = node.parentID {
            depth += 1
            guard let parentNode = try await nodeRepository.findByID(parentID) else {
                break
            }
            node = parentNode
        }
        
        return depth
    }
    
    public func getSubtreeNodes(_ rootID: UUID) async throws -> [Node] {
        var result: [Node] = []
        var queue: [UUID] = [rootID]
        
        while !queue.isEmpty {
            let currentID = queue.removeFirst()
            
            guard let node = try await nodeRepository.findByID(currentID) else {
                continue
            }
            
            result.append(node)
            queue.append(contentsOf: node.childIDs)
        }
        
        return result
    }
    
    public func calculateNodePositions(for mindMapID: UUID) async throws -> [UUID: CGPoint] {
        let nodes = try await nodeRepository.findByMindMapID(mindMapID)
        let nodeDict = Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) })
        
        var positions: [UUID: CGPoint] = [:]
        
        // 既存の位置を保持
        for node in nodes {
            positions[node.id] = node.position
        }
        
        // ルートノードから開始して自動配置
        let rootNodes = nodes.filter { $0.isRoot }
        for rootNode in rootNodes {
            calculateSubtreePositions(
                nodeID: rootNode.id,
                nodeDict: nodeDict,
                positions: &positions,
                centerPosition: rootNode.position,
                level: 0
            )
        }
        
        return positions
    }
    
    private func findPath(from startID: UUID, to targetID: UUID, in nodeDict: [UUID: Node]) -> [Node]? {
        guard let startNode = nodeDict[startID] else { return nil }
        
        if startID == targetID {
            return [startNode]
        }
        
        for childID in startNode.childIDs {
            if let path = findPath(from: childID, to: targetID, in: nodeDict) {
                return [startNode] + path
            }
        }
        
        return nil
    }
    
    private func calculateSubtreePositions(
        nodeID: UUID,
        nodeDict: [UUID: Node],
        positions: inout [UUID: CGPoint],
        centerPosition: CGPoint,
        level: Int
    ) {
        guard let node = nodeDict[nodeID] else { return }
        
        let children = node.childIDs.compactMap { nodeDict[$0] }
        guard !children.isEmpty else { return }
        
        let radius: CGFloat = 150 + CGFloat(level * 50)
        let angleStep = 2 * CGFloat.pi / CGFloat(children.count)
        
        for (index, child) in children.enumerated() {
            let angle = CGFloat(index) * angleStep
            let x = centerPosition.x + radius * cos(angle)
            let y = centerPosition.y + radius * sin(angle)
            let childPosition = CGPoint(x: x, y: y)
            
            positions[child.id] = childPosition
            
            calculateSubtreePositions(
                nodeID: child.id,
                nodeDict: nodeDict,
                positions: &positions,
                centerPosition: childPosition,
                level: level + 1
            )
        }
    }
}