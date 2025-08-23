import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - Accessibility Tests
struct AccessibilityTests {
    
    // MARK: - Test Setup
    func createTestMindMap() -> MindMap {
        MindMap(
            id: UUID(),
            title: "テスト用マインドマップ",
            rootNodeID: UUID(),
            nodeIDs: Set([UUID()])
        )
    }
    
    func createTestNode() -> Node {
        Node(
            id: UUID(),
            text: "テストノード",
            position: CGPoint(x: 100, y: 100)
        )
    }
    
    // MARK: - VoiceOver Support Tests
    @Test("MindMapCanvasのVoiceOverサポート")
    func testMindMapCanvasVoiceOverSupport() {
        // Given
        let mindMap = createTestMindMap()
        let node = createTestNode()
        
        // When
        let accessibilityLabel = AccessibilityHelper.generateCanvasLabel(for: mindMap)
        let accessibilityHint = AccessibilityHelper.generateCanvasHint()
        
        // Then
        #expect(accessibilityLabel.contains("マインドマップ"))
        #expect(accessibilityLabel.contains("テスト用マインドマップ"))
        #expect(accessibilityHint.contains("ノードを追加"))
        #expect(accessibilityHint.contains("ダブルタップ"))
    }
    
    @Test("NodeViewのVoiceOverサポート")
    func testNodeViewVoiceOverSupport() {
        // Given
        let node = createTestNode()
        
        // When
        let accessibilityLabel = AccessibilityHelper.generateNodeLabel(for: node)
        let accessibilityHint = AccessibilityHelper.generateNodeHint(for: node)
        let accessibilityTraits = AccessibilityHelper.getNodeTraits(for: node)
        
        // Then
        #expect(accessibilityLabel == "ノード: テストノード")
        #expect(accessibilityHint.contains("編集するにはダブルタップ"))
        #expect(accessibilityTraits.contains(.button))
        #expect(accessibilityTraits.contains(.allowsDirectInteraction))
    }
    
    @Test("階層構造のVoiceOver表現")
    func testHierarchicalVoiceOverSupport() {
        // Given
        let parentNode = createTestNode()
        let childNode = Node(
            id: UUID(),
            text: "子ノード",
            position: CGPoint(x: 200, y: 150),
            parentID: parentNode.id
        )
        
        // When
        let parentLabel = AccessibilityHelper.generateNodeLabel(for: parentNode, level: 0)
        let childLabel = AccessibilityHelper.generateNodeLabel(for: childNode, level: 1)
        
        // Then
        #expect(parentLabel.contains("ルートノード"))
        #expect(childLabel.contains("レベル1"))
        #expect(childLabel.contains("子ノード"))
    }
    
    @Test("編集状態のVoiceOverサポート")
    func testEditingStateVoiceOverSupport() {
        // Given
        let node = createTestNode()
        
        // When
        let editingLabel = AccessibilityHelper.generateEditingLabel(for: node)
        let editingHint = AccessibilityHelper.generateEditingHint()
        let editingTraits = AccessibilityHelper.getEditingTraits()
        
        // Then
        #expect(editingLabel.contains("編集中"))
        #expect(editingLabel.contains("テストノード"))
        #expect(editingHint.contains("完了するには"))
        #expect(editingTraits.contains(.updatesFrequently))
        #expect(editingTraits.contains(.causesPageTurn))
    }
    
    // MARK: - Dynamic Type Tests
    @Test("Dynamic Type対応テスト")
    func testDynamicTypeSupport() {
        // Given
        let node = createTestNode()
        let sizes: [ContentSizeCategory] = [
            .extraSmall,
            .medium,
            .extraLarge,
            .accessibilityMedium,
            .accessibilityExtraExtraLarge
        ]
        
        for sizeCategory in sizes {
            // When
            let fontSize = DynamicTypeHelper.getNodeFontSize(for: sizeCategory)
            let minimumTapSize = DynamicTypeHelper.getMinimumTapSize(for: sizeCategory)
            
            // Then
            #expect(fontSize >= DynamicTypeHelper.minimumFontSize)
            #expect(fontSize <= DynamicTypeHelper.maximumFontSize)
            #expect(minimumTapSize.width >= 44.0)
            #expect(minimumTapSize.height >= 44.0)
        }
    }
    
    @Test("コントラスト比テスト")
    func testContrastRatioCompliance() {
        // Given
        let colorSchemes: [ColorScheme] = [.light, .dark]
        let contrastLevels: [UIAccessibilityContrast] = [.normal, .high]
        
        for colorScheme in colorSchemes {
            for contrastLevel in contrastLevels {
                // When
                let colors = ColorAccessibilityHelper.getColors(
                    for: colorScheme,
                    contrast: contrastLevel
                )
                
                let textContrastRatio = ColorAccessibilityHelper.calculateContrastRatio(
                    foreground: colors.text,
                    background: colors.background
                )
                
                let buttonContrastRatio = ColorAccessibilityHelper.calculateContrastRatio(
                    foreground: colors.buttonText,
                    background: colors.buttonBackground
                )
                
                // Then
                #expect(textContrastRatio >= 4.5) // WCAG AA標準
                #expect(buttonContrastRatio >= 3.0) // WCAG AA非テキスト標準
                
                if contrastLevel == .high {
                    #expect(textContrastRatio >= 7.0) // WCAG AAA標準
                }
            }
        }
    }
    
    @Test("色覚対応テスト")
    func testColorBlindnessSupport() {
        // Given
        let node = createTestNode()
        
        // When
        let hasIconIndicators = AccessibilityHelper.hasNonColorIndicators(for: node)
        let hasPatternSupport = AccessibilityHelper.hasPatternSupport(for: node)
        let hasShapeVariation = AccessibilityHelper.hasShapeVariation(for: node)
        
        // Then
        #expect(hasIconIndicators == true)
        #expect(hasPatternSupport == true) 
        #expect(hasShapeVariation == true)
    }
    
    // MARK: - Keyboard Navigation Tests
    @Test("キーボードナビゲーション基本テスト")
    func testKeyboardNavigationBasics() {
        // Given
        let mindMap = createTestMindMap()
        let keyboardManager = KeyboardNavigationManager(mindMap: mindMap)
        
        // When
        let canReceiveFocus = keyboardManager.canReceiveFocus()
        let focusableElements = keyboardManager.getFocusableElements()
        
        // Then
        #expect(canReceiveFocus == true)
        #expect(focusableElements.count > 0)
        #expect(focusableElements.contains { $0.type == .canvas })
        #expect(focusableElements.contains { $0.type == .toolbar })
    }
    
    @Test("キーボードショートカットテスト")
    func testKeyboardShortcuts() {
        // Given
        let shortcutManager = KeyboardShortcutManager()
        
        // When
        let shortcuts = shortcutManager.getAvailableShortcuts()
        
        // Then
        #expect(shortcuts.contains { $0.key == .escape && $0.description.contains("キャンセル") })
        #expect(shortcuts.contains { $0.key == .return && $0.description.contains("確定") })
        #expect(shortcuts.contains { $0.key == .tab && $0.description.contains("次の要素") })
        #expect(shortcuts.contains { $0.key == .space && $0.description.contains("選択") })
    }
    
    @Test("スイッチコントロール対応テスト")
    func testSwitchControlSupport() {
        // Given
        let node = createTestNode()
        let switchController = SwitchControlHelper()
        
        // When
        let switchActions = switchController.getAvailableActions(for: node)
        let canPerformSwitchAction = switchController.canPerformAction(.select, on: node)
        
        // Then
        #expect(switchActions.contains(.select))
        #expect(switchActions.contains(.activate))
        #expect(switchActions.contains(.showMenu))
        #expect(canPerformSwitchAction == true)
    }
    
    // MARK: - Focus Management Tests
    @Test("フォーカス管理テスト")
    func testFocusManagement() {
        // Given
        let focusManager = FocusManager()
        let node1 = createTestNode()
        let node2 = Node(id: UUID(), text: "ノード2", position: CGPoint(x: 200, y: 200))
        
        // When
        focusManager.setFocus(to: node1)
        let currentFocus = focusManager.getCurrentFocus()
        
        focusManager.moveFocusToNext()
        let nextFocus = focusManager.getCurrentFocus()
        
        // Then
        #expect(currentFocus?.id == node1.id)
        #expect(nextFocus?.id != node1.id) // 次の要素にフォーカスが移動
    }
    
    // MARK: - Accessibility Actions Tests
    @Test("カスタムアクセシビリティアクション")
    func testCustomAccessibilityActions() {
        // Given
        let node = createTestNode()
        
        // When
        let actions = AccessibilityActionHelper.getCustomActions(for: node)
        
        // Then
        #expect(actions.contains { $0.name == "子ノードを追加" })
        #expect(actions.contains { $0.name == "ノードを編集" })
        #expect(actions.contains { $0.name == "ノードを削除" })
        #expect(actions.contains { $0.name == "メディアを追加" })
    }
    
    // MARK: - Accessibility Notifications Tests
    @Test("アクセシビリティ通知テスト")
    func testAccessibilityNotifications() {
        // Given
        let notificationHelper = AccessibilityNotificationHelper()
        
        // When
        let layoutChangedNotification = notificationHelper.createLayoutChangedNotification("新しいノードが追加されました")
        let screenChangedNotification = notificationHelper.createScreenChangedNotification("編集モードに切り替えました")
        
        // Then
        #expect(layoutChangedNotification.type == .layoutChanged)
        #expect(layoutChangedNotification.message.contains("追加"))
        #expect(screenChangedNotification.type == .screenChanged)
        #expect(screenChangedNotification.message.contains("編集モード"))
    }
}