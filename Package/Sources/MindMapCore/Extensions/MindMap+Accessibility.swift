import Foundation

// MARK: - MindMap Accessibility Extension
extension MindMap {
    
    // MARK: - Basic Accessibility Properties
    public var accessibilityLabel: String {
        var label = "マインドマップ: \(title)"
        
        if isShared {
            let permissionText = sharePermissions == .readOnly ? "読み取り専用" : "編集可能"
            label += ", 共有中: \(permissionText)"
        }
        
        return label
    }
    
    public var accessibilityValue: String {
        let nodeCount = nodeIDs.count
        return "\(nodeCount)個のノード"
    }
    
    public var accessibilityHint: String {
        if isEmpty {
            return "ノードを追加してマインドマップを作成してください"
        } else {
            return "ノードをタップして編集、空白部分をタップして新しいノードを追加"
        }
    }
    
    // MARK: - Navigation Info
    public var accessibilityNavigationInfo: AccessibilityNavigationInfo {
        return AccessibilityNavigationInfo(
            totalNodes: nodeIDs.count,
            currentNodeIndex: 0, // 基本実装
            hasNext: nodeIDs.count > 1,
            hasPrevious: nodeIDs.count > 1
        )
    }
}

// MARK: - AccessibilityNavigationInfo
public struct AccessibilityNavigationInfo {
    public let totalNodes: Int
    public let currentNodeIndex: Int?
    public let hasNext: Bool
    public let hasPrevious: Bool
    
    public init(
        totalNodes: Int,
        currentNodeIndex: Int?,
        hasNext: Bool,
        hasPrevious: Bool
    ) {
        self.totalNodes = totalNodes
        self.currentNodeIndex = currentNodeIndex
        self.hasNext = hasNext
        self.hasPrevious = hasPrevious
    }
}