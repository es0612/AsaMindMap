//
//  GestureIntegrationUITests.swift
//  AsaMindMapUITests
//  
//  Gesture and canvas interaction integration tests
//

import XCTest

// MARK: - Gesture Integration Tests
final class GestureIntegrationUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITesting", "GestureTestingMode"]
        app.launch()
        
        waitForAppLaunch(app)
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Canvas Zoom and Pan Tests
    @MainActor
    func testCanvasZoomOperations() throws {
        // Test: Canvas zoom in/out operations with pinch gestures
        // RED: This test will fail until we implement zoom functionality
        
        // 1. Create mind map with multiple nodes
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "ズームテスト")
        let centerNode = app.otherElements["centerNode"]
        
        // Add several child nodes to have content to zoom
        for i in 0..<5 {
            _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "ノード\(i+1)")
        }
        
        // 2. Test zoom in
        let initialZoomLevel = getCanvasZoomLevel()
        UITestHelpers.performCanvasZoom(canvas: canvas, scale: 2.0)
        
        let zoomedInLevel = getCanvasZoomLevel()
        XCTAssertGreaterThan(zoomedInLevel, initialZoomLevel, "Canvas should zoom in")
        
        // 3. Test zoom out
        UITestHelpers.performCanvasZoom(canvas: canvas, scale: 0.5)
        
        let zoomedOutLevel = getCanvasZoomLevel()
        XCTAssertLessThan(zoomedOutLevel, zoomedInLevel, "Canvas should zoom out")
        
        // 4. Test double tap to fit
        UITestHelpers.performDoubleTapToFit(canvas: canvas)
        
        let fitZoomLevel = getCanvasZoomLevel()
        XCTAssertNotEqual(fitZoomLevel, zoomedOutLevel, "Double tap should change zoom level to fit content")
    }
    
    @MainActor
    func testCanvasPanOperations() throws {
        // Test: Canvas panning with two-finger drag
        // RED: This test will fail until we implement pan functionality
        
        // 1. Setup with large mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "パンテスト")
        
        // Zoom out to make panning more apparent
        UITestHelpers.performCanvasZoom(canvas: canvas, scale: 0.3)
        
        // 2. Get initial canvas position
        let initialPanOffset = getCanvasPanOffset()
        
        // 3. Test panning in different directions
        UITestHelpers.performCanvasPan(canvas: canvas, direction: .left)
        let leftPanOffset = getCanvasPanOffset()
        XCTAssertNotEqual(leftPanOffset.dx, initialPanOffset.dx, "Canvas should pan left")
        
        UITestHelpers.performCanvasPan(canvas: canvas, direction: .right)
        let rightPanOffset = getCanvasPanOffset()
        XCTAssertGreaterThan(rightPanOffset.dx, leftPanOffset.dx, "Canvas should pan right")
        
        UITestHelpers.performCanvasPan(canvas: canvas, direction: .up)
        let upPanOffset = getCanvasPanOffset()
        XCTAssertLessThan(upPanOffset.dy, rightPanOffset.dy, "Canvas should pan up")
        
        UITestHelpers.performCanvasPan(canvas: canvas, direction: .down)
        let downPanOffset = getCanvasPanOffset()
        XCTAssertGreaterThan(downPanOffset.dy, upPanOffset.dy, "Canvas should pan down")
    }
    
    // MARK: - Node Drag and Drop Tests
    @MainActor
    func testNodeDragAndDrop() throws {
        // Test: Dragging nodes to reposition them
        // RED: This test will fail until we implement node dragging
        
        // 1. Create mind map with nodes
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "ドラッグテスト")
        let centerNode = app.otherElements["centerNode"]
        
        let childNode = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "ドラッグ対象")
        
        // 2. Get initial position
        let initialFrame = childNode.frame
        
        // 3. Drag node to new position
        let dragDestination = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.2))
        childNode.press(forDuration: 0.5, thenDragTo: dragDestination)
        
        // 4. Verify position changed
        let newFrame = childNode.frame
        XCTAssertNotEqual(initialFrame.midX, newFrame.midX, "Node X position should change after drag")
        XCTAssertNotEqual(initialFrame.midY, newFrame.midY, "Node Y position should change after drag")
    }
    
    @MainActor
    func testNodeConnectionDragging() throws {\n        // Test: Creating connections by dragging from one node to another\n        // RED: This test will fail until we implement connection dragging\n        \n        // 1. Create mind map with multiple nodes\n        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: \"接続テスト\")\n        let centerNode = app.otherElements[\"centerNode\"]\n        \n        let node1 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: \"ノード1\")\n        let node2 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: \"ノード2\")\n        \n        // 2. Start connection drag from node1\n        node1.press(forDuration: 1.0)\n        \n        // Look for connection handle or mode\n        let connectionHandle = app.buttons[\"connectionHandle\"]\n        XCTAssertTrue(connectionHandle.waitForExistence(timeout: 3), \"Connection handle should appear\")\n        \n        // 3. Drag to create connection\n        connectionHandle.press(forDuration: 0, thenDragTo: node2)\n        \n        // 4. Verify connection was created\n        let connection = app.otherElements[\"connection-node1-node2\"]\n        XCTAssertTrue(connection.waitForExistence(timeout: 3), \"Connection should be created between nodes\")\n    }\n    \n    // MARK: - Multi-touch Gesture Tests\n    @MainActor\n    func testMultiTouchGestures() throws {\n        // Test: Handling multiple simultaneous touches\n        // RED: This test will fail until we implement multi-touch handling\n        \n        // 1. Create mind map\n        let canvas = try UITestHelpers.createBasicMindMap(app: app)\n        \n        // 2. Test simultaneous zoom and pan\n        // This is challenging to test in UI tests, but we can verify the end result\n        let initialZoom = getCanvasZoomLevel()\n        let initialPan = getCanvasPanOffset()\n        \n        // Perform complex multi-touch gesture (simulated)\n        canvas.pinch(withScale: 1.5, velocity: 1.0)\n        canvas.swipeLeft()\n        \n        let finalZoom = getCanvasZoomLevel()\n        let finalPan = getCanvasPanOffset()\n        \n        XCTAssertNotEqual(initialZoom, finalZoom, \"Zoom should change during multi-touch\")\n        XCTAssertNotEqual(initialPan.dx, finalPan.dx, \"Pan should change during multi-touch\")\n    }\n    \n    @MainActor\n    func testGestureConflictResolution() throws {\n        // Test: Resolving conflicts between different gesture types\n        // RED: This test will fail until we implement gesture conflict resolution\n        \n        // 1. Setup\n        let canvas = try UITestHelpers.createBasicMindMap(app: app)\n        let centerNode = app.otherElements[\"centerNode\"]\n        \n        // 2. Test tap vs long press\n        // Quick tap should select, long press should show context menu\n        centerNode.tap()\n        let isSelected = app.otherElements[\"selectedNode\"].exists\n        XCTAssertTrue(isSelected, \"Quick tap should select node\")\n        \n        // Long press\n        centerNode.press(forDuration: 1.0)\n        let contextMenu = app.otherElements[\"nodeContextMenu\"]\n        XCTAssertTrue(contextMenu.waitForExistence(timeout: 2), \"Long press should show context menu\")\n        \n        // 3. Test drag vs pan\n        // Dragging on node should move node, dragging on empty canvas should pan\n        let initialNodeFrame = centerNode.frame\n        let initialCanvasPan = getCanvasPanOffset()\n        \n        // Drag on node\n        centerNode.press(forDuration: 0.3, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.7)))\n        \n        let finalNodeFrame = centerNode.frame\n        XCTAssertNotEqual(initialNodeFrame.midX, finalNodeFrame.midX, \"Node should move when dragged\")\n        \n        // Drag on empty canvas area\n        let emptyArea = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))\n        emptyArea.press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3)))\n        \n        let finalCanvasPan = getCanvasPanOffset()\n        XCTAssertNotEqual(initialCanvasPan.dx, finalCanvasPan.dx, \"Canvas should pan when dragging empty area\")\n    }\n    \n    // MARK: - Focus Mode Tests\n    @MainActor\n    func testFocusModeActivation() throws {\n        // Test: Focus mode activation and node highlighting\n        // RED: This test will fail until we implement focus mode\n        \n        // 1. Create mind map with multiple branches\n        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: \"フォーカステスト\")\n        let centerNode = app.otherElements[\"centerNode\"]\n        \n        // Create multiple branches\n        let branch1 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: \"ブランチ1\")\n        let branch2 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: \"ブランチ2\")\n        let branch3 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: \"ブランチ3\")\n        \n        // 2. Activate focus mode on branch1\n        branch1.tap()\n        let focusButton = app.buttons[\"focusModeButton\"]\n        XCTAssertTrue(focusButton.waitForExistence(timeout: 3), \"Focus mode button should appear\")\n        focusButton.tap()\n        \n        // 3. Verify focus mode is active\n        let focusModeIndicator = app.staticTexts[\"focusModeActive\"]\n        XCTAssertTrue(focusModeIndicator.exists, \"Focus mode indicator should be visible\")\n        \n        // 4. Verify other branches are dimmed\n        let dimmedBranch2 = app.otherElements[\"dimmedNode-branch2\"]\n        let dimmedBranch3 = app.otherElements[\"dimmedNode-branch3\"]\n        \n        XCTAssertTrue(dimmedBranch2.exists, \"Branch 2 should be dimmed in focus mode\")\n        XCTAssertTrue(dimmedBranch3.exists, \"Branch 3 should be dimmed in focus mode\")\n        \n        // 5. Verify focused branch is highlighted\n        let highlightedBranch1 = app.otherElements[\"highlightedNode-branch1\"]\n        XCTAssertTrue(highlightedBranch1.exists, \"Branch 1 should be highlighted in focus mode\")\n        \n        // 6. Exit focus mode\n        let exitFocusButton = app.buttons[\"exitFocusModeButton\"]\n        exitFocusButton.tap()\n        \n        XCTAssertFalse(focusModeIndicator.exists, \"Focus mode indicator should disappear\")\n        XCTAssertFalse(dimmedBranch2.exists, \"Branches should no longer be dimmed\")\n    }\n    \n    // MARK: - Performance Tests for Gestures\n    @MainActor\n    func testGestureResponsiveness() throws {\n        // Test: Gesture response times\n        let canvas = try UITestHelpers.createBasicMindMap(app: app)\n        \n        // Test tap responsiveness\n        let centerNode = app.otherElements[\"centerNode\"]\n        \n        let (_, tapResponseTime) = UITestHelpers.measureOperation {\n            centerNode.tap()\n            return app.otherElements[\"selectedNode\"].waitForExistence(timeout: 1)\n        }\n        \n        XCTAssertLessThan(tapResponseTime, 0.1, \"Tap response should be under 100ms\")\n        \n        // Test zoom responsiveness\n        let (_, zoomResponseTime) = UITestHelpers.measureOperation {\n            canvas.pinch(withScale: 2.0, velocity: 1.0)\n            Thread.sleep(forTimeInterval: 0.2) // Allow zoom to complete\n        }\n        \n        XCTAssertLessThan(zoomResponseTime, 0.5, \"Zoom response should be under 500ms\")\n    }\n    \n    @MainActor\n    func testGesturePerformanceUnderLoad() throws {\n        // Test: Gesture performance with many nodes\n        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: \"負荷テスト\")\n        let centerNode = app.otherElements[\"centerNode\"]\n        \n        // Create many nodes to stress test\n        for i in 0..<20 {\n            _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: \"負荷ノード\\(i+1)\")\n        }\n        \n        // Test zoom performance with many nodes\n        let (_, zoomTime) = UITestHelpers.measureOperation {\n            canvas.pinch(withScale: 0.5, velocity: -1.0)\n            Thread.sleep(forTimeInterval: 0.3)\n        }\n        \n        XCTAssertLessThan(zoomTime, 1.0, \"Zoom with 20 nodes should complete within 1 second\")\n        \n        // Test pan performance\n        let (_, panTime) = UITestHelpers.measureOperation {\n            canvas.swipeLeft()\n            Thread.sleep(forTimeInterval: 0.2)\n        }\n        \n        XCTAssertLessThan(panTime, 0.5, \"Pan with 20 nodes should complete within 500ms\")\n    }\n    \n    // MARK: - Helper Methods\n    private func getCanvasZoomLevel() -> CGFloat {\n        // In real implementation, this would query the actual zoom level\n        // For UI testing, we might need to read from accessibility values\n        let zoomIndicator = app.staticTexts[\"zoomLevelIndicator\"]\n        if zoomIndicator.exists {\n            let zoomText = zoomIndicator.label\n            return CGFloat(Double(zoomText.replacingOccurrences(of: \"%\", with: \"\")) ?? 100.0) / 100.0\n        }\n        return 1.0 // Default zoom level\n    }\n    \n    private func getCanvasPanOffset() -> CGPoint {\n        // In real implementation, this would query the actual pan offset\n        let panXIndicator = app.staticTexts[\"panXIndicator\"]\n        let panYIndicator = app.staticTexts[\"panYIndicator\"]\n        \n        let x = panXIndicator.exists ? CGFloat(Double(panXIndicator.label) ?? 0.0) : 0.0\n        let y = panYIndicator.exists ? CGFloat(Double(panYIndicator.label) ?? 0.0) : 0.0\n        \n        return CGPoint(x: x, y: y)\n    }\n}\n\n// MARK: - Accessibility Integration for Gestures\nextension GestureIntegrationUITests {\n    \n    @MainActor\n    func testAccessibilityGestureSupport() throws {\n        // Test: Gesture alternatives for accessibility users\n        // RED: This test will fail until we implement accessibility gesture alternatives\n        \n        // 1. Enable VoiceOver simulation\n        app.launchArguments.append(\"SimulateVoiceOver\")\n        app.terminate()\n        app.launch()\n        \n        waitForAppLaunch(app)\n        \n        let canvas = try UITestHelpers.createBasicMindMap(app: app)\n        \n        // 2. Test zoom alternatives\n        let zoomInButton = app.buttons[\"accessibilityZoomInButton\"]\n        let zoomOutButton = app.buttons[\"accessibilityZoomOutButton\"]\n        \n        XCTAssertTrue(zoomInButton.waitForExistence(timeout: 5), \"Accessibility zoom in button should exist\")\n        XCTAssertTrue(zoomOutButton.exists, \"Accessibility zoom out button should exist\")\n        \n        let initialZoom = getCanvasZoomLevel()\n        zoomInButton.tap()\n        let zoomedInLevel = getCanvasZoomLevel()\n        XCTAssertGreaterThan(zoomedInLevel, initialZoom, \"Accessibility zoom in should work\")\n        \n        // 3. Test pan alternatives\n        let panLeftButton = app.buttons[\"accessibilityPanLeftButton\"]\n        let panRightButton = app.buttons[\"accessibilityPanRightButton\"]\n        \n        XCTAssertTrue(panLeftButton.exists, \"Accessibility pan left button should exist\")\n        XCTAssertTrue(panRightButton.exists, \"Accessibility pan right button should exist\")\n        \n        let initialPan = getCanvasPanOffset()\n        panLeftButton.tap()\n        let pannedOffset = getCanvasPanOffset()\n        XCTAssertNotEqual(initialPan.dx, pannedOffset.dx, \"Accessibility pan should work\")\n    }\n    \n    @MainActor\n    func testKeyboardNavigation() throws {\n        // Test: Keyboard navigation for canvas operations\n        // RED: This test will fail until we implement keyboard navigation\n        \n        let canvas = try UITestHelpers.createBasicMindMap(app: app)\n        let centerNode = app.otherElements[\"centerNode\"]\n        \n        // Test keyboard focus\n        centerNode.tap()\n        \n        // Test arrow key navigation\n        app.typeKey(\"+\", modifierFlags: .command) // Zoom in\n        let zoomedLevel = getCanvasZoomLevel()\n        XCTAssertGreaterThan(zoomedLevel, 1.0, \"Keyboard zoom in should work\")\n        \n        app.typeKey(\"-\", modifierFlags: .command) // Zoom out\n        let zoomedOutLevel = getCanvasZoomLevel()\n        XCTAssertLessThan(zoomedOutLevel, zoomedLevel, \"Keyboard zoom out should work\")\n        \n        // Test arrow key panning\n        let initialPan = getCanvasPanOffset()\n        app.typeKey(XCUIKeyboardKey.leftArrow, modifierFlags: .shift)\n        let pannedLeft = getCanvasPanOffset()\n        XCTAssertNotEqual(initialPan.dx, pannedLeft.dx, \"Keyboard pan should work\")\n    }\n}"}, {"old_string": "", "new_string": ""}]