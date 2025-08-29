import Testing
import Foundation
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

struct TutorialViewModelTests {
    
    @Test("チュートリアルViewModelの初期化テスト")
    func testTutorialViewModelInitialization() {
        // When
        let viewModel = TutorialViewModel()
        
        // Then
        #expect(viewModel.availableTutorials.isEmpty)
        #expect(viewModel.currentTutorial == nil)
        #expect(viewModel.isShowingTutorial == false)
        #expect(viewModel.currentStepIndex == 0)
    }
    
    @Test("チュートリアル読み込みテスト")
    func testLoadTutorials() async {
        // Given
        let viewModel = TutorialViewModel()
        
        // When
        await viewModel.loadTutorials()
        
        // Then
        #expect(!viewModel.availableTutorials.isEmpty)
        #expect(viewModel.availableTutorials.count > 0)
    }
    
    @Test("チュートリアル開始テスト")
    func testStartTutorial() async {
        // Given
        let viewModel = TutorialViewModel()
        await viewModel.loadTutorials()
        
        guard let firstTutorial = viewModel.availableTutorials.first else {
            Issue.record("チュートリアルが読み込まれていません")
            return
        }
        
        // When
        viewModel.startTutorial(firstTutorial)
        
        // Then
        #expect(viewModel.currentTutorial?.id == firstTutorial.id)
        #expect(viewModel.isShowingTutorial == true)
        #expect(viewModel.currentStepIndex == 0)
    }
    
    @Test("ステップ進行テスト")
    func testStepProgression() async {
        // Given
        let viewModel = TutorialViewModel()
        await viewModel.loadTutorials()
        
        guard let tutorial = viewModel.availableTutorials.first(where: { !$0.steps.isEmpty }) else {
            Issue.record("ステップを持つチュートリアルが見つかりません")
            return
        }
        
        viewModel.startTutorial(tutorial)
        
        // When
        let canProceed = viewModel.nextStep()
        
        // Then
        #expect(canProceed == true)
        #expect(viewModel.currentStepIndex == 1)
    }
    
    @Test("チュートリアル完了テスト")
    func testTutorialCompletion() async {
        // Given
        let viewModel = TutorialViewModel()
        
        // 単一ステップのチュートリアルを作成
        let singleStepTutorial = Tutorial(
            title: "単一ステップテスト",
            description: "テスト用",
            targetFeature: .basic,
            steps: [
                TutorialStep(order: 1, instruction: "テストステップ", highlightArea: .zero, action: .tap, isCompleted: false)
            ]
        )
        
        viewModel.startTutorial(singleStepTutorial)
        
        // When
        _ = viewModel.nextStep() // ステップを完了
        
        // Then
        #expect(viewModel.isShowingTutorial == false) // チュートリアルが終了
    }
    
    @Test("チュートリアル中断テスト")
    func testTutorialCancellation() async {
        // Given
        let viewModel = TutorialViewModel()
        await viewModel.loadTutorials()
        
        guard let tutorial = viewModel.availableTutorials.first else {
            Issue.record("チュートリアルが見つかりません")
            return
        }
        
        viewModel.startTutorial(tutorial)
        
        // When
        viewModel.cancelTutorial()
        
        // Then
        #expect(viewModel.currentTutorial == nil)
        #expect(viewModel.isShowingTutorial == false)
        #expect(viewModel.currentStepIndex == 0)
    }
    
    @Test("進捗計算テスト")
    func testProgressCalculation() async {
        // Given
        let viewModel = TutorialViewModel()
        
        let multiStepTutorial = Tutorial(
            title: "マルチステップテスト",
            description: "テスト用",
            targetFeature: .nodeEditing,
            steps: [
                TutorialStep(order: 1, instruction: "ステップ1", highlightArea: .zero, action: .tap, isCompleted: false),
                TutorialStep(order: 2, instruction: "ステップ2", highlightArea: .zero, action: .drag, isCompleted: false),
                TutorialStep(order: 3, instruction: "ステップ3", highlightArea: .zero, action: .tap, isCompleted: false)
            ]
        )
        
        viewModel.startTutorial(multiStepTutorial)
        
        // When & Then
        #expect(viewModel.progress == 0.0) // 開始時は0%
        
        _ = viewModel.nextStep()
        #expect(viewModel.progress > 0.0) // 進捗が進む
        #expect(viewModel.progress < 1.0) // まだ完了していない
        
        _ = viewModel.nextStep()
        #expect(viewModel.progress > 0.5) // 半分以上進んでいる
    }
}