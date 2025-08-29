import SwiftUI
import MindMapCore

public struct HelpDetailView: View {
    
    let content: HelpContent
    @Environment(\.dismiss) private var dismiss
    
    public init(content: HelpContent) {
        self.content = content
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // ヘッダー
                headerSection
                
                // メインコンテンツ
                mainContentSection
                
                // ステップリスト
                if !content.steps.isEmpty {
                    stepsSection
                }
                
                // フィードバックボタン
                feedbackSection
            }
            .padding()
        }
        .navigationTitle(content.title)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        #endif
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(content.category.displayName)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.1))
                    )
                    .foregroundColor(.blue)
                
                Spacer()
                
                if content.isMultiStep {
                    Label("\(content.stepCount)ステップ", systemImage: "list.number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var mainContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("概要")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content.content)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("手順")
                .font(.headline)
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(content.steps.enumerated()), id: \.element.id) { index, step in
                    HelpStepCard(step: step, stepNumber: index + 1)
                }
            }
        }
    }
    
    private var feedbackSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 8)
            
            Text("この記事は役に立ちましたか？")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 20) {
                Button(action: sendPositiveFeedback) {
                    HStack {
                        Image(systemName: "hand.thumbsup")
                        Text("はい")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
                    .foregroundColor(.green)
                }
                
                Button(action: sendNegativeFeedback) {
                    HStack {
                        Image(systemName: "hand.thumbsdown")
                        Text("いいえ")
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.red.opacity(0.1))
                    )
                    .foregroundColor(.red)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Actions
    
    private func sendPositiveFeedback() {
        // フィードバック送信ロジック
        // TODO: フィードバック送信機能の実装
    }
    
    private func sendNegativeFeedback() {
        // ネガティブフィードバック送信ロジック
        // TODO: フィードバック送信機能の実装
    }
}

// MARK: - Supporting Views

struct HelpStepCard: View {
    let step: HelpStep
    let stepNumber: Int
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // ステップ番号
            Text("\(stepNumber)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(Color.blue)
                )
            
            // ステップ内容
            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let imageName = step.imageName, !imageName.isEmpty {
                    AsyncImage(url: URL(string: imageName)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 120)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.title)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(maxHeight: 200)
                    .clipped()
                    .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        HelpDetailView(
            content: HelpContent(
                title: "マインドマップの作成方法",
                content: "新しいマインドマップを作成するには、「新規作成」ボタンをタップしてください。このガイドでは、基本的な作成手順から、効果的なマインドマップを作るためのコツまでを詳しく説明します。",
                category: .gettingStarted,
                steps: [
                    HelpStep(
                        order: 1,
                        title: "新規作成をタップ",
                        description: "メイン画面の右上にある「+」ボタンまたは「新規作成」ボタンをタップします。"
                    ),
                    HelpStep(
                        order: 2,
                        title: "タイトルを入力",
                        description: "マインドマップのタイトルを入力してください。後から変更することも可能です。"
                    ),
                    HelpStep(
                        order: 3,
                        title: "中央ノードを編集",
                        description: "中央のノードをダブルタップして、メインテーマを入力します。これがマインドマップの中心となります。"
                    )
                ]
            )
        )
    }
}