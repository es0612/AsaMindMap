//
//  ApplePencilUITests.swift  
//  AsaMindMapUITests
//  
//  Apple Pencil specific UI tests
//

import XCTest

// MARK: - Apple Pencil UI Tests
final class ApplePencilUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITesting", "ApplePencilMode"]
        app.launch()
        
        // Wait for app initialization
        waitForAppLaunch(app)
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Apple Pencil Detection Tests
    @MainActor
    func testApplePencilDetection() throws {
        // Test: Apple Pencil detection and mode switching
        // RED: This test will fail until we implement Apple Pencil detection
        
        // 1. Create mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "Pencil Test")
        
        // 2. Simulate Apple Pencil touch (this is challenging in UI tests)
        // For now, we test the UI state when pencil is detected
        
        // 3. Check if pencil mode indicator appears
        let pencilModeIndicator = app.staticTexts["applePencilModeIndicator"]
        XCTAssertTrue(pencilModeIndicator.waitForExistence(timeout: 5), "Apple Pencil mode indicator should appear")
        
        // 4. Verify tool palette is accessible
        let toolPalette = app.otherElements["toolPalette"]
        canvas.doubleTap() // Double tap with Apple Pencil should show tools
        XCTAssertTrue(toolPalette.waitForExistence(timeout: 3), "Tool palette should appear on double tap")
    }
    
    @MainActor  
    func testPencilDrawingMode() throws {
        // Test: Drawing mode activation and drawing operations
        // RED: This test will fail until we implement drawing mode
        
        // 1. Create mind map and enter drawing mode
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        
        // 2. Activate drawing mode
        let drawingModeButton = app.buttons["drawingModeButton"]
        XCTAssertTrue(drawingModeButton.waitForExistence(timeout: 5), "Drawing mode button should exist")
        drawingModeButton.tap()
        
        // 3. Verify drawing mode is active
        let drawingModeIndicator = app.staticTexts["drawingModeActive"]
        XCTAssertTrue(drawingModeIndicator.exists, "Drawing mode indicator should be visible")
        
        // 4. Test drawing gesture (simulate with finger on simulator)
        let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2))
        let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
        
        startPoint.press(forDuration: 0, thenDragTo: endPoint)
        
        // 5. Verify stroke was created
        let strokeElement = app.otherElements["stroke-0"]
        XCTAssertTrue(strokeElement.waitForExistence(timeout: 3), "Drawing stroke should be created")
    }
    
    @MainActor
    func testPencilTextRecognition() throws {
        // Test: Handwriting recognition functionality  
        // RED: This test will fail until we implement text recognition
        
        // 1. Create mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        
        // 2. Add a node for text input
        let centerNode = app.otherElements["centerNode"]
        _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "")
        
        // 3. Activate handwriting mode
        let handwritingButton = app.buttons["handwritingModeButton"]
        XCTAssertTrue(handwritingButton.waitForExistence(timeout: 5), "Handwriting mode button should exist")
        handwritingButton.tap()
        
        // 4. Simulate handwriting (draw text-like strokes)
        let childNode = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'childNode-'")).firstMatch
        
        // Simulate writing "Test" in handwriting
        simulateHandwriting(in: childNode, text: "Test")
        
        // 5. Verify text recognition
        let recognizedText = app.staticTexts["Test"]
        XCTAssertTrue(recognizedText.waitForExistence(timeout: 10), "Handwritten text should be recognized and converted")
    }
    
    @MainActor
    func testPencilPressureAndTilt() throws {
        // Test: Pressure sensitivity and tilt detection
        // RED: This test will fail until we implement pressure/tilt handling
        
        // 1. Setup drawing mode  
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        app.buttons["drawingModeButton"].tap()
        
        // 2. Test different pressure levels (simulated)
        // In real testing, this would require actual Apple Pencil input
        app.launchArguments.append("SimulatePressureVariation")
        
        // 3. Draw strokes with varying simulated pressure
        let lightStrokePoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3))
        let heavyStrokePoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.7))
        
        // Light pressure stroke
        lightStrokePoint.press(forDuration: 0, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.3)))
        
        // Heavy pressure stroke  
        heavyStrokePoint.press(forDuration: 0, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.7)))
        
        // 4. Verify different stroke weights
        let lightStroke = app.otherElements["lightStroke"]
        let heavyStroke = app.otherElements["heavyStroke"]
        
        XCTAssertTrue(lightStroke.waitForExistence(timeout: 3), "Light pressure stroke should exist")
        XCTAssertTrue(heavyStroke.waitForExistence(timeout: 3), "Heavy pressure stroke should exist")
    }
    
    @MainActor
    func testPencilDoubleTabGesture() throws {
        // Test: Apple Pencil double tap gesture handling
        // RED: This test will fail until we implement double tap handling
        
        // 1. Create mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        
        // 2. Enter drawing mode
        app.buttons["drawingModeButton"].tap()
        
        // 3. Simulate Apple Pencil double tap (switch to eraser)
        // In simulator, we can trigger this through accessibility or special gestures
        canvas.doubleTap() // This would be double tap with pencil in real device
        
        // 4. Verify eraser mode activated
        let eraserModeIndicator = app.staticTexts["eraserModeActive"]
        XCTAssertTrue(eraserModeIndicator.waitForExistence(timeout: 3), "Eraser mode should be activated")
        
        // 5. Test erasing functionality
        // First draw something
        let drawPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        drawPoint.press(forDuration: 0, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)))
        
        // Then erase it
        let erasePoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.6, dy: 0.5))
        erasePoint.tap()
        
        // 6. Verify content was erased
        let stroke = app.otherElements["stroke-0"]
        XCTAssertFalse(stroke.exists, "Stroke should be erased")
    }
    
    @MainActor
    func testPencilPalmRejection() throws {
        // Test: Palm rejection while using Apple Pencil
        // RED: This test will fail until we implement palm rejection
        
        // 1. Setup
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        app.buttons["drawingModeButton"].tap()
        
        // 2. Simulate simultaneous touch events (pencil + palm)
        app.launchArguments.append("SimulatePalmTouch")
        
        // 3. Draw with pencil while palm is touching
        let pencilPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.3))
        let palmArea = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.7))
        
        // Simulate palm touch first
        palmArea.press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8)))
        
        // Then pencil stroke
        pencilPoint.press(forDuration: 0, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)))
        
        // 4. Verify only pencil stroke was recorded
        let pencilStroke = app.otherElements["stroke-0"]
        let palmStroke = app.otherElements["stroke-1"]
        
        XCTAssertTrue(pencilStroke.waitForExistence(timeout: 3), "Pencil stroke should be recorded")
        XCTAssertFalse(palmStroke.exists, "Palm touch should be rejected")
    }
    
    @MainActor
    func testPencilToolSwitching() throws {
        // Test: Tool switching with Apple Pencil
        // RED: This test will fail until we implement tool switching
        
        // 1. Setup drawing mode
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        app.buttons["drawingModeButton"].tap()
        
        // 2. Open tool palette
        canvas.doubleTap() // Apple Pencil double tap
        let toolPalette = app.otherElements["toolPalette"]
        XCTAssertTrue(toolPalette.waitForExistence(timeout: 3), "Tool palette should appear")
        
        // 3. Test different tools
        let penTool = toolPalette.buttons["penTool"]
        let highlighterTool = toolPalette.buttons["highlighterTool"]
        let eraserTool = toolPalette.buttons["eraserTool"]
        
        // Test pen tool
        penTool.tap()
        let penModeIndicator = app.staticTexts["penToolActive"]
        XCTAssertTrue(penModeIndicator.exists, "Pen tool should be active")
        
        // Test highlighter tool
        highlighterTool.tap()
        let highlighterModeIndicator = app.staticTexts["highlighterToolActive"]
        XCTAssertTrue(highlighterModeIndicator.exists, "Highlighter tool should be active")
        
        // Test eraser tool
        eraserTool.tap()
        let eraserModeIndicator = app.staticTexts["eraserToolActive"]
        XCTAssertTrue(eraserModeIndicator.exists, "Eraser tool should be active")
    }
    
    // MARK: - Helper Methods
    private func simulateHandwriting(in element: XCUIElement, text: String) {
        // Simulate handwriting by drawing letter-like strokes
        // This is a simplified simulation - real handwriting would be much more complex
        
        let bounds = element.frame
        let startX = bounds.midX - 50
        let startY = bounds.midY
        
        for (index, _) in text.enumerated() {
            let letterStartPoint = element.coordinate(withNormalizedOffset: CGVector(dx: 0.1 + Double(index) * 0.1, dy: 0.5))
            let letterEndPoint = element.coordinate(withNormalizedOffset: CGVector(dx: 0.1 + Double(index) * 0.1 + 0.05, dy: 0.3))
            
            letterStartPoint.press(forDuration: 0, thenDragTo: letterEndPoint)
            
            // Small delay between letters
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // Wait for recognition processing
        Thread.sleep(forTimeInterval: 1.0)
    }
}

// MARK: - Apple Pencil Performance Tests
extension ApplePencilUITests {
    
    @MainActor
    func testPencilInputLatency() throws {
        // Test: Input latency for Apple Pencil
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        app.buttons["drawingModeButton"].tap()
        
        // Measure stroke response time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let strokeStart = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.2))
        let strokeEnd = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.8))
        
        strokeStart.press(forDuration: 0, thenDragTo: strokeEnd)
        
        // Wait for stroke to appear
        let stroke = app.otherElements["stroke-0"]
        XCTAssertTrue(stroke.waitForExistence(timeout: 1), "Stroke should appear quickly")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let latency = endTime - startTime
        
        XCTAssertLessThan(latency, 0.2, "Pencil input latency should be under 200ms")
    }
    
    @MainActor
    func testContinuousDrawingPerformance() throws {
        // Test: Performance during continuous drawing
        let canvas = try UITestHelpers.createBasicMindMap(app: app)
        app.buttons["drawingModeButton"].tap()
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Draw multiple continuous strokes
        for i in 0..<10 {
            let y = 0.1 + Double(i) * 0.08
            let startPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: y))
            let endPoint = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: y))
            
            startPoint.press(forDuration: 0, thenDragTo: endPoint)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        
        XCTAssertLessThan(totalTime, 5.0, "Drawing 10 strokes should complete within 5 seconds")
        
        // Verify all strokes were created
        let strokeCount = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'stroke-'")).count
        XCTAssertEqual(strokeCount, 10, "All 10 strokes should be created")
    }
}