import Testing
import Foundation
@testable import MindMapCore

struct OnboardingTests {
    
    @Test("オンボーディングフロー作成テスト")
    func testOnboardingFlowCreation() {
        // Given
        let id = UUID()
        let name = "初回起動オンボーディング"
        let description = "アプリの基本的な使い方を紹介します"
        let targetAudience = OnboardingAudience.firstTimeUser
        
        // When
        let onboardingFlow = OnboardingFlow(
            id: id,
            name: name,
            description: description,
            targetAudience: targetAudience,
            screens: [],
            isCompleted: false,
            currentScreenIndex: 0
        )
        
        // Then
        #expect(onboardingFlow.id == id)
        #expect(onboardingFlow.name == name)
        #expect(onboardingFlow.description == description)
        #expect(onboardingFlow.targetAudience == targetAudience)
        #expect(onboardingFlow.screens.isEmpty)
        #expect(onboardingFlow.isCompleted == false)
        #expect(onboardingFlow.currentScreenIndex == 0)
    }
    
    @Test("オンボーディングスクリーン追加テスト")
    func testAddOnboardingScreen() {
        // Given
        var onboardingFlow = OnboardingFlow(
            id: UUID(),
            name: "テストフロー",
            description: "テスト用のフロー",
            targetAudience: .returningUser,
            screens: [],
            isCompleted: false,
            currentScreenIndex: 0
        )
        
        let screen = OnboardingScreen(
            id: UUID(),
            order: 1,
            title: "ようこそ",
            subtitle: "AsaMindMapへようこそ",
            content: "このアプリであなたのアイデアを整理しましょう",
            imageName: "welcome_image",
            animationType: .fadeIn,
            interactionType: .tap,
            skipable: true
        )
        
        // When
        onboardingFlow.addScreen(screen)
        
        // Then
        #expect(onboardingFlow.screens.count == 1)
        #expect(onboardingFlow.screens.first?.title == "ようこそ")
        #expect(onboardingFlow.screens.first?.skipable == true)
    }
    
    @Test("オンボーディング進行管理テスト")
    func testOnboardingProgression() {
        // Given
        let screens = [
            OnboardingScreen(id: UUID(), order: 1, title: "画面1", subtitle: "1", content: "1", imageName: "", animationType: .fadeIn, interactionType: .tap, skipable: true),
            OnboardingScreen(id: UUID(), order: 2, title: "画面2", subtitle: "2", content: "2", imageName: "", animationType: .slideIn, interactionType: .swipe, skipable: false),
            OnboardingScreen(id: UUID(), order: 3, title: "画面3", subtitle: "3", content: "3", imageName: "", animationType: .fadeIn, interactionType: .tap, skipable: true)
        ]
        
        var onboardingFlow = OnboardingFlow(
            id: UUID(),
            name: "進行テスト",
            description: "進行管理のテスト",
            targetAudience: .firstTimeUser,
            screens: screens,
            isCompleted: false,
            currentScreenIndex: 0
        )
        
        // When - Move to next screen
        let canProceed = onboardingFlow.proceedToNext()
        
        // Then
        #expect(canProceed == true)
        #expect(onboardingFlow.currentScreenIndex == 1)
        #expect(onboardingFlow.isCompleted == false)
        #expect(onboardingFlow.progress == 1.0/3.0) // 33.3%
        
        // When - Complete all screens
        _ = onboardingFlow.proceedToNext() // Screen 2
        let completed = onboardingFlow.proceedToNext() // Screen 3 (last)
        
        // Then
        #expect(completed == true)
        #expect(onboardingFlow.isCompleted == true)
        #expect(onboardingFlow.progress == 1.0) // 100%
    }
    
    @Test("オンボーディングスキップ機能テスト")
    func testOnboardingSkipFunctionality() {
        // Given
        let screens = [
            OnboardingScreen(id: UUID(), order: 1, title: "必須画面", subtitle: "", content: "", imageName: "", animationType: .fadeIn, interactionType: .tap, skipable: false),
            OnboardingScreen(id: UUID(), order: 2, title: "スキップ可能", subtitle: "", content: "", imageName: "", animationType: .fadeIn, interactionType: .tap, skipable: true),
            OnboardingScreen(id: UUID(), order: 3, title: "最終画面", subtitle: "", content: "", imageName: "", animationType: .fadeIn, interactionType: .tap, skipable: true)
        ]
        
        var onboardingFlow = OnboardingFlow(
            id: UUID(),
            name: "スキップテスト",
            description: "スキップ機能のテスト",
            targetAudience: .returningUser,
            screens: screens,
            isCompleted: false,
            currentScreenIndex: 0
        )
        
        // When - Try to skip first screen (not skipable)
        let canSkipFirst = onboardingFlow.canSkipCurrent()
        
        // Then
        #expect(canSkipFirst == false)
        
        // When - Move to second screen and try to skip
        _ = onboardingFlow.proceedToNext()
        let canSkipSecond = onboardingFlow.canSkipCurrent()
        let skipped = onboardingFlow.skipToEnd()
        
        // Then
        #expect(canSkipSecond == true)
        #expect(skipped == true)
        #expect(onboardingFlow.isCompleted == true)
    }
    
    @Test("オンボーディング条件分岐テスト")
    func testOnboardingConditionalFlow() {
        // Given
        let conditions = OnboardingConditions(
            isFirstLaunch: true,
            hasCreatedMindMap: false,
            hasCompletedTutorial: false,
            appVersion: "1.0.0"
        )
        
        // When
        let shouldShowOnboarding = OnboardingFlow.shouldShow(for: conditions)
        let recommendedFlow = OnboardingFlow.recommendedFlow(for: conditions)
        
        // Then
        #expect(shouldShowOnboarding == true)
        #expect(recommendedFlow == .firstTimeUser)
        
        // Given - Returning user conditions
        let returningConditions = OnboardingConditions(
            isFirstLaunch: false,
            hasCreatedMindMap: true,
            hasCompletedTutorial: true,
            appVersion: "1.1.0"
        )
        
        // When
        let shouldShowForReturning = OnboardingFlow.shouldShow(for: returningConditions)
        let returningFlow = OnboardingFlow.recommendedFlow(for: returningConditions)
        
        // Then
        #expect(shouldShowForReturning == true) // New version, should show update features
        #expect(returningFlow == .versionUpdate)
    }
    
    @Test("オンボーディング分析データ収集テスト")
    func testOnboardingAnalyticsCollection() {
        // Given
        var onboardingFlow = OnboardingFlow(
            id: UUID(),
            name: "分析テスト",
            description: "分析データ収集のテスト",
            targetAudience: .firstTimeUser,
            screens: [
                OnboardingScreen(id: UUID(), order: 1, title: "画面1", subtitle: "", content: "", imageName: "", animationType: .fadeIn, interactionType: .tap, skipable: true)
            ],
            isCompleted: false,
            currentScreenIndex: 0
        )
        
        let startTime = Date()
        
        // When
        onboardingFlow.startTracking()
        Thread.sleep(forTimeInterval: 0.1) // Simulate time spent
        onboardingFlow.recordScreenView(screenIndex: 0, timeSpent: 0.1)
        _ = onboardingFlow.proceedToNext()
        onboardingFlow.completeTracking()
        
        let analytics = onboardingFlow.getAnalytics()
        
        // Then
        #expect(analytics != nil)
        #expect(analytics!.totalTimeSpent > 0)
        #expect(analytics!.screensViewed.count == 1)
        #expect(analytics!.completionRate == 1.0)
        #expect(analytics!.dropOffPoints.isEmpty) // No drop-off since completed
    }
}