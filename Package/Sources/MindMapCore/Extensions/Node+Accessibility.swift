import Foundation

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Node Accessibility Extension
extension Node {
    
    // MARK: - Basic Accessibility Properties
    public var accessibilityLabel: String {
        let nodeType = isRoot ? "ルートノード" : "ノード"
        var label = "\(nodeType): \(text)"
        
        if isTask {
            let status = isCompleted ? "完了" : "未完了"
            label += ", タスク: \(status)"
        }
        
        if hasMedia {
            label += ", 画像付き"
        }
        
        return label
    }
    
    public var accessibilityValue: String {
        return text
    }
    
    public var accessibilityHint: String {
        var hint = "編集するにはダブルタップ"
        
        if isTask {
            hint += ", 完了状態を切り替えるにはスワイプ"
        }
        
        if hasMedia {
            hint += ", メディアを表示するにはタップ"
        }
        
        return hint
    }
    
    #if canImport(UIKit)
    public var accessibilityTraits: UIAccessibilityTraits {
        var traits: UIAccessibilityTraits = [.button, .allowsDirectInteraction]
        
        if isTask {
            traits.insert(.updatesFrequently)
        }
        
        if isCompleted {
            // 完了タスクは視覚的に無効化（コメント）
        }
        
        return traits
    }
    #endif
    
    // MARK: - Hierarchical Accessibility
    public func accessibilityLabel(level: Int) -> String {
        let levelText = level == 0 ? "ルートノード" : "第\(level)階層"
        var label = "\(levelText): \(text)"
        
        if isTask {
            let status = isCompleted ? "完了" : "未完了"
            label += ", タスク: \(status)"
        }
        
        return label
    }
    
    public func accessibilityLabel(tags: [Tag]) -> String {
        var label = accessibilityLabel
        
        if !tags.isEmpty {
            let tagNames = tags.map { $0.name }.joined(separator: ", ")
            label += ", タグ: \(tagNames)"
        }
        
        return label
    }
    
    // MARK: - Custom Accessibility Actions
    public var accessibilityActions: [AccessibilityCustomAction] {
        var actions: [AccessibilityCustomAction] = []
        
        // 基本アクション
        actions.append(AccessibilityCustomAction(name: "編集") {
            // 編集アクション (実装はViewModelで処理)
        })
        
        actions.append(AccessibilityCustomAction(name: "子ノード追加") {
            // 子ノード追加アクション
        })
        
        actions.append(AccessibilityCustomAction(name: "削除") {
            // 削除アクション
        })
        
        // タスク関連アクション
        if isTask {
            actions.append(AccessibilityCustomAction(name: "完了状態切り替え") {
                // 完了状態切り替えアクション
            })
            
            actions.append(AccessibilityCustomAction(name: "タスク解除") {
                // タスク解除アクション
            })
        }
        
        return actions
    }
    
    // MARK: - Focus Management
    public var canReceiveFocus: Bool {
        return true // 基本的にすべてのノードはフォーカス可能
    }
    
    public var focusPriority: Int {
        if isEditing {
            return 100 // 編集中は最高優先度
        } else if isTask && !isCompleted {
            return 50 // 未完了タスクは高優先度
        } else {
            return 0 // 通常の優先度
        }
    }
    
    // MARK: - Task Management Methods
    public mutating func markAsTask() {
        isTask = true
        updatedAt = Date()
    }
    
    public mutating func markAsCompleted() {
        guard isTask else { return }
        isCompleted = true
        updatedAt = Date()
    }
    
    public mutating func markAsIncomplete() {
        guard isTask else { return }
        isCompleted = false
        updatedAt = Date()
    }
    
    // MARK: - Media Management
    public mutating func attachMedia(_ media: Media) {
        mediaIDs.insert(media.id)
        updatedAt = Date()
    }
    
    // MARK: - Editing State (temporary for testing)
    private static var editingNodes: Set<UUID> = []
    
    public var isEditing: Bool {
        return Self.editingNodes.contains(id)
    }
    
    public mutating func startEditing() {
        Self.editingNodes.insert(id)
        updatedAt = Date()
    }
    
    public mutating func stopEditing() {
        Self.editingNodes.remove(id)
        updatedAt = Date()
    }
}

// MARK: - AccessibilityCustomAction for Node
public struct AccessibilityCustomAction {
    public let name: String
    public let action: () -> Void
    
    public init(name: String, action: @escaping () -> Void) {
        self.name = name
        self.action = action
    }
}