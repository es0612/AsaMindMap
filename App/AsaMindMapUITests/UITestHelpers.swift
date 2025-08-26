//
//  UITestHelpers.swift
//  AsaMindMapUITests
//  
//  UI testing helper functions and utilities
//

import XCTest

// MARK: - UI Test Helpers
struct UITestHelpers {
    
    // MARK: - App State Management
    static func launchAppWithCleanState(app: XCUIApplication) {
        app.launchArguments = ["UITesting", "CleanState"]
        app.launch()
        
        // Wait for app initialization
        let mainView = app.otherElements["mainView"]
        let exists = NSPredicate(format: "exists == 1")
        let expectation = XCTestCase().expectation(for: exists, evaluatedWith: mainView, handler: nil)
        XCTestCase().wait(for: [expectation], timeout: 10)
    }
    
    static func enableTestingMode(app: XCUIApplication) {
        // Enable special testing features
        app.launchArguments.append("EnableTestingMode")
    }
    
    // MARK: - Mind Map Creation
    static func createBasicMindMap(app: XCUIApplication, title: String = "テストマインドマップ") throws -> XCUIElement {
        // Navigate to create mind map
        let createButton = app.buttons["createMindMapButton"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5), "Create button should exist")
        createButton.tap()
        
        // Wait for canvas
        let canvas = app.otherElements["mindMapCanvas"]
        XCTAssertTrue(canvas.waitForExistence(timeout: 10), "Canvas should appear")
        
        // Set center node title
        let centerNode = app.otherElements["centerNode"]
        XCTAssertTrue(centerNode.waitForExistence(timeout: 5), "Center node should exist")
        
        centerNode.tap()
        let textField = app.textFields.firstMatch
        XCTAssertTrue(textField.waitForExistence(timeout: 3), "Text field should appear")
        
        textField.typeText(title)
        app.keyboards.buttons["完了"].tap()
        
        return canvas
    }
    
    static func addChildNode(app: XCUIApplication, to parentNode: XCUIElement, text: String) throws -> XCUIElement {
        // Long press to show context menu
        parentNode.press(forDuration: 1.0)
        
        // Tap add child button
        let addButton = app.buttons["addChildNodeButton"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 3), "Add child button should appear")
        addButton.tap()
        
        // Find the new child node (assuming it gets a predictable identifier)
        let childNodes = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'childNode-'"))
        let childNode = childNodes.element(boundBy: childNodes.count - 1)
        
        XCTAssertTrue(childNode.waitForExistence(timeout: 5), "Child node should be created")
        
        // Set text if provided
        if !text.isEmpty {
            childNode.tap()
            let textField = app.textFields.firstMatch
            XCTAssertTrue(textField.waitForExistence(timeout: 3), "Text field should appear")
            textField.typeText(text)
            app.keyboards.buttons["完了"].tap()
        }
        
        return childNode
    }
    
    // MARK: - Gesture Operations
    static func performCanvasZoom(canvas: XCUIElement, scale: CGFloat) {
        canvas.pinch(withScale: scale, velocity: 1.0)
        
        // Small delay to allow gesture to complete
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    static func performCanvasPan(canvas: XCUIElement, direction: PanDirection) {
        switch direction {
        case .left:
            canvas.swipeLeft()
        case .right:
            canvas.swipeRight()
        case .up:
            canvas.swipeUp()
        case .down:
            canvas.swipeDown()
        }
        
        Thread.sleep(forTimeInterval: 0.3)
    }
    
    static func performDoubleTapToFit(canvas: XCUIElement) {
        canvas.doubleTap()
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    // MARK: - Node Operations
    static func selectMultipleNodes(app: XCUIApplication, nodeIdentifiers: [String]) throws {
        // Enable multi-selection mode if needed
        let canvas = app.otherElements["mindMapCanvas"]
        canvas.tap() // Ensure canvas is focused
        
        // Select nodes one by one
        for identifier in nodeIdentifiers {
            let node = app.otherElements[identifier]
            XCTAssertTrue(node.waitForExistence(timeout: 3), "Node \(identifier) should exist")
            
            // For multi-selection, we might need to hold a modifier or use specific gesture
            // For now, assume tap with modifier key simulation
            node.tap()
        }
    }
    
    static func deleteSelectedNodes(app: XCUIApplication) throws {
        let deleteButton = app.buttons["deleteSelectedNodesButton"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3), "Delete button should be available")
        deleteButton.tap()
        
        // Confirm deletion if alert appears
        let alert = app.alerts.firstMatch
        if alert.waitForExistence(timeout: 2) {
            let confirmButton = alert.buttons["削除"]
            if confirmButton.exists {
                confirmButton.tap()
            } else {
                // Try alternative button text
                alert.buttons["OK"].tap()
            }
        }
    }
    
    // MARK: - Export Operations
    static func performExport(app: XCUIApplication, format: ExportFormat) throws {
        // Open menu
        let menuButton = app.buttons["menuButton"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5), "Menu button should exist")
        menuButton.tap()
        
        // Select export
        let exportButton = app.buttons["exportButton"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 3), "Export button should exist")
        exportButton.tap()
        
        // Select format
        let exportSheet = app.sheets.firstMatch
        XCTAssertTrue(exportSheet.waitForExistence(timeout: 5), "Export sheet should appear")
        
        let formatButton = exportSheet.buttons[format.rawValue]
        XCTAssertTrue(formatButton.exists, "Format button \(format.rawValue) should exist")
        formatButton.tap()
        
        // Handle share sheet
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10), "Share sheet should appear")
        
        return // Let caller handle share sheet dismissal
    }
    
    // MARK: - Settings Operations  
    static func enableCloudKitSync(app: XCUIApplication) throws {
        // Navigate to settings
        let settingsButton = app.buttons["settingsButton"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button should exist")
        settingsButton.tap()
        
        // Enable sync
        let syncToggle = app.switches["iCloudSyncToggle"]
        XCTAssertTrue(syncToggle.waitForExistence(timeout: 3), "Sync toggle should exist")
        
        if !syncToggle.isSelected {
            syncToggle.tap()
        }
        
        // Return to main view
        let doneButton = app.navigationBars.buttons["完了"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            // Alternative navigation
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    // MARK: - Wait Helpers
    static func waitForSyncCompletion(app: XCUIApplication, timeout: TimeInterval = 30) throws {
        let syncIndicator = app.activityIndicators["syncIndicator"]
        
        if syncIndicator.exists {
            // Wait for sync to complete (indicator disappears)
            let syncComplete = NSPredicate(format: "exists == 0")
            let expectation = XCTestCase().expectation(for: syncComplete, evaluatedWith: syncIndicator, handler: nil)
            XCTestCase().wait(for: [expectation], timeout: timeout)
        }
    }
    
    static func waitForElementToDisappear(_ element: XCUIElement, timeout: TimeInterval = 10) throws {
        let disappear = NSPredicate(format: "exists == 0")
        let expectation = XCTestCase().expectation(for: disappear, evaluatedWith: element, handler: nil)
        XCTestCase().wait(for: [expectation], timeout: timeout)
    }
    
    // MARK: - Performance Helpers
    static func measureOperation<T>(_ operation: () throws -> T) rethrows -> (result: T, timeElapsed: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let endTime = CFAbsoluteTimeGetCurrent()
        
        return (result: result, timeElapsed: endTime - startTime)
    }
    
    // MARK: - Error Simulation
    static func simulateNetworkError(app: XCUIApplication) {
        app.launchArguments.append("SimulateNetworkFailure")
    }
    
    static func simulateLargeDataset(app: XCUIApplication) {
        app.launchArguments.append("CreateLargeDataset")
    }
    
    static func simulateMemoryPressure(app: XCUIApplication) {
        app.launchArguments.append("SimulateMemoryPressure")
    }
}

// MARK: - Supporting Types
enum PanDirection {
    case left
    case right
    case up
    case down
}

enum ExportFormat: String {
    case pdf = "PDF"
    case png = "PNG"
    case opml = "OPML"
    case csv = "CSV"
}

// MARK: - Custom XCTestCase Extensions
extension XCTestCase {
    
    func waitForAppLaunch(_ app: XCUIApplication, timeout: TimeInterval = 15) {
        let mainView = app.otherElements["mainView"]
        XCTAssertTrue(mainView.waitForExistence(timeout: timeout), "App should launch successfully")
    }
    
    func assertPerformance<T>(_ operation: () throws -> T, 
                            expectedMaxTime: TimeInterval, 
                            description: String) rethrows -> T {
        let (result, timeElapsed) = try UITestHelpers.measureOperation(operation)
        XCTAssertLessThan(timeElapsed, expectedMaxTime, description)
        return result
    }
    
    func dismissAnyPresentedSheets(_ app: XCUIApplication) {
        // Dismiss any modal sheets that might be open
        if app.sheets.count > 0 {
            let sheet = app.sheets.firstMatch
            if sheet.buttons["キャンセル"].exists {
                sheet.buttons["キャンセル"].tap()
            } else if sheet.buttons["Cancel"].exists {
                sheet.buttons["Cancel"].tap()
            } else {
                // Try tapping outside the sheet
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1)).tap()
            }
        }
    }
    
    func assertNoUITestFailures() {
        // Custom assertion to check for common UI test failures
        // This could be extended to check for specific error patterns
    }
}

// MARK: - Test Data Helpers
struct TestDataHelpers {
    
    static let sampleMindMapTitles = [
        "プロジェクト企画",
        "学習ノート",
        "アイデア整理",
        "会議議事録",
        "研究メモ"
    ]
    
    static let sampleNodeTexts = [
        "メインアイデア",
        "サブトピック1",
        "サブトピック2",
        "詳細項目",
        "参考資料",
        "次のアクション",
        "重要ポイント",
        "疑問点",
        "解決策",
        "まとめ"
    ]
    
    static func randomMindMapTitle() -> String {
        return sampleMindMapTitles.randomElement() ?? "テストマインドマップ"
    }
    
    static func randomNodeText() -> String {
        return sampleNodeTexts.randomElement() ?? "テストノード"
    }
    
    static func generateLargeTextContent(words: Int = 100) -> String {
        let baseWords = ["アイデア", "思考", "概念", "計画", "目標", "戦略", "方法", "手順", "結果", "成果"]
        return (0..<words).map { _ in baseWords.randomElement()! }.joined(separator: " ")
    }
}