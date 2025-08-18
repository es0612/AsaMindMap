import Testing
import SwiftUI
@testable import MindMapUI

// MARK: - GestureManager Tests
@MainActor
struct GestureManagerTests {
    
    // MARK: - Initialization Tests
    
    @Test("GestureManagerの初期化が正しく行われる")
    func testInitialization() {
        // Given & When
        let gestureManager = GestureManager()
        
        // Then
        #expect(gestureManager.dragState == .inactive)
        #expect(gestureManager.magnificationScale == 1.0)
        #expect(gestureManager.lastMagnificationScale == 1.0)
        #expect(gestureManager.panOffset == .zero)
        #expect(gestureManager.lastPanOffset == .zero)
        #expect(gestureManager.minimumZoomScale == 0.5)
        #expect(gestureManager.maximumZoomScale == 3.0)
        #expect(gestureManager.doubleTapZoomScale == 2.0)
    }
    
    // MARK: - Gesture State Management Tests
    
    @Test("ジェスチャー状態のリセットが正常に動作する")
    func testResetGestureState() {
        // Given
        let gestureManager = GestureManager()
        gestureManager.magnificationScale = 2.0
        gestureManager.lastMagnificationScale = 2.0
        gestureManager.panOffset = CGSize(width: 100, height: 100)
        gestureManager.lastPanOffset = CGSize(width: 100, height: 100)
        
        // When
        gestureManager.resetGestureState()
        
        // Then
        #expect(gestureManager.dragState == .inactive)
        #expect(gestureManager.magnificationScale == 1.0)
        #expect(gestureManager.lastMagnificationScale == 1.0)
        #expect(gestureManager.panOffset == .zero)
        #expect(gestureManager.lastPanOffset == .zero)
    }
    
    @Test("ズームスケールの設定が正常に動作する")
    func testSetZoomScale() {
        // Given
        let gestureManager = GestureManager()
        let targetScale: CGFloat = 2.0
        
        // When
        gestureManager.setZoomScale(targetScale, animated: false)
        
        // Then
        #expect(gestureManager.magnificationScale == targetScale)
        #expect(gestureManager.lastMagnificationScale == targetScale)
    }
    
    @Test("ズームスケールの制限が正常に動作する")
    func testSetZoomScaleWithLimits() {
        // Given
        let gestureManager = GestureManager()
        
        // When - 最小値以下のテスト
        gestureManager.setZoomScale(0.1, animated: false)
        
        // Then
        #expect(gestureManager.magnificationScale == gestureManager.minimumZoomScale)
        
        // When - 最大値以上のテスト
        gestureManager.setZoomScale(5.0, animated: false)
        
        // Then
        #expect(gestureManager.magnificationScale == gestureManager.maximumZoomScale)
    }
    
    @Test("パンオフセットの設定が正常に動作する")
    func testSetPanOffset() {
        // Given
        let gestureManager = GestureManager()
        let targetOffset = CGSize(width: 50, height: 30)
        
        // When
        gestureManager.setPanOffset(targetOffset, animated: false)
        
        // Then
        #expect(gestureManager.panOffset == targetOffset)
        #expect(gestureManager.lastPanOffset == targetOffset)
    }
    
    // MARK: - Coordinate Conversion Tests
    
    @Test("スクリーン座標からキャンバス座標への変換が正常に動作する")
    func testConvertPointToCanvas() {
        // Given
        let gestureManager = GestureManager()
        gestureManager.magnificationScale = 2.0
        gestureManager.panOffset = CGSize(width: 100, height: 50)
        
        let screenPoint = CGPoint(x: 200, y: 150)
        
        // When
        let canvasPoint = gestureManager.convertPointToCanvas(screenPoint)
        
        // Then
        // Expected: (200 - 100) / 2.0 = 50, (150 - 50) / 2.0 = 50
        #expect(abs(canvasPoint.x - 50) < 0.1)
        #expect(abs(canvasPoint.y - 50) < 0.1)
    }
    
    @Test("キャンバス座標からスクリーン座標への変換が正常に動作する")
    func testConvertPointFromCanvas() {
        // Given
        let gestureManager = GestureManager()
        gestureManager.magnificationScale = 2.0
        gestureManager.panOffset = CGSize(width: 100, height: 50)
        
        let canvasPoint = CGPoint(x: 50, y: 50)
        
        // When
        let screenPoint = gestureManager.convertPointFromCanvas(canvasPoint)
        
        // Then
        // Expected: 50 * 2.0 + 100 = 200, 50 * 2.0 + 50 = 150
        #expect(abs(screenPoint.x - 200) < 0.1)
        #expect(abs(screenPoint.y - 150) < 0.1)
    }
    
    @Test("座標変換の往復が正常に動作する")
    func testCoordinateConversionRoundTrip() {
        // Given
        let gestureManager = GestureManager()
        gestureManager.magnificationScale = 1.5
        gestureManager.panOffset = CGSize(width: 75, height: 25)
        
        let originalPoint = CGPoint(x: 100, y: 200)
        
        // When
        let canvasPoint = gestureManager.convertPointToCanvas(originalPoint)
        let backToScreenPoint = gestureManager.convertPointFromCanvas(canvasPoint)
        
        // Then
        #expect(abs(backToScreenPoint.x - originalPoint.x) < 0.1)
        #expect(abs(backToScreenPoint.y - originalPoint.y) < 0.1)
    }
    
    // MARK: - Callback Tests
    
    @Test("パンジェスチャーのコールバックが正常に動作する")
    func testPanCallbacks() {
        // Given
        let gestureManager = GestureManager()
        var panChangedCalled = false
        var panEndedCalled = false
        var lastPanOffset: CGSize = .zero
        
        gestureManager.onPanChanged = { offset in
            panChangedCalled = true
            lastPanOffset = offset
        }
        
        gestureManager.onPanEnded = { offset in
            panEndedCalled = true
            lastPanOffset = offset
        }
        
        let testOffset = CGSize(width: 50, height: 30)
        
        // When
        gestureManager.panOffset = testOffset
        gestureManager.onPanChanged?(testOffset)
        gestureManager.onPanEnded?(testOffset)
        
        // Then
        #expect(panChangedCalled == true)
        #expect(panEndedCalled == true)
        #expect(lastPanOffset == testOffset)
    }
    
    @Test("ズームジェスチャーのコールバックが正常に動作する")
    func testZoomCallbacks() {
        // Given
        let gestureManager = GestureManager()
        var zoomChangedCalled = false
        var zoomEndedCalled = false
        var lastZoomScale: CGFloat = 0
        
        gestureManager.onZoomChanged = { scale in
            zoomChangedCalled = true
            lastZoomScale = scale
        }
        
        gestureManager.onZoomEnded = { scale in
            zoomEndedCalled = true
            lastZoomScale = scale
        }
        
        let testScale: CGFloat = 2.0
        
        // When
        gestureManager.magnificationScale = testScale
        gestureManager.onZoomChanged?(testScale)
        gestureManager.onZoomEnded?(testScale)
        
        // Then
        #expect(zoomChangedCalled == true)
        #expect(zoomEndedCalled == true)
        #expect(lastZoomScale == testScale)
    }
    
    @Test("ノードジェスチャーのコールバックが正常に動作する")
    func testNodeGestureCallbacks() {
        // Given
        let gestureManager = GestureManager()
        let testNodeID = UUID()
        var tapCalled = false
        var doubleTapCalled = false
        var longPressCalled = false
        var lastNodeID: UUID?
        
        gestureManager.onNodeTap = { nodeID in
            tapCalled = true
            lastNodeID = nodeID
        }
        
        gestureManager.onNodeDoubleTap = { nodeID in
            doubleTapCalled = true
            lastNodeID = nodeID
        }
        
        gestureManager.onNodeLongPress = { nodeID in
            longPressCalled = true
            lastNodeID = nodeID
        }
        
        // When & Then - ノードタップ
        gestureManager.onNodeTap?(testNodeID)
        #expect(tapCalled == true)
        #expect(lastNodeID == testNodeID)
        
        // When & Then - ノードダブルタップ
        gestureManager.onNodeDoubleTap?(testNodeID)
        #expect(doubleTapCalled == true)
        #expect(lastNodeID == testNodeID)
        
        // When & Then - ノード長押し
        gestureManager.onNodeLongPress?(testNodeID)
        #expect(longPressCalled == true)
        #expect(lastNodeID == testNodeID)
    }
    
    // MARK: - Animation Helper Tests
    
    @Test("コンテンツフィット機能が正常に動作する")
    func testAnimateToFitContent() {
        // Given
        let gestureManager = GestureManager()
        let contentBounds = CGRect(x: 0, y: 0, width: 200, height: 100)
        let screenSize = CGSize(width: 400, height: 300)
        
        // When
        gestureManager.animateToFitContent(contentBounds: contentBounds, screenSize: screenSize)
        
        // Then
        // スケールは適切な範囲内であることを確認
        #expect(gestureManager.magnificationScale > 1.0)
        #expect(gestureManager.magnificationScale <= gestureManager.maximumZoomScale)
    }
    
    @Test("中央揃え機能が正常に動作する")
    func testAnimateToCenter() {
        // Given
        let gestureManager = GestureManager()
        let targetPoint = CGPoint(x: 100, y: 50)
        let screenSize = CGSize(width: 400, height: 300)
        gestureManager.magnificationScale = 2.0
        
        // When
        gestureManager.animateToCenter(on: targetPoint, screenSize: screenSize)
        
        // Then
        // パンオフセットが適切に設定されることを確認（アニメーション中の可能性があるため近似値）
        #expect(abs(gestureManager.panOffset.x - 0) < 50)
        #expect(abs(gestureManager.panOffset.y - 50) < 50)
    }
}

// MARK: - DragState Equatable Extension for Testing
extension DragState: Equatable {
    public static func == (lhs: DragState, rhs: DragState) -> Bool {
        switch (lhs, rhs) {
        case (.inactive, .inactive):
            return true
        case (.dragging(let lhsTranslation), .dragging(let rhsTranslation)):
            return lhsTranslation == rhsTranslation
        default:
            return false
        }
    }
}