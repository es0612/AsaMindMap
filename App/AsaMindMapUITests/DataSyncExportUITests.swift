//
//  DataSyncExportUITests.swift
//  AsaMindMapUITests
//  
//  Data synchronization and export end-to-end tests
//

import XCTest

// MARK: - Data Sync and Export Tests
final class DataSyncExportUITests: XCTestCase {
    
    private var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UITesting", "DataSyncTestMode"]
        app.launch()
        
        waitForAppLaunch(app)
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - CloudKit Sync End-to-End Tests
    @MainActor
    func testCloudKitSyncFullWorkflow() throws {
        // Test: Complete CloudKit sync workflow
        // RED: This test will fail until we implement CloudKit sync
        
        // 1. Enable CloudKit sync
        try UITestHelpers.enableCloudKitSync(app: app)
        
        // 2. Create mind map with rich content
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "クラウド同期テスト")
        let centerNode = app.otherElements["centerNode"]
        
        // Add various content types
        let textNode = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "テキストノード")
        let taskNode = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "タスクノード")
        
        // Convert to task
        taskNode.press(forDuration: 1.0)
        app.buttons["convertToTaskButton"].tap()
        
        // Add tag
        textNode.press(forDuration: 1.0)
        app.buttons["addTagButton"].tap()
        
        let tagTextField = app.textFields["tagInputField"]
        tagTextField.typeText("重要")
        app.keyboards.buttons["完了"].tap()
        
        // 3. Verify sync starts
        let syncIndicator = app.activityIndicators["syncIndicator"]
        XCTAssertTrue(syncIndicator.waitForExistence(timeout: 5), "Sync should start automatically")
        
        // 4. Wait for sync completion
        try UITestHelpers.waitForSyncCompletion(app: app, timeout: 30)
        
        // 5. Verify sync success indicator
        let syncSuccessIndicator = app.staticTexts["syncSuccessIndicator"]
        XCTAssertTrue(syncSuccessIndicator.waitForExistence(timeout: 5), "Sync success should be indicated")
        
        // 6. Test sync across app sessions
        app.terminate()
        app.launch()
        waitForAppLaunch(app)
        
        // 7. Verify data is restored from CloudKit
        XCTAssertTrue(app.staticTexts["クラウド同期テスト"].waitForExistence(timeout: 10), "Synced mind map should be restored")
        XCTAssertTrue(app.staticTexts["テキストノード"].exists, "Synced text node should be restored")
        XCTAssertTrue(app.staticTexts["タスクノード"].exists, "Synced task node should be restored")
        
        // Verify task state is preserved
        let restoredTaskNode = app.otherElements.matching(NSPredicate(format: "label CONTAINS 'タスクノード'")).firstMatch
        XCTAssertTrue(restoredTaskNode.exists, "Task node should maintain its task state after sync")
        
        // Verify tag is preserved
        let taggedNode = app.otherElements.matching(NSPredicate(format: "label CONTAINS '重要'")).firstMatch
        XCTAssertTrue(taggedNode.exists, "Tag should be preserved after sync")
    }
    
    @MainActor
    func testConflictResolutionWorkflow() throws {
        // Test: CloudKit sync conflict resolution
        // RED: This test will fail until we implement conflict resolution
        
        // 1. Setup initial sync
        try UITestHelpers.enableCloudKitSync(app: app)
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "競合テスト")
        
        try UITestHelpers.waitForSyncCompletion(app: app)
        
        // 2. Simulate conflict scenario
        app.launchArguments.append("SimulateSyncConflict")
        
        // 3. Make local changes
        let centerNode = app.otherElements["centerNode"]
        centerNode.tap()
        
        let textField = app.textFields.firstMatch
        textField.clearText()
        textField.typeText("ローカル変更")
        app.keyboards.buttons["完了"].tap()
        
        // 4. Trigger sync that will cause conflict
        let syncButton = app.buttons["forceSyncButton"]
        syncButton.tap()
        
        // 5. Verify conflict resolution UI appears
        let conflictAlert = app.alerts.firstMatch
        XCTAssertTrue(conflictAlert.waitForExistence(timeout: 10), "Conflict resolution alert should appear")
        
        XCTAssertTrue(conflictAlert.staticTexts["同期競合が発生しました"].exists, "Conflict message should be shown")
        XCTAssertTrue(conflictAlert.buttons["ローカルを保持"].exists, "Keep local option should be available")
        XCTAssertTrue(conflictAlert.buttons["リモートを保持"].exists, "Keep remote option should be available")
        XCTAssertTrue(conflictAlert.buttons["マージ"].exists, "Merge option should be available")
        
        // 6. Test conflict resolution choice
        conflictAlert.buttons["ローカルを保持"].tap()
        
        // 7. Verify resolution result
        try UITestHelpers.waitForSyncCompletion(app: app)
        XCTAssertTrue(app.staticTexts["ローカル変更"].exists, "Local changes should be preserved")
    }
    
    @MainActor
    func testOfflineToOnlineSync() throws {
        // Test: Offline work followed by sync when online
        // RED: This test will fail until we implement offline handling
        
        // 1. Start offline
        app.launchArguments.append("SimulateOfflineMode")
        app.terminate()
        app.launch()
        waitForAppLaunch(app)
        
        // 2. Create content offline
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "オフライン作業")
        let centerNode = app.otherElements["centerNode"]
        
        for i in 0..<5 {
            _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "オフラインノード\(i+1)")
        }
        
        // 3. Verify offline indicator
        let offlineIndicator = app.staticTexts["offlineModeIndicator"]
        XCTAssertTrue(offlineIndicator.exists, "Offline mode should be indicated")
        
        // 4. Enable sync (go online)
        try UITestHelpers.enableCloudKitSync(app: app)
        
        // Remove offline simulation
        app.launchArguments.removeAll { $0 == "SimulateOfflineMode" }
        
        // 5. Verify sync starts for offline changes
        let syncIndicator = app.activityIndicators["syncIndicator"]
        XCTAssertTrue(syncIndicator.waitForExistence(timeout: 5), "Sync should start when going online")
        
        // 6. Wait for sync completion
        try UITestHelpers.waitForSyncCompletion(app: app, timeout: 45)
        
        // 7. Verify all offline changes are synced
        for i in 0..<5 {
            XCTAssertTrue(app.staticTexts["オフラインノード\(i+1)"].exists, "Offline node \(i+1) should be synced")
        }
    }
    
    // MARK: - Export Functionality Tests
    @MainActor
    func testPDFExportWorkflow() throws {
        // Test: Complete PDF export workflow
        // RED: This test will fail until we implement PDF export
        
        // 1. Create rich mind map for export
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "PDF エクスポート")
        let centerNode = app.otherElements["centerNode"]
        
        // Add content with different formatting
        let node1 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "重要ポイント")
        let node2 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "参考資料")
        let node3 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "次のアクション")
        
        // Add colors and tags
        node1.press(forDuration: 1.0)
        app.buttons["formatNodeButton"].tap()
        app.buttons["redColorButton"].tap()
        
        node2.press(forDuration: 1.0)
        app.buttons["addTagButton"].tap()
        let tagField = app.textFields["tagInputField"]
        tagField.typeText("資料")
        app.keyboards.buttons["完了"].tap()
        
        // 2. Initiate PDF export
        try UITestHelpers.performExport(app: app, format: .pdf)
        
        // 3. Verify PDF options are shown
        let pdfOptionsSheet = app.sheets["pdfExportOptions"]
        XCTAssertTrue(pdfOptionsSheet.waitForExistence(timeout: 5), "PDF export options should appear")
        
        // Test different PDF options
        let includeColorsToggle = pdfOptionsSheet.switches["includeColorsToggle"]
        let includeTagsToggle = pdfOptionsSheet.switches["includeTagsToggle"]
        let highQualityToggle = pdfOptionsSheet.switches["highQualityToggle"]
        
        XCTAssertTrue(includeColorsToggle.exists, "Include colors option should exist")
        XCTAssertTrue(includeTagsToggle.exists, "Include tags option should exist")
        XCTAssertTrue(highQualityToggle.exists, "High quality option should exist")
        
        // Configure export settings
        includeColorsToggle.tap()
        includeTagsToggle.tap()
        highQualityToggle.tap()
        
        // 4. Confirm export
        let exportButton = pdfOptionsSheet.buttons["exportToPDFButton"]
        exportButton.tap()
        
        // 5. Verify iOS share sheet appears
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10), "Share sheet should appear")
        
        // 6. Test save to files
        let saveToFilesButton = shareSheet.buttons["Save to Files"]
        if saveToFilesButton.exists {
            saveToFilesButton.tap()
            
            // Verify files app interaction
            let filesApp = app.otherElements["filesAppInterface"]
            XCTAssertTrue(filesApp.waitForExistence(timeout: 5), "Files app interface should appear")
            
            // Select save location and confirm
            let documentsFolder = app.buttons["documentsFolder"]
            if documentsFolder.exists {
                documentsFolder.tap()
            }
            
            let saveButton = app.buttons["Save"]
            saveButton.tap()
            
            // 7. Verify export completion
            let exportSuccessAlert = app.alerts.firstMatch
            if exportSuccessAlert.waitForExistence(timeout: 10) {
                XCTAssertTrue(exportSuccessAlert.staticTexts["エクスポートが完了しました"].exists, "Export success should be confirmed")
                exportSuccessAlert.buttons["OK"].tap()
            }
        } else {
            // Cancel share sheet for test cleanup
            shareSheet.buttons["Cancel"].tap()
        }
    }
    
    @MainActor
    func testPNGExportWithTransparency() throws {
        // Test: PNG export with transparency options
        // RED: This test will fail until we implement PNG export
        
        // 1. Create visual mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "PNG エクスポート")
        let centerNode = app.otherElements["centerNode"]
        
        // Add nodes with different colors
        let coloredNode = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "カラーノード")
        coloredNode.press(forDuration: 1.0)
        app.buttons["formatNodeButton"].tap()
        app.buttons["blueColorButton"].tap()
        
        // 2. Initiate PNG export
        try UITestHelpers.performExport(app: app, format: .png)
        
        // 3. Verify PNG options
        let pngOptionsSheet = app.sheets["pngExportOptions"]
        XCTAssertTrue(pngOptionsSheet.waitForExistence(timeout: 5), "PNG export options should appear")
        
        let transparentBackgroundToggle = pngOptionsSheet.switches["transparentBackgroundToggle"]
        let highResolutionToggle = pngOptionsSheet.switches["highResolutionToggle"]
        
        XCTAssertTrue(transparentBackgroundToggle.exists, "Transparent background option should exist")
        XCTAssertTrue(highResolutionToggle.exists, "High resolution option should exist")
        
        // 4. Configure and export
        transparentBackgroundToggle.tap() // Enable transparency
        highResolutionToggle.tap() // Enable high resolution
        
        let exportButton = pngOptionsSheet.buttons["exportToPNGButton"]
        exportButton.tap()
        
        // 5. Handle share sheet
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10), "Share sheet should appear")
        
        // Test copying to clipboard
        let copyButton = shareSheet.buttons["Copy"]
        if copyButton.exists {
            copyButton.tap()
            
            // Verify copy success (if system provides feedback)
            let copySuccessIndicator = app.staticTexts["copiedToClipboard"]
            if copySuccessIndicator.waitForExistence(timeout: 3) {
                XCTAssertTrue(copySuccessIndicator.exists, "Copy success should be indicated")
            }
        } else {
            shareSheet.buttons["Cancel"].tap()
        }
    }
    
    @MainActor
    func testOPMLExportForCompatibility() throws {
        // Test: OPML export for third-party compatibility
        // RED: This test will fail until we implement OPML export
        
        // 1. Create hierarchical mind map
        let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "OPML エクスポート")
        let centerNode = app.otherElements["centerNode"]
        
        // Create multi-level hierarchy
        let level1Node = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "レベル1")
        let level2Node = try UITestHelpers.addChildNode(app: app, to: level1Node, text: "レベル2")
        let level3Node = try UITestHelpers.addChildNode(app: app, to: level2Node, text: "レベル3")
        
        // Add another branch
        let branch2 = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "ブランチ2")
        _ = try UITestHelpers.addChildNode(app: app, to: branch2, text: "サブブランチ")
        
        // 2. Export as OPML
        try UITestHelpers.performExport(app: app, format: .opml)
        
        // 3. Verify OPML-specific options
        let opmlOptionsSheet = app.sheets["opmlExportOptions"]
        XCTAssertTrue(opmlOptionsSheet.waitForExistence(timeout: 5), "OPML export options should appear")
        
        let includeMetadataToggle = opmlOptionsSheet.switches["includeMetadataToggle"]
        let preserveHierarchyToggle = opmlOptionsSheet.switches["preserveHierarchyToggle"]
        
        XCTAssertTrue(includeMetadataToggle.exists, "Include metadata option should exist")
        XCTAssertTrue(preserveHierarchyToggle.exists, "Preserve hierarchy option should exist")
        
        // 4. Configure and export
        includeMetadataToggle.tap()
        preserveHierarchyToggle.tap()
        
        let exportButton = opmlOptionsSheet.buttons["exportToOPMLButton"]
        exportButton.tap()
        
        // 5. Handle share sheet
        let shareSheet = app.sheets.firstMatch
        XCTAssertTrue(shareSheet.waitForExistence(timeout: 10), "Share sheet should appear")
        
        // Test sharing via email (if available)
        let mailButton = shareSheet.buttons["Mail"]
        if mailButton.exists {
            mailButton.tap()
            
            let mailComposer = app.otherElements["mailComposer"]
            if mailComposer.waitForExistence(timeout: 5) {
                // Verify OPML file is attached
                let attachment = mailComposer.otherElements["opmlAttachment"]
                XCTAssertTrue(attachment.exists, "OPML file should be attached to email")
                
                // Cancel mail composer
                let cancelButton = app.buttons["Cancel"]
                cancelButton.tap()
                
                if app.alerts.firstMatch.exists {
                    app.alerts.firstMatch.buttons["Delete Draft"].tap()
                }
            }
        } else {
            shareSheet.buttons["Cancel"].tap()
        }
    }
    
    // MARK: - Import Functionality Tests
    @MainActor
    func testOPMLImportWorkflow() throws {
        // Test: OPML file import and parsing
        // RED: This test will fail until we implement OPML import
        
        // 1. Navigate to import functionality
        let menuButton = app.buttons["mainMenuButton"]
        menuButton.tap()
        
        let importButton = app.buttons["importButton"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 3), "Import button should exist")
        importButton.tap()
        
        // 2. Select import source
        let importSourceSheet = app.sheets["importSourceOptions"]
        XCTAssertTrue(importSourceSheet.waitForExistence(timeout: 5), "Import source options should appear")
        
        let fromFilesButton = importSourceSheet.buttons["From Files"]
        XCTAssertTrue(fromFilesButton.exists, "From Files option should exist")
        fromFilesButton.tap()
        
        // 3. Simulate file selection (in real testing, this would open Files app)
        app.launchArguments.append("SimulateOPMLFileSelection")
        
        // 4. Verify import preview
        let importPreviewScreen = app.otherElements["importPreviewScreen"]
        XCTAssertTrue(importPreviewScreen.waitForExistence(timeout: 10), "Import preview should appear")
        
        // Verify parsed content preview
        let previewTitle = app.staticTexts["Sample OPML Mind Map"]
        XCTAssertTrue(previewTitle.exists, "Imported title should be previewed")
        
        let previewHierarchy = app.otherElements["importPreviewHierarchy"]
        XCTAssertTrue(previewHierarchy.exists, "Imported hierarchy should be previewed")
        
        // 5. Configure import options
        let importOptionsSection = app.otherElements["importOptionsSection"]
        let preserveFormattingToggle = importOptionsSection.switches["preserveFormattingToggle"]
        let mergeWithExistingToggle = importOptionsSection.switches["mergeWithExistingToggle"]
        
        XCTAssertTrue(preserveFormattingToggle.exists, "Preserve formatting option should exist")
        XCTAssertTrue(mergeWithExistingToggle.exists, "Merge with existing option should exist")
        
        // 6. Confirm import
        let confirmImportButton = app.buttons["confirmImportButton"]
        confirmImportButton.tap()
        
        // 7. Verify import success
        let importSuccessAlert = app.alerts.firstMatch
        XCTAssertTrue(importSuccessAlert.waitForExistence(timeout: 10), "Import success alert should appear")
        XCTAssertTrue(importSuccessAlert.staticTexts["インポートが完了しました"].exists, "Import success message should be shown")
        importSuccessAlert.buttons["OK"].tap()
        
        // 8. Verify imported content
        XCTAssertTrue(app.staticTexts["Sample OPML Mind Map"].exists, "Imported mind map should be available")
    }
    
    // MARK: - Batch Operations Tests
    @MainActor
    func testBatchExportMultipleMindMaps() throws {
        // Test: Exporting multiple mind maps at once
        // RED: This test will fail until we implement batch export
        
        // 1. Create multiple mind maps
        for i in 0..<3 {
            let canvas = try UITestHelpers.createBasicMindMap(app: app, title: "バッチエクスポート\(i+1)")
            
            // Add some content
            let centerNode = app.otherElements["centerNode"]
            _ = try UITestHelpers.addChildNode(app: app, to: centerNode, text: "コンテンツ\(i+1)")
            
            // Return to main screen
            app.navigationBars.buttons["戻る"].tap()
        }
        
        // 2. Access batch export
        let menuButton = app.buttons["mainMenuButton"]
        menuButton.tap()
        
        let batchExportButton = app.buttons["batchExportButton"]
        XCTAssertTrue(batchExportButton.waitForExistence(timeout: 3), "Batch export button should exist")
        batchExportButton.tap()
        
        // 3. Select mind maps for export
        let batchExportScreen = app.otherElements["batchExportScreen"]
        XCTAssertTrue(batchExportScreen.waitForExistence(timeout: 5), "Batch export screen should appear")
        
        // Select all mind maps
        let selectAllButton = app.buttons["selectAllButton"]
        selectAllButton.tap()
        
        // Verify selection
        for i in 0..<3 {
            let checkbox = app.buttons["mindMapCheckbox-\(i)"]
            XCTAssertTrue(checkbox.isSelected, "Mind map \(i) should be selected")
        }
        
        // 4. Choose export format
        let exportFormatSelector = app.segmentedControls["exportFormatSelector"]
        exportFormatSelector.buttons["PDF"].tap()
        
        // 5. Start batch export
        let startBatchExportButton = app.buttons["startBatchExportButton"]
        startBatchExportButton.tap()
        
        // 6. Monitor progress
        let progressIndicator = app.progressIndicators["batchExportProgress"]
        XCTAssertTrue(progressIndicator.waitForExistence(timeout: 5), "Batch export progress should be shown")
        
        let progressLabel = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Exporting'")).firstMatch
        XCTAssertTrue(progressLabel.exists, "Progress status should be shown")
        
        // 7. Wait for completion
        let completionAlert = app.alerts.firstMatch
        XCTAssertTrue(completionAlert.waitForExistence(timeout: 60), "Batch export should complete")
        XCTAssertTrue(completionAlert.staticTexts["バッチエクスポートが完了しました"].exists, "Completion message should be shown")
        
        completionAlert.buttons["OK"].tap()
        
        // 8. Verify export results
        let exportResultsScreen = app.otherElements["exportResultsScreen"]
        XCTAssertTrue(exportResultsScreen.exists, "Export results should be shown")
        
        let successCount = app.staticTexts["exportSuccessCount"]
        XCTAssertTrue(successCount.label.contains("3"), "All 3 mind maps should be exported successfully")
    }
}