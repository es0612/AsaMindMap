import XCTest
@testable import MindMapCore

class I18nEntitiesTests: XCTestCase {
    
    func testSupportedLanguageEnum() {
        // Given & When
        let languages = SupportedLanguage.allCases
        
        // Then
        XCTAssertEqual(languages.count, 4)
        XCTAssertTrue(languages.contains(.japanese))
        XCTAssertTrue(languages.contains(.english))
        XCTAssertTrue(languages.contains(.chineseSimplified))
        XCTAssertTrue(languages.contains(.korean))
    }
    
    func testLanguageCodeMapping() {
        // Given
        let japanese = SupportedLanguage.japanese
        let english = SupportedLanguage.english
        let chinese = SupportedLanguage.chineseSimplified
        let korean = SupportedLanguage.korean
        
        // When & Then
        XCTAssertEqual(japanese.languageCode, "ja")
        XCTAssertEqual(english.languageCode, "en")
        XCTAssertEqual(chinese.languageCode, "zh-Hans")
        XCTAssertEqual(korean.languageCode, "ko")
    }
    
    func testLanguageFromCode() {
        // Given & When
        let japaneseFromCode = SupportedLanguage.from(languageCode: "ja")
        let englishFromCode = SupportedLanguage.from(languageCode: "en")
        let chineseFromCode = SupportedLanguage.from(languageCode: "zh-Hans")
        let koreanFromCode = SupportedLanguage.from(languageCode: "ko")
        let unsupportedFromCode = SupportedLanguage.from(languageCode: "fr")
        
        // Then
        XCTAssertEqual(japaneseFromCode, .japanese)
        XCTAssertEqual(englishFromCode, .english)
        XCTAssertEqual(chineseFromCode, .chineseSimplified)
        XCTAssertEqual(koreanFromCode, .korean)
        XCTAssertNil(unsupportedFromCode)
    }
    
    func testLayoutDirectionEnum() {
        // Given & When
        let ltr = LayoutDirection.leftToRight
        let rtl = LayoutDirection.rightToLeft
        
        // Then
        XCTAssertNotEqual(ltr, rtl)
        XCTAssertEqual(ltr.rawValue, "ltr")
        XCTAssertEqual(rtl.rawValue, "rtl")
    }
    
    func testTextAlignmentEnum() {
        // Given & When
        let leading = TextAlignment.leading
        let center = TextAlignment.center
        let trailing = TextAlignment.trailing
        
        // Then
        XCTAssertNotEqual(leading, center)
        XCTAssertNotEqual(center, trailing)
        XCTAssertNotEqual(leading, trailing)
    }
    
    func testSwipeDirectionEnum() {
        // Given & When
        let up = SwipeDirection.up
        let down = SwipeDirection.down
        let left = SwipeDirection.left
        let right = SwipeDirection.right
        
        // Then
        XCTAssertEqual(SwipeDirection.allCases.count, 4)
        XCTAssertTrue(SwipeDirection.allCases.contains(up))
        XCTAssertTrue(SwipeDirection.allCases.contains(down))
        XCTAssertTrue(SwipeDirection.allCases.contains(left))
        XCTAssertTrue(SwipeDirection.allCases.contains(right))
    }
    
    func testConnectionDirectionEnum() {
        // Given & When
        let topToBottom = ConnectionDirection.topToBottom
        let leftToRight = ConnectionDirection.leftToRight
        let topLeftToBottomRight = ConnectionDirection.topLeftToBottomRight
        
        // Then
        XCTAssertNotEqual(topToBottom, leftToRight)
        XCTAssertNotEqual(leftToRight, topLeftToBottomRight)
    }
    
    func testLocalizationErrorEnum() {
        // Given & When
        let fileNotFound = LocalizationError.localizationFileNotFound("ja")
        let keyNotFound = LocalizationError.localizationKeyNotFound("test.key")
        let unsupportedLanguage = LocalizationError.unsupportedLanguage("fr")
        
        // Then
        switch fileNotFound {
        case .localizationFileNotFound(let language):
            XCTAssertEqual(language, "ja")
        default:
            XCTFail("Expected localizationFileNotFound")
        }
        
        switch keyNotFound {
        case .localizationKeyNotFound(let key):
            XCTAssertEqual(key, "test.key")
        default:
            XCTFail("Expected localizationKeyNotFound")
        }
        
        switch unsupportedLanguage {
        case .unsupportedLanguage(let language):
            XCTAssertEqual(language, "fr")
        default:
            XCTFail("Expected unsupportedLanguage")
        }
    }
    
    func testWeekdayEnum() {
        // Given & When
        let weekdays = Weekday.allCases
        
        // Then
        XCTAssertEqual(weekdays.count, 7)
        XCTAssertEqual(weekdays[0], .sunday)
        XCTAssertEqual(weekdays[1], .monday)
        XCTAssertEqual(weekdays[6], .saturday)
    }
    
    func testLanguageDisplayName() {
        // Given
        let japanese = SupportedLanguage.japanese
        let english = SupportedLanguage.english
        let chinese = SupportedLanguage.chineseSimplified
        let korean = SupportedLanguage.korean
        
        // When & Then
        XCTAssertEqual(japanese.displayName, "日本語")
        XCTAssertEqual(english.displayName, "English")
        XCTAssertEqual(chinese.displayName, "简体中文")
        XCTAssertEqual(korean.displayName, "한국어")
    }
    
    func testLanguageNativeName() {
        // Given
        let japanese = SupportedLanguage.japanese
        let english = SupportedLanguage.english
        
        // When & Then
        XCTAssertEqual(japanese.nativeName, "日本語")
        XCTAssertEqual(english.nativeName, "English")
    }
    
    func testLanguageFlagEmoji() {
        // Given
        let japanese = SupportedLanguage.japanese
        let english = SupportedLanguage.english
        let chinese = SupportedLanguage.chineseSimplified
        let korean = SupportedLanguage.korean
        
        // When & Then
        XCTAssertEqual(japanese.flagEmoji, "🇯🇵")
        XCTAssertEqual(english.flagEmoji, "🇺🇸")
        XCTAssertEqual(chinese.flagEmoji, "🇨🇳")
        XCTAssertEqual(korean.flagEmoji, "🇰🇷")
    }
}