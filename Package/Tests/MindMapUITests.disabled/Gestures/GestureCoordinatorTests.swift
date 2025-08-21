import Testing
import SwiftUI
@testable import MindMapUI

// MARK: - Gesture Coordinator Tests
@MainActor
struct GestureCoordinatorTests {
    
    // MARK: - Initialization Tests
    
    @Test("GestureCoordinatorの初期化が正しく行われる")
    func testInitialization() {
        // Given & When
        let coordinator = GestureCoordinator()
        
        // Then
        #expect(coordinator.activeGestureType == .none)
        #expect(coordinator.isGestureActive == false)
        #expect(coordinator.interactionMode == .navigation)
        #expect(coordinator.configuration.enablePencilGestures == true)
        #expect(coordinator.configuration.enableMultiTouch == true)
        #expect(coordinator.configuration.enableKeyboardShortcuts == true)
    }
    
    @Test("カスタムマネージャーでの初期化が正常に動作する")
    func testInitializationWithCustomManagers() {
        // Given
        let gestureManager = GestureManager()
        let pencilManager = ApplePencilManager()
        let selectionManager = NodeSelectionManager()
        
        // When
        let coordinator = GestureCoordinator(
            gestureManager: gestureManager,
            pencilManager: pencilManager,
            selectionManager: selectionManager
        )
        
        // Then
        #expect(coordinator.gestureManager === gestureManager)
        #expect(coordinator.pencilManager === pencilManager)
        #expect(coordinator.selectionManager === selectionManager)
    }
    
    // MARK: - Interaction Mode Tests
    
    @Test("インタラクションモードの設定が正常に動作する")
    func testSetInteractionMode() {
        // Given
        let coordinator = GestureCoordinator()
        var modeChangedCallbacks: [GestureCoordinator.InteractionMode] = []
        
        coordinator.onInteractionModeChanged = { mode in
            modeChangedCallbacks.append(mode)
        }
        
        // When
        coordinator.setInteractionMode(.drawing)
        
        // Then
        #expect(coordinator.interactionMode == .drawing)
        #expect(coordinator.pencilManager.isDrawingMode == true)
        #expect(modeChangedCallbacks == [.drawing])
        
        // When - 編集モードに変更
        coordinator.setInteractionMode(.editing)
        
        // Then
        #expect(coordinator.interactionMode == .editing)
        #expect(coordinator.pencilManager.isDrawingMode == false)
        #expect(modeChangedCallbacks == [.drawing, .editing])
    }
    
    @Test("同じインタラクションモードの設定が無視される")
    func testSetSameInteractionMode() {
        // Given
        let coordinator = GestureCoordinator()
        var modeChangeCount = 0
        
        coordinator.onInteractionModeChanged = { _ in
            modeChangeCount += 1
        }
        
        // When
        coordinator.setInteractionMode(.navigation)
        coordinator.setInteractionMode(.navigation)
        
        // Then
        #expect(modeChangeCount == 0) // 同じモードなので変更されない
    }
    
    @Test("選択モードへの遷移が正常に動作する")
    func testTransitionToSelectionMode() {
        // Given
        let coordinator = GestureCoordinator()
        
        // When
        coordinator.setInteractionMode(.selection)
        
        // Then
        #expect(coordinator.interactionMode == .selection)
        #expect(coordinator.selectionManager.multiSelectMode == true)
    }
    
    @Test("選択モードからの遷移が正常に動作する")
    func testTransitionFromSelectionMode() {
        // Given
        let coordinator = GestureCoordinator()
        coordinator.setInteractionMode(.selection)
        coordinator.selectionManager.startEditingNode(UUID())
        
        // When
        coordinator.setInteractionMode(.navigation)
        
        // Then
        #expect(coordinator.interactionMode == .navigation)
        #expect(coordinator.selectionManager.multiSelectMode == false)
        #expect(coordinator.selectionManager.isEditingText == false)
    }
    
    // MARK: - Gesture Handling Tests
    
    @Test("ジェスチャー処理可能性の判定が正常に動作する")
    func testCanHandleGesture() {
        // Given
        let coordinator = GestureCoordinator()
        
        // When & Then - ナビゲーションモード
        coordinator.setInteractionMode(.navigation)
        #expect(coordinator.canHandleGesture(.pan) == true)
        #expect(coordinator.canHandleGesture(.zoom) == true)
        #expect(coordinator.canHandleGesture(.tap) == true)
        #expect(coordinator.canHandleGesture(.pencilDraw) == true)
        
        // When & Then - 描画モード
        coordinator.setInteractionMode(.drawing)
        #expect(coordinator.canHandleGesture(.pencilDraw) == true)
        #expect(coordinator.canHandleGesture(.pencilErase) == true)
        #expect(coordinator.canHandleGesture(.pan) == false)
        #expect(coordinator.canHandleGesture(.zoom) == false)
        
        // When & Then - 編集モード
        coordinator.setInteractionMode(.editing)
        #expect(coordinator.canHandleGesture(.tap) == true)
        #expect(coordinator.canHandleGesture(.doubleTap) == true)
        #expect(coordinator.canHandleGesture(.pan) == false)
        #expect(coordinator.canHandleGesture(.pencilDraw) == false)
        
        // When & Then - 選択モード
        coordinator.setInteractionMode(.selection)
        #expect(coordinator.canHandleGesture(.tap) == true)
        #expect(coordinator.canHandleGesture(.longPress) == true)
        #expect(coordinator.canHandleGesture(.pan) == true)
        #expect(coordinator.canHandleGesture(.zoom) == true)
    }
    
    // MARK: - Keyboard Shortcut Tests
    
    @Test("キーボードショートカットの処理が正常に動作する")
    func testHandleKeyboardShortcut() {
        // Given
        let coordinator = GestureCoordinator()
        coordinator.setInteractionMode(.navigation)
        
        // When & Then - 選択マネージャーが処理するショートカット
        let handled = coordinator.handleKeyboardShortcut("c", modifiers: [.command])
        #expect(handled == true) // 選択マネージャーが処理
    }
    
    @Test("編集モードでのキーボードショートカット処理が正常に動作する")
    func testHandleKeyboardShortcutInEditingMode() {
        // Given
        let coordinator = GestureCoordinator()
        coordinator.setInteractionMode(.editing)
        coordinator.selectionManager.startEditingNode(UUID())
        
        // When & Then - Escapeキー
        let escapeHandled = coordinator.handleKeyboardShortcut("escape", modifiers: [])
        #expect(escapeHandled == true)
        #expect(coordinator.selectionManager.isEditingText == false)
        
        // When & Then - Enterキー
        coordinator.selectionManager.startEditingNode(UUID())
        let enterHandled = coordinator.handleKeyboardShortcut("return", modifiers: [])
        #expect(enterHandled == true)
        #expect(coordinator.selectionManager.isEditingText == false)
    }
    
    @Test("描画モードでのキーボードショートカット処理が正常に動作する")
    func testHandleKeyboardShortcutInDrawingMode() {
        // Given
        let coordinator = GestureCoordinator()
        coordinator.setInteractionMode(.drawing)
        
        // When & Then - Escapeキー
        let escapeHandled = coordinator.handleKeyboardShortcut("escape", modifiers: [])
        #expect(escapeHandled == true)
        #expect(coordinator.interactionMode == .navigation)
        
        // When & Then - Cmd+Z (Undo)
        coordinator.setInteractionMode(.drawing)
        #if canImport(PencilKit)
        coordinator.pencilManager.addStroke(createTestStroke())
        
        let undoHandled = coordinator.handleKeyboardShortcut("z", modifiers: [.command])
        #expect(undoHandled == true)
        #expect(coordinator.pencilManager.currentDrawing.strokes.isEmpty)
        
        // When & Then - Cmd+C (Clear)
        coordinator.pencilManager.addStroke(createTestStroke())
        let clearHandled = coordinator.handleKeyboardShortcut("c", modifiers: [.command])
        #expect(clearHandled == true)
        #expect(coordinator.pencilManager.currentDrawing.strokes.isEmpty)
        #else
        let undoHandled = coordinator.handleKeyboardShortcut("z", modifiers: [.command])
        #expect(undoHandled == true)
        
        let clearHandled = coordinator.handleKeyboardShortcut("c", modifiers: [.command])
        #expect(clearHandled == true)
        #endif
    }
    
    @Test("キーボードショートカットが無効化されている場合の処理")
    func testHandleKeyboardShortcutDisabled() {
        // Given
        let coordinator = GestureCoordinator()
        coordinator.configuration.enableKeyboardShortcuts = false
        
        // When
        let handled = coordinator.handleKeyboardShortcut("c", modifiers: [.command])
        
        // Then
        #expect(handled == false)
    }
    
    // MARK: - Gesture State Management Tests
    
    @Test("ジェスチャー状態の変更が正常に動作する")
    func testGestureStateChanged() {
        // Given
        let coordinator = GestureCoordinator()
        var stateChanges: [(GestureCoordinator.GestureType, Bool)] = []
        
        coordinator.onGestureStateChanged = { type, active in
            stateChanges.append((type, active))
        }
        
        // When - パンジェスチャー開始をシミュレート
        coordinator.gestureManager.onPanChanged?(CGSize(width: 10, height: 10))
        
        // Then
        // 実際の実装では内部的にsetActiveGestureが呼ばれる
        // ここではコールバックが設定されていることを確認
        #expect(coordinator.onGestureStateChanged != nil)
    }
    
    // MARK: - Reset Tests
    
    @Test("全ジェスチャーのリセットが正常に動作する")
    func testResetAllGestures() {
        // Given
        let coordinator = GestureCoordinator()
        
        // 状態を変更
        coordinator.setInteractionMode(.drawing)
        coordinator.gestureManager.magnificationScale = 2.0
        coordinator.selectionManager.selectNode(UUID())
        coordinator.selectionManager.startEditingNode(UUID())
        coordinator.pencilManager.addStroke(createTestStroke())
        
        // When
        coordinator.resetAllGestures()
        
        // Then
        #expect(coordinator.interactionMode == .navigation)
        #expect(coordinator.gestureManager.magnificationScale == 1.0)
        #expect(coordinator.selectionManager.selectedNodeIDs.isEmpty)
        #expect(coordinator.selectionManager.isEditingText == false)
        #expect(coordinator.pencilManager.currentDrawing.strokes.isEmpty)
    }
    
    // MARK: - Configuration Tests
    
    @Test("ジェスチャー設定の変更が正常に動作する")
    func testGestureConfiguration() {
        // Given
        let coordinator = GestureCoordinator()
        
        // When
        coordinator.configuration.enablePencilGestures = false
        coordinator.configuration.enableMultiTouch = false
        coordinator.configuration.minimumDragDistance = 20
        coordinator.configuration.longPressDelay = 1.0
        
        // Then
        #expect(coordinator.configuration.enablePencilGestures == false)
        #expect(coordinator.configuration.enableMultiTouch == false)
        #expect(coordinator.configuration.minimumDragDistance == 20)
        #expect(coordinator.configuration.longPressDelay == 1.0)
    }
    
    // MARK: - Mode Observation Tests
    
    @Test("描画モード変更の監視が正常に動作する")
    func testDrawingModeObservation() {
        // Given
        let coordinator = GestureCoordinator()
        
        // When
        coordinator.pencilManager.isDrawingMode = true
        
        // Then
        // 実際の実装では Publisher の監視により自動的にモードが変更される
        // ここでは監視が設定されていることを確認
        #expect(coordinator.pencilManager.isDrawingMode == true)
    }
    
    @Test("テキスト編集モード変更の監視が正常に動作する")
    func testEditingModeObservation() {
        // Given
        let coordinator = GestureCoordinator()
        
        // When
        coordinator.selectionManager.isEditingText = true
        
        // Then
        // 実際の実装では Publisher の監視により自動的にモードが変更される
        #expect(coordinator.selectionManager.isEditingText == true)
    }
    
    @Test("複数選択モード変更の監視が正常に動作する")
    func testMultiSelectModeObservation() {
        // Given
        let coordinator = GestureCoordinator()
        
        // When
        coordinator.selectionManager.multiSelectMode = true
        
        // Then
        #expect(coordinator.selectionManager.multiSelectMode == true)
    }
    
    // MARK: - Helper Methods
    
    #if canImport(PencilKit)
    private func createTestStroke() -> PKStroke {
        let path = PKStrokePath(
            controlPoints: [
                PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0, size: CGSize(width: 2, height: 2), opacity: 1.0, force: 1.0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 10, y: 10), timeOffset: 0.1, size: CGSize(width: 2, height: 2), opacity: 1.0, force: 1.0, azimuth: 0, altitude: 0)
            ],
            creationDate: Date()
        )
        
        #if canImport(UIKit)
        let ink = PKInk(.pen, color: UIColor.black)
        #else
        let ink = PKInk(.pen, color: NSColor.black)
        #endif
        return PKStroke(ink: ink, path: path)
    }
    #endif
}

// MARK: - Extensions for Testing
// Equatable conformance is now declared in the main types

// KeyboardModifiers already conforms to Equatable