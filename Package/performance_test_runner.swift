import Foundation

// MARK: - Performance Test Framework

struct PerformanceTestResult {
    let testName: String
    let executionTime: TimeInterval
    let memoryUsage: Double
    let throughput: Double?
    let passed: Bool
    let details: [String: Any]
    
    init(testName: String, executionTime: TimeInterval, memoryUsage: Double = 0, throughput: Double? = nil, passed: Bool, details: [String: Any] = [:]) {
        self.testName = testName
        self.executionTime = executionTime
        self.memoryUsage = memoryUsage
        self.throughput = throughput
        self.passed = passed
        self.details = details
    }
}

struct PerformanceTestSuite {
    let name: String
    var results: [PerformanceTestResult] = []
    
    init(name: String) {
        self.name = name
    }
    
    mutating func addResult(_ result: PerformanceTestResult) {
        results.append(result)
    }
    
    var passRate: Double {
        let passedTests = results.filter { $0.passed }.count
        return results.isEmpty ? 0 : Double(passedTests) / Double(results.count)
    }
    
    var averageExecutionTime: TimeInterval {
        let totalTime = results.reduce(0) { $0 + $1.executionTime }
        return results.isEmpty ? 0 : totalTime / Double(results.count)
    }
    
    var totalMemoryUsage: Double {
        return results.reduce(0) { $0 + $1.memoryUsage }
    }
    
    func generateReport() -> String {
        var report = """
        \n📊 Performance Test Report: \(name)
        =====================================
        Total Tests: \(results.count)
        Passed: \(results.filter { $0.passed }.count)
        Failed: \(results.filter { !$0.passed }.count)
        Pass Rate: \(String(format: "%.1f", passRate * 100))%
        Average Execution Time: \(String(format: "%.3f", averageExecutionTime))s
        Total Memory Usage: \(String(format: "%.1f", totalMemoryUsage))MB
        
        Individual Test Results:
        """
        
        for result in results {
            let status = result.passed ? "✅" : "❌"
            report += """
            \n\(status) \(result.testName)
              Execution Time: \(String(format: "%.3f", result.executionTime))s
              Memory Usage: \(String(format: "%.1f", result.memoryUsage))MB
            """
            
            if let throughput = result.throughput {
                report += "\n  Throughput: \(String(format: "%.1f", throughput)) ops/sec"
            }
            
            if !result.details.isEmpty {
                report += "\n  Details:"
                for (key, value) in result.details {
                    report += "\n    \(key): \(value)"
                }
            }
        }
        
        return report
    }
}

// MARK: - Mock Implementations for Performance Testing

class MockPerformanceRepository {
    private var data: [String: Any] = [:]
    private let processingDelay: TimeInterval
    
    init(processingDelay: TimeInterval = 0.001) {
        self.processingDelay = processingDelay
    }
    
    func search(query: String, limit: Int) async -> [MockSearchResult] {
        // Simulate processing time
        try? await Task.sleep(nanoseconds: UInt64(processingDelay * 1_000_000_000))
        
        // Generate mock results
        let resultCount = min(limit, Int.random(in: 10...100))
        return (0..<resultCount).map { i in
            MockSearchResult(
                id: UUID(),
                title: "Result \(i) for query: \(query)",
                score: Double.random(in: 0.1...1.0)
            )
        }
    }
    
    func createIndex(itemCount: Int) async -> Bool {
        // Simulate index creation time based on item count
        let indexTime = Double(itemCount) * 0.0001 // 0.1ms per item
        try? await Task.sleep(nanoseconds: UInt64(indexTime * 1_000_000_000))
        return true
    }
}

struct MockSearchResult {
    let id: UUID
    let title: String
    let score: Double
}

// MARK: - Performance Test Runner

class PerformanceTestRunner {
    var testSuite: PerformanceTestSuite
    private let repository: MockPerformanceRepository
    
    init(suiteName: String, processingDelay: TimeInterval = 0.001) {
        self.testSuite = PerformanceTestSuite(name: suiteName)
        self.repository = MockPerformanceRepository(processingDelay: processingDelay)
    }
    
    // MARK: - Search Performance Tests
    
    func runBasicSearchPerformanceTest() async {
        let testName = "Basic Search Performance"
        let queries = ["test", "performance", "search", "data", "result"]
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        var totalResults = 0
        for query in queries {
            let results = await repository.search(query: query, limit: 50)
            totalResults += results.count
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()
        
        let executionTime = endTime - startTime
        let memoryUsage = endMemory - startMemory
        let throughput = Double(queries.count) / executionTime
        
        let passed = executionTime < 0.1 && memoryUsage < 10.0
        
        let result = PerformanceTestResult(
            testName: testName,
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            throughput: throughput,
            passed: passed,
            details: [
                "queries": queries.count,
                "total_results": totalResults,
                "avg_results_per_query": Double(totalResults) / Double(queries.count)
            ]
        )
        
        testSuite.addResult(result)
    }
    
    func runConcurrentSearchPerformanceTest() async {
        let testName = "Concurrent Search Performance"
        let concurrentQueries = 20
        let queries = (1...concurrentQueries).map { "concurrent_query_\($0)" }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        let results = await withTaskGroup(of: [MockSearchResult].self) { group in
            for query in queries {
                group.addTask {
                    return await self.repository.search(query: query, limit: 30)
                }
            }
            
            var allResults: [[MockSearchResult]] = []
            for await result in group {
                allResults.append(result)
            }
            return allResults
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()
        
        let executionTime = endTime - startTime
        let memoryUsage = endMemory - startMemory
        let throughput = Double(concurrentQueries) / executionTime
        let totalResults = results.reduce(0) { $0 + $1.count }
        
        let passed = executionTime < 0.5 && memoryUsage < 20.0 && results.count == concurrentQueries
        
        let result = PerformanceTestResult(
            testName: testName,
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            throughput: throughput,
            passed: passed,
            details: [
                "concurrent_queries": concurrentQueries,
                "total_results": totalResults,
                "completed_queries": results.count
            ]
        )
        
        testSuite.addResult(result)
    }
    
    func runScalabilityTest() async {
        let testName = "Scalability Test"
        let dataSizes = [100, 500, 1000, 5000]
        var scalabilityResults: [(size: Int, time: TimeInterval)] = []
        
        let startMemory = getCurrentMemoryUsage()
        
        for dataSize in dataSizes {
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = await repository.createIndex(itemCount: dataSize)
            let _ = await repository.search(query: "scalability_test", limit: 50)
            let endTime = CFAbsoluteTimeGetCurrent()
            
            let executionTime = endTime - startTime
            scalabilityResults.append((size: dataSize, time: executionTime))
        }
        
        let endMemory = getCurrentMemoryUsage()
        let totalExecutionTime = scalabilityResults.reduce(0) { $0 + $1.time }
        let memoryUsage = endMemory - startMemory
        
        // Check if performance scales reasonably (should be roughly linear)
        let firstTime = scalabilityResults.first?.time ?? 0
        let lastTime = scalabilityResults.last?.time ?? 0
        let firstSize = Double(scalabilityResults.first?.size ?? 1)
        let lastSize = Double(scalabilityResults.last?.size ?? 1)
        
        let scalingFactor = (lastTime / firstTime) / (lastSize / firstSize)
        let passed = scalingFactor < 2.0 && totalExecutionTime < 5.0 // Reasonable scaling
        
        let result = PerformanceTestResult(
            testName: testName,
            executionTime: totalExecutionTime,
            memoryUsage: memoryUsage,
            throughput: nil,
            passed: passed,
            details: [
                "data_sizes": dataSizes,
                "scaling_factor": String(format: "%.2f", scalingFactor),
                "results": scalabilityResults.map { "Size \($0.size): \(String(format: "%.3f", $0.time))s" }
            ]
        )
        
        testSuite.addResult(result)
    }
    
    func runMemoryLeakTest() async {
        let testName = "Memory Leak Test"
        let iterations = 1000
        
        let startMemory = getCurrentMemoryUsage()
        let checkpoints = [100, 300, 500, 700, 900]
        var memoryCheckpoints: [(iteration: Int, memory: Double)] = []
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 1...iterations {
            let _ = await repository.search(query: "memory_test_\(i)", limit: 20)
            
            if checkpoints.contains(i) {
                let currentMemory = getCurrentMemoryUsage()
                memoryCheckpoints.append((iteration: i, memory: currentMemory - startMemory))
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()
        
        let executionTime = endTime - startTime
        let totalMemoryGrowth = endMemory - startMemory
        
        // Check for memory leaks (should not grow linearly with iterations)
        let firstCheckpoint = memoryCheckpoints.first?.memory ?? 0
        let lastCheckpoint = memoryCheckpoints.last?.memory ?? 0
        let memoryGrowthRate = (lastCheckpoint - firstCheckpoint) / Double(iterations - 100)
        
        let passed = totalMemoryGrowth < 50.0 && memoryGrowthRate < 0.1 // <0.1MB per 1000 operations
        
        let result = PerformanceTestResult(
            testName: testName,
            executionTime: executionTime,
            memoryUsage: totalMemoryGrowth,
            throughput: Double(iterations) / executionTime,
            passed: passed,
            details: [
                "iterations": iterations,
                "memory_growth_rate": String(format: "%.4f", memoryGrowthRate),
                "checkpoints": memoryCheckpoints.map { "Iter \($0.iteration): \(String(format: "%.1f", $0.memory))MB" }
            ]
        )
        
        testSuite.addResult(result)
    }
    
    func runThroughputTest() async {
        let testName = "Throughput Test"
        let duration: TimeInterval = 5.0 // 5 seconds
        var operationCount = 0
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let startMemory = getCurrentMemoryUsage()
        
        while CFAbsoluteTimeGetCurrent() - startTime < duration {
            let _ = await repository.search(query: "throughput_test_\(operationCount)", limit: 10)
            operationCount += 1
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let endMemory = getCurrentMemoryUsage()
        
        let executionTime = endTime - startTime
        let memoryUsage = endMemory - startMemory
        let throughput = Double(operationCount) / executionTime
        
        let passed = throughput > 100.0 && memoryUsage < 30.0 // >100 ops/sec
        
        let result = PerformanceTestResult(
            testName: testName,
            executionTime: executionTime,
            memoryUsage: memoryUsage,
            throughput: throughput,
            passed: passed,
            details: [
                "operations": operationCount,
                "duration": String(format: "%.1f", duration),
                "ops_per_second": String(format: "%.1f", throughput)
            ]
        )
        
        testSuite.addResult(result)
    }
    
    // MARK: - Test Execution
    
    func runAllTests() async -> String {
        print("🚀 Starting Performance Tests...")
        
        await runBasicSearchPerformanceTest()
        await runConcurrentSearchPerformanceTest()
        await runScalabilityTest()
        await runMemoryLeakTest()
        await runThroughputTest()
        
        return testSuite.generateReport()
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentMemoryUsage() -> Double {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(taskInfo.resident_size) / (1024 * 1024) // MB
        }
        return 0.0
    }
}

// MARK: - Optimization Analyzer

struct OptimizationAnalyzer {
    static func analyzeResults(_ results: [PerformanceTestResult]) -> [String] {
        var recommendations: [String] = []
        
        for result in results {
            if !result.passed {
                if result.executionTime > 1.0 {
                    recommendations.append("⚠️ \(result.testName): 実行時間が長すぎます。インデックス最適化やキャッシュの実装を検討してください。")
                }
                
                if result.memoryUsage > 100.0 {
                    recommendations.append("⚠️ \(result.testName): メモリ使用量が多すぎます。メモリリークの確認やデータ構造の最適化を行ってください。")
                }
                
                if let throughput = result.throughput, throughput < 50.0 {
                    recommendations.append("⚠️ \(result.testName): スループットが低すぎます。並行処理の改善や処理アルゴリズムの最適化を検討してください。")
                }
            }
        }
        
        // General optimization recommendations
        recommendations.append("💡 パフォーマンス最適化の推奨事項:")
        recommendations.append("  - インメモリキャッシュの実装")
        recommendations.append("  - 検索インデックスの事前構築")
        recommendations.append("  - 結果のページング処理")
        recommendations.append("  - バックグラウンド処理の活用")
        recommendations.append("  - データベース接続プールの使用")
        
        return recommendations
    }
}

// MARK: - Main Performance Test Execution

print("🔍 Search Performance Test Suite")
print("===============================")

let testRunner = PerformanceTestRunner(suiteName: "Search Engine Performance Tests")
let report = await testRunner.runAllTests()

print(report)

let recommendations = OptimizationAnalyzer.analyzeResults(testRunner.testSuite.results)
print("\n🎯 Optimization Recommendations")
print("==============================")
for recommendation in recommendations {
    print(recommendation)
}

print("\n✅ Performance testing completed!")