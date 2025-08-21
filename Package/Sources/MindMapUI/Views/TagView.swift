import SwiftUI
import MindMapCore

// MARK: - Tag View
@available(iOS 16.0, macOS 14.0, *)
public struct TagView: View {
    
    // MARK: - Properties
    let tag: Tag
    let size: TagSize
    let style: TagStyle
    let onTap: (() -> Void)?
    let onRemove: (() -> Void)?
    
    // MARK: - Initializers
    public init(
        tag: Tag,
        size: TagSize = .medium,
        style: TagStyle = .default,
        onTap: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.tag = tag
        self.size = size
        self.style = style
        self.onTap = onTap
        self.onRemove = onRemove
    }
    
    // MARK: - Body
    public var body: some View {
        HStack(spacing: size.spacing) {
            // Tag Icon
            if size.showIcon {
                Image(systemName: "tag.fill")
                    .font(.system(size: size.iconSize))
                    .foregroundColor(style.iconColor)
            }
            
            // Tag Text
            Text(tag.name)
                .font(.system(size: size.fontSize, weight: size.fontWeight))
                .foregroundColor(style.textColor)
                .lineLimit(1)
            
            // Remove Button
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: size.removeIconSize, weight: .medium))
                        .foregroundColor(style.removeButtonColor)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("タグを削除")
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(style.backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(style.borderColor, lineWidth: style.borderWidth)
        )
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("タグ: \(tag.name)")
        .accessibilityHint(onTap != nil ? "タップして詳細表示" : "")
    }
}

// MARK: - Tag Size
public enum TagSize {
    case small
    case medium
    case large
    
    var fontSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }
    
    var fontWeight: Font.Weight {
        switch self {
        case .small: return .medium
        case .medium: return .medium
        case .large: return .semibold
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
    
    var removeIconSize: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 3
        case .large: return 4
        }
    }
    
    var showIcon: Bool {
        switch self {
        case .small: return false
        case .medium, .large: return true
        }
    }
}

// MARK: - Tag Style
public enum TagStyle {
    case `default`
    case primary
    case secondary
    case success
    case warning
    case danger
    case custom(backgroundColor: Color, textColor: Color, borderColor: Color)
    
    var backgroundColor: Color {
        switch self {
        case .default: return Color.gray.opacity(0.1)
        case .primary: return Color.blue.opacity(0.1)
        case .secondary: return Color.purple.opacity(0.1)
        case .success: return Color.green.opacity(0.1)
        case .warning: return Color.orange.opacity(0.1)
        case .danger: return Color.red.opacity(0.1)
        case .custom(let backgroundColor, _, _): return backgroundColor
        }
    }
    
    var textColor: Color {
        switch self {
        case .default: return .primary
        case .primary: return .blue
        case .secondary: return .purple
        case .success: return .green
        case .warning: return .orange
        case .danger: return .red
        case .custom(_, let textColor, _): return textColor
        }
    }
    
    var borderColor: Color {
        switch self {
        case .default: return Color.gray.opacity(0.3)
        case .primary: return Color.blue.opacity(0.3)
        case .secondary: return Color.purple.opacity(0.3)
        case .success: return Color.green.opacity(0.3)
        case .warning: return Color.orange.opacity(0.3)
        case .danger: return Color.red.opacity(0.3)
        case .custom(_, _, let borderColor): return borderColor
        }
    }
    
    var borderWidth: CGFloat {
        return 1
    }
    
    var iconColor: Color {
        return textColor.opacity(0.7)
    }
    
    var removeButtonColor: Color {
        return textColor.opacity(0.6)
    }
}

// MARK: - Tag Collection View
@available(iOS 16.0, macOS 14.0, *)
public struct TagCollectionView: View {
    
    // MARK: - Properties
    let tags: [Tag]
    let size: TagSize
    let maxDisplayCount: Int?
    let spacing: CGFloat
    let onTagTap: ((Tag) -> Void)?
    let onTagRemove: ((Tag) -> Void)?
    let onShowAll: (() -> Void)?
    
    // MARK: - Initializers
    public init(
        tags: [Tag],
        size: TagSize = .medium,
        maxDisplayCount: Int? = nil,
        spacing: CGFloat = 4,
        onTagTap: ((Tag) -> Void)? = nil,
        onTagRemove: ((Tag) -> Void)? = nil,
        onShowAll: (() -> Void)? = nil
    ) {
        self.tags = tags
        self.size = size
        self.maxDisplayCount = maxDisplayCount
        self.spacing = spacing
        self.onTagTap = onTagTap
        self.onTagRemove = onTagRemove
        self.onShowAll = onShowAll
    }
    
    // MARK: - Body
    public var body: some View {
        if tags.isEmpty {
            EmptyView()
        } else {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: spacing) {
                ForEach(displayedTags, id: \.id) { tag in
                    TagView(
                        tag: tag,
                        size: size,
                        style: tagStyle(for: tag),
                        onTap: { onTagTap?(tag) },
                        onRemove: onTagRemove != nil ? { onTagRemove?(tag) } : nil
                    )
                }
                
                // More indicator
                if shouldShowMoreIndicator {
                    moreIndicator
                }
            }
        }
    }
    
    // MARK: - Private Properties
    private var displayedTags: [Tag] {
        guard let maxCount = maxDisplayCount else { return tags }
        return Array(tags.prefix(maxCount))
    }
    
    private var shouldShowMoreIndicator: Bool {
        guard let maxCount = maxDisplayCount else { return false }
        return tags.count > maxCount
    }
    
    private var remainingCount: Int {
        guard let maxCount = maxDisplayCount else { return 0 }
        return max(0, tags.count - maxCount)
    }
    
    // MARK: - Private Views
    @ViewBuilder
    private var moreIndicator: some View {
        Button(action: { onShowAll?() }) {
            HStack(spacing: 2) {
                Text("+\(remainingCount)")
                    .font(.system(size: size.fontSize, weight: size.fontWeight))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(remainingCount)個の追加タグを表示")
    }
    
    // MARK: - Private Methods
    private func tagStyle(for tag: Tag) -> TagStyle {
        let colorIndex = abs(tag.name.hashValue) % 6
        switch colorIndex {
        case 0: return .primary
        case 1: return .secondary
        case 2: return .success
        case 3: return .warning
        case 4: return .danger
        default: return .default
        }
    }
}

// MARK: - Preview
@available(iOS 16.0, macOS 14.0, *)
struct TagView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTags = [
            Tag(id: UUID(), name: "重要", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "プロジェクト", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "アイデア", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "TODO", createdAt: Date(), updatedAt: Date()),
            Tag(id: UUID(), name: "会議", createdAt: Date(), updatedAt: Date())
        ]
        
        VStack(spacing: 20) {
            // Individual tag views
            VStack(alignment: .leading, spacing: 8) {
                Text("Individual Tags")
                    .font(.headline)
                
                HStack {
                    TagView(tag: sampleTags[0], size: .small)
                    TagView(tag: sampleTags[1], size: .medium)
                    TagView(tag: sampleTags[2], size: .large)
                }
            }
            
            // Tag collection
            VStack(alignment: .leading, spacing: 8) {
                Text("Tag Collection")
                    .font(.headline)
                
                TagCollectionView(
                    tags: sampleTags,
                    maxDisplayCount: 3,
                    onTagTap: { tag in
                        print("Tapped: \(tag.name)")
                    }
                )
            }
            
            Spacer()
        }
        .padding()
    }
}