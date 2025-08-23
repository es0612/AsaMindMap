import SwiftUI
import MindMapCore

// MARK: - Focusable View Modifier
public struct FocusableViewModifier: ViewModifier {
    
    let element: FocusableElement
    @EnvironmentObject private var accessibilityConfig: AccessibilityConfiguration
    @FocusState private var isFocused: Bool
    
    public func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .accessibilityElement()
            .accessibilityLabel(element.accessibilityLabel)
            .accessibilityAddTraits(isFocused ? .isSelected : [])
            .onExitCommand {
                // Escapeキーで現在の操作をキャンセル
                isFocused = false
            }
    }
}

// MARK: - Keyboard Navigation View
public struct KeyboardNavigationView<Content: View>: View {
    
    let content: Content
    let mindMap: MindMap
    @StateObject private var keyboardManager: KeyboardNavigationManager
    @StateObject private var focusManager = FocusManager()
    
    public init(
        mindMap: MindMap,
        @ViewBuilder content: () -> Content
    ) {
        self.mindMap = mindMap
        self.content = content()
        self._keyboardManager = StateObject(wrappedValue: KeyboardNavigationManager(mindMap: mindMap))
    }
    
    public var body: some View {
        content
            .environmentObject(focusManager)
            .accessibilityElement(children: .contain)
            .onKeyPress(.tab) { press in
                if press.modifiers.contains(.shift) {
                    focusManager.moveFocusToPrevious()
                } else {
                    focusManager.moveFocusToNext()
                }
                return .handled
            }
            .onKeyPress(.space) {
                if let currentFocus = focusManager.getCurrentFocus() {
                    handleSpaceKeyPress(for: currentFocus)
                }
                return .handled
            }
            .onKeyPress(.return) {
                if let currentFocus = focusManager.getCurrentFocus() {
                    handleEnterKeyPress(for: currentFocus)
                }
                return .handled
            }
    }
    
    private func handleSpaceKeyPress(for node: Node) {
        // スペースキー: ノード選択
        NotificationCenter.default.post(
            name: .nodeSelected,
            object: node.id
        )
    }
    
    private func handleEnterKeyPress(for node: Node) {
        // Enterキー: ノード編集
        NotificationCenter.default.post(
            name: .nodeEditRequested,
            object: node.id
        )
    }
}

// MARK: - Focus Manager Extension
extension FocusManager {
    func moveFocusToPrevious() {
        // 前のフォーカス可能要素に移動
        // 基本実装では何もしない
    }
}

// MARK: - Notification Extensions
extension Notification.Name {
    static let nodeSelected = Notification.Name("nodeSelected")
    static let nodeEditRequested = Notification.Name("nodeEditRequested")
    
    // Accessibility notifications
    static let accessibilityElementFocusedNotification = Notification.Name("UIAccessibilityElementFocusedNotification")
    static let accessibilityLayoutChangedNotification = Notification.Name("UIAccessibilityLayoutChangedNotification")
}

// MARK: - View Extensions
extension View {
    public func focusable(_ element: FocusableElement) -> some View {
        modifier(FocusableViewModifier(element: element))
    }
    
    public func keyboardNavigable(mindMap: MindMap) -> some View {
        KeyboardNavigationView(mindMap: mindMap) {
            self
        }
    }
}