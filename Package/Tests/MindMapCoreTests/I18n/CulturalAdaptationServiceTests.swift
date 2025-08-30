import XCTest
import Foundation
@testable import MindMapCore

class CulturalAdaptationServiceTests: XCTestCase {
    
    func testDateFormattingForDifferentLocales() {
        // Given
        let service = CulturalAdaptationService()
        let testDate = Date(timeIntervalSince1970: 1640995200) // 2022-01-01 00:00:00 UTC
        
        // When
        let japaneseDate = service.formatDate(testDate, for: .japanese)
        let englishDate = service.formatDate(testDate, for: .english)
        let chineseDate = service.formatDate(testDate, for: .chineseSimplified)
        let koreanDate = service.formatDate(testDate, for: .korean)
        
        // Then
        XCTAssertEqual(japaneseDate, "2022年1月1日")
        XCTAssertEqual(englishDate, "January 1, 2022")
        XCTAssertEqual(chineseDate, "2022年1月1日")
        XCTAssertEqual(koreanDate, "2022년 1월 1일")
    }
    
    func testTimeFormattingForDifferentLocales() {
        // Given
        let service = CulturalAdaptationService()
        let testDate = Date(timeIntervalSince1970: 1640995200 + 3661) // 01:01:01
        
        // When
        let japaneseTime = service.formatTime(testDate, for: .japanese)
        let englishTime = service.formatTime(testDate, for: .english)
        let chineseTime = service.formatTime(testDate, for: .chineseSimplified)
        
        // Then
        XCTAssertEqual(japaneseTime, "1:01")
        XCTAssertEqual(englishTime, "1:01 AM")
        XCTAssertEqual(chineseTime, "上午1:01")
    }
    
    func testNumberFormattingForDifferentLocales() {
        // Given
        let service = CulturalAdaptationService()
        let testNumber = 1234.56
        
        // When
        let japaneseNumber = service.formatNumber(testNumber, for: .japanese)
        let englishNumber = service.formatNumber(testNumber, for: .english)
        let germanNumber = service.formatNumber(testNumber, for: .german)
        
        // Then
        XCTAssertEqual(japaneseNumber, "1,234.56")
        XCTAssertEqual(englishNumber, "1,234.56")
        XCTAssertEqual(germanNumber, "1.234,56")
    }
    
    func testCurrencyFormattingForDifferentLocales() {
        // Given
        let service = CulturalAdaptationService()
        let testAmount = 1234.56
        
        // When
        let japanesePrice = service.formatCurrency(testAmount, for: .japanese)
        let englishPrice = service.formatCurrency(testAmount, for: .english)
        let chinesePrice = service.formatCurrency(testAmount, for: .chineseSimplified)
        
        // Then
        XCTAssertEqual(japanesePrice, "¥1,235") // Rounded to nearest yen
        XCTAssertEqual(englishPrice, "$1,234.56")
        XCTAssertEqual(chinesePrice, "¥1,234.56")
    }
    
    func testPercentFormattingForDifferentLocales() {
        // Given
        let service = CulturalAdaptationService()
        let testPercentage = 0.75
        
        // When
        let japanesePercent = service.formatPercentage(testPercentage, for: .japanese)
        let englishPercent = service.formatPercentage(testPercentage, for: .english)
        let arabicPercent = service.formatPercentage(testPercentage, for: .arabic)
        
        // Then
        XCTAssertEqual(japanesePercent, "75%")
        XCTAssertEqual(englishPercent, "75%")
        XCTAssertEqual(arabicPercent, "٧٥٪") // Arabic-Indic digits
    }
    
    func testFileNameFormattingForExport() {
        // Given
        let service = CulturalAdaptationService()
        let mindMapTitle = "プロジェクト計画"
        let testDate = Date(timeIntervalSince1970: 1640995200)
        
        // When
        let japaneseFileName = service.formatExportFileName(mindMapTitle, date: testDate, for: .japanese)
        let englishFileName = service.formatExportFileName("Project Plan", date: testDate, for: .english)
        
        // Then
        XCTAssertEqual(japaneseFileName, "プロジェクト計画_2022-01-01.pdf")
        XCTAssertEqual(englishFileName, "Project Plan_2022-01-01.pdf")
    }
    
    func testMindMapNodeCountDescription() {
        // Given
        let service = CulturalAdaptationService()
        
        // When
        let japaneseCount = service.formatNodeCountDescription(5, for: .japanese)
        let englishCount = service.formatNodeCountDescription(5, for: .english)
        let chineseCount = service.formatNodeCountDescription(5, for: .chineseSimplified)
        
        // Then
        XCTAssertEqual(japaneseCount, "5個のノード")
        XCTAssertEqual(englishCount, "5 nodes")
        XCTAssertEqual(chineseCount, "5个节点")
    }
    
    func testTaskProgressDescription() {
        // Given
        let service = CulturalAdaptationService()
        
        // When
        let japaneseProgress = service.formatTaskProgressDescription(completed: 3, total: 10, for: .japanese)
        let englishProgress = service.formatTaskProgressDescription(completed: 3, total: 10, for: .english)
        let koreanProgress = service.formatTaskProgressDescription(completed: 3, total: 10, for: .korean)
        
        // Then
        XCTAssertEqual(japaneseProgress, "10個中3個完了")
        XCTAssertEqual(englishProgress, "3 of 10 completed")
        XCTAssertEqual(koreanProgress, "10개 중 3개 완료")
    }
    
    func testListSeparatorForDifferentLocales() {
        // Given
        let service = CulturalAdaptationService()
        let items = ["項目1", "項目2", "項目3"]
        
        // When
        let japaneseList = service.formatList(items, for: .japanese)
        let englishList = service.formatList(["Item 1", "Item 2", "Item 3"], for: .english)
        let chineseList = service.formatList(["项目1", "项目2", "项目3"], for: .chineseSimplified)
        
        // Then
        XCTAssertEqual(japaneseList, "項目1、項目2、項目3")
        XCTAssertEqual(englishList, "Item 1, Item 2, Item 3")
        XCTAssertEqual(chineseList, "项目1、项目2、项目3")
    }
    
    func testWeekdayOrderForDifferentLocales() {
        // Given
        let service = CulturalAdaptationService()
        
        // When
        let japaneseWeekdays = service.weekdayOrder(for: .japanese)
        let englishWeekdays = service.weekdayOrder(for: .english)
        let arabicWeekdays = service.weekdayOrder(for: .arabic)
        
        // Then
        XCTAssertEqual(japaneseWeekdays.first, .sunday)
        XCTAssertEqual(englishWeekdays.first, .sunday)
        XCTAssertEqual(arabicWeekdays.first, .saturday)
    }
}