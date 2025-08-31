import Testing
import Foundation
@testable import MindMapCore

// MARK: - AI Mind Map Generation Tests

@Suite("Mind Map AI Generator Tests")
struct MindMapAIGeneratorTests {
    
    // MARK: - Mind Map Generation from Text
    
    @Test("AI生成: テキストからマインドマップの自動生成")
    func testGenerateMindMapFromText() async throws {
        // Given
        let generator = MindMapAIGenerator()
        let inputText = """
        プロジェクト計画
        - 要件分析
          - ユーザー調査
          - 競合分析
        - 設計
          - アーキテクチャ
          - UI/UX
        - 実装
          - フロントエンド
          - バックエンド
        - テスト
          - 単体テスト
          - 統合テスト
        """
        
        // When
        let result = try await generator.generateMindMap(from: inputText)
        
        // Then
        #expect(result.rootNode != nil)
        #expect(result.rootNode?.text == "プロジェクト計画")
        #expect(result.rootNode?.children.count == 4)
        
        let requirements = result.rootNode?.children.first { $0.text == "要件分析" }
        #expect(requirements != nil)
        #expect(requirements?.children.count == 2)
    }
    
    @Test("AI生成: 空テキストでの生成エラー")
    func testGenerateMindMapFromEmptyText() async throws {
        // Given
        let generator = MindMapAIGenerator()
        let emptyText = ""
        
        // When & Then
        await #expect(throws: AIGenerationError.emptyInput) {
            try await generator.generateMindMap(from: emptyText)
        }
    }
    
    @Test("AI生成: 長すぎるテキストでの制限エラー")
    func testGenerateMindMapFromTooLongText() async throws {
        // Given
        let generator = MindMapAIGenerator()
        let longText = String(repeating: "A", count: 50000) // 50KB
        
        // When & Then
        await #expect(throws: AIGenerationError.inputTooLong) {
            try await generator.generateMindMap(from: longText)
        }
    }
    
    // MARK: - Core ML Model Integration
    
    @Test("Core ML統合: モデル読み込みテスト")
    func testCoreMLModelLoading() async throws {
        // Given
        let generator = MindMapAIGenerator()
        
        // When
        let isModelReady = await generator.isCoreMLModelReady()
        
        // Then
        #expect(isModelReady == true)
    }
    
    @Test("Core ML統合: 予測実行テスト")
    func testCoreMLPrediction() async throws {
        // Given
        let generator = MindMapAIGenerator()
        let testInput = "会議の議題: 予算、スケジュール、リソース"
        
        // When
        let prediction = try await generator.predictNodeStructure(from: testInput)
        
        // Then
        #expect(prediction.nodes.count >= 3)
        #expect(prediction.relationships.count >= 2)
        #expect(prediction.confidence >= 0.7)
    }
}

// MARK: - Natural Language Processing Tests

@Suite("Natural Language Processor Tests")
struct NaturalLanguageProcessorTests {
    
    // MARK: - Text Classification
    
    @Test("NLP: テキスト分類機能")
    func testTextClassification() async throws {
        // Given
        let processor = NaturalLanguageProcessor()
        let businessText = "売上向上のための戦略を検討する必要がある"
        
        // When
        let classification = try await processor.classifyText(businessText)
        
        // Then
        #expect(classification.category == .business)
        #expect(classification.confidence >= 0.8)
        #expect(classification.subcategories.contains("戦略"))
    }
    
    @Test("NLP: 複数言語サポート")
    func testMultiLanguageClassification() async throws {
        // Given
        let processor = NaturalLanguageProcessor()
        let englishText = "Project planning and resource allocation"
        
        // When
        let classification = try await processor.classifyText(englishText, language: .english)
        
        // Then
        #expect(classification.category == .project)
        #expect(classification.language == .english)
        #expect(classification.confidence >= 0.7)
    }
    
    // MARK: - Auto-tagging
    
    @Test("NLP: 自動タグ付け機能")
    func testAutoTagging() async throws {
        // Given
        let processor = NaturalLanguageProcessor()
        let text = "AI技術を活用した機械学習プロジェクトの実装計画"
        
        // When
        let tags = try await processor.extractTags(from: text)
        
        // Then
        #expect(tags.contains("AI"))
        #expect(tags.contains("機械学習"))
        #expect(tags.contains("プロジェクト"))
        #expect(tags.contains("実装"))
        #expect(tags.count >= 3)
    }
    
    @Test("NLP: キーワード抽出")
    func testKeywordExtraction() async throws {
        // Given
        let processor = NaturalLanguageProcessor()
        let text = "データサイエンスチームがビッグデータ分析の新しい手法を開発している"
        
        // When
        let keywords = try await processor.extractKeywords(from: text, maxCount: 5)
        
        // Then
        #expect(keywords.count <= 5)
        #expect(keywords.contains { $0.word == "データサイエンス" && $0.relevance >= 0.8 })
        #expect(keywords.contains { $0.word == "ビッグデータ" && $0.relevance >= 0.7 })
    }
    
    // MARK: - Sentiment Analysis
    
    @Test("NLP: 感情分析機能")
    func testSentimentAnalysis() async throws {
        // Given
        let processor = NaturalLanguageProcessor()
        let positiveText = "このプロジェクトは素晴らしい成果を上げている"
        let negativeText = "進捗が遅れており、問題が多発している"
        
        // When
        let positiveSentiment = try await processor.analyzeSentiment(positiveText)
        let negativeSentiment = try await processor.analyzeSentiment(negativeText)
        
        // Then
        #expect(positiveSentiment.polarity >= 0.6)
        #expect(positiveSentiment.classification == .positive)
        #expect(negativeSentiment.polarity <= -0.6)
        #expect(negativeSentiment.classification == .negative)
    }
}

// MARK: - Smart Suggestion System Tests

@Suite("Smart Suggestion System Tests")
struct SmartSuggestionSystemTests {
    
    // MARK: - Content Recommendation
    
    @Test("スマート提案: 関連コンテンツ推薦")
    func testContentRecommendation() async throws {
        // Given
        let suggestionSystem = SmartSuggestionSystem()
        let currentNode = Node(
            id: UUID(),
            text: "機械学習アルゴリズム",
            position: CGPoint(x: 100, y: 100)
        )
        
        // When
        let suggestions = try await suggestionSystem.generateSuggestions(for: currentNode)
        
        // Then
        #expect(suggestions.count >= 3)
        #expect(suggestions.count <= 10)
        #expect(suggestions.contains { $0.text.contains("深層学習") })
        #expect(suggestions.contains { $0.text.contains("データ前処理") })
        #expect(suggestions.allSatisfy { $0.relevanceScore >= 0.5 })
    }
    
    @Test("スマート提案: ユーザー履歴基づく提案")
    func testHistoryBasedSuggestions() async throws {
        // Given
        let suggestionSystem = SmartSuggestionSystem()
        let userHistory = UserInteractionHistory(
            frequentTerms: ["プロジェクト管理", "アジャイル", "スクラム"],
            recentNodes: ["要件定義", "スプリント計画", "レトロスペクティブ"],
            preferredCategories: [.project, .business]
        )
        let currentNode = Node(
            id: UUID(),
            text: "開発プロセス",
            position: CGPoint(x: 0, y: 0)
        )
        
        // When
        let suggestions = try await suggestionSystem.generatePersonalizedSuggestions(
            for: currentNode,
            userHistory: userHistory
        )
        
        // Then
        #expect(suggestions.count >= 3)
        #expect(suggestions.contains { $0.text.contains("アジャイル") })
        #expect(suggestions.contains { $0.text.contains("スクラム") })
        #expect(suggestions.allSatisfy { $0.personalizationScore >= 0.6 })
    }
    
    @Test("スマート提案: コンテキスト対応提案")
    func testContextAwareSuggestions() async throws {
        // Given
        let suggestionSystem = SmartSuggestionSystem()
        let parentNode = Node(
            id: UUID(),
            text: "マーケティング戦略",
            position: CGPoint(x: 0, y: 0)
        )
        let siblingNodes = [
            Node(id: UUID(), text: "ターゲット分析", position: CGPoint(x: 100, y: 50)),
            Node(id: UUID(), text: "競合調査", position: CGPoint(x: 100, y: 150))
        ]
        
        // When
        let suggestions = try await suggestionSystem.generateContextualSuggestions(
            parent: parentNode,
            siblings: siblingNodes
        )
        
        // Then
        #expect(suggestions.count >= 2)
        #expect(suggestions.contains { $0.text.contains("プロモーション") || $0.text.contains("広告") })
        #expect(suggestions.contains { $0.text.contains("KPI") || $0.text.contains("効果測定") })
        #expect(suggestions.allSatisfy { $0.contextRelevance >= 0.7 })
    }
    
    // MARK: - Learning and Adaptation
    
    @Test("学習機能: ユーザーフィードバックからの学習")
    func testUserFeedbackLearning() async throws {
        // Given
        let suggestionSystem = SmartSuggestionSystem()
        let feedback = [
            SuggestionFeedback(suggestionID: UUID(), accepted: true, rating: 5),
            SuggestionFeedback(suggestionID: UUID(), accepted: false, rating: 2),
            SuggestionFeedback(suggestionID: UUID(), accepted: true, rating: 4)
        ]
        
        // When
        try await suggestionSystem.learnFromFeedback(feedback)
        let modelAccuracy = try await suggestionSystem.getCurrentModelAccuracy()
        
        // Then
        #expect(modelAccuracy >= 0.6)
    }
    
    @Test("学習機能: 使用パターンの分析")
    func testUsagePatternAnalysis() async throws {
        // Given
        let suggestionSystem = SmartSuggestionSystem()
        let usageData = UsagePatternData(
            nodeCreationPatterns: ["親ノード作成", "子ノード追加", "関連ノード作成"],
            timeBasedPatterns: [.morning: ["計画"], .afternoon: ["実行"], .evening: ["振り返り"]],
            categoryPreferences: [.business: 0.6, .project: 0.8, .personal: 0.3]
        )
        
        // When
        let patterns = try await suggestionSystem.analyzeUsagePatterns(usageData)
        
        // Then
        #expect(patterns.dominantWorkflow != nil)
        #expect(patterns.timePreferences.count >= 2)
        #expect(patterns.categoryAffinities[.project] >= 0.7)
    }
}

// MARK: - Privacy Protection Tests

@Suite("AI Privacy Protection Tests")
struct AIPrivacyProtectionTests {
    
    // MARK: - Local Processing
    
    @Test("プライバシー: ローカルAI処理の確認")
    func testLocalAIProcessing() async throws {
        // Given
        let privacyManager = AIPrivacyManager()
        let sensitiveText = "個人情報: 田中太郎, メール: tanaka@example.com"
        
        // When
        let processingLocation = await privacyManager.determineProcessingLocation(for: sensitiveText)
        let isLocalProcessing = await privacyManager.isProcessingLocal()
        
        // Then
        #expect(processingLocation == .localDevice)
        #expect(isLocalProcessing == true)
    }
    
    @Test("プライバシー: データ匿名化機能")
    func testDataAnonymization() async throws {
        // Given
        let privacyManager = AIPrivacyManager()
        let personalData = "山田花子さんの電話番号は090-1234-5678です"
        
        // When
        let anonymizedData = try await privacyManager.anonymizeData(personalData)
        
        // Then
        #expect(!anonymizedData.contains("山田花子"))
        #expect(!anonymizedData.contains("090-1234-5678"))
        #expect(anonymizedData.contains("[NAME]"))
        #expect(anonymizedData.contains("[PHONE]"))
    }
    
    @Test("プライバシー: 機密情報検出")
    func testSensitiveDataDetection() async throws {
        // Given
        let privacyManager = AIPrivacyManager()
        let mixedText = "プロジェクトの進捗について、佐藤さん（ID: emp001）と相談した"
        
        // When
        let detectionResult = try await privacyManager.detectSensitiveInformation(in: mixedText)
        
        // Then
        #expect(detectionResult.hasSensitiveData == true)
        #expect(detectionResult.detectedTypes.contains(.personalName))
        #expect(detectionResult.detectedTypes.contains(.employeeID))
        #expect(detectionResult.riskLevel == .medium)
    }
    
    // MARK: - User Consent Management
    
    @Test("プライバシー: ユーザー同意管理")
    func testUserConsentManagement() async throws {
        // Given
        let consentManager = AIConsentManager()
        
        // When
        let hasConsent = await consentManager.hasUserConsent(for: .aiProcessing)
        try await consentManager.requestConsent(for: .aiProcessing)
        let hasConsentAfterRequest = await consentManager.hasUserConsent(for: .aiProcessing)
        
        // Then
        #expect(hasConsent == false) // 初期状態
        #expect(hasConsentAfterRequest == true) // 同意後
    }
    
    @Test("プライバシー: データ保持期間管理")
    func testDataRetentionManagement() async throws {
        // Given
        let privacyManager = AIPrivacyManager()
        let aiData = AIProcessingData(
            inputText: "テストデータ",
            processedAt: Date(),
            retentionPeriod: .days(30)
        )
        
        // When
        try await privacyManager.storeProcessingData(aiData)
        let shouldRetain = await privacyManager.shouldRetainData(aiData)
        
        // Then
        #expect(shouldRetain == true)
        
        // 保持期間経過後のシミュレーション
        let expiredData = AIProcessingData(
            inputText: "期限切れデータ",
            processedAt: Date().addingTimeInterval(-31 * 24 * 3600), // 31日前
            retentionPeriod: .days(30)
        )
        let shouldRetainExpired = await privacyManager.shouldRetainData(expiredData)
        #expect(shouldRetainExpired == false)
    }
}

// MARK: - AI Accuracy Validation Tests

@Suite("AI Accuracy Validation Tests")
struct AIAccuracyValidationTests {
    
    // MARK: - Model Performance Testing
    
    @Test("精度検証: モデル性能測定")
    func testModelPerformanceMetrics() async throws {
        // Given
        let validator = AIAccuracyValidator()
        let testDataset = createTestDataset()
        
        // When
        let performanceMetrics = try await validator.evaluateModel(with: testDataset)
        
        // Then
        #expect(performanceMetrics.accuracy >= 0.8)
        #expect(performanceMetrics.precision >= 0.75)
        #expect(performanceMetrics.recall >= 0.75)
        #expect(performanceMetrics.f1Score >= 0.75)
    }
    
    @Test("精度検証: バイアス検出テスト")
    func testBiasDetection() async throws {
        // Given
        let validator = AIAccuracyValidator()
        let diverseTestData = createDiverseTestDataset()
        
        // When
        let biasAnalysis = try await validator.analyzeBias(with: diverseTestData)
        
        // Then
        #expect(biasAnalysis.overallBiasScore <= 0.2) // 低バイアス
        #expect(biasAnalysis.fairnessMetrics.demographicParity >= 0.8)
        #expect(biasAnalysis.fairnessMetrics.equalizedOdds >= 0.8)
    }
    
    @Test("精度検証: エッジケース処理")
    func testEdgeCaseHandling() async throws {
        // Given
        let validator = AIAccuracyValidator()
        let edgeCases = [
            "特殊文字!@#$%^&*()",
            "非常に短いテキスト",
            "非常に長いテキストでありしかも意味のない文章が延々と続いていてAIが混乱する可能性のあるケース..." + String(repeating: "長い", count: 100),
            "🎉 絵文字だらけのテキスト 🚀 🌟",
            "" // 空文字
        ]
        
        // When & Then
        for edgeCase in edgeCases {
            let result = try await validator.testEdgeCase(input: edgeCase)
            #expect(result.handled == true)
            #expect(result.errorOccurred == false)
        }
    }
    
    // MARK: - A/B Testing Framework
    
    @Test("精度検証: A/Bテスト実行")
    func testABTesting() async throws {
        // Given
        let abTester = AIABTester()
        let modelA = "baseline_model"
        let modelB = "improved_model"
        let testUsers = (1...100).map { UserID($0) }
        
        // When
        let experiment = try await abTester.createExperiment(
            name: "suggestion_quality_test",
            modelA: modelA,
            modelB: modelB,
            userGroup: testUsers
        )
        let results = try await abTester.runExperiment(experiment, duration: .seconds(1)) // テスト用短時間
        
        // Then
        #expect(results.totalParticipants == 100)
        #expect(results.groupA.count + results.groupB.count == 100)
        #expect(results.statisticalSignificance != nil)
    }
    
    // MARK: - Continuous Monitoring
    
    @Test("精度検証: 継続的監視システム")
    func testContinuousMonitoring() async throws {
        // Given
        let monitor = AIContinuousMonitor()
        let performanceThreshold = AIPerformanceThreshold(
            minAccuracy: 0.8,
            maxLatency: 2.0,
            maxMemoryUsage: 500 * 1024 * 1024 // 500MB
        )
        
        // When
        try await monitor.startMonitoring(threshold: performanceThreshold)
        
        // シミュレートされた使用で性能を測定
        for _ in 1...10 {
            let testInput = "テスト用の入力データ"
            _ = try await monitor.processWithMonitoring(input: testInput)
        }
        
        let monitoringReport = try await monitor.generateReport()
        
        // Then
        #expect(monitoringReport.averageAccuracy >= performanceThreshold.minAccuracy)
        #expect(monitoringReport.averageLatency <= performanceThreshold.maxLatency)
        #expect(monitoringReport.peakMemoryUsage <= performanceThreshold.maxMemoryUsage)
        #expect(monitoringReport.alertsTriggered.isEmpty)
    }
    
    // MARK: - Helper Methods
    
    private func createTestDataset() -> AITestDataset {
        return AITestDataset(samples: [
            AITestSample(input: "プロジェクト管理", expectedOutput: ["計画", "実行", "監視", "クロージング"]),
            AITestSample(input: "マーケティング", expectedOutput: ["調査", "戦略", "実施", "評価"]),
            AITestSample(input: "技術開発", expectedOutput: ["要件定義", "設計", "実装", "テスト"])
        ])
    }
    
    private func createDiverseTestDataset() -> AITestDataset {
        return AITestDataset(samples: [
            AITestSample(input: "ビジネス戦略", expectedOutput: ["SWOT分析", "競合分析"]),
            AITestSample(input: "個人目標", expectedOutput: ["健康", "スキル向上"]),
            AITestSample(input: "研究計画", expectedOutput: ["文献調査", "実験設計"])
        ])
    }
}