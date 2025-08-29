import Foundation
import SwiftUI
import Combine
import MindMapCore

@MainActor
public class TutorialViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var availableTutorials: [Tutorial] = []
    @Published public var currentTutorial: Tutorial? = nil
    @Published public var isShowingTutorial: Bool = false
    @Published public var currentStepIndex: Int = 0
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String?
    
    // MARK: - Computed Properties
    
    public var progress: Double {
        guard let tutorial = currentTutorial, !tutorial.steps.isEmpty else {
            return 0.0
        }
        return Double(currentStepIndex) / Double(tutorial.steps.count)
    }
    
    public var currentStep: TutorialStep? {
        guard let tutorial = currentTutorial,
              currentStepIndex < tutorial.steps.count else {
            return nil
        }
        return tutorial.steps[currentStepIndex]
    }
    
    public var isLastStep: Bool {
        guard let tutorial = currentTutorial else { return false }
        return currentStepIndex >= tutorial.steps.count - 1
    }
    
    public var canGoBack: Bool {
        return currentStepIndex > 0
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init() {
        setupBindings()
    }
    
    // MARK: - Public Methods
    
    public func loadTutorials() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // シミュレートされたチュートリアルの読み込み
            try await Task.sleep(nanoseconds: 300_000_000) // 0.3秒の遅延
            
            let tutorials = createSampleTutorials()
            availableTutorials = tutorials
            
        } catch {
            errorMessage = "チュートリアルの読み込みに失敗しました: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    public func startTutorial(_ tutorial: Tutorial) {
        currentTutorial = tutorial
        currentStepIndex = 0
        isShowingTutorial = true
    }
    
    public func nextStep() -> Bool {
        guard let tutorial = currentTutorial else { return false }
        
        if currentStepIndex < tutorial.steps.count - 1 {
            currentStepIndex += 1
            return true
        } else {
            // 最後のステップに到達した場合、チュートリアルを完了
            completeTutorial()
            return false
        }
    }
    
    public func previousStep() -> Bool {
        guard canGoBack else { return false }
        currentStepIndex -= 1
        return true
    }
    
    public func completeTutorial() {
        currentTutorial = nil
        isShowingTutorial = false
        currentStepIndex = 0
    }
    
    public func cancelTutorial() {
        currentTutorial = nil
        isShowingTutorial = false
        currentStepIndex = 0
    }
    
    public func skipTutorial() {
        completeTutorial()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        // 現在のチュートリアルが変更された時の処理
        $currentTutorial
            .sink { [weak self] tutorial in
                if tutorial == nil {
                    self?.currentStepIndex = 0
                }
            }
            .store(in: &cancellables)
    }
    
    private func createSampleTutorials() -> [Tutorial] {
        return [
            Tutorial(
                title: "基本操作チュートリアル",
                description: "AsaMindMapの基本的な操作方法を学習します",
                targetFeature: .basic,
                steps: [
                    TutorialStep(
                        order: 1,
                        instruction: "画面中央のノードをタップしてください",
                        highlightArea: CGRect(x: 200, y: 300, width: 150, height: 80),
                        action: .tap,
                        isCompleted: false
                    ),
                    TutorialStep(
                        order: 2,
                        instruction: "テキストを入力して、Enterキーを押してください",
                        highlightArea: CGRect(x: 100, y: 50, width: 250, height: 40),
                        action: .tap,
                        isCompleted: false
                    ),
                    TutorialStep(
                        order: 3,
                        instruction: "ノードから外側にドラッグして子ノードを作成してください",
                        highlightArea: CGRect(x: 200, y: 300, width: 150, height: 80),
                        action: .drag,
                        isCompleted: false
                    )
                ]
            ),
            Tutorial(
                title: "マインドマップ作成",
                description: "新しいマインドマップの作成方法を学習します",
                targetFeature: .mindMapCreation,
                steps: [
                    TutorialStep(
                        order: 1,
                        instruction: "「新規作成」ボタンをタップしてください",
                        highlightArea: CGRect(x: 300, y: 50, width: 80, height: 40),
                        action: .tap,
                        isCompleted: false
                    ),
                    TutorialStep(
                        order: 2,
                        instruction: "マインドマップのタイトルを入力してください",
                        highlightArea: CGRect(x: 50, y: 100, width: 300, height: 40),
                        action: .tap,
                        isCompleted: false
                    )
                ]
            ),
            Tutorial(
                title: "ノード編集",
                description: "ノードの編集とフォーマット方法を学習します",
                targetFeature: .nodeEditing,
                steps: [
                    TutorialStep(
                        order: 1,
                        instruction: "ノードをダブルタップして編集モードに入ってください",
                        highlightArea: CGRect(x: 200, y: 300, width: 150, height: 80),
                        action: .doubleTap,
                        isCompleted: false
                    ),
                    TutorialStep(
                        order: 2,
                        instruction: "ノードを長押ししてフォーマットオプションを表示してください",
                        highlightArea: CGRect(x: 200, y: 300, width: 150, height: 80),
                        action: .longPress,
                        isCompleted: false
                    )
                ]
            ),
            Tutorial(
                title: "ジェスチャー操作",
                description: "マルチタッチジェスチャーの使い方を学習します",
                targetFeature: .gestures,
                steps: [
                    TutorialStep(
                        order: 1,
                        instruction: "2本指でピンチしてズームしてください",
                        highlightArea: CGRect(x: 100, y: 200, width: 200, height: 200),
                        action: .pinch,
                        isCompleted: false
                    ),
                    TutorialStep(
                        order: 2,
                        instruction: "2本指でドラッグしてキャンバスを移動してください",
                        highlightArea: CGRect(x: 0, y: 0, width: 400, height: 600),
                        action: .drag,
                        isCompleted: false
                    )
                ]
            )
        ]
    }
}