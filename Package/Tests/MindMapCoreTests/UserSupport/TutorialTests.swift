import Testing
import Foundation
@testable import MindMapCore

struct TutorialTests {
    
    @Test("チュートリアル作成テスト")
    func testTutorialCreation() {
        // Given
        let id = UUID()
        let title = "初回利用チュートリアル"
        let description = "AsaMindMapの基本的な使い方を学習します"
        let targetFeature = TutorialFeature.mindMapCreation
        
        // When
        let tutorial = Tutorial(
            id: id,
            title: title,
            description: description,
            targetFeature: targetFeature,
            steps: []
        )
        
        // Then
        #expect(tutorial.id == id)
        #expect(tutorial.title == title)
        #expect(tutorial.description == description)
        #expect(tutorial.targetFeature == targetFeature)
        #expect(tutorial.steps.isEmpty)
        #expect(tutorial.isCompleted == true) // Empty tutorial is considered completed
    }
    
    @Test("チュートリアルステップ追加テスト")
    func testAddTutorialStep() {
        // Given
        var tutorial = Tutorial(
            id: UUID(),
            title: "テストチュートリアル",
            description: "テスト用",
            targetFeature: .nodeEditing,
            steps: []
        )
        
        let step = TutorialStep(
            order: 1,
            instruction: "画面中央をタップしてください",
            highlightArea: CGRect(x: 100, y: 100, width: 200, height: 200),
            action: .tap,
            isCompleted: false
        )
        
        // When
        tutorial.addStep(step)
        
        // Then
        #expect(tutorial.steps.count == 1)
        #expect(tutorial.steps.first?.instruction == "画面中央をタップしてください")
        #expect(tutorial.steps.first?.isCompleted == false)
    }
    
    @Test("チュートリアル進捗管理テスト")
    func testTutorialProgressTracking() {
        // Given
        var tutorial = Tutorial(
            id: UUID(),
            title: "進捗テスト",
            description: "進捗管理のテスト",
            targetFeature: .gestures,
            steps: [
                TutorialStep(order: 1, instruction: "ステップ1", highlightArea: .zero, action: .tap, isCompleted: false),
                TutorialStep(order: 2, instruction: "ステップ2", highlightArea: .zero, action: .drag, isCompleted: false)
            ]
        )
        
        // When
        tutorial.completeStep(at: 0)
        
        // Then
        #expect(tutorial.steps[0].isCompleted == true)
        #expect(tutorial.steps[1].isCompleted == false)
        #expect(tutorial.progress == 0.5) // 50% complete
        #expect(tutorial.isCompleted == false) // Not fully completed
        
        // When - complete all steps
        tutorial.completeStep(at: 1)
        
        // Then
        #expect(tutorial.isCompleted == true)
        #expect(tutorial.progress == 1.0) // 100% complete
    }
    
    @Test("チュートリアル完了条件テスト")
    func testTutorialCompletionConditions() {
        // Given
        let emptyTutorial = Tutorial(
            id: UUID(),
            title: "空のチュートリアル",
            description: "ステップがないチュートリアル",
            targetFeature: .basic,
            steps: []
        )
        
        // When/Then - Empty tutorial should be considered completed
        #expect(emptyTutorial.progress == 1.0)
        
        // Given
        let singleStepTutorial = Tutorial(
            id: UUID(),
            title: "単一ステップ",
            description: "1ステップのチュートリアル",
            targetFeature: .basic,
            steps: [
                TutorialStep(order: 1, instruction: "完了", highlightArea: .zero, action: .tap, isCompleted: true)
            ]
        )
        
        // Then
        #expect(singleStepTutorial.progress == 1.0)
    }
}