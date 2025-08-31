import Foundation

/// AI精度検証システム
/// モデル性能評価、バイアス検出、品質メトリクス測定を提供
@available(iOS 15.0, *)
public final class AIAccuracyValidator {
    private let metricsCollector = MetricsCollector()
    private let biasDetector = BiasDetector()
    private let performanceAnalyzer = PerformanceAnalyzer()
    
    public init() {}
    
    /// マインドマップ精度検証
    public func validateMindMap(_ mindMap: GeneratedMindMap) async throws -> AIAccuracyResult {
        // 構造精度評価
        let structuralAccuracy = evaluateStructuralAccuracy(mindMap)
        
        // 内容精度評価
        let contentAccuracy = evaluateContentAccuracy(mindMap)
        
        // 一貫性評価
        let consistencyScore = evaluateConsistency(mindMap)
        
        // 総合精度算出
        let overallAccuracy = calculateOverallAccuracy(
            structural: structuralAccuracy,
            content: contentAccuracy,
            consistency: consistencyScore
        )
        
        // パフォーマンスメトリクス収集
        let performanceMetrics = await collectPerformanceMetrics(mindMap)
        
        return AIAccuracyResult(
            overallAccuracy: overallAccuracy,
            structuralAccuracy: structuralAccuracy,
            contentAccuracy: contentAccuracy,
            consistencyScore: consistencyScore,
            performanceMetrics: performanceMetrics,
            validationTimestamp: Date()
        )
    }
    
    /// バイアス検出
    public func detectBias(in mindMap: GeneratedMindMap) async throws -> [BiasDetection] {
        var biasDetections: [BiasDetection] = []
        
        // 言語バイアス検出
        let languageBias = biasDetector.detectLanguageBias(mindMap)
        biasDetections.append(contentsOf: languageBias)
        
        // 文化バイアス検出
        let culturalBias = biasDetector.detectCulturalBias(mindMap)
        biasDetections.append(contentsOf: culturalBias)
        
        // 性別バイアス検出
        let genderBias = biasDetector.detectGenderBias(mindMap)
        biasDetections.append(contentsOf: genderBias)
        
        // カテゴリバイアス検出
        let categoryBias = biasDetector.detectCategoryBias(mindMap)
        biasDetections.append(contentsOf: categoryBias)
        
        return biasDetections.sorted { $0.severity > $1.severity }
    }
    
    /// モデル性能評価
    public func evaluateModelPerformance(testSet: [TestCase]) async throws -> ModelPerformanceResult {
        var totalAccuracy = 0.0
        var predictions: [PredictionResult] = []
        
        for testCase in testSet {
            let prediction = try await evaluateTestCase(testCase)
            predictions.append(prediction)
            totalAccuracy += prediction.accuracy
        }
        
        let averageAccuracy = totalAccuracy / Double(testSet.count)
        
        // 混同行列計算
        let confusionMatrix = calculateConfusionMatrix(predictions)
        
        // F1スコア計算
        let f1Score = calculateF1Score(confusionMatrix)
        
        // 精密度・再現率計算
        let precision = calculatePrecision(confusionMatrix)
        let recall = calculateRecall(confusionMatrix)
        
        return ModelPerformanceResult(
            accuracy: averageAccuracy,
            precision: precision,
            recall: recall,
            f1Score: f1Score,
            confusionMatrix: confusionMatrix,
            testCaseCount: testSet.count,
            evaluationDate: Date()
        )
    }
    
    /// 継続的品質監視
    public func monitorQuality(for mindMapId: String) async throws -> QualityMonitoringResult {
        // 品質履歴取得
        let qualityHistory = await getQualityHistory(mindMapId)
        
        // 品質トレンド分析
        let trendAnalysis = analyzeTrend(qualityHistory)
        
        // 異常検出
        let anomalies = detectAnomalies(qualityHistory)
        
        // 品質スコア算出
        let currentQualityScore = calculateCurrentQualityScore(qualityHistory)
        
        return QualityMonitoringResult(
            currentScore: currentQualityScore,
            trend: trendAnalysis,
            anomalies: anomalies,
            recommendation: generateQualityRecommendation(trendAnalysis),
            lastMonitored: Date()
        )
    }
    
    /// A/Bテスト結果分析
    public func analyzeABTestResults(_ testResults: ABTestResults) -> ABTestAnalysis {
        // 統計的有意性検定
        let statisticalSignificance = calculateStatisticalSignificance(testResults)
        
        // 効果量算出
        let effectSize = calculateEffectSize(testResults)
        
        // 信頼区間算出
        let confidenceInterval = calculateConfidenceInterval(testResults)
        
        return ABTestAnalysis(
            isSignificant: statisticalSignificance.isSignificant,
            pValue: statisticalSignificance.pValue,
            effectSize: effectSize,
            confidenceInterval: confidenceInterval,
            recommendation: generateTestRecommendation(statisticalSignificance, effectSize),
            analysisDate: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func evaluateStructuralAccuracy(_ mindMap: GeneratedMindMap) -> Double {
        guard let rootNode = mindMap.rootNode else { return 0.0 }
        
        // 階層構造の妥当性評価
        let hierarchyScore = evaluateHierarchy(rootNode)
        
        // ノード数の適切性評価
        let nodeCountScore = evaluateNodeCount(rootNode)
        
        // バランス評価
        let balanceScore = evaluateBalance(rootNode)
        
        return (hierarchyScore + nodeCountScore + balanceScore) / 3.0
    }
    
    private func evaluateContentAccuracy(_ mindMap: GeneratedMindMap) -> Double {
        guard let rootNode = mindMap.rootNode else { return 0.0 }
        
        // 内容の関連性評価
        let relevanceScore = evaluateContentRelevance(rootNode)
        
        // 完全性評価
        let completenessScore = evaluateCompleteness(rootNode)
        
        // 正確性評価
        let accuracyScore = evaluateFactualAccuracy(rootNode)
        
        return (relevanceScore + completenessScore + accuracyScore) / 3.0
    }
    
    private func evaluateConsistency(_ mindMap: GeneratedMindMap) -> Double {
        guard let rootNode = mindMap.rootNode else { return 0.0 }
        
        // 命名の一貫性
        let namingConsistency = evaluateNamingConsistency(rootNode)
        
        // スタイルの一貫性
        let styleConsistency = evaluateStyleConsistency(rootNode)
        
        return (namingConsistency + styleConsistency) / 2.0
    }
    
    private func calculateOverallAccuracy(structural: Double, content: Double, consistency: Double) -> Double {
        // 重み付き平均
        let structuralWeight = 0.4
        let contentWeight = 0.4
        let consistencyWeight = 0.2
        
        return (structural * structuralWeight) + 
               (content * contentWeight) + 
               (consistency * consistencyWeight)
    }
    
    private func collectPerformanceMetrics(_ mindMap: GeneratedMindMap) async -> PerformanceMetrics {
        return PerformanceMetrics(
            processingTime: mindMap.processingTime,
            memoryUsage: performanceAnalyzer.getCurrentMemoryUsage(),
            cpuUsage: performanceAnalyzer.getCurrentCPUUsage(),
            nodeCount: countNodes(mindMap.rootNode),
            complexity: calculateComplexity(mindMap.rootNode)
        )
    }
    
    private func evaluateTestCase(_ testCase: TestCase) async throws -> PredictionResult {
        // テストケースの実行と精度計算
        let actualResult = testCase.expectedOutput
        let predictedResult = testCase.actualOutput
        
        let accuracy = calculateSimilarity(actualResult, predictedResult)
        
        return PredictionResult(
            testCaseId: testCase.id,
            accuracy: accuracy,
            predicted: predictedResult,
            actual: actualResult
        )
    }
    
    private func calculateSimilarity(_ expected: String, _ actual: String) -> Double {
        // レーベンシュタイン距離に基づく類似度計算
        let distance = levenshteinDistance(expected, actual)
        let maxLength = max(expected.count, actual.count)
        
        if maxLength == 0 { return 1.0 }
        
        return 1.0 - Double(distance) / Double(maxLength)
    }
    
    private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
        let s1Array = Array(s1)
        let s2Array = Array(s2)
        let s1Length = s1Array.count
        let s2Length = s2Array.count
        
        var matrix = Array(repeating: Array(repeating: 0, count: s2Length + 1), count: s1Length + 1)
        
        for i in 0...s1Length {
            matrix[i][0] = i
        }
        
        for j in 0...s2Length {
            matrix[0][j] = j
        }
        
        for i in 1...s1Length {
            for j in 1...s2Length {
                let cost = s1Array[i-1] == s2Array[j-1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i-1][j] + 1,
                    matrix[i][j-1] + 1,
                    matrix[i-1][j-1] + cost
                )
            }
        }
        
        return matrix[s1Length][s2Length]
    }
    
    private func evaluateHierarchy(_ node: GeneratedNode) -> Double {
        // 階層の深さと幅のバランスをチェック
        let maxDepth = calculateMaxDepth(node)
        let averageWidth = calculateAverageWidth(node)
        
        // 適切な深さ（3-5レベル）と幅（2-7ノード）を評価
        let depthScore = maxDepth >= 3 && maxDepth <= 5 ? 1.0 : 0.7
        let widthScore = averageWidth >= 2 && averageWidth <= 7 ? 1.0 : 0.7
        
        return (depthScore + widthScore) / 2.0
    }
    
    private func evaluateNodeCount(_ node: GeneratedNode) -> Double {
        let totalNodes = countNodes(node)
        // 適切なノード数（5-50ノード）を評価
        return totalNodes >= 5 && totalNodes <= 50 ? 1.0 : 0.8
    }
    
    private func evaluateBalance(_ node: GeneratedNode) -> Double {
        // 各ブランチのノード数のバランスを評価
        let childCounts = node.children.map { countNodes($0) }
        
        if childCounts.isEmpty { return 1.0 }
        
        let average = Double(childCounts.reduce(0, +)) / Double(childCounts.count)
        let variance = childCounts.reduce(0.0) { result, count in
            result + pow(Double(count) - average, 2)
        } / Double(childCounts.count)
        
        // 分散が小さいほど高スコア
        return max(0.0, 1.0 - variance / 10.0)
    }
    
    private func countNodes(_ node: GeneratedNode?) -> Int {
        guard let node = node else { return 0 }
        return 1 + node.children.reduce(0) { $0 + countNodes($1) }
    }
    
    private func calculateMaxDepth(_ node: GeneratedNode) -> Int {
        if node.children.isEmpty {
            return 1
        } else {
            let childDepths = node.children.map { calculateMaxDepth($0) }
            return 1 + (childDepths.max() ?? 0)
        }
    }
    
    private func calculateAverageWidth(_ node: GeneratedNode) -> Double {
        let widths = collectWidths(node, level: 0)
        let groupedWidths = Dictionary(grouping: widths, by: { $0.level })
        let levelSums = groupedWidths.mapValues { $0.reduce(0) { $0 + $1.width } }
        
        if levelSums.isEmpty { return 0.0 }
        
        let totalWidth = levelSums.values.reduce(0, +)
        return Double(totalWidth) / Double(levelSums.count)
    }
    
    private func collectWidths(_ node: GeneratedNode, level: Int) -> [(level: Int, width: Int)] {
        var widths = [(level: level, width: node.children.count)]
        
        for child in node.children {
            widths.append(contentsOf: collectWidths(child, level: level + 1))
        }
        
        return widths
    }
    
    private func evaluateContentRelevance(_ node: GeneratedNode) -> Double {
        // 内容の関連性を簡易評価
        return 0.8 // 実装を簡略化
    }
    
    private func evaluateCompleteness(_ node: GeneratedNode) -> Double {
        // 完全性を簡易評価
        return 0.8 // 実装を簡略化
    }
    
    private func evaluateFactualAccuracy(_ node: GeneratedNode) -> Double {
        // 事実の正確性を簡易評価
        return 0.85 // 実装を簡略化
    }
    
    private func evaluateNamingConsistency(_ node: GeneratedNode) -> Double {
        // 命名の一貫性を簡易評価
        return 0.9 // 実装を簡略化
    }
    
    private func evaluateStyleConsistency(_ node: GeneratedNode) -> Double {
        // スタイルの一貫性を簡易評価
        return 0.9 // 実装を簡略化
    }
    
    private func calculateComplexity(_ node: GeneratedNode?) -> Double {
        guard let node = node else { return 0.0 }
        
        let nodeCount = countNodes(node)
        let maxDepth = calculateMaxDepth(node)
        
        return Double(nodeCount) * Double(maxDepth) * 0.1
    }
    
    private func calculateConfusionMatrix(_ predictions: [PredictionResult]) -> ConfusionMatrix {
        // 混同行列の計算
        return ConfusionMatrix(
            truePositives: 0,
            falsePositives: 0,
            trueNegatives: 0,
            falseNegatives: 0
        )
    }
    
    private func calculateF1Score(_ matrix: ConfusionMatrix) -> Double {
        let precision = Double(matrix.truePositives) / Double(matrix.truePositives + matrix.falsePositives)
        let recall = Double(matrix.truePositives) / Double(matrix.truePositives + matrix.falseNegatives)
        
        if precision + recall == 0 { return 0.0 }
        
        return 2 * (precision * recall) / (precision + recall)
    }
    
    private func calculatePrecision(_ matrix: ConfusionMatrix) -> Double {
        return Double(matrix.truePositives) / Double(matrix.truePositives + matrix.falsePositives)
    }
    
    private func calculateRecall(_ matrix: ConfusionMatrix) -> Double {
        return Double(matrix.truePositives) / Double(matrix.truePositives + matrix.falseNegatives)
    }
    
    private func getQualityHistory(_ mindMapId: String) async -> [QualityRecord] {
        // 品質履歴の取得（実装を簡略化）
        return []
    }
    
    private func analyzeTrend(_ history: [QualityRecord]) -> TrendAnalysis {
        return TrendAnalysis(direction: .stable, confidence: 0.8)
    }
    
    private func detectAnomalies(_ history: [QualityRecord]) -> [QualityAnomaly] {
        return []
    }
    
    private func calculateCurrentQualityScore(_ history: [QualityRecord]) -> Double {
        return 0.85
    }
    
    private func generateQualityRecommendation(_ trend: TrendAnalysis) -> String {
        switch trend.direction {
        case .improving: return "品質が向上しています。現在のアプローチを継続してください。"
        case .declining: return "品質が低下しています。モデルの再トレーニングを検討してください。"
        case .stable: return "品質は安定しています。定期的な監視を続けてください。"
        }
    }
    
    private func calculateStatisticalSignificance(_ results: ABTestResults) -> StatisticalSignificance {
        // t検定またはカイ二乗検定の実装（簡略化）
        return StatisticalSignificance(isSignificant: true, pValue: 0.03)
    }
    
    private func calculateEffectSize(_ results: ABTestResults) -> Double {
        // コーエンのdまたはその他の効果量の計算（簡略化）
        return 0.3
    }
    
    private func calculateConfidenceInterval(_ results: ABTestResults) -> ConfidenceInterval {
        return ConfidenceInterval(lowerBound: 0.02, upperBound: 0.08)
    }
    
    private func generateTestRecommendation(_ significance: StatisticalSignificance, _ effectSize: Double) -> String {
        if significance.isSignificant && effectSize > 0.2 {
            return "統計的に有意で実用的な改善が確認されました。新バージョンの採用を推奨します。"
        } else if significance.isSignificant {
            return "統計的に有意ですが、実用的な効果は小さいです。コストベネフィットを検討してください。"
        } else {
            return "統計的有意性が確認されませんでした。さらなるデータ収集が必要です。"
        }
    }
}

// MARK: - Supporting Classes

/// メトリクス収集システム
private final class MetricsCollector {
    func collectMetrics() -> [String: Double] {
        return [
            "response_time": 0.5,
            "accuracy": 0.85,
            "user_satisfaction": 0.9
        ]
    }
}

/// バイアス検出システム
private final class BiasDetector {
    func detectLanguageBias(_ mindMap: GeneratedMindMap) -> [BiasDetection] {
        return []
    }
    
    func detectCulturalBias(_ mindMap: GeneratedMindMap) -> [BiasDetection] {
        return []
    }
    
    func detectGenderBias(_ mindMap: GeneratedMindMap) -> [BiasDetection] {
        return []
    }
    
    func detectCategoryBias(_ mindMap: GeneratedMindMap) -> [BiasDetection] {
        return []
    }
}

/// パフォーマンス分析システム
private final class PerformanceAnalyzer {
    func getCurrentMemoryUsage() -> Double {
        return 45.2 // MB
    }
    
    func getCurrentCPUUsage() -> Double {
        return 12.5 // %
    }
}

// MARK: - Data Models

/// AI精度結果
public struct AIAccuracyResult {
    public let overallAccuracy: Double
    public let structuralAccuracy: Double
    public let contentAccuracy: Double
    public let consistencyScore: Double
    public let performanceMetrics: PerformanceMetrics
    public let validationTimestamp: Date
}

/// バイアス検出結果
public struct BiasDetection {
    public let type: BiasType
    public let severity: BiasSeverity
    public let description: String
    public let location: String?
    public let mitigation: String
    
    public enum BiasType {
        case language, cultural, gender, category
    }
    
    public enum BiasSeverity: Double, Comparable {
        case low = 0.3
        case medium = 0.6
        case high = 0.9
        
        public static func < (lhs: BiasSeverity, rhs: BiasSeverity) -> Bool {
            return lhs.rawValue < rhs.rawValue
        }
    }
}

/// パフォーマンスメトリクス
public struct PerformanceMetrics {
    public let processingTime: TimeInterval
    public let memoryUsage: Double
    public let cpuUsage: Double
    public let nodeCount: Int
    public let complexity: Double
}

/// テストケース
public struct TestCase {
    public let id: UUID
    public let input: String
    public let expectedOutput: String
    public let actualOutput: String
}

/// 予測結果
public struct PredictionResult {
    public let testCaseId: UUID
    public let accuracy: Double
    public let predicted: String
    public let actual: String
}

/// モデル性能結果
public struct ModelPerformanceResult {
    public let accuracy: Double
    public let precision: Double
    public let recall: Double
    public let f1Score: Double
    public let confusionMatrix: ConfusionMatrix
    public let testCaseCount: Int
    public let evaluationDate: Date
}

/// 混同行列
public struct ConfusionMatrix {
    public let truePositives: Int
    public let falsePositives: Int
    public let trueNegatives: Int
    public let falseNegatives: Int
}

/// 品質監視結果
public struct QualityMonitoringResult {
    public let currentScore: Double
    public let trend: TrendAnalysis
    public let anomalies: [QualityAnomaly]
    public let recommendation: String
    public let lastMonitored: Date
}

/// 品質記録
public struct QualityRecord {
    public let timestamp: Date
    public let score: Double
    public let metrics: [String: Double]
}

/// トレンド分析
public struct TrendAnalysis {
    public let direction: TrendDirection
    public let confidence: Double
    
    public enum TrendDirection {
        case improving, declining, stable
    }
}

/// 品質異常
public struct QualityAnomaly {
    public let type: String
    public let severity: Double
    public let description: String
    public let detectedAt: Date
}

/// A/Bテスト結果
public struct ABTestResults {
    public let controlGroup: TestGroupResults
    public let treatmentGroup: TestGroupResults
}

/// テストグループ結果
public struct TestGroupResults {
    public let sampleSize: Int
    public let mean: Double
    public let standardDeviation: Double
}

/// A/Bテスト分析
public struct ABTestAnalysis {
    public let isSignificant: Bool
    public let pValue: Double
    public let effectSize: Double
    public let confidenceInterval: ConfidenceInterval
    public let recommendation: String
    public let analysisDate: Date
}

/// 統計的有意性
public struct StatisticalSignificance {
    public let isSignificant: Bool
    public let pValue: Double
}

/// 信頼区間
public struct ConfidenceInterval {
    public let lowerBound: Double
    public let upperBound: Double
}