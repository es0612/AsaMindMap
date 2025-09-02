import Foundation
import Combine

/// A/Bテスト実験の状態
public enum ExperimentState {
    case draft
    case running
    case paused
    case completed
    case cancelled
}

/// A/Bテストバリアント
public struct Variant {
    public let id: String
    public let name: String
    public let description: String
    public let weight: Double // 0.0 - 1.0
    public let configuration: [String: Any]
    
    public init(id: String, name: String, description: String, weight: Double, configuration: [String: Any] = [:]) {
        self.id = id
        self.name = name
        self.description = description
        self.weight = weight
        self.configuration = configuration
    }
}

/// A/Bテスト実験
public struct Experiment {
    public let id: String
    public let name: String
    public let description: String
    public let state: ExperimentState
    public let variants: [Variant]
    public let primaryMetric: KPIType
    public let secondaryMetrics: [KPIType]
    public let targetAudience: AudienceFilter?
    public let startDate: Date?
    public let endDate: Date?
    public let minimumSampleSize: Int
    public let confidenceLevel: Double
    public let metadata: [String: Any]?
    
    public init(
        id: String,
        name: String,
        description: String,
        state: ExperimentState = .draft,
        variants: [Variant],
        primaryMetric: KPIType,
        secondaryMetrics: [KPIType] = [],
        targetAudience: AudienceFilter? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        minimumSampleSize: Int = 1000,
        confidenceLevel: Double = 0.95,
        metadata: [String: Any]? = nil
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.state = state
        self.variants = variants
        self.primaryMetric = primaryMetric
        self.secondaryMetrics = secondaryMetrics
        self.targetAudience = targetAudience
        self.startDate = startDate
        self.endDate = endDate
        self.minimumSampleSize = minimumSampleSize
        self.confidenceLevel = confidenceLevel
        self.metadata = metadata
    }
}

/// オーディエンスフィルター
public struct AudienceFilter {
    public let userSegments: [String]?
    public let countries: [String]?
    public let appVersions: [String]?
    public let deviceTypes: [String]?
    public let customFilters: [String: Any]?
    
    public init(
        userSegments: [String]? = nil,
        countries: [String]? = nil,
        appVersions: [String]? = nil,
        deviceTypes: [String]? = nil,
        customFilters: [String: Any]? = nil
    ) {
        self.userSegments = userSegments
        self.countries = countries
        self.appVersions = appVersions
        self.deviceTypes = deviceTypes
        self.customFilters = customFilters
    }
}

/// 実験割り当て
public struct ExperimentAssignment {
    public let experimentId: String
    public let userId: String
    public let variantId: String
    public let assignedAt: Date
    public let metadata: [String: Any]?
    
    public init(experimentId: String, userId: String, variantId: String, assignedAt: Date = Date(), metadata: [String: Any]? = nil) {
        self.experimentId = experimentId
        self.userId = userId
        self.variantId = variantId
        self.assignedAt = assignedAt
        self.metadata = metadata
    }
}

/// 実験結果
public struct ExperimentResult {
    public let experimentId: String
    public let variantId: String
    public let metric: KPIType
    public let sampleSize: Int
    public let mean: Double
    public let standardDeviation: Double
    public let confidenceInterval: (lower: Double, upper: Double)
    public let significanceLevel: Double
    public let isStatisticallySignificant: Bool
    
    public init(
        experimentId: String,
        variantId: String,
        metric: KPIType,
        measurements: [KPIMeasurement]
    ) {
        self.experimentId = experimentId
        self.variantId = variantId
        self.metric = metric
        
        let values = measurements.map { $0.value.numericValue }
        self.sampleSize = values.count
        
        if values.isEmpty {
            self.mean = 0
            self.standardDeviation = 0
            self.confidenceInterval = (0, 0)
            self.significanceLevel = 1.0
            self.isStatisticallySignificant = false
        } else {
            self.mean = values.reduce(0, +) / Double(values.count)
            
            let meanValue = self.mean
            let variance = values.map { pow($0 - meanValue, 2) }.reduce(0, +) / Double(max(values.count - 1, 1))
            self.standardDeviation = sqrt(variance)
            
            // 95%信頼区間を計算 (t-distribution approximation)
            let tValue = 1.96 // For large samples, approximating with normal distribution
            let standardError = standardDeviation / sqrt(Double(values.count))
            let marginOfError = tValue * standardError
            
            self.confidenceInterval = (mean - marginOfError, mean + marginOfError)
            
            // 統計的有意性は比較対照群が必要なため、ここでは仮の実装
            self.significanceLevel = 0.05
            self.isStatisticallySignificant = values.count >= 30 // 仮の条件
        }
    }
}

/// A/Bテスト実験比較結果
public struct ExperimentComparison {
    public let experimentId: String
    public let controlVariantId: String
    public let testVariantId: String
    public let metric: KPIType
    public let controlResult: ExperimentResult
    public let testResult: ExperimentResult
    public let liftPercentage: Double
    public let pValue: Double
    public let isStatisticallySignificant: Bool
    public let recommendation: ExperimentRecommendation
    
    public init(controlResult: ExperimentResult, testResult: ExperimentResult) {
        self.experimentId = controlResult.experimentId
        self.controlVariantId = controlResult.variantId
        self.testVariantId = testResult.variantId
        self.metric = controlResult.metric
        self.controlResult = controlResult
        self.testResult = testResult
        
        // リフト計算
        if controlResult.mean > 0 {
            self.liftPercentage = ((testResult.mean - controlResult.mean) / controlResult.mean) * 100
        } else {
            self.liftPercentage = 0
        }
        
        // 仮のp値計算（実際にはWelch's t-testなどを使用）
        self.pValue = 0.05 // 仮の値
        self.isStatisticallySignificant = pValue < 0.05 && min(controlResult.sampleSize, testResult.sampleSize) >= 100
        
        // 推奨決定
        if isStatisticallySignificant {
            if liftPercentage > 5 {
                self.recommendation = .adoptTestVariant
            } else if liftPercentage < -5 {
                self.recommendation = .keepControlVariant
            } else {
                self.recommendation = .noSignificantDifference
            }
        } else {
            self.recommendation = .needMoreData
        }
    }
}

/// 実験推奨
public enum ExperimentRecommendation {
    case adoptTestVariant
    case keepControlVariant
    case noSignificantDifference
    case needMoreData
}

/// A/Bテスティングフレームワーク
@MainActor
public class ABTestingFramework: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var activeExperiments: [Experiment] = []
    @Published public private(set) var userAssignments: [String: [ExperimentAssignment]] = [:]
    
    private var storage: ABTestStorageProtocol
    private var kpiTracker: KPITracker
    
    // MARK: - Initialization
    
    public init(storage: ABTestStorageProtocol = CoreDataABTestStorage(), kpiTracker: KPITracker) {
        self.storage = storage
        self.kpiTracker = kpiTracker
        loadActiveExperiments()
    }
    
    // MARK: - Experiment Management
    
    public func createExperiment(_ experiment: Experiment) async throws {
        var validatedExperiment = experiment
        
        // バリアントの重み合計が1.0になることを確認
        let totalWeight = experiment.variants.map { $0.weight }.reduce(0, +)
        if abs(totalWeight - 1.0) > 0.001 {
            throw ABTestError.invalidVariantWeights
        }
        
        try await storage.saveExperiment(validatedExperiment)
        if validatedExperiment.state == .running {
            activeExperiments.append(validatedExperiment)
        }
    }
    
    public func startExperiment(_ experimentId: String) async throws {
        var experiment = try await getExperiment(experimentId)
        experiment = Experiment(
            id: experiment.id,
            name: experiment.name,
            description: experiment.description,
            state: .running,
            variants: experiment.variants,
            primaryMetric: experiment.primaryMetric,
            secondaryMetrics: experiment.secondaryMetrics,
            targetAudience: experiment.targetAudience,
            startDate: Date(),
            endDate: experiment.endDate,
            minimumSampleSize: experiment.minimumSampleSize,
            confidenceLevel: experiment.confidenceLevel,
            metadata: experiment.metadata
        )
        
        try await storage.saveExperiment(experiment)
        if !activeExperiments.contains(where: { $0.id == experimentId }) {
            activeExperiments.append(experiment)
        }
    }
    
    public func stopExperiment(_ experimentId: String) async throws {
        var experiment = try await getExperiment(experimentId)
        experiment = Experiment(
            id: experiment.id,
            name: experiment.name,
            description: experiment.description,
            state: .completed,
            variants: experiment.variants,
            primaryMetric: experiment.primaryMetric,
            secondaryMetrics: experiment.secondaryMetrics,
            targetAudience: experiment.targetAudience,
            startDate: experiment.startDate,
            endDate: Date(),
            minimumSampleSize: experiment.minimumSampleSize,
            confidenceLevel: experiment.confidenceLevel,
            metadata: experiment.metadata
        )
        
        try await storage.saveExperiment(experiment)
        activeExperiments.removeAll { $0.id == experimentId }
    }
    
    // MARK: - User Assignment
    
    public func assignUserToExperiment(_ userId: String, experimentId: String) async throws -> Variant? {
        let experiment = try await getExperiment(experimentId)
        
        guard experiment.state == .running else {
            return nil
        }
        
        // 既に割り当て済みかチェック
        if let existingAssignment = try await storage.getUserAssignment(userId: userId, experimentId: experimentId) {
            return experiment.variants.first { $0.id == existingAssignment.variantId }
        }
        
        // オーディエンスフィルターをチェック
        if let targetAudience = experiment.targetAudience {
            let matches = await checkAudienceFilter(userId: userId, filter: targetAudience)
            guard matches else { return nil }
        }
        
        // バリアントを選択
        let selectedVariant = selectVariant(for: userId, in: experiment)
        
        // 割り当てを保存
        let assignment = ExperimentAssignment(
            experimentId: experimentId,
            userId: userId,
            variantId: selectedVariant.id
        )
        
        try await storage.saveAssignment(assignment)
        
        // ローカルキャッシュを更新
        if userAssignments[userId] == nil {
            userAssignments[userId] = []
        }
        userAssignments[userId]?.append(assignment)
        
        return selectedVariant
    }
    
    public func getUserVariant(userId: String, experimentId: String) async throws -> Variant? {
        if let assignment = try await storage.getUserAssignment(userId: userId, experimentId: experimentId) {
            let experiment = try await getExperiment(experimentId)
            return experiment.variants.first { $0.id == assignment.variantId }
        }
        return nil
    }
    
    // MARK: - Results Analysis
    
    public func getExperimentResults(_ experimentId: String) async throws -> [ExperimentResult] {
        let experiment = try await getExperiment(experimentId)
        var results: [ExperimentResult] = []
        
        let period = DateInterval(
            start: experiment.startDate ?? Date.distantPast,
            end: experiment.endDate ?? Date()
        )
        
        for variant in experiment.variants {
            let assignments = try await storage.getVariantAssignments(experimentId: experimentId, variantId: variant.id)
            let userIds = assignments.map { $0.userId }
            
            // Primary metric results
            let measurements = try await getKPIMeasurements(
                for: userIds,
                metric: experiment.primaryMetric,
                period: period
            )
            
            let result = ExperimentResult(
                experimentId: experimentId,
                variantId: variant.id,
                metric: experiment.primaryMetric,
                measurements: measurements
            )
            
            results.append(result)
        }
        
        return results
    }
    
    public func compareVariants(experimentId: String, controlVariantId: String, testVariantId: String) async throws -> ExperimentComparison {
        let results = try await getExperimentResults(experimentId)
        
        guard let controlResult = results.first(where: { $0.variantId == controlVariantId }),
              let testResult = results.first(where: { $0.variantId == testVariantId }) else {
            throw ABTestError.variantNotFound
        }
        
        return ExperimentComparison(controlResult: controlResult, testResult: testResult)
    }
    
    // MARK: - Private Methods
    
    private func loadActiveExperiments() {
        Task {
            do {
                let experiments = try await storage.getActiveExperiments()
                await MainActor.run {
                    activeExperiments = experiments
                }
            } catch {
                print("Failed to load active experiments: \(error)")
            }
        }
    }
    
    private func getExperiment(_ experimentId: String) async throws -> Experiment {
        if let experiment = activeExperiments.first(where: { $0.id == experimentId }) {
            return experiment
        }
        return try await storage.getExperiment(experimentId)
    }
    
    private func selectVariant(for userId: String, in experiment: Experiment) -> Variant {
        // ユーザーIDをハッシュして一貫した割り当てを保証
        let hash = abs(userId.hashValue) % 1000
        let threshold = Double(hash) / 1000.0
        
        var cumulativeWeight = 0.0
        for variant in experiment.variants {
            cumulativeWeight += variant.weight
            if threshold <= cumulativeWeight {
                return variant
            }
        }
        
        // Fallback to first variant
        return experiment.variants.first!
    }
    
    private func checkAudienceFilter(userId: String, filter: AudienceFilter) async -> Bool {
        // 実際の実装では、ユーザーの属性をチェック
        // 今回は簡略化してtrueを返す
        return true
    }
    
    private func getKPIMeasurements(for userIds: [String], metric: KPIType, period: DateInterval) async throws -> [KPIMeasurement] {
        // 実際の実装では、KPITrackerから特定ユーザーのメトリクスを取得
        // 今回は空の配列を返す
        return []
    }
}

// MARK: - Storage Protocol

public protocol ABTestStorageProtocol {
    func saveExperiment(_ experiment: Experiment) async throws
    func getExperiment(_ experimentId: String) async throws -> Experiment
    func getActiveExperiments() async throws -> [Experiment]
    func saveAssignment(_ assignment: ExperimentAssignment) async throws
    func getUserAssignment(userId: String, experimentId: String) async throws -> ExperimentAssignment?
    func getVariantAssignments(experimentId: String, variantId: String) async throws -> [ExperimentAssignment]
}

// MARK: - Core Data Implementation

public class CoreDataABTestStorage: ABTestStorageProtocol {
    
    public init() {}
    
    public func saveExperiment(_ experiment: Experiment) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Saving experiment \(experiment.id)")
    }
    
    public func getExperiment(_ experimentId: String) async throws -> Experiment {
        // CoreData実装（今回はMock実装）
        throw ABTestError.experimentNotFound
    }
    
    public func getActiveExperiments() async throws -> [Experiment] {
        // CoreData実装（今回はMock実装）
        return []
    }
    
    public func saveAssignment(_ assignment: ExperimentAssignment) async throws {
        // CoreData実装（今回はMock実装）
        print("CoreData: Saving assignment for user \(assignment.userId)")
    }
    
    public func getUserAssignment(userId: String, experimentId: String) async throws -> ExperimentAssignment? {
        // CoreData実装（今回はMock実装）
        return nil
    }
    
    public func getVariantAssignments(experimentId: String, variantId: String) async throws -> [ExperimentAssignment] {
        // CoreData実装（今回はMock実装）
        return []
    }
}

// MARK: - Errors

public enum ABTestError: Error {
    case experimentNotFound
    case variantNotFound
    case invalidVariantWeights
    case insufficientData
}