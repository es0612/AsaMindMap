//
//  ErrorHandlingUITests.swift
//  AsaMindMapUITests
//  
//  Error handling and edge case regression tests
//

import XCTest

// MARK: - Error Handling and Edge Case Tests
final class ErrorHandlingUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITesting", "ErrorTestingMode"]
        app.launch()
        
        waitForAppLaunch(app)
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Network Error Scenarios
    @MainActor
    func testNetworkFailureRecovery() throws {
        // Test: Graceful handling of network failures
        // RED: This test will fail until we implement network error handling
        
        // 1. Enable sync and create content
        try UITestHelpers.enableCloudKitSync(app: app)
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "ネットワークテスト")
        
        // 2. Simulate network failure during sync
        UITestHelpers.simulateNetworkError(app: app)
        
        // Force sync attempt
        let syncButton = app.buttons["forceSyncButton"]
        if syncButton.exists {
            syncButton.tap()
        }
        
        // 3. Verify error handling
        let networkErrorAlert = app.alerts.firstMatch
        XCTAssertTrue(networkErrorAlert.waitForExistence(timeout: 10), "Network error alert should appear")
        
        // Check error message content
        XCTAssertTrue(networkErrorAlert.staticTexts["ネットワークに接続できません"].exists, "Appropriate error message should be shown")
        XCTAssertTrue(networkErrorAlert.buttons["再試行"].exists, "Retry option should be available")
        XCTAssertTrue(networkErrorAlert.buttons["後で同期"].exists, "Defer sync option should be available")
        
        // 4. Test retry functionality
        networkErrorAlert.buttons["再試行"].tap()
        
        // Should show retry in progress
        let retryIndicator = app.activityIndicators["retryingSyncIndicator"]
        XCTAssertTrue(retryIndicator.waitForExistence(timeout: 3), "Retry indicator should appear")
        
        // 5. Test deferred sync option
        if app.alerts.firstMatch.exists {
            app.alerts.firstMatch.buttons["後で同期"].tap()
        }
        
        // Verify offline mode indicator
        let offlineIndicator = app.staticTexts["offlineModeIndicator"]
        XCTAssertTrue(offlineIndicator.exists, "Offline mode should be indicated")
        
        // 6. Test automatic retry when network returns
        // Remove network error simulation
        app.launchArguments.removeAll { $0.contains("NetworkFailure") }
        
        // Simulate network restoration
        let networkRestoredButton = app.buttons["simulateNetworkRestoredButton"]
        if networkRestoredButton.exists {
            networkRestoredButton.tap()
        }
        
        // Should automatically attempt sync
        let autoSyncIndicator = app.activityIndicators["syncIndicator"]
        XCTAssertTrue(autoSyncIndicator.waitForExistence(timeout: 5), "Auto sync should start when network returns")
    }
    
    @MainActor
    func testCloudKitQuotaExceededHandling() throws {
        // Test: Handling CloudKit storage quota exceeded
        // RED: This test will fail until we implement quota handling
        
        // 1. Setup sync
        try UITestHelpers.enableCloudKitSync(app: app)
        
        // 2. Simulate quota exceeded scenario
        app.launchArguments.append("SimulateCloudKitQuotaExceeded")
        
        // 3. Create large content to trigger quota error
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "クォータテスト")
        let centerNode = app.otherElements["centerNode"]
        
        // Add many nodes to simulate large data
        for i in 0..<50 {
            _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "大容量ノード\(i+1) " + String(repeating: "データ", count: 100))
        }
        
        // 4. Verify quota exceeded handling
        let quotaErrorAlert = app.alerts.firstMatch
        XCTAssertTrue(quotaErrorAlert.waitForExistence(timeout: 15), "Quota exceeded alert should appear")
        
        XCTAssertTrue(quotaErrorAlert.staticTexts["iCloudストレージが不足しています"].exists, "Quota error message should be shown")
        XCTAssertTrue(quotaErrorAlert.buttons["ストレージを管理"].exists, "Manage storage option should be available")
        XCTAssertTrue(quotaErrorAlert.buttons["ローカルのみ継続"].exists, "Continue local only option should be available")
        
        // 5. Test storage management option
        quotaErrorAlert.buttons["ストレージを管理"].tap()
        
        // Should open settings or storage management
        let storageManagementScreen = app.otherElements["storageManagementScreen"]
        XCTAssertTrue(storageManagementScreen.waitForExistence(timeout: 5), "Storage management should be accessible")
        
        // Return to main app
        app.navigationBars.buttons.firstMatch.tap()
        
        // 6. Test local-only continuation
        if app.alerts.firstMatch.exists {
            app.alerts.firstMatch.buttons["ローカルのみ継続"].tap()
        }
        
        // Verify local-only mode
        let localOnlyIndicator = app.staticTexts["localOnlyModeIndicator"]
        XCTAssertTrue(localOnlyIndicator.exists, "Local-only mode should be indicated")
    }
    
    // MARK: - Data Corruption Scenarios
    @MainActor
    func testDataCorruptionRecovery() throws {
        // Test: Handling corrupted local data
        // RED: This test will fail until we implement data corruption recovery
        
        // 1. Create mind map with content
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "データ破損テスト")
        let centerNode = app.otherElements["centerNode"]
        _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "重要なデータ")
        
        // 2. Simulate data corruption
        app.launchArguments.append("SimulateDataCorruption")
        app.terminate()
        app.launch()
        
        // 3. Verify corruption detection and recovery
        let corruptionAlert = app.alerts.firstMatch
        XCTAssertTrue(corruptionAlert.waitForExistence(timeout: 15), "Data corruption alert should appear")
        
        XCTAssertTrue(corruptionAlert.staticTexts["データの整合性に問題が検出されました"].exists, "Data corruption message should be shown")
        XCTAssertTrue(corruptionAlert.buttons["自動修復"].exists, "Auto repair option should be available")
        XCTAssertTrue(corruptionAlert.buttons["バックアップから復元"].exists, "Restore from backup option should be available")
        XCTAssertTrue(corruptionAlert.buttons["新しく開始"].exists, "Start fresh option should be available")
        
        // 4. Test automatic repair
        corruptionAlert.buttons["自動修復"].tap()
        
        let repairIndicator = app.activityIndicators["dataRepairIndicator"]
        XCTAssertTrue(repairIndicator.waitForExistence(timeout: 5), "Data repair should start")
        
        // Wait for repair completion
        let repairResultAlert = app.alerts.firstMatch
        XCTAssertTrue(repairResultAlert.waitForExistence(timeout: 30), "Repair result should be shown")
        
        if repairResultAlert.staticTexts["修復が完了しました"].exists {
            repairResultAlert.buttons["OK"].tap()
            
            // Verify data is accessible after repair
            XCTAssertTrue(app.staticTexts["データ破損テスト"].waitForExistence(timeout: 10), "Repaired data should be accessible")
        } else if repairResultAlert.staticTexts["修復に失敗しました"].exists {
            repairResultAlert.buttons["バックアップから復元"].tap()
            
            // Handle backup restoration flow
            let backupListScreen = app.otherElements["backupListScreen"]
            XCTAssertTrue(backupListScreen.waitForExistence(timeout: 10), "Backup list should be shown")
        }
    }
    
    @MainActor
    func testInvalidFileImportHandling() throws {
        // Test: Handling invalid or corrupted import files
        // RED: This test will fail until we implement import validation
        
        // 1. Navigate to import
        let menuButton = app.buttons["mainMenuButton"]
        menuButton.tap()
        
        let importButton = app.buttons["importButton"]
        importButton.tap()
        
        // 2. Simulate selecting invalid file
        app.launchArguments.append("SimulateInvalidFileImport")
        
        let fromFilesButton = app.sheets.firstMatch.buttons["From Files"]
        fromFilesButton.tap()
        
        // 3. Verify invalid file handling
        let invalidFileAlert = app.alerts.firstMatch
        XCTAssertTrue(invalidFileAlert.waitForExistence(timeout: 10), "Invalid file alert should appear")
        
        XCTAssertTrue(invalidFileAlert.staticTexts["サポートされていないファイル形式です"].exists, "Invalid format message should be shown")
        XCTAssertTrue(invalidFileAlert.buttons["別のファイルを選択"].exists, "Select another file option should be available")
        XCTAssertTrue(invalidFileAlert.buttons["キャンセル"].exists, "Cancel option should be available")
        
        // 4. Test corrupted file handling
        invalidFileAlert.buttons["別のファイルを選択"].tap()
        app.launchArguments.removeAll { $0.contains("InvalidFileImport") }
        app.launchArguments.append("SimulateCorruptedFileImport")
        
        // Simulate selecting corrupted file
        fromFilesButton.tap()
        
        let corruptedFileAlert = app.alerts.firstMatch
        XCTAssertTrue(corruptedFileAlert.waitForExistence(timeout: 10), "Corrupted file alert should appear")
        
        XCTAssertTrue(corruptedFileAlert.staticTexts["ファイルが破損しているか読み取れません"].exists, "Corrupted file message should be shown")
        corruptedFileAlert.buttons["OK"].tap()
    }
    
    // MARK: - Memory and Performance Edge Cases
    @MainActor
    func testLowMemoryScenarios() throws {
        // Test: App behavior under low memory conditions
        // RED: This test will fail until we implement memory management
        
        // 1. Create large mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "メモリテスト")
        let centerNode = app.otherElements["centerNode"]
        
        // 2. Add many nodes to consume memory
        for i in 0..<100 {
            _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "メモリ消費ノード\(i+1)")
        }
        
        // 3. Simulate memory pressure
        UITestHelpers.simulateMemoryPressure(app: app)
        
        // 4. Verify memory warning handling
        let memoryWarningAlert = app.alerts.firstMatch
        if memoryWarningAlert.waitForExistence(timeout: 5) {
            XCTAssertTrue(memoryWarningAlert.staticTexts["メモリが不足しています"].exists, "Memory warning should be shown")
            XCTAssertTrue(memoryWarningAlert.buttons["データを保存"].exists, "Save data option should be available")
            XCTAssertTrue(memoryWarningAlert.buttons["続行"].exists, "Continue option should be available")
            
            memoryWarningAlert.buttons["データを保存"].tap()
            
            // Verify data is saved
            let saveIndicator = app.activityIndicators["savingDataIndicator"]
            XCTAssertTrue(saveIndicator.waitForExistence(timeout: 5), "Data saving should start")
        }
        
        // 5. Test app stability after memory pressure
        let (_, responseTime) = UITestHelpers.measureOperation {
            centerNode.tap()
            return app.otherElements["selectedNode"].waitForExistence(timeout: 2)
        }
        
        XCTAssertLessThan(responseTime, 3.0, "App should remain responsive after memory pressure")
        
        // 6. Test memory cleanup on background/foreground
        // Simulate app going to background
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)
        
        // Return to app
        app.activate()
        
        // Verify app restored correctly
        waitForAppLaunch(app, timeout: 10)
        XCTAssertTrue(app.staticTexts["メモリテスト"].exists, "App should restore correctly after backgrounding")
    }
    
    @MainActor
    func testExtremelyLargeDatasets() throws {
        // Test: Handling extremely large mind maps
        // RED: This test will fail until we implement virtualization
        
        // 1. Create mind map with extreme number of nodes
        UITestHelpers.simulateLargeDataset(app: app)
        app.terminate()
        app.launch()
        waitForAppLaunch(app)
        
        // 2. Verify large dataset handling
        let largeDatasetIndicator = app.staticTexts["largeDatasetModeIndicator"]
        XCTAssertTrue(largeDatasetIndicator.exists, "Large dataset mode should be indicated")
        
        // 3. Test basic operations with large dataset
        let canvas = app.otherElements["mindMapCanvas"]
        XCTAssertTrue(canvas.exists, "Canvas should load with large dataset")
        
        // Test zoom performance
        let (_, zoomTime) = UITestHelpers.measureOperation {
            canvas.pinch(withScale: 2.0, velocity: 1.0)
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        XCTAssertLessThan(zoomTime, 2.0, "Zoom should complete within 2 seconds even with large dataset")
        
        // Test pan performance
        let (_, panTime) = UITestHelpers.measureOperation {
            canvas.swipeLeft()
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        XCTAssertLessThan(panTime, 1.0, "Pan should complete within 1 second even with large dataset")
        
        // 4. Test search functionality with large dataset
        let searchButton = app.buttons["searchButton"]
        if searchButton.exists {
            searchButton.tap()
            
            let searchField = app.textFields["searchTextField"]
            searchField.typeText("検索テスト")
            
            let searchResults = app.otherElements["searchResults"]
            XCTAssertTrue(searchResults.waitForExistence(timeout: 10), "Search should work with large datasets")
        }
    }
    
    // MARK: - User Input Edge Cases
    @MainActor
    func testExtremeLengthTextInput() throws {
        // Test: Handling extremely long text input
        // RED: This test will fail until we implement input validation
        
        // 1. Create mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "テキスト長テスト")
        let centerNode = app.otherElements["centerNode"]
        
        // 2. Test extremely long text
        let veryLongText = String(repeating: "非常に長いテキスト", count: 1000) // ~15,000 characters
        
        let childNode = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "")
        
        childNode.tap()
        let textField = app.textFields.firstMatch
        textField.typeText(veryLongText)
        
        // 3. Verify input validation
        let textLengthWarning = app.alerts.firstMatch
        if textLengthWarning.waitForExistence(timeout: 5) {
            XCTAssertTrue(textLengthWarning.staticTexts["テキストが長すぎます"].exists, "Text length warning should appear")
            XCTAssertTrue(textLengthWarning.buttons["短縮"].exists, "Truncate option should be available")
            XCTAssertTrue(textLengthWarning.buttons["そのまま保存"].exists, "Keep as-is option should be available")
            
            textLengthWarning.buttons["短縮"].tap()
        } else {
            app.keyboards.buttons["完了"].tap()
        }
        
        // 4. Verify app stability with long text
        let (_, renderTime) = UITestHelpers.measureOperation {
            canvas.pinch(withScale: 2.0, velocity: 1.0)
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        XCTAssertLessThan(renderTime, 2.0, "App should handle long text without performance issues")
    }
    
    @MainActor
    func testSpecialCharacterHandling() throws {
        // Test: Handling special characters and emojis
        // RED: This test will fail until we implement proper character encoding
        
        // 1. Create mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "特殊文字テスト")
        let centerNode = app.otherElements["centerNode"]
        
        // 2. Test various special characters
        let specialTexts = [
            "🚀🎯📱💡🌟", // Emojis
            "数学: ∑∫∞√π", // Mathematical symbols
            "通貨: ¥€$£¢", // Currency symbols
            "アクセント: café naïve résumé", // Accented characters
            "中文字符测试", // Chinese characters
            "اختبار عربي", // Arabic text
            "тест кириллицы", // Cyrillic text
            "ελληνικό κείμενο", // Greek text
        ]
        
        for (index, text) in specialTexts.enumerated() {
            let node = try UITestHelpers.addChildNode(app: app, to: centerNode, text: text)
            
            // Verify text is displayed correctly
            XCTAssertTrue(app.staticTexts[text].exists, "Special text '\(text)' should be displayed correctly")
        }
        
        // 3. Test copy/paste with special characters
        let emojiNode = app.staticTexts["🚀🎯📱💡🌟"]
        emojiNode.press(forDuration: 1.0)
        
        if app.buttons["コピー"].exists {
            app.buttons["コピー"].tap()
            
            // Create new node and paste
            centerNode.press(forDuration: 1.0)
            app.buttons["addChildNodeButton"].tap()
            
            let newNode = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'childNode-'")).element(boundBy: specialTexts.count)
            newNode.tap()
            
            let textField = app.textFields.firstMatch
            textField.press(forDuration: 1.0)
            
            if app.buttons["ペースト"].exists {
                app.buttons["ペースト"].tap()
                app.keyboards.buttons["完了"].tap()
                
                // Verify paste worked correctly
                XCTAssertTrue(app.staticTexts["🚀🎯📱💡🌟"].allElementsBoundByIndex.count >= 2, "Emoji text should be pasted correctly")
            }
        }
    }
    
    // MARK: - Concurrent Operation Tests
    @MainActor
    func testConcurrentEditingOperations() throws {
        // Test: Handling multiple simultaneous operations
        // RED: This test will fail until we implement operation queueing
        
        // 1. Create mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "同期操作テスト")
        let centerNode = app.otherElements["centerNode"]
        
        // 2. Simulate concurrent operations
        // This is challenging in UI tests, but we can test rapid sequential operations
        
        // Rapid node creation
        for i in 0..<10 {
            centerNode.press(forDuration: 0.1)
            
            let addButton = app.buttons["addChildNodeButton"]
            if addButton.waitForExistence(timeout: 1) {
                addButton.tap()
                
                let newNode = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'childNode-'")).element(boundBy: i)
                if newNode.waitForExistence(timeout: 2) {
                    newNode.tap()
                    
                    let textField = app.textFields.firstMatch
                    if textField.waitForExistence(timeout: 1) {
                        textField.typeText("高速ノード\(i+1)")
                        app.keyboards.buttons["完了"].tap()
                    }
                }
            }
            
            // Small delay to allow operation to complete
            Thread.sleep(forTimeInterval: 0.1)
        }
        
        // 3. Verify all operations completed successfully
        let nodeCount = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH 'childNode-'")).count
        XCTAssertEqual(nodeCount, 10, "All rapid operations should complete successfully")
        
        // 4. Test app stability after concurrent operations
        let (_, responseTime) = UITestHelpers.measureOperation {
            canvas.pinch(withScale: 2.0, velocity: 1.0)
            Thread.sleep(forTimeInterval: 0.3)
        }
        
        XCTAssertLessThan(responseTime, 1.0, "App should remain responsive after concurrent operations")
    }
    
    // MARK: - Recovery and Persistence Tests
    @MainActor
    func testUnexpectedAppTermination() throws {
        // Test: Data preservation during unexpected termination
        // RED: This test will fail until we implement auto-save
        
        // 1. Create mind map with unsaved changes
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "終了テスト")
        let centerNode = app.otherElements["centerNode"]
        
        let importantNode = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "重要な未保存データ")
        
        // 2. Simulate unexpected termination (force kill)
        app.terminate()
        Thread.sleep(forTimeInterval: 1) // Simulate immediate restart
        app.launch()
        
        waitForAppLaunch(app)
        
        // 3. Verify data recovery
        let recoveryAlert = app.alerts.firstMatch
        if recoveryAlert.waitForExistence(timeout: 10) {
            XCTAssertTrue(recoveryAlert.staticTexts["前回のセッションが予期せず終了しました"].exists, "Recovery message should be shown")
            XCTAssertTrue(recoveryAlert.buttons["復元"].exists, "Recovery option should be available")
            
            recoveryAlert.buttons["復元"].tap()
        }
        
        // Verify data was recovered
        XCTAssertTrue(app.staticTexts["終了テスト"].waitForExistence(timeout: 10), "Mind map should be recovered")
        XCTAssertTrue(app.staticTexts["重要な未保存データ"].exists, "Unsaved data should be recovered")
        
        // 4. Test recovery quality
        let recoveredNode = app.staticTexts["重要な未保存データ"]
        recoveredNode.tap()
        
        // Verify node is fully functional after recovery
        XCTAssertTrue(app.otherElements["selectedNode"].exists, "Recovered node should be interactive")
    }
}