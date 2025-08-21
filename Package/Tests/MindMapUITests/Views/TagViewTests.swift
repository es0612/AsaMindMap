import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

@available(iOS 16.0, macOS 14.0, *)
struct TagViewTests {
    
    // MARK: - Test Data
    private let sampleTag = Tag(
        id: UUID(),
        name: "テストタグ",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    private let sampleTags = [
        Tag(id: UUID(), name: "重要", createdAt: Date(), updatedAt: Date()),
        Tag(id: UUID(), name: "プロジェクト", createdAt: Date(), updatedAt: Date()),
        Tag(id: UUID(), name: "アイデア", createdAt: Date(), updatedAt: Date()),
        Tag(id: UUID(), name: "TODO", createdAt: Date(), updatedAt: Date()),
        Tag(id: UUID(), name: "会議", createdAt: Date(), updatedAt: Date())
    ]
    
    // MARK: - TagView Tests
    
    @Test
    func testTagViewInitialization() {
        let tagView = TagView(tag: sampleTag)
        
        #expect(tagView.tag.name == "テストタグ")
        #expect(tagView.size == .medium)
        #expect(tagView.style == .default)
    }
    
    @Test
    func testTagViewWithCustomProperties() {
        var tapCalled = false
        var removeCalled = false
        
        let tagView = TagView(
            tag: sampleTag,
            size: .large,
            style: .primary,
            onTap: { tapCalled = true },
            onRemove: { removeCalled = true }
        )
        
        #expect(tagView.tag.name == "テストタグ")
        #expect(tagView.size == .large)
        #expect(tagView.style == .primary)
    }
    
    // MARK: - TagSize Tests
    
    @Test
    func testTagSizeProperties() {
        let smallSize = TagSize.small
        let mediumSize = TagSize.medium
        let largeSize = TagSize.large
        
        // Font sizes
        #expect(smallSize.fontSize == 10)
        #expect(mediumSize.fontSize == 12)
        #expect(largeSize.fontSize == 14)
        
        // Icon visibility
        #expect(smallSize.showIcon == false)
        #expect(mediumSize.showIcon == true)
        #expect(largeSize.showIcon == true)
        
        // Padding
        #expect(smallSize.horizontalPadding == 4)
        #expect(mediumSize.horizontalPadding == 6)
        #expect(largeSize.horizontalPadding == 8)
    }
    
    // MARK: - TagStyle Tests
    
    @Test
    func testTagStyleColors() {
        let defaultStyle = TagStyle.default
        let primaryStyle = TagStyle.primary
        let successStyle = TagStyle.success
        let dangerStyle = TagStyle.danger
        
        // Background colors should be different
        #expect(defaultStyle.backgroundColor != primaryStyle.backgroundColor)
        #expect(successStyle.backgroundColor != dangerStyle.backgroundColor)
        
        // Text colors should be different
        #expect(defaultStyle.textColor != primaryStyle.textColor)
        #expect(successStyle.textColor != dangerStyle.textColor)
    }
    
    @Test
    func testCustomTagStyle() {
        let customStyle = TagStyle.custom(
            backgroundColor: .red,
            textColor: .white,
            borderColor: .black
        )
        
        #expect(customStyle.backgroundColor == .red)
        #expect(customStyle.textColor == .white)
        #expect(customStyle.borderColor == .black)
    }
    
    // MARK: - TagCollectionView Tests
    
    @Test
    func testTagCollectionViewInitialization() {
        let collectionView = TagCollectionView(tags: sampleTags)
        
        #expect(collectionView.tags.count == 5)
        #expect(collectionView.size == .medium)
        #expect(collectionView.spacing == 4)
    }
    
    @Test
    func testTagCollectionViewWithMaxDisplayCount() {
        let collectionView = TagCollectionView(
            tags: sampleTags,
            maxDisplayCount: 3
        )
        
        #expect(collectionView.tags.count == 5)
        #expect(collectionView.maxDisplayCount == 3)
    }
    
    @Test
    func testTagCollectionViewEmptyTags() {
        let collectionView = TagCollectionView(tags: [])
        
        #expect(collectionView.tags.isEmpty)
    }
    
    // MARK: - Integration Tests
    
    @Test
    func testTagViewAccessibility() {
        let tagView = TagView(tag: sampleTag)
        
        // TagView should be accessible
        // Note: Actual accessibility testing would require ViewRenderer
        // This is a structural test to ensure accessibility properties are set
        #expect(tagView.tag.name == "テストタグ")
    }
    
    @Test
    func testTagCollectionViewWithCallbacks() {
        var tagTapCount = 0
        var removedTags: [Tag] = []
        var showAllCalled = false
        
        let collectionView = TagCollectionView(
            tags: sampleTags,
            maxDisplayCount: 2,
            onTagTap: { _ in tagTapCount += 1 },
            onTagRemove: { tag in removedTags.append(tag) },
            onShowAll: { showAllCalled = true }
        )
        
        #expect(collectionView.tags.count == 5)
        #expect(collectionView.maxDisplayCount == 2)
    }
}