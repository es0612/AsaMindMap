import SwiftUI
import MindMapCore
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Node View
@available(iOS 16.0, macOS 14.0, *)
public struct NodeView: View {
    
    // MARK: - Properties
    let node: Node
    let tags: [Tag]
    let isSelected: Bool
    let isEditing: Bool
    let isFocused: Bool
    let isFocusMode: Bool
    let media: [Media]
    let showDetailedTags: Bool
    let onAddMedia: (() -> Void)?
    let onMediaTap: ((Media) -> Void)?
    let onRemoveMedia: ((Media) -> Void)?
    let onToggleTask: (() -> Void)?
    let onToggleCompletion: (() -> Void)?
    let onTagTap: ((Tag) -> Void)?
    let onRemoveTag: ((Tag) -> Void)?
    let onShowAllTags: (() -> Void)?
    
    @State private var editingText: String = ""
    @State private var showingMediaPicker = false
    @State private var showingDetailedTags = false
    @FocusState private var isTextFieldFocused: Bool
    
    // MARK: - Computed Properties
    private var nodeOpacity: Double {
        if isFocusMode {
            return isFocused ? 1.0 : 0.3
        }
        return 1.0
    }
    
    private var borderColor: Color {
        if isSelected {
            return .blue
        } else if isFocused && isFocusMode {
            return .orange
        } else {
            return Color.primary.opacity(0.3)
        }
    }
    
    private var borderWidth: CGFloat {
        if isSelected {
            return 3
        } else if isFocused && isFocusMode {
            return 2
        } else {
            return 1
        }
    }
    
    private var backgroundColor: Color {
        if node.isTask && node.isCompleted {
            return Color.green.opacity(0.2)
        } else if node.isTask {
            return Color.blue.opacity(0.1)
        } else {
            return Color.white
        }
    }
    
    // MARK: - Initializers
    public init(
        node: Node,
        tags: [Tag] = [],
        isSelected: Bool = false,
        isEditing: Bool = false,
        isFocused: Bool = false,
        isFocusMode: Bool = false,
        media: [Media] = [],
        showDetailedTags: Bool = false,
        onAddMedia: (() -> Void)? = nil,
        onMediaTap: ((Media) -> Void)? = nil,
        onRemoveMedia: ((Media) -> Void)? = nil,
        onToggleTask: (() -> Void)? = nil,
        onToggleCompletion: (() -> Void)? = nil,
        onTagTap: ((Tag) -> Void)? = nil,
        onRemoveTag: ((Tag) -> Void)? = nil,
        onShowAllTags: (() -> Void)? = nil
    ) {
        self.node = node
        self.tags = tags
        self.isSelected = isSelected
        self.isEditing = isEditing
        self.isFocused = isFocused
        self.isFocusMode = isFocusMode
        self.media = media
        self.showDetailedTags = showDetailedTags
        self.onAddMedia = onAddMedia
        self.onMediaTap = onMediaTap
        self.onRemoveMedia = onRemoveMedia
        self.onToggleTask = onToggleTask
        self.onToggleCompletion = onToggleCompletion
        self.onTagTap = onTagTap
        self.onRemoveTag = onRemoveTag
        self.onShowAllTags = onShowAllTags
    }
    
    // MARK: - Body
    public var body: some View {
        ZStack {
            // Node Background
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .stroke(borderColor, lineWidth: borderWidth)
                .shadow(
                    color: isSelected ? .blue.opacity(0.3) : .black.opacity(0.1),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: 1
                )
            
            // Node Content
            VStack(spacing: 8) {
                // Main content row
                HStack(spacing: 8) {
                    // Task Checkbox
                    if node.isTask {
                        taskCheckbox
                    }
                    
                    // Text Content
                    textContent
                    
                    // Action Buttons
                    if isSelected {
                        actionButtons
                    }
                }
                
                // Tags Display
                if !tags.isEmpty && (showDetailedTags || showingDetailedTags) {
                    tagDetailView
                } else if !tags.isEmpty {
                    tagSummaryView
                }
                
                // Media Display
                if !media.isEmpty {
                    MediaDisplayView(
                        media: media,
                        maxDisplayCount: 3,
                        onMediaTap: onMediaTap,
                        onRemoveMedia: onRemoveMedia
                    )
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .opacity(nodeOpacity)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .optimizedAnimation(AnimationConfiguration.nodeSelection(), value: isSelected)
        .optimizedAnimation(AnimationConfiguration.nodeSelection(duration: 0.3), value: nodeOpacity)
        .onAppear {
            editingText = node.text
        }
        .onChange(of: isEditing) { editing in
            if editing {
                editingText = node.text
                isTextFieldFocused = true
            } else {
                isTextFieldFocused = false
            }
        }
        .onTapGesture(count: 2) {
            if node.isTask {
                onToggleCompletion?()
            }
        }
        // Accessibility
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(accessibilityHint)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Task Checkbox
    @ViewBuilder
    private var taskCheckbox: some View {
        Button(action: {
            onToggleCompletion?()
        }) {
            ZStack {
                Circle()
                    .stroke(node.isCompleted ? Color.green : Color.gray, lineWidth: 2)
                    .frame(width: 18, height: 18)
                
                if node.isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(node.isCompleted ? "完了済みタスク" : "未完了タスク")
        .accessibilityHint("タップして完了状態を切り替え")
    }
    
    // MARK: - Text Content
    @ViewBuilder
    private var textContent: some View {
        if isEditing {
            TextField("ノードテキスト", text: $editingText)
                .focused($isTextFieldFocused)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 14, weight: .medium))
                .multilineTextAlignment(.center)
                .onSubmit {
                    // Text update will be handled by parent view
                }
        } else {
            Text(node.text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .strikethrough(node.isTask && node.isCompleted)
        }
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 4) {
            // Task Toggle Button
            if onToggleTask != nil {
                Button(action: {
                    onToggleTask?()
                }) {
                    Image(systemName: node.isTask ? "square.fill" : "square")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(node.isTask ? .blue : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(node.isTask ? "タスクを解除" : "タスクに変換")
            }
            
            // Media Button
            if onAddMedia != nil {
                Button(action: {
                    onAddMedia?()
                }) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("メディアを追加")
            }
        }
    }
    
    // MARK: - Tag Summary View
    @ViewBuilder
    private var tagSummaryView: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                showingDetailedTags.toggle()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: "tag")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                
                Text("\(tags.count)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                if tags.count > 0 {
                    Text("・\(tags.prefix(2).map(\.name).joined(separator: "・"))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(tags.count)個のタグ")
        .accessibilityHint("タップして詳細表示")
    }
    
    // MARK: - Tag Detail View
    @ViewBuilder
    private var tagDetailView: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("タグ")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingDetailedTags = false
                    }
                }) {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            TagCollectionView(
                tags: tags,
                size: .small,
                maxDisplayCount: showDetailedTags ? nil : 4,
                onTagTap: onTagTap,
                onTagRemove: onRemoveTag,
                onShowAll: onShowAllTags
            )
        }
        .padding(.top, 4)
    }
    
    // MARK: - Accessibility
    private var accessibilityLabel: String {
        // アクセシビリティヘルパーを使用
        return node.accessibilityLabel(tags: tags)
    }
    
    private var accessibilityHint: String {
        // アクセシビリティヘルパーを使用
        if isEditing {
            return AccessibilityHelper.generateEditingHint()
        } else {
            return node.accessibilityHint
        }
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 16.0, macOS 14.0, *)
struct NodeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Regular node
            NodeView(
                node: Node(
                    id: UUID(),
                    text: "サンプルノード",
                    position: .zero
                ),
                isSelected: false,
                isEditing: false,
                isFocused: true,
                isFocusMode: false,
                media: [],
                onAddMedia: nil,
                onMediaTap: nil,
                onRemoveMedia: nil
            )
            
            // Selected node
            NodeView(
                node: Node(
                    id: UUID(),
                    text: "選択されたノード",
                    position: .zero
                ),
                isSelected: true,
                isEditing: false,
                isFocused: true,
                isFocusMode: false,
                media: [],
                onAddMedia: { print("Add media") },
                onMediaTap: nil,
                onRemoveMedia: nil
            )
            
            // Task node
            NodeView(
                node: Node(
                    id: UUID(),
                    text: "タスクノード",
                    position: .zero,
                    isTask: true,
                    isCompleted: false
                ),
                isSelected: false,
                isEditing: false,
                isFocused: true,
                isFocusMode: false,
                media: [],
                onAddMedia: nil,
                onMediaTap: nil,
                onRemoveMedia: nil
            )
            
            // Node with media
            NodeView(
                node: Node(
                    id: UUID(),
                    text: "メディア付きノード",
                    position: .zero
                ),
                isSelected: false,
                isEditing: false,
                isFocused: true,
                isFocusMode: false,
                media: [
                    Media(type: .image, fileName: "test.jpg"),
                    Media(type: .link, url: "https://example.com")
                ],
                onAddMedia: nil,
                onMediaTap: { _ in print("Media tapped") },
                onRemoveMedia: { _ in print("Remove media") }
            )
            
            // Editing node
            NodeView(
                node: Node(
                    id: UUID(),
                    text: "編集中のノード",
                    position: .zero
                ),
                isSelected: false,
                isEditing: true,
                isFocused: true,
                isFocusMode: false,
                media: [],
                onAddMedia: nil,
                onMediaTap: nil,
                onRemoveMedia: nil
            )
        }
        .padding()
        .previewDisplayName("Node Variations")
    }
}
#endif