import SwiftUI
import MindMapCore

// MARK: - Accessibility Helper
public final class AccessibilityHelper {
    
    public init() {}
    
    // MARK: - Canvas Accessibility
    public static func generateCanvasLabel(for mindMap: MindMap) -> String {
        return "マインドマップ: \(mindMap.title)"
    }
    
    public static func generateCanvasHint() -> String {
        return "ダブルタップしてノードを追加"
    }
    
    // MARK: - Node Accessibility
    public static func generateNodeLabel(for node: Node, level: Int = 0) -> String {
        let levelText = level == 0 ? "ルートノード" : "レベル\(level)"
        return "\(levelText): \(node.text)"
    }
    
    public static func generateNodeHint(for node: Node) -> String {
        return "編集するにはダブルタップ、子ノードを追加するにはロングプレス"
    }
    
    public static func getNodeTraits(for node: Node) -> AccessibilityTraits {
        var traits: AccessibilityTraits = []
        
        if node.isTask {
            // タスクノードの特別な扱い
        }
        
        return traits
    }
    
    // MARK: - Editing State Accessibility
    public static func generateEditingLabel(for node: Node) -> String {
        return "編集中: \(node.text)"
    }
    
    public static func generateEditingHint() -> String {
        return "完了するには外側をタップ"
    }
    
    public static func getEditingTraits() -> AccessibilityTraits {
        return []
    }
    
    // MARK: - Color Blind Support
    public static func hasNonColorIndicators(for node: Node) -> Bool {
        // アイコンやパターンによる視覚的指標があるかチェック
        return true // 基本実装では常にtrue
    }
    
    public static func hasPatternSupport(for node: Node) -> Bool {
        // パターンサポートがあるかチェック
        return true // 基本実装では常にtrue
    }
    
    public static func hasShapeVariation(for node: Node) -> Bool {
        // 形状バリエーションがあるかチェック
        return true // 基本実装では常にtrue
    }
}

// MARK: - Dynamic Type Helper
public final class DynamicTypeHelper {
    
    public static let minimumFontSize: CGFloat = 12.0
    public static let maximumFontSize: CGFloat = 48.0
    
    public init() {}
    
    public static func getNodeFontSize(for sizeCategory: ContentSizeCategory) -> CGFloat {
        switch sizeCategory {
        case .extraSmall:
            return 14.0
        case .small:
            return 16.0
        case .medium:
            return 18.0
        case .large:
            return 20.0
        case .extraLarge:
            return 22.0
        case .extraExtraLarge:
            return 24.0
        case .extraExtraExtraLarge:
            return 26.0
        case .accessibilityMedium:
            return 32.0
        case .accessibilityLarge:
            return 36.0
        case .accessibilityExtraLarge:
            return 40.0
        case .accessibilityExtraExtraLarge:
            return 44.0
        case .accessibilityExtraExtraExtraLarge:
            return 48.0
        @unknown default:
            return 18.0
        }
    }
    
    public static func getMinimumTapSize(for sizeCategory: ContentSizeCategory) -> CGSize {
        // アクセシビリティガイドラインに従った最小タップサイズ
        let baseSize: CGFloat = 44.0
        let multiplier = sizeCategory.isAccessibilityCategory ? 1.2 : 1.0
        let size = baseSize * multiplier
        return CGSize(width: size, height: size)
    }
}

// MARK: - Color Accessibility Helper
public final class ColorAccessibilityHelper {
    
    public init() {}
    
    public static func getColors(
        for colorScheme: ColorScheme,
        contrast: AccessibilityContrast
    ) -> ColorAccessibilityInfo {
        switch (colorScheme, contrast) {
        case (.light, .normal):
            return ColorAccessibilityInfo(
                text: Color.black,
                background: Color.white,
                buttonText: Color.white,
                buttonBackground: Color.blue,
                accent: Color.blue,
                secondary: Color.gray
            )
        case (.light, .high):
            return ColorAccessibilityInfo(
                text: Color.black,
                background: Color.white,
                buttonText: Color.white,
                buttonBackground: Color.black,
                accent: Color.black,
                secondary: Color.black.opacity(0.7)
            )
        case (.dark, .normal):
            return ColorAccessibilityInfo(
                text: Color.white,
                background: Color.black,
                buttonText: Color.black,
                buttonBackground: Color.white,
                accent: Color.blue,
                secondary: Color.gray
            )
        case (.dark, .high):
            return ColorAccessibilityInfo(
                text: Color.white,
                background: Color.black,
                buttonText: Color.black,
                buttonBackground: Color.white,
                accent: Color.white,
                secondary: Color.white.opacity(0.7)
            )
        }
    }
    
    public static func calculateContrastRatio(
        foreground: Color,
        background: Color
    ) -> Double {
        // 簡略化されたコントラスト比計算
        // 実際の実装では相対輝度を正確に計算する必要がある
        let fgLuminance = getLuminance(for: foreground)
        let bgLuminance = getLuminance(for: background)
        
        let lighter = max(fgLuminance, bgLuminance)
        let darker = min(fgLuminance, bgLuminance)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    private static func getLuminance(for color: Color) -> Double {
        // 簡略化された輝度計算
        // 実際の実装ではsRGB変換とガンマ補正が必要
        if color == .white {
            return 1.0
        } else if color == .black {
            return 0.0
        } else {
            return 0.5 // 中間値として処理
        }
    }
}

// MARK: - Keyboard Navigation Manager
public final class KeyboardNavigationManager: ObservableObject {
    
    private let mindMap: MindMap
    
    public init(mindMap: MindMap) {
        self.mindMap = mindMap
    }
    
    public func canReceiveFocus() -> Bool {
        return true
    }
    
    public func getFocusableElements() -> [FocusableElement] {
        var elements: [FocusableElement] = []
        
        // Canvas要素
        elements.append(FocusableElement(
            id: mindMap.id,
            type: .canvas,
            frame: CGRect(x: 0, y: 0, width: 375, height: 667),
            accessibilityLabel: "マインドマップキャンバス"
        ))
        
        // Toolbar要素
        elements.append(FocusableElement(
            id: UUID(),
            type: .toolbar,
            frame: CGRect(x: 0, y: 0, width: 375, height: 44),
            accessibilityLabel: "ツールバー"
        ))
        
        return elements
    }
}

// MARK: - Keyboard Shortcut Manager
public final class KeyboardShortcutManager {
    
    public init() {}
    
    public func getAvailableShortcuts() -> [KeyboardShortcut] {
        return [
            KeyboardShortcut(
                key: .escape,
                modifiers: [],
                description: "キャンセル",
                action: {}
            ),
            KeyboardShortcut(
                key: .return,
                modifiers: [],
                description: "確定",
                action: {}
            ),
            KeyboardShortcut(
                key: .tab,
                modifiers: [],
                description: "次の要素",
                action: {}
            ),
            KeyboardShortcut(
                key: .space,
                modifiers: [],
                description: "選択",
                action: {}
            )
        ]
    }
}

// MARK: - Switch Control Helper
public final class SwitchControlHelper {
    
    public init() {}
    
    public func getAvailableActions(for node: Node) -> [SwitchAction] {
        return [.select, .activate, .showMenu]
    }
    
    public func canPerformAction(_ action: SwitchAction, on node: Node) -> Bool {
        return true // 基本実装では常にtrue
    }
}

// MARK: - Focus Manager
public final class FocusManager: ObservableObject {
    
    private var currentFocusedNode: Node?
    
    public init() {}
    
    public func getCurrentFocus() -> Node? {
        return currentFocusedNode
    }
    
    public func setFocus(to node: Node) {
        currentFocusedNode = node
    }
    
    public func moveFocusToNext() {
        // 基本実装では何もしない
        // 実際の実装では次のフォーカス可能要素を探す
    }
}

// MARK: - Accessibility Action Helper
public final class AccessibilityActionHelper {
    
    public init() {}
    
    public static func getCustomActions(for node: Node) -> [AccessibilityCustomAction] {
        return [
            AccessibilityCustomAction(name: "子ノードを追加") {},
            AccessibilityCustomAction(name: "ノードを編集") {},
            AccessibilityCustomAction(name: "ノードを削除") {},
            AccessibilityCustomAction(name: "メディアを追加") {}
        ]
    }
}

// MARK: - Accessibility Notification Helper
public final class AccessibilityNotificationHelper {
    
    public init() {}
    
    public func createLayoutChangedNotification(_ message: String) -> AccessibilityNotification {
        return AccessibilityNotification(
            type: .layoutChanged,
            message: message,
            element: nil
        )
    }
    
    public func createScreenChangedNotification(_ message: String) -> AccessibilityNotification {
        return AccessibilityNotification(
            type: .screenChanged,
            message: message,
            element: nil
        )
    }
}