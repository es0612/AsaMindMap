//
//  AsaMindMapUITests.swift
//  AsaMindMapUITests
//  
//  Created on 2025/08/17
//

import XCTest

// MARK: - Main UI Test Suite
final class AsaMindMapUITests: XCTestCase {
    
    // MARK: - Properties
    private var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITesting"]
        app.launch()
        
        // Wait for app to be ready
        let mainView = app.otherElements["mainView"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: mainView, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Core User Journey Tests
    @MainActor
    func testCompleteUserJourney_CreateMindMapFromScratch() throws {
        // Test: Complete user journey from app launch to mind map creation
        // RED: This test will fail until we implement the UI elements
        
        // 1. Verify initial state
        XCTAssertTrue(app.buttons["createMindMapButton"].exists, "Create mind map button should exist")
        
        // 2. Create new mind map
        app.buttons["createMindMapButton"].tap()
        
        // 3. Verify canvas appears
        let canvas = app.otherElements["mindMapCanvas"]
        XCTAssertTrue(canvas.exists, "Mind map canvas should appear")
        
        // 4. Verify center node exists
        let centerNode = app.otherElements["centerNode"]
        XCTAssertTrue(centerNode.exists, "Center node should exist")
        
        // 5. Test node editing
        centerNode.tap()
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.exists, "Text field should appear for editing")
        
        textField.typeText("メインアイデア")
        app.keyboards.buttons["完了"].tap()
        
        // 6. Verify text was saved
        XCTAssertTrue(app.staticTexts["メインアイデア"].exists, "Main idea text should be saved")
        
        // 7. Test child node creation
        centerNode.press(forDuration: 1.0)
        app.buttons["addChildNodeButton"].tap()
        
        let childNode = app.otherElements["childNode-0"]
        XCTAssertTrue(childNode.exists, "Child node should be created")
    }
    
    @MainActor
    func testMindMapPersistence_SaveAndReload() throws {
        // Test: Data persistence across app sessions
        // RED: This test will fail until we implement persistence
        
        // 1. Create mind map with content
        app.buttons["createMindMapButton"].tap()
        let canvas = app.otherElements["mindMapCanvas"]
        let centerNode = app.otherElements["centerNode"]
        
        centerNode.tap()
        let textField = app.textFields.firstMatch
        textField.typeText("永続化テスト")
        app.keyboards.buttons["完了"].tap()
        
        // 2. Restart app
        app.terminate()
        app.launch()
        
        // 3. Verify mind map is restored
        let mainView = app.otherElements["mainView"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: mainView, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
        
        // 4. Check if saved mind map appears
        XCTAssertTrue(app.staticTexts["永続化テスト"].exists, "Saved mind map should persist")
    }
    
    // MARK: - Performance Tests
    @MainActor
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launch()
            testApp.terminate()
        }
    }
    
    @MainActor
    func testMindMapCreationPerformance() throws {
        // Test: Performance of mind map creation
        let createButton = app.buttons["createMindMapButton"]
        
        measure {
            createButton.tap()
            let canvas = app.otherElements["mindMapCanvas"]
            let exists = NSPredicate(format: "exists == 1")
            expectation(for: exists, evaluatedWith: canvas, handler: nil)
            waitForExpectations(timeout: 5, handler: nil)
            
            // Go back to prepare for next iteration
            app.navigationBars.buttons["戻る"].tap()
        }
    }
}

// MARK: - Gesture and Canvas Integration Tests
extension AsaMindMapUITests {
    
    @MainActor
    func testCanvasGestureOperations() throws {
        // Test: Canvas zoom, pan, and node manipulation gestures
        // RED: This test will fail until we implement gesture handling
        
        // 1. Create mind map
        app.buttons["createMindMapButton"].tap()
        let canvas = app.otherElements["mindMapCanvas"]
        
        // 2. Test pinch to zoom
        canvas.pinch(withScale: 2.0, velocity: 1.0)
        
        // 3. Test pan gesture
        canvas.swipeLeft()
        canvas.swipeRight()
        
        // 4. Test double tap to fit
        canvas.doubleTap()
        
        // 5. Test node drag operation
        let centerNode = app.otherElements["centerNode"]
        centerNode.press(forDuration: 0.5, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.3)))
        
        // Verify node position changed
        let movedNode = app.otherElements["centerNode"]
        XCTAssertTrue(movedNode.exists, "Node should exist after drag operation")
    }
    
    @MainActor
    func testMultiNodeSelection() throws {
        // Test: Multiple node selection and operations
        // RED: This test will fail until we implement multi-selection
        
        // 1. Create mind map with multiple nodes
        app.buttons["createMindMapButton"].tap()
        let canvas = app.otherElements["mindMapCanvas"]
        let centerNode = app.otherElements["centerNode"]
        
        // Add multiple child nodes
        for i in 0..<3 {
            centerNode.press(forDuration: 1.0)
            app.buttons["addChildNodeButton"].tap()
            
            let childNode = app.otherElements["childNode-\(i)"]
            childNode.tap()
            let textField = app.textFields.firstMatch
            textField.typeText("子ノード\(i + 1)")
            app.keyboards.buttons["完了"].tap()
        }
        
        // 2. Test multi-selection
        let firstChild = app.otherElements["childNode-0"]
        let secondChild = app.otherElements["childNode-1"]
        
        firstChild.tap()
        secondChild.tap() // Should add to selection
        
        // 3. Verify selection UI
        XCTAssertTrue(app.buttons["deleteSelectedNodesButton"].exists, "Delete button should appear for multi-selection")
        
        // 4. Test bulk operations
        app.buttons["deleteSelectedNodesButton"].tap()
        app.alerts.buttons["削除"].tap()
        
        // Verify nodes were deleted
        XCTAssertFalse(firstChild.exists, "First selected node should be deleted")
        XCTAssertFalse(secondChild.exists, "Second selected node should be deleted")
    }
}

// MARK: - Data Sync and Export Tests
extension AsaMindMapUITests {
    
    @MainActor
    func testExportFunctionality() throws {
        // Test: Export mind map to various formats
        // RED: This test will fail until we implement export
        
        // 1. Create mind map with content
        app.buttons["createMindMapButton"].tap()
        let centerNode = app.otherElements["centerNode"]
        
        centerNode.tap()
        let textField = app.textFields.firstMatch
        textField.typeText("エクスポートテスト")
        app.keyboards.buttons["完了"].tap()
        
        // 2. Access export menu
        app.buttons["menuButton"].tap()
        app.buttons["exportButton"].tap()
        
        // 3. Test different export formats
        let exportSheet = app.sheets.firstMatch
        XCTAssertTrue(exportSheet.exists, "Export sheet should appear")
        
        // Test PDF export
        exportSheet.buttons["PDF"].tap()
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.exists, "iOS share sheet should appear")
        shareSheet.buttons["キャンセル"].tap()
        
        // Test PNG export
        app.buttons["exportButton"].tap()
        exportSheet.buttons["PNG"].tap()
        XCTAssertTrue(app.sheets.firstMatch.exists, "Share sheet should appear for PNG")
        app.sheets.firstMatch.buttons["キャンセル"].tap()
    }
    
    @MainActor
    func testCloudKitSync() throws {
        // Test: iCloud synchronization functionality
        // RED: This test will fail until we implement CloudKit sync
        
        // 1. Enable sync in settings
        app.buttons["settingsButton"].tap()
        let syncToggle = app.switches["iCloudSyncToggle"]
        if !syncToggle.isSelected {
            syncToggle.tap()
        }
        app.navigationBars.buttons["完了"].tap()
        
        // 2. Create mind map
        app.buttons["createMindMapButton"].tap()
        let centerNode = app.otherElements["centerNode"]
        
        centerNode.tap()
        let textField = app.textFields.firstMatch
        textField.typeText("同期テスト")
        app.keyboards.buttons["完了"].tap()
        
        // 3. Verify sync indicator appears
        let syncIndicator = app.activityIndicators["syncIndicator"]
        XCTAssertTrue(syncIndicator.exists, "Sync indicator should appear")
        
        // 4. Wait for sync completion
        let syncComplete = NSPredicate(format: "exists == 0")
        expectation(for: syncComplete, evaluatedWith: syncIndicator, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }
}

// MARK: - Error Handling and Edge Cases
extension AsaMindMapUITests {
    
    @MainActor
    func testErrorRecovery_NetworkFailure() throws {
        // Test: App behavior during network failures
        // RED: This test will fail until we implement error handling
        
        // 1. Simulate network failure
        app.launchArguments.append("SimulateNetworkFailure")
        app.terminate()
        app.launch()
        
        // 2. Try to sync
        app.buttons["settingsButton"].tap()
        app.switches["iCloudSyncToggle"].tap()
        
        // 3. Verify error handling
        let errorAlert = app.alerts.firstMatch
        XCTAssertTrue(errorAlert.exists, "Error alert should appear for network failure")
        XCTAssertTrue(errorAlert.staticTexts["ネットワークに接続できません"].exists, "Appropriate error message should be shown")
        
        errorAlert.buttons["再試行"].tap()
    }
    
    @MainActor
    func testLargeDatasetPerformance() throws {
        // Test: App performance with large mind maps
        // RED: This test will fail until we implement performance optimizations
        
        // 1. Create mind map
        app.buttons["createMindMapButton"].tap()
        let canvas = app.otherElements["mindMapCanvas"]
        let centerNode = app.otherElements["centerNode"]
        
        // 2. Create large number of nodes (simulate)
        app.launchArguments.append("CreateLargeDataset")
        app.terminate()
        app.launch()
        
        // 3. Test canvas responsiveness
        let startTime = CFAbsoluteTimeGetCurrent()
        
        canvas.pinch(withScale: 2.0, velocity: 1.0)
        canvas.swipeLeft()
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let responseTime = endTime - startTime
        
        XCTAssertLessThan(responseTime, 2.0, "Canvas should remain responsive with large datasets")
    }
    
    @MainActor
    func testMemoryManagement_LongSession() throws {
        // Test: Memory management during extended use
        // RED: This test will fail until we implement proper memory management
        
        // 1. Simulate long session with multiple operations
        for i in 0..<10 {
            // Create mind map
            app.buttons["createMindMapButton"].tap()
            
            // Add content
            let centerNode = app.otherElements["centerNode"]
            centerNode.tap()
            let textField = app.textFields.firstMatch
            textField.typeText("テスト\(i)")
            app.keyboards.buttons["完了"].tap()
            
            // Add child nodes
            for j in 0..<5 {
                centerNode.press(forDuration: 1.0)
                app.buttons["addChildNodeButton"].tap()
            }
            
            // Close mind map
            app.navigationBars.buttons["戻る"].tap()
        }
        
        // 2. Verify app is still responsive
        let createButton = app.buttons["createMindMapButton"]
        XCTAssertTrue(createButton.isEnabled, "App should remain functional after extended use")
        
        // 3. Test memory-intensive operation
        createButton.tap()
        let canvas = app.otherElements["mindMapCanvas"]
        canvas.pinch(withScale: 0.1, velocity: -1.0) // Zoom out significantly
        
        XCTAssertTrue(canvas.exists, "Canvas should remain functional after memory-intensive operations")
    }
}