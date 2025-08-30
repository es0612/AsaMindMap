import XCTest
@testable import MindMapCore

class RTLLayoutManagerTests: XCTestCase {
    
    func testDefaultLayoutDirectionIsLTR() {
        // Given
        let manager = RTLLayoutManager()
        
        // When
        let direction = manager.currentLayoutDirection
        
        // Then
        XCTAssertEqual(direction, .leftToRight)
    }
    
    func testDetectRTLLanguage() {
        // Given
        let manager = RTLLayoutManager()
        
        // When
        let arabicIsRTL = manager.isRTLLanguage(.arabic)
        let hebrewIsRTL = manager.isRTLLanguage(.hebrew)
        let englishIsRTL = manager.isRTLLanguage(.english)
        let japaneseIsRTL = manager.isRTLLanguage(.japanese)
        
        // Then
        XCTAssertTrue(arabicIsRTL)
        XCTAssertTrue(hebrewIsRTL)
        XCTAssertFalse(englishIsRTL)
        XCTAssertFalse(japaneseIsRTL)
    }
    
    func testLayoutDirectionForLanguage() {
        // Given
        let manager = RTLLayoutManager()
        
        // When
        let arabicDirection = manager.layoutDirection(for: .arabic)
        let englishDirection = manager.layoutDirection(for: .english)
        let hebrewDirection = manager.layoutDirection(for: .hebrew)
        let japaneseDirection = manager.layoutDirection(for: .japanese)
        
        // Then
        XCTAssertEqual(arabicDirection, .rightToLeft)
        XCTAssertEqual(englishDirection, .leftToRight)
        XCTAssertEqual(hebrewDirection, .rightToLeft)
        XCTAssertEqual(japaneseDirection, .leftToRight)
    }
    
    func testMindMapLayoutAdjustmentForRTL() {
        // Given
        let manager = RTLLayoutManager()
        let mindMap = MindMap(title: "Test Map")
        let rootNode = Node(text: "Root", position: CGPoint(x: 100, y: 100))
        let childNode = Node(text: "Child", position: CGPoint(x: 200, y: 100))
        
        // When
        let adjustedLayout = manager.adjustMindMapLayout(mindMap, for: .rightToLeft)
        
        // Then
        XCTAssertNotNil(adjustedLayout)
        // Child node should be positioned to the left of root in RTL
        XCTAssertLessThan(adjustedLayout.nodes.first { $0.text == "Child" }?.position.x ?? 0,
                         adjustedLayout.nodes.first { $0.text == "Root" }?.position.x ?? 0)
    }
    
    func testTextAlignmentForRTL() {
        // Given
        let manager = RTLLayoutManager()
        
        // When
        let ltrAlignment = manager.textAlignment(for: .leftToRight)
        let rtlAlignment = manager.textAlignment(for: .rightToLeft)
        
        // Then
        XCTAssertEqual(ltrAlignment, .leading)
        XCTAssertEqual(rtlAlignment, .trailing)
    }
    
    func testRTLLayoutTransformation() {
        // Given
        let manager = RTLLayoutManager()
        let originalPoint = CGPoint(x: 100, y: 50)
        let containerWidth: CGFloat = 300
        
        // When
        let transformedPoint = manager.transformPointForRTL(originalPoint, containerWidth: containerWidth)
        
        // Then
        // x coordinate should be flipped: new_x = containerWidth - original_x
        XCTAssertEqual(transformedPoint.x, 200) // 300 - 100
        XCTAssertEqual(transformedPoint.y, 50) // y unchanged
    }
    
    func testNodeConnectionDirectionForRTL() {
        // Given
        let manager = RTLLayoutManager()
        let parentNode = Node(text: "Parent", position: CGPoint(x: 150, y: 100))
        let childNode = Node(text: "Child", position: CGPoint(x: 100, y: 150))
        
        // When
        let connectionDirection = manager.connectionDirection(from: parentNode, to: childNode, layout: .rightToLeft)
        
        // Then
        XCTAssertEqual(connectionDirection, .topLeftToBottomRight)
    }
    
    func testSwipeGestureDirectionForRTL() {
        // Given
        let manager = RTLLayoutManager()
        
        // When
        let rtlForward = manager.adjustSwipeDirection(.right, for: .rightToLeft)
        let rtlBackward = manager.adjustSwipeDirection(.left, for: .rightToLeft)
        let ltrForward = manager.adjustSwipeDirection(.right, for: .leftToRight)
        
        // Then
        XCTAssertEqual(rtlForward, .left) // Right swipe becomes left in RTL
        XCTAssertEqual(rtlBackward, .right) // Left swipe becomes right in RTL
        XCTAssertEqual(ltrForward, .right) // No change in LTR
    }
    
    func testMenuPositioningForRTL() {
        // Given
        let manager = RTLLayoutManager()
        let touchPoint = CGPoint(x: 100, y: 100)
        
        // When
        let ltrPosition = manager.adjustMenuPosition(touchPoint, for: .leftToRight)
        let rtlPosition = manager.adjustMenuPosition(touchPoint, for: .rightToLeft)
        
        // Then
        XCTAssertEqual(ltrPosition.x, 110) // Default offset to right
        XCTAssertEqual(rtlPosition.x, 90)  // Offset to left for RTL
        XCTAssertEqual(ltrPosition.y, rtlPosition.y) // Y unchanged
    }
}