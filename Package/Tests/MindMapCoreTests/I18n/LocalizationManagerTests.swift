import XCTest
@testable import MindMapCore

class LocalizationManagerTests: XCTestCase {
    
    func testDefaultLocaleIsSystemLocale() {
        // Given
        let manager = LocalizationManager()
        
        // When
        let currentLocale = manager.currentLocale
        
        // Then
        XCTAssertNotNil(currentLocale)
    }
    
    func testSwitchingToSupportedLanguage() {
        // Given
        let manager = LocalizationManager()
        
        // When
        let success = manager.setLanguage(.english)
        
        // Then
        XCTAssertTrue(success)
        XCTAssertEqual(manager.currentLanguage, .english)
    }
    
    func testLocalizedStringRetrieval() {
        // Given
        let manager = LocalizationManager()
        manager.setLanguage(.english)
        
        // When
        let localizedString = manager.localizedString(for: "mindmap.create.title")
        
        // Then
        XCTAssertNotEqual(localizedString, "mindmap.create.title") // Should not return key
        XCTAssertFalse(localizedString.isEmpty)
    }
    
    func testJapaneseLocalization() {
        // Given
        let manager = LocalizationManager()
        manager.setLanguage(.japanese)
        
        // When
        let title = manager.localizedString(for: "mindmap.create.title")
        let cancel = manager.localizedString(for: "common.cancel")
        
        // Then
        XCTAssertEqual(title, "マインドマップを作成")
        XCTAssertEqual(cancel, "キャンセル")
    }
    
    func testEnglishLocalization() {
        // Given
        let manager = LocalizationManager()
        manager.setLanguage(.english)
        
        // When
        let title = manager.localizedString(for: "mindmap.create.title")
        let cancel = manager.localizedString(for: "common.cancel")
        
        // Then
        XCTAssertEqual(title, "Create Mind Map")
        XCTAssertEqual(cancel, "Cancel")
    }
    
    func testChineseSimplifiedLocalization() {
        // Given
        let manager = LocalizationManager()
        manager.setLanguage(.chineseSimplified)
        
        // When
        let title = manager.localizedString(for: "mindmap.create.title")
        let cancel = manager.localizedString(for: "common.cancel")
        
        // Then
        XCTAssertEqual(title, "创建思维导图")
        XCTAssertEqual(cancel, "取消")
    }
    
    func testKoreanLocalization() {
        // Given
        let manager = LocalizationManager()
        manager.setLanguage(.korean)
        
        // When
        let title = manager.localizedString(for: "mindmap.create.title")
        let cancel = manager.localizedString(for: "common.cancel")
        
        // Then
        XCTAssertEqual(title, "마인드맵 만들기")
        XCTAssertEqual(cancel, "취소")
    }
    
    func testUnsupportedLanguageFallbackToEnglish() {
        // Given
        let manager = LocalizationManager()
        
        // When
        let success = manager.setLanguage(.french) // Unsupported
        
        // Then
        XCTAssertFalse(success)
        XCTAssertEqual(manager.currentLanguage, .english) // Fallback
    }
    
    func testPluralLocalization() {
        // Given
        let manager = LocalizationManager()
        manager.setLanguage(.english)
        
        // When
        let singleNode = manager.pluralizedString(for: "node.count", count: 1)
        let multipleNodes = manager.pluralizedString(for: "node.count", count: 5)
        
        // Then
        XCTAssertEqual(singleNode, "1 node")
        XCTAssertEqual(multipleNodes, "5 nodes")
    }
    
    func testLanguageObservation() {
        // Given
        let manager = LocalizationManager()
        var languageChanged = false
        let expectation = self.expectation(description: "Language change notification")
        
        let cancellable = manager.languageDidChangePublisher.sink { _ in
            languageChanged = true
            expectation.fulfill()
        }
        
        // When
        manager.setLanguage(.japanese)
        
        // Then
        waitForExpectations(timeout: 1.0)
        XCTAssertTrue(languageChanged)
        cancellable.cancel()
    }
}