import Foundation
import CoreGraphics

// MARK: - MindMap Extensions for API Integration
extension MindMap {
    /// 既存のMindMapエンティティとテスト・API統合の互換性を保つための拡張
    
    // Test compatibility - rootNode computed property
    public var rootNode: Node {
        get {
            // デフォルトのrootNodeを返す（実際の実装では適切なNode管理が必要）
            Node(
                id: rootNodeID ?? UUID(),
                text: title,
                position: CGPoint(x: 0, y: 0)
            )
        }
    }
    
    // Test compatibility - nodes computed property
    public var nodes: [Node] {
        get {
            // 簡略化されたnodes配列（実際の実装では適切なNode管理が必要）
            var nodeArray = [Node]()
            
            if let rootID = rootNodeID {
                let rootNode = Node(
                    id: rootID,
                    text: title,
                    position: CGPoint(x: 0, y: 0)
                )
                nodeArray.append(rootNode)
            }
            
            // 他のノードも含める（実際の実装では永続化されたノードを取得）
            for nodeID in nodeIDs.prefix(5) { // 最大5個のサンプルノード
                if nodeID != rootNodeID {
                    let node = Node(
                        id: nodeID,
                        text: "Node \(nodeID.uuidString.prefix(8))",
                        position: CGPoint(x: 100, y: 50)
                    )
                    nodeArray.append(node)
                }
            }
            
            return nodeArray
        }
    }
    
    // Test compatibility - tags computed property
    public var tags: [Tag] {
        get {
            return tagIDs.map { tagID in
                Tag(
                    id: tagID,
                    name: "Tag-\(tagID.uuidString.prefix(8))",
                    color: .accent
                )
            }
        }
        set {
            tagIDs = Set(newValue.map { $0.id })
            updatedAt = Date()
        }
    }
    
    /// API integration用の便利な初期化子
    public init(
        id: UUID = UUID(),
        title: String,
        rootNode: Node,
        nodes: [Node],
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.rootNodeID = rootNode.id
        self.nodeIDs = Set(nodes.map { $0.id })
        self.tagIDs = Set(tags.enumerated().map { _, name in
            let tag = Tag(name: name)
            return tag.id
        })
        self.mediaIDs = []
        self.isShared = false
        self.shareURL = nil
        self.sharePermissions = .private
        self.templateId = nil
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = nil
        self.version = 1
    }
    
    /// MindMapにTagを動的に追加する互換メソッド
    public mutating func addTag(_ tag: Tag) {
        tagIDs.insert(tag.id)
        updatedAt = Date()
    }
}

// MARK: - Node Extensions for API Integration
extension Node {
    /// APIテスト用の便利なプロパティ
    public var children: [Node] {
        get {
            // 実際の実装では適切な子ノード管理が必要
            return childIDs.map { childID in
                Node(
                    id: childID,
                    text: "Child \(childID.uuidString.prefix(8))",
                    position: CGPoint(x: position.x + 100, y: position.y + 50),
                    parentID: self.id
                )
            }
        }
        set {
            childIDs = Set(newValue.map { $0.id })
            updatedAt = Date()
        }
    }
    
    /// 子ノードを追加するメソッド
    public mutating func appendChild(_ child: Node) {
        childIDs.insert(child.id)
        updatedAt = Date()
    }
}