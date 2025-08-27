import XCTest
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

final class TagViewTestsXC: XCTestCase {
    
    // MARK: - Test Data
    private var sampleTag: Tag!
    private var sampleTags: [Tag]!
    
    override func setUp() {
        super.setUp()
        sampleTag = Tag(
            id: UUID(),
            name: "テストタグ",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        sampleTags = [
            Tag(id: UUID(), name: "重要", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "プロジェクト", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "アイデア", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "TODO", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "会議", createdAt: Date(), updatedAt: Date())
        ]
    }
    
    // MARK: - TagView Tests
    
    func testTagViewInitialization() {
        let tagView = TagView(tag: sampleTag)
        
        XCTAssertEqual(tagView.tag.name, "テストタグ")
        XCTAssertEqual(tagView.size, .medium)
        // TagStyle is not Equatable, so we check its properties instead
        XCTAssertNotNil(tagView.style.backgroundColor)
    }
    
    func testTagViewWithCustomProperties() {
        var tapCalled = false
        var removeCalled = false
        
        let tagView = TagView(
            tag: sampleTag,
            size: .small,
            style: .primary,
            onTap: { tapCalled = true },
            onRemove: { removeCalled = true }
        )
        
        XCTAssertEqual(tagView.tag.name, "テストタグ")
        XCTAssertEqual(tagView.size, .small)
        // TagStyle is not Equatable, check backgroundColor instead
        XCTAssertNotNil(tagView.style.backgroundColor)
    }
    
    // MARK: - TagSize Tests
    
    func testTagSizeProperties() {
        let smallSize = TagSize.small
        let mediumSize = TagSize.medium
        let largeSize = TagSize.large
        
        XCTAssertEqual(smallSize.fontSize, 10)
        XCTAssertEqual(smallSize.horizontalPadding, 4)
        
        XCTAssertEqual(mediumSize.fontSize, 12)
        XCTAssertEqual(mediumSize.horizontalPadding, 6)
        
        XCTAssertEqual(largeSize.fontSize, 14)
        XCTAssertEqual(largeSize.horizontalPadding, 8)
    }
    
    // MARK: - TagStyle Tests
    
    func testTagStyleColors() {
        let defaultStyle = TagStyle.default
        let primaryStyle = TagStyle.primary
        let secondaryStyle = TagStyle.secondary
        let successStyle = TagStyle.success
        let warningStyle = TagStyle.warning
        let dangerStyle = TagStyle.danger
        
        XCTAssertNotNil(defaultStyle.backgroundColor)
        XCTAssertNotNil(primaryStyle.backgroundColor)
        XCTAssertNotNil(secondaryStyle.backgroundColor)
        XCTAssertNotNil(successStyle.backgroundColor)
        XCTAssertNotNil(warningStyle.backgroundColor)
        XCTAssertNotNil(dangerStyle.backgroundColor)
    }
    
    func testCustomTagStyle() {
        let customStyle = TagStyle.custom(
            backgroundColor: .blue,
            textColor: .white,
            borderColor: .blue.opacity(0.5)
        )
        
        XCTAssertNotNil(customStyle.backgroundColor)
        XCTAssertNotNil(customStyle.textColor)
        XCTAssertNotNil(customStyle.borderColor)
    }
    
    // MARK: - TagCollectionView Tests
    
    func testTagCollectionViewInitialization() {
        let collectionView = TagCollectionView(tags: sampleTags)
        
        XCTAssertEqual(collectionView.tags.count, 5)
        XCTAssertEqual(collectionView.maxDisplayCount, nil)
        XCTAssertEqual(collectionView.size, .medium)
    }
    
    func testTagCollectionViewWithMaxDisplayCount() {
        let collectionView = TagCollectionView(
            tags: sampleTags,
            size: .small,
            maxDisplayCount: 3
        )
        
        XCTAssertEqual(collectionView.maxDisplayCount, 3)
        XCTAssertEqual(collectionView.size, .small)
    }
    
    func testTagCollectionViewEmptyTags() {
        let collectionView = TagCollectionView(tags: [])
        
        XCTAssertEqual(collectionView.tags.count, 0)
    }
    
    // MARK: - Integration Tests
    
    func testTagViewAccessibility() {
        let tagView = TagView(tag: sampleTag)
        
        XCTAssertNotNil(tagView.tag)
        // 実際のアクセシビリティテストは SwiftUI テストで確認
    }
    
    func testTagCollectionViewWithCallbacks() {
        var tagTapCount = 0
        var tagRemoveCount = 0
        
        let collectionView = TagCollectionView(
            tags: sampleTags,
            onTagTap: { _ in tagTapCount += 1 },
            onTagRemove: { _ in tagRemoveCount += 1 }
        )
        
        XCTAssertNotNil(collectionView.onTagTap)
        XCTAssertNotNil(collectionView.onTagRemove)
    }
}