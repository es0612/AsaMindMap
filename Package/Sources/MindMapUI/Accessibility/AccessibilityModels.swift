import SwiftUI
import Foundation
import MindMapCore

// MARK: - Focusable Element
public struct FocusableElement {
    public let id: UUID
    public let type: FocusableElementType
    public let frame: CGRect
    public let accessibilityLabel: String
    
    public init(
        id: UUID,
        type: FocusableElementType,
        frame: CGRect,
        accessibilityLabel: String
    ) {
        self.id = id
        self.type = type
        self.frame = frame
        self.accessibilityLabel = accessibilityLabel
    }
}

// MARK: - Focusable Element Type
public enum FocusableElementType {
    case canvas
    case toolbar
    case node
    case button
    case textField
}

// MARK: - Keyboard Shortcut
public struct KeyboardShortcut {
    public let key: KeyEquivalent
    public let modifiers: EventModifiers
    public let description: String
    public let action: () -> Void
    
    public init(
        key: KeyEquivalent,
        modifiers: EventModifiers = [],
        description: String,
        action: @escaping () -> Void
    ) {
        self.key = key
        self.modifiers = modifiers
        self.description = description
        self.action = action
    }
}

// MARK: - Switch Action
public enum SwitchAction {
    case select
    case activate
    case showMenu
}

// MARK: - Accessibility Notification
public struct AccessibilityNotification {
    public let type: AccessibilityNotificationType
    public let message: String
    public let element: AnyView?
    
    public init(
        type: AccessibilityNotificationType,
        message: String,
        element: AnyView? = nil
    ) {
        self.type = type
        self.message = message
        self.element = element
    }
}

// MARK: - Accessibility Notification Type
public enum AccessibilityNotificationType {
    case layoutChanged
    case screenChanged
    case announcement
}

// MARK: - Color Accessibility Info
public struct ColorAccessibilityInfo {
    public let text: Color
    public let background: Color
    public let buttonText: Color
    public let buttonBackground: Color
    public let accent: Color
    public let secondary: Color
    
    public init(
        text: Color,
        background: Color,
        buttonText: Color,
        buttonBackground: Color,
        accent: Color,
        secondary: Color
    ) {
        self.text = text
        self.background = background
        self.buttonText = buttonText
        self.buttonBackground = buttonBackground
        self.accent = accent
        self.secondary = secondary
    }
}

// MARK: - Accessibility Custom Action
public struct AccessibilityCustomAction {
    public let name: String
    public let action: () -> Void
    
    public init(name: String, action: @escaping () -> Void) {
        self.name = name
        self.action = action
    }
}

// MARK: - Node Group (for grouping accessibility)
public enum NodeGroup {
    public static func accessibilityLabel(for nodes: [Node]) -> String {
        return "\(nodes.count)個のノードグループ"
    }
    
    public static func accessibilityHint(for nodes: [Node]) -> String {
        return "グループ内のノードを操作するには選択してください"
    }
}

// MARK: - Accessibility Contrast
public enum AccessibilityContrast {
    case normal
    case high
}

// MARK: - ContentSizeCategory Extension
extension ContentSizeCategory {
    public var isAccessibilityCategory: Bool {
        switch self {
        case .accessibilityMedium,
             .accessibilityLarge,
             .accessibilityExtraLarge,
             .accessibilityExtraExtraLarge,
             .accessibilityExtraExtraExtraLarge:
            return true
        default:
            return false
        }
    }
}