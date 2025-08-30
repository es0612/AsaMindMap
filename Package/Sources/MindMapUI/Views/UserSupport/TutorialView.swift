import SwiftUI
import MindMapCore

public struct TutorialView: View {
    
    @StateObject private var viewModel = TutorialViewModel()
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
NavigationView {
            VStack(spacing: 0) {
                if viewModel.isShowingTutorial {
                    // アクティブなチュートリアル表示
                    activeTutorialView
                } else {
                    // チュートリアル選択画面
                    tutorialSelectionView
                }
            }
            .navigationTitle("チュートリアル")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                #else
                ToolbarItem(placement: .primaryAction) {
                #endif
                    if viewModel.isShowingTutorial {
                        Button("終了") {
                            viewModel.cancelTutorial()
                        }
                    } else {
                        Button("完了") {
                            dismiss()
                        }
                    }
                }
            }
            .task {
                await viewModel.loadTutorials()
            }
        }
    }
    
    // MARK: - Tutorial Selection View
    
    private var tutorialSelectionView: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else {
                tutorialListView
            }
        }
        .padding()
    }
    
    private var tutorialListView: some View {
        VStack(spacing: 16) {
            Text("学習したいトピックを選択してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.availableTutorials) { tutorial in
                    TutorialCard(tutorial: tutorial) {
                        viewModel.startTutorial(tutorial)
                    }
                }
            }
        }
    }
    
    // MARK: - Active Tutorial View
    
    private var activeTutorialView: some View {
        VStack(spacing: 0) {
            // プログレスバー
            progressBar
            
            // チュートリアル内容
            Spacer()
            
            if let currentStep = viewModel.currentStep {
                tutorialStepView(step: currentStep)
            }
            
            Spacer()
            
            // ナビゲーションボタン
            navigationButtons
        }
        .background(Color.black.opacity(0.3)) // 半透明オーバーレイ
    }
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            HStack {
                Text(viewModel.currentTutorial?.title ?? "チュートリアル")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(viewModel.currentStepIndex + 1) / \(viewModel.currentTutorial?.steps.count ?? 0)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            ProgressView(value: viewModel.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .background(Color.white.opacity(0.3))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.black.opacity(0.6))
    }
    
    private func tutorialStepView(step: TutorialStep) -> some View {
        VStack(spacing: 20) {
            // ハイライト領域表示（シミュレーション）
            tutorialHighlight(for: step)
            
            // 指示カード
            instructionCard(step: step)
        }
    }
    
    private func tutorialHighlight(for step: TutorialStep) -> some View {
        GeometryReader { geometry in
            ZStack {
                // 暗いオーバーレイ
                Rectangle()
                    .fill(Color.black.opacity(0.3))
                    .ignoresSafeArea()
                
                // ハイライト領域
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.blue, lineWidth: 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                    )
                    .frame(
                        width: step.highlightArea.width,
                        height: step.highlightArea.height
                    )
                    .position(
                        x: step.highlightArea.midX,
                        y: step.highlightArea.midY
                    )
                    .animation(.easeInOut(duration: 0.5), value: step.id)
                
                // アクションインジケーター
                actionIndicator(for: step)
                    .position(
                        x: step.highlightArea.midX,
                        y: step.highlightArea.midY
                    )
            }
        }
    }
    
    private func actionIndicator(for step: TutorialStep) -> some View {
        Group {
            switch step.action {
            case .tap:
                tapIndicator
            case .drag:
                dragIndicator
            case .pinch:
                pinchIndicator
            case .longPress:
                longPressIndicator
            case .swipe:
                swipeIndicator
            case .doubleTap:
                doubleTapIndicator
            }
        }
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: step.id)
    }
    
    private var tapIndicator: some View {
        Circle()
            .fill(Color.blue.opacity(0.6))
            .frame(width: 30, height: 30)
            .scaleEffect(1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: UUID())
    }
    
    private var dragIndicator: some View {
        HStack(spacing: 4) {
            Circle().fill(Color.blue).frame(width: 8, height: 8)
            Circle().fill(Color.blue.opacity(0.7)).frame(width: 8, height: 8)
            Circle().fill(Color.blue.opacity(0.4)).frame(width: 8, height: 8)
        }
    }
    
    private var pinchIndicator: some View {
        HStack(spacing: 20) {
            Circle().fill(Color.blue).frame(width: 20, height: 20)
            Circle().fill(Color.blue).frame(width: 20, height: 20)
        }
        .scaleEffect(0.8)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
    }
    
    private var longPressIndicator: some View {
        Circle()
            .strokeBorder(Color.blue, lineWidth: 3)
            .frame(width: 40, height: 40)
            .overlay(
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .scaleEffect(0.7)
            )
    }
    
    private var swipeIndicator: some View {
        Image(systemName: "arrow.right")
            .font(.title2)
            .foregroundColor(.blue)
            .offset(x: -10)
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: UUID())
    }
    
    private var doubleTapIndicator: some View {
        VStack {
            Circle().fill(Color.blue.opacity(0.6)).frame(width: 25, height: 25)
            Circle().fill(Color.blue.opacity(0.6)).frame(width: 25, height: 25)
        }
        .animation(.easeInOut(duration: 0.6).repeatForever(), value: UUID())
    }
    
    private func instructionCard(step: TutorialStep) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(step.instruction)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
            
            HStack {
                Image(systemName: actionIcon(for: step.action))
                    .font(.title3)
                    .foregroundColor(.blue)
                
                Text(step.action.displayName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.primary.opacity(0.1))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if viewModel.canGoBack {
                Button("戻る") {
                    _ = viewModel.previousStep()
                }
                .buttonStyle(TutorialButtonStyle(isPrimary: false))
            }
            
            Spacer()
            
            Button("スキップ") {
                viewModel.skipTutorial()
            }
            .buttonStyle(TutorialButtonStyle(isPrimary: false))
            
            Button(viewModel.isLastStep ? "完了" : "次へ") {
                _ = viewModel.nextStep()
            }
            .buttonStyle(TutorialButtonStyle(isPrimary: true))
        }
        .padding()
        .background(Color.primary.opacity(0.05))
    }
    
    // MARK: - Loading & Error Views
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("チュートリアルを読み込んでいます...")
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack {
            Image(systemName: "exclamationmark.triangle")
                .font(.title)
                .foregroundColor(.orange)
            
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Button("再試行") {
                Task {
                    await viewModel.loadTutorials()
                }
            }
            .padding(.top, 16)
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    private func actionIcon(for action: TutorialAction) -> String {
        switch action {
        case .tap: return "hand.tap"
        case .drag: return "hand.draw"
        case .pinch: return "hand.pinch"
        case .longPress: return "hand.press"
        case .swipe: return "hand.wave"
        case .doubleTap: return "hand.tap.fill"
        }
    }
}

// MARK: - Supporting Views

struct TutorialCard: View {
    let tutorial: Tutorial
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(tutorial.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(tutorial.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                
                HStack {
                    Label(tutorial.targetFeature.displayName, systemImage: featureIcon(for: tutorial.targetFeature))
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                    
                    Text("\(tutorial.steps.count)ステップ")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.primary.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.primary.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func featureIcon(for feature: TutorialFeature) -> String {
        switch feature {
        case .mindMapCreation: return "plus.circle"
        case .nodeEditing: return "pencil.circle"
        case .gestures: return "hand.raised"
        case .basic: return "graduationcap"
        case .mediaAttachment: return "paperclip"
        case .sharing: return "square.and.arrow.up"
        case .export: return "square.and.arrow.down"
        }
    }
}

struct TutorialButtonStyle: ButtonStyle {
    let isPrimary: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline)
            .fontWeight(isPrimary ? .semibold : .regular)
            .foregroundColor(isPrimary ? .white : .blue)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPrimary ? Color.blue : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue, lineWidth: isPrimary ? 0 : 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    TutorialView()
}