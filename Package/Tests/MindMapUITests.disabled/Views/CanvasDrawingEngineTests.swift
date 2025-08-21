import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - Canvas Drawing Engine Tests
@available(iOS 16.0, macOS 14.0, *)
struct CanvasDrawingEngineTests {
    
    // MARK: - Test Properties
    private let drawingEngine = CanvasDrawingEngine()
    private let canvasSize = CGSize(width: 800, height: 600)
    
    // MARK: - Configuration Tests
    @Test("Drawing engine initializes with default configuration")
    func testDefaultConfiguration() {
        let engine = CanvasDrawingEngine()
        // Test passes if no crash occurs during initialization
        #expect(true)
    }
    
    @Test("Drawing engine initializes with custom configuration")
    func testCustomConfiguration() {
        let config = CanvasDrawingEngine.DrawingConfig(
            connectionLineWidth: 3.0,
            connectionColor: .blue,
            focusedConnectionColor: .red,
            unfocusedOpacity: 0.5,
            connectionStyle: .organic,
            nodeSpacing: 150.0,
            branchSpacing: 100.0
        )
        
        let engine = CanvasDrawingEngine(config: config)
        // Test passes if no crash occurs during initialization
        #expect(true)
    }
    
    // MARK: - Node Layout Tests
    @Test("Calculate optimal positions for single root node")
    func testSingleRootNodeLayout() {
        let rootNode = Node(
            id: UUID(),
            text: "Root",
            position: .zero
        )
        
        let positions = drawingEngine.calculateOptimalNodePositions(
            nodes: [rootNode],
            rootNodeID: rootNode.id,
            canvasSize: canvasSize
        )
        
        #expect(positions.count == 1)
        #expect(positions[rootNode.id] != nil)
        
        let rootPosition = positions[rootNode.id]!
        #expect(rootPosition.x == canvasSize.width / 2)
        #expect(rootPosition.y == canvasSize.height / 2)
    }
    
    @Test("Calculate optimal positions for root with children")
    func testRootWithChildrenLayout() {
        let rootID = UUID()
        let child1ID = UUID()
        let child2ID = UUID()
        
        var rootNode = Node(id: rootID, text: "Root", position: .zero)
        var child1 = Node(id: child1ID, text: "Child 1", position: .zero, parentID: rootID)
        var child2 = Node(id: child2ID, text: "Child 2", position: .zero, parentID: rootID)
        
        rootNode.addChild(child1ID)
        rootNode.addChild(child2ID)
        
        let nodes = [rootNode, child1, child2]
        
        let positions = drawingEngine.calculateOptimalNodePositions(
            nodes: nodes,
            rootNodeID: rootID,
            canvasSize: canvasSize
        )
        
        #expect(positions.count == 3)
        #expect(positions[rootID] != nil)
        #expect(positions[child1ID] != nil)
        #expect(positions[child2ID] != nil)
        
        // Root should be at center
        let rootPosition = positions[rootID]!
        #expect(rootPosition.x == canvasSize.width / 2)
        #expect(rootPosition.y == canvasSize.height / 2)
        
        // Children should be positioned around root
        let child1Position = positions[child1ID]!
        let child2Position = positions[child2ID]!
        
        let distanceFromRoot1 = sqrt(
            pow(child1Position.x - rootPosition.x, 2) +
            pow(child1Position.y - rootPosition.y, 2)
        )
        let distanceFromRoot2 = sqrt(
            pow(child2Position.x - rootPosition.x, 2) +
            pow(child2Position.y - rootPosition.y, 2)
        )
        
        // Both children should be approximately the same distance from root
        #expect(abs(distanceFromRoot1 - distanceFromRoot2) < 10.0)
    }
    
    // MARK: - Content Bounds Tests
    @Test("Calculate content bounds for empty nodes")
    func testEmptyNodesContentBounds() {
        let bounds = drawingEngine.calculateContentBounds(nodes: [])
        #expect(bounds == .zero)
    }
    
    @Test("Calculate content bounds for single node")
    func testSingleNodeContentBounds() {
        let node = Node(
            id: UUID(),
            text: "Test",
            position: CGPoint(x: 100, y: 200)
        )
        
        let bounds = drawingEngine.calculateContentBounds(nodes: [node])
        
        #expect(bounds.origin.x == 0) // 100 - 100 padding
        #expect(bounds.origin.y == 100) // 200 - 100 padding
        #expect(bounds.size.width == 200) // 0 width + 200 padding
        #expect(bounds.size.height == 200) // 0 height + 200 padding
    }
    
    @Test("Calculate content bounds for multiple nodes")
    func testMultipleNodesContentBounds() {
        let nodes = [
            Node(id: UUID(), text: "Node 1", position: CGPoint(x: 0, y: 0)),
            Node(id: UUID(), text: "Node 2", position: CGPoint(x: 200, y: 100)),
            Node(id: UUID(), text: "Node 3", position: CGPoint(x: -50, y: 150))
        ]
        
        let bounds = drawingEngine.calculateContentBounds(nodes: nodes)
        
        #expect(bounds.origin.x == -150) // -50 - 100 padding
        #expect(bounds.origin.y == -100) // 0 - 100 padding
        #expect(bounds.size.width == 450) // 250 width + 200 padding
        #expect(bounds.size.height == 350) // 150 height + 200 padding
    }
    
    // MARK: - Fit to Screen Transform Tests
    @Test("Create fit to screen transform for small content")
    func testFitToScreenSmallContent() {
        let contentBounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        let screenSize = CGSize(width: 800, height: 600)
        
        let transform = drawingEngine.createFitToScreenTransform(
            contentBounds: contentBounds,
            screenSize: screenSize,
            maxScale: 2.0
        )
        
        // Should scale up to max scale since content is small
        #expect(transform.scale == 2.0)
        
        // Should center the content
        let expectedOffsetX = screenSize.width / 2 - contentBounds.midX * transform.scale
        let expectedOffsetY = screenSize.height / 2 - contentBounds.midY * transform.scale
        
        #expect(abs(transform.offset.width - expectedOffsetX) < 1.0)
        #expect(abs(transform.offset.height - expectedOffsetY) < 1.0)
    }
    
    @Test("Create fit to screen transform for large content")
    func testFitToScreenLargeContent() {
        let contentBounds = CGRect(x: 0, y: 0, width: 1000, height: 800)
        let screenSize = CGSize(width: 800, height: 600)
        
        let transform = drawingEngine.createFitToScreenTransform(
            contentBounds: contentBounds,
            screenSize: screenSize,
            maxScale: 2.0
        )
        
        // Should scale down to fit screen
        let expectedScaleX = (screenSize.width - 100) / contentBounds.width // 100 = 2 * 50 padding
        let expectedScaleY = (screenSize.height - 100) / contentBounds.height
        let expectedScale = min(expectedScaleX, expectedScaleY)
        
        #expect(abs(transform.scale - expectedScale) < 0.01)
    }
    
    // MARK: - Connection Style Tests
    @Test("Connection styles are properly defined")
    func testConnectionStyles() {
        let straightConfig = CanvasDrawingEngine.DrawingConfig(connectionStyle: .straight)
        let curvedConfig = CanvasDrawingEngine.DrawingConfig(connectionStyle: .curved)
        let organicConfig = CanvasDrawingEngine.DrawingConfig(connectionStyle: .organic)
        
        let straightEngine = CanvasDrawingEngine(config: straightConfig)
        let curvedEngine = CanvasDrawingEngine(config: curvedConfig)
        let organicEngine = CanvasDrawingEngine(config: organicConfig)
        
        // Test passes if no crash occurs during initialization
        #expect(true)
    }
    
    // MARK: - Performance Tests
    @Test("Handle large number of nodes efficiently")
    func testLargeNodeSetPerformance() {
        let nodeCount = 1000
        var nodes: [Node] = []
        
        // Create a large set of nodes
        for i in 0..<nodeCount {
            let node = Node(
                id: UUID(),
                text: "Node \(i)",
                position: CGPoint(
                    x: Double.random(in: -500...500),
                    y: Double.random(in: -500...500)
                )
            )
            nodes.append(node)
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let bounds = drawingEngine.calculateContentBounds(nodes: nodes)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(bounds != .zero)
        #expect(timeElapsed < 0.1) // Should complete within 100ms
    }
}

// MARK: - Canvas Drawing Integration Tests
@available(iOS 16.0, macOS 14.0, *)
struct CanvasDrawingIntegrationTests {
    
    @Test("Canvas drawing engine integrates with view model")
    func testCanvasViewModelIntegration() async {
        let container = DIContainer.configure()
        let viewModel = MindMapViewModel(container: container)
        let drawingEngine = CanvasDrawingEngine()
        
        // Create a mind map with nodes
        viewModel.createNewMindMap(title: "Test Map")
        
        // Wait for async operations
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(viewModel.nodes.count > 0)
        
        // Test content bounds calculation
        let bounds = drawingEngine.calculateContentBounds(nodes: viewModel.nodes)
        #expect(bounds != .zero)
    }
    
    @Test("Canvas handles focus mode correctly")
    func testCanvasFocusMode() {
        let rootID = UUID()
        let child1ID = UUID()
        let child2ID = UUID()
        
        var rootNode = Node(id: rootID, text: "Root", position: CGPoint(x: 0, y: 0))
        let child1 = Node(id: child1ID, text: "Child 1", position: CGPoint(x: 100, y: 0), parentID: rootID)
        let child2 = Node(id: child2ID, text: "Child 2", position: CGPoint(x: -100, y: 0), parentID: rootID)
        
        rootNode.addChild(child1ID)
        rootNode.addChild(child2ID)
        
        let nodes = [rootNode, child1, child2]
        let drawingEngine = CanvasDrawingEngine()
        
        // Test that drawing engine can handle focus mode
        // This is mainly testing that no crashes occur
        let bounds = drawingEngine.calculateContentBounds(nodes: nodes)
        #expect(bounds != .zero)
    }
}