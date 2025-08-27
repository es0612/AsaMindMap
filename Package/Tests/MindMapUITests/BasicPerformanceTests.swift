import XCTest
@testable import MindMapUI
@testable import MindMapCore

final class BasicPerformanceTests: XCTestCase {
    
    func testPerformanceManagerBasics() {
        let manager = PerformanceManager()
        
        XCTAssertNotNil(manager)
        XCTAssertFalse(manager.isVirtualizationEnabled)
        XCTAssertEqual(manager.currentFrameRate, 60)
    }
    
    func testNodeMemoryPool() {
        let pool = NodeMemoryPool()
        
        XCTAssertEqual(pool.totalAllocatedMemory, 0)
        
        let node = pool.acquireNode()
        XCTAssertNotNil(node)
        XCTAssertGreaterThan(pool.totalAllocatedMemory, 0)
        
        pool.releaseNode(node)
    }
    
    func testBatteryEfficientDrawing() {
        let drawing = BatteryEfficientDrawing()
        
        XCTAssertEqual(drawing.targetFrameRate, 60)
        
        drawing.setBatteryLevel(0.2) // Low battery
        XCTAssertEqual(drawing.targetFrameRate, 30)
        
        drawing.setBatteryLevel(0.8) // High battery
        XCTAssertEqual(drawing.targetFrameRate, 60)
    }
    
    func testCoreAnimationOptimizer() {
        let optimizer = CoreAnimationOptimizer()
        
        XCTAssertEqual(optimizer.measuredFrameRate, 60.0)
        
        optimizer.animateNodeTransition(
            from: CGPoint(x: 0, y: 0),
            to: CGPoint(x: 100, y: 100),
            duration: 0.1
        )
        
        // Frame rate measurement happens asynchronously
        let expectation = expectation(description: "Animation completed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testLazyNodeLoader() {
        let loader = LazyNodeLoader()
        
        XCTAssertEqual(loader.loadedNodeCount, 0)
        
        let testNodes = createTestNodes(count: 5)
        loader.loadNodesForViewport(rootNodes: testNodes, visibleDepth: 2)
        
        XCTAssertGreaterThan(loader.loadedNodeCount, 0)
    }
    
    func testPerformanceBenchmark() {
        let benchmark = PerformanceBenchmark()
        
        let results = benchmark.runFullSuite()
        
        XCTAssertGreaterThan(results.nodeRenderTime, 0)
        XCTAssertGreaterThan(results.memoryUsage, 0)
        XCTAssertGreaterThan(results.batteryEfficiency, 0)
    }
    
    func testMemoryLeakTracker() {
        let tracker = MemoryLeakTracker()
        
        XCTAssertEqual(tracker.unreleasedObjects, 0)
        
        let testObject = NSObject()
        tracker.trackObject(testObject)
        XCTAssertEqual(tracker.unreleasedObjects, 1)
        
        tracker.releaseObject(testObject)
        XCTAssertEqual(tracker.unreleasedObjects, 0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestNodes(count: Int) -> [Node] {
        var nodes: [Node] = []
        
        for i in 0..<count {
            let node = Node(
                text: "Test Node \(i)",
                position: CGPoint(x: Double(i * 100), y: Double(i * 50))
            )
            nodes.append(node)
        }
        
        return nodes
    }
}

// Note: Mock classes are defined in PerformanceTests.swift to avoid duplication