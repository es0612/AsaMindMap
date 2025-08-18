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
    let isSelected: Bool
    let isEditing: Bool
    let isFocused: Bool
    let isFocusMode: Bool
    
    @State private var editingText: String = ""
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
            HStack(spacing: 8) {
                // Task Checkbox
                if node.isTask {
                    taskCheckbox
                }
                
                // Text Content
                textContent
                
                // Media Indicator
                if !node.mediaIDs.isEmpty {
                    mediaIndicator
                }
                
                // Tag Indicators
                if !node.tagIDs.isEmpty {
                    tagIndicators
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .opacity(nodeOpacity)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .animation(.easeInOut(duration: 0.3), value: nodeOpacity)
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
            // Task completion toggle - will be implemented in task management
        }) {
            Image(systemName: node.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(node.isCompleted ? .green : .gray)
                .font(.system(size: 16, weight: .medium))
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
    
    // MARK: - Media Indicator
    @ViewBuilder
    private var mediaIndicator: some View {
        HStack(spacing: 2) {
            Image(systemName: "paperclip")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text("\(node.mediaIDs.count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(node.mediaIDs.count)個のメディア添付")
    }
    
    // MARK: - Tag Indicators
    @ViewBuilder
    private var tagIndicators: some View {
        HStack(spacing: 2) {
            Image(systemName: "tag")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            Text("\(node.tagIDs.count)")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(node.tagIDs.count)個のタグ")
    }
    
    // MARK: - Accessibility
    private var accessibilityLabel: String {
        var label = node.text
        
        if node.isTask {
            label += node.isCompleted ? "、完了済みタスク" : "、未完了タスク"
        }
        
        if !node.mediaIDs.isEmpty {
            label += "、\(node.mediaIDs.count)個のメディア添付"
        }
        
        if !node.tagIDs.isEmpty {
            label += "、\(node.tagIDs.count)個のタグ"
        }
        
        return label
    }
    
    private var accessibilityHint: String {
        var hints: [String] = []
        
        if isEditing {
            hints.append("テキストを編集中")
        } else {
            hints.append("ダブルタップで編集")
        }
        
        hints.append("長押しでブランチにフォーカス")
        
        return hints.joined(separator: "、")
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
                isFocusMode: false
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
                isFocusMode: false
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
                isFocusMode: false
            )
            
            // Completed task node
            NodeView(
                node: Node(
                    id: UUID(),
                    text: "完了済みタスク",
                    position: .zero,
                    isTask: true,
                    isCompleted: true
                ),
                isSelected: false,
                isEditing: false,
                isFocused: true,
                isFocusMode: false
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
                isFocusMode: false
            )
        }
        .padding()
        .previewDisplayName("Node Variations")
    }
}
#endif