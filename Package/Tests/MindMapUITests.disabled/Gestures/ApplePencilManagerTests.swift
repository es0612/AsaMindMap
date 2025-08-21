import Testing
import SwiftUI
import PencilKit
@testable import MindMapUI

// MARK: - Apple Pencil Manager Tests
@MainActor
struct ApplePencilManagerTests {
    
    // MARK: - Initialization Tests
    
    @Test("ApplePencilManagerの初期化が正しく行われる")
    func testInitialization() {
        // Given & When
        let pencilManager = ApplePencilManager()
        
        // Then
        #expect(pencilManager.isDrawingMode == false)
        #expect(pencilManager.currentTool == .pen)
        #expect(pencilManager.strokeColor == .black)
        #expect(pencilManager.strokeWidth == 2.0)
        #expect(pencilManager.isHandwritingRecognitionEnabled == true)
        #expect(pencilManager.currentDrawing.strokes.isEmpty)
        #expect(pencilManager.handwritingStrokes.isEmpty)
    }
    
    // MARK: - Tool Management Tests
    
    @Test("ペンツールの選択が正常に動作する")
    func testSelectPenTool() {
        // Given
        let pencilManager = ApplePencilManager()
        
        // When
        pencilManager.selectTool(.pen)
        
        // Then
        #expect(pencilManager.currentTool == .pen)
        #expect(pencilManager.isDrawingMode == true)
        #expect(pencilManager.strokeWidth == 2.0)
        #expect(pencilManager.strokeColor == .black)
    }
    
    @Test("鉛筆ツールの選択が正常に動作する")
    func testSelectPencilTool() {
        // Given
        let pencilManager = ApplePencilManager()
        
        // When
        pencilManager.selectTool(.pencil)
        
        // Then
        #expect(pencilManager.currentTool == .pencil)
        #expect(pencilManager.isDrawingMode == true)
        #expect(pencilManager.strokeWidth == 1.5)
        #expect(pencilManager.strokeColor == .gray)
    }
    
    @Test("マーカーツールの選択が正常に動作する")
    func testSelectMarkerTool() {
        // Given
        let pencilManager = ApplePencilManager()
        
        // When
        pencilManager.selectTool(.marker)
        
        // Then
        #expect(pencilManager.currentTool == .marker)
        #expect(pencilManager.isDrawingMode == true)
        #expect(pencilManager.strokeWidth == 8.0)
        #expect(pencilManager.strokeColor == .yellow)
    }
    
    @Test("消しゴムツールの選択が正常に動作する")
    func testSelectEraserTool() {
        // Given
        let pencilManager = ApplePencilManager()
        pencilManager.isDrawingMode = true
        
        // When
        pencilManager.selectTool(.eraser)
        
        // Then
        #expect(pencilManager.currentTool == .eraser)
        #expect(pencilManager.isDrawingMode == false)
    }
    
    @Test("描画モードの切り替えが正常に動作する")
    func testToggleDrawingMode() {
        // Given
        let pencilManager = ApplePencilManager()
        pencilManager.isDrawingMode = false
        pencilManager.currentTool = .eraser
        
        // When
        pencilManager.toggleDrawingMode()
        
        // Then
        #expect(pencilManager.isDrawingMode == true)
        #expect(pencilManager.currentTool == .pen)
        
        // When - 再度切り替え
        pencilManager.toggleDrawingMode()
        
        // Then
        #expect(pencilManager.isDrawingMode == false)
        #expect(pencilManager.currentTool == .eraser)
    }
    
    // MARK: - Drawing Operations Tests
    
    @Test("ストロークの追加が正常に動作する")
    func testAddStroke() {
        // Given
        let pencilManager = ApplePencilManager()
        let stroke = createTestStroke()
        
        // When
        pencilManager.addStroke(stroke)
        
        // Then
        #expect(pencilManager.currentDrawing.strokes.count == 1)
        // Note: PKStroke doesn't conform to Equatable, so we check count instead
    }
    
    @Test("ストロークの削除が正常に動作する")
    func testRemoveStroke() {
        // Given
        let pencilManager = ApplePencilManager()
        let stroke1 = createTestStroke()
        let stroke2 = createTestStroke()
        pencilManager.addStroke(stroke1)
        pencilManager.addStroke(stroke2)
        
        // When
        pencilManager.removeStroke(at: 0)
        
        // Then
        #expect(pencilManager.currentDrawing.strokes.count == 1)
        // Note: PKStroke doesn't conform to Equatable, so we check count instead
    }
    
    @Test("範囲外インデックスでのストローク削除が安全に処理される")
    func testRemoveStrokeOutOfBounds() {
        // Given
        let pencilManager = ApplePencilManager()
        let stroke = createTestStroke()
        pencilManager.addStroke(stroke)
        
        // When & Then - 例外が発生しないことを確認
        pencilManager.removeStroke(at: 5)
        #expect(pencilManager.currentDrawing.strokes.count == 1)
    }
    
    @Test("描画のクリアが正常に動作する")
    func testClearDrawing() {
        // Given
        let pencilManager = ApplePencilManager()
        let stroke1 = createTestStroke()
        let stroke2 = createTestStroke()
        pencilManager.addStroke(stroke1)
        pencilManager.addStroke(stroke2)
        pencilManager.handwritingStrokes = [stroke1]
        
        // When
        pencilManager.clearDrawing()
        
        // Then
        #expect(pencilManager.currentDrawing.strokes.isEmpty)
        #expect(pencilManager.handwritingStrokes.isEmpty)
    }
    
    @Test("最後のストロークの取り消しが正常に動作する")
    func testUndoLastStroke() {
        // Given
        let pencilManager = ApplePencilManager()
        let stroke1 = createTestStroke()
        let stroke2 = createTestStroke()
        pencilManager.addStroke(stroke1)
        pencilManager.addStroke(stroke2)
        
        // When
        pencilManager.undoLastStroke()
        
        // Then
        #expect(pencilManager.currentDrawing.strokes.count == 1)
        // Note: PKStroke doesn't conform to Equatable, so we check count instead
    }
    
    @Test("空の描画での取り消しが安全に処理される")
    func testUndoLastStrokeEmpty() {
        // Given
        let pencilManager = ApplePencilManager()
        
        // When & Then - 例外が発生しないことを確認
        pencilManager.undoLastStroke()
        #expect(pencilManager.currentDrawing.strokes.isEmpty)
    }
    
    // MARK: - Pencil Gesture Tests
    
    @Test("Apple Pencilダブルタップの処理が正常に動作する")
    func testHandlePencilDoubleTap() {
        // Given
        let pencilManager = ApplePencilManager()
        pencilManager.currentTool = .pen
        var doubleTapCalled = false
        
        pencilManager.onPencilDoubleTap = {
            doubleTapCalled = true
        }
        
        // When
        pencilManager.handlePencilDoubleTap()
        
        // Then
        #expect(pencilManager.currentTool == .eraser)
        #expect(doubleTapCalled == true)
        
        // When - 再度ダブルタップ
        pencilManager.handlePencilDoubleTap()
        
        // Then
        #expect(pencilManager.currentTool == .pen)
    }
    
    @Test("Apple Pencilスクイーズの処理が正常に動作する")
    func testHandlePencilSqueeze() {
        // Given
        let pencilManager = ApplePencilManager()
        var squeezePhases: [ApplePencilManager.PencilSqueezePhase] = []
        
        pencilManager.onPencilSqueeze = { phase in
            squeezePhases.append(phase)
        }
        
        // When
        pencilManager.handlePencilSqueeze(phase: .began)
        pencilManager.handlePencilSqueeze(phase: .changed)
        pencilManager.handlePencilSqueeze(phase: .ended)
        
        // Then
        #expect(squeezePhases.count == 3)
        #expect(squeezePhases[0] == .began)
        #expect(squeezePhases[1] == .changed)
        #expect(squeezePhases[2] == .ended)
    }
    
    // MARK: - Tool Creation Tests
    
    @Test("PKInkingToolの作成が正常に動作する")
    func testCreatePKInkingTool() {
        // Given
        let pencilManager = ApplePencilManager()
        pencilManager.selectTool(.pen)
        
        // When
        let inkingTool = pencilManager.createPKInkingTool()
        
        // Then
        #expect(inkingTool.inkType == .pen)
        #expect(inkingTool.width == 2.0)
    }
    
    @Test("PKEraserToolの作成が正常に動作する")
    func testCreatePKEraserTool() {
        // Given
        let pencilManager = ApplePencilManager()
        
        // When
        let eraserTool = pencilManager.createPKEraserTool()
        
        // Then
        #expect(eraserTool.eraserType == .bitmap)
    }
    
    // MARK: - Callback Tests
    
    @Test("描画変更コールバックが正常に動作する")
    func testDrawingChangedCallback() {
        // Given
        let pencilManager = ApplePencilManager()
        var callbackDrawing: PKDrawing?
        
        pencilManager.onDrawingChanged = { drawing in
            callbackDrawing = drawing
        }
        
        let stroke = createTestStroke()
        
        // When
        pencilManager.addStroke(stroke)
        
        // Then
        #expect(callbackDrawing != nil)
        #expect(callbackDrawing?.strokes.count == 1)
    }
    
    @Test("手書き文字認識コールバックが正常に動作する")
    func testHandwritingRecognizedCallback() {
        // Given
        let pencilManager = ApplePencilManager()
        var recognizedText: String?
        
        pencilManager.onHandwritingRecognized = { text in
            recognizedText = text
        }
        
        // When
        pencilManager.onHandwritingRecognized?("テストテキスト")
        
        // Then
        #expect(recognizedText == "テストテキスト")
    }
    
    // MARK: - Helper Methods
    
    private func createTestStroke() -> PKStroke {
        let path = PKStrokePath(
            controlPoints: [
                PKStrokePoint(location: CGPoint(x: 0, y: 0), timeOffset: 0, size: CGSize(width: 2, height: 2), opacity: 1.0, force: 1.0, azimuth: 0, altitude: 0),
                PKStrokePoint(location: CGPoint(x: 10, y: 10), timeOffset: 0.1, size: CGSize(width: 2, height: 2), opacity: 1.0, force: 1.0, azimuth: 0, altitude: 0)
            ],
            creationDate: Date()
        )
        
        let ink = PKInk(.pen, color: .black)
        return PKStroke(ink: ink, path: path)
    }
}

// MARK: - Extensions for Testing
// Equatable conformance is now declared in the main type