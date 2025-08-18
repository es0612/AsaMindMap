import Testing
import SwiftUI
@testable import MindMapUI
@testable import MindMapCore

// MARK: - Gesture Integration Demo
// This demonstrates the enhanced gesture functionality implemented in Task 7

@MainActor
struct GestureIntegrationDemo {
    
    @Test("Enhanced gesture system integration works")
    func testEnhancedGestureIntegration() async {
        // Given - Create the enhanced gesture system
        let gestureManager = GestureManager()
        let pencilManager = ApplePencilManager()
        let selectionManager = NodeSelectionManager()
        let gestureCoordinator = GestureCoordinator(
            gestureManager: gestureManager,
            pencilManager: pencilManager,
            selectionManager: selectionManager
        )
        
        // Test basic initialization
        #expect(gestureCoordinator.interactionMode == .navigation)
        #expect(gestureManager.magnificationScale == 1.0)
        #expect(gestureManager.panOffset == .zero)
        #expect(selectionManager.selectedNodeIDs.isEmpty)
        #expect(pencilManager.currentTool == .pen)
        
        // Test interaction mode switching
        gestureCoordinator.setInteractionMode(.drawing)
        #expect(gestureCoordinator.interactionMode == .drawing)
        #expect(pencilManager.isDrawingMode == true)
        
        gestureCoordinator.setInteractionMode(.selection)
        #expect(gestureCoordinator.interactionMode == .selection)
        #expect(selectionManager.multiSelectMode == true)
        
        gestureCoordinator.setInteractionMode(.editing)
        #expect(gestureCoordinator.interactionMode == .editing)
        
        // Test gesture capability checking
        #expect(gestureCoordinator.canHandleGesture(.pan) == false) // Not allowed in editing mode
        #expect(gestureCoordinator.canHandleGesture(.tap) == true)   // Allowed in editing mode
        
        gestureCoordinator.setInteractionMode(.navigation)
        #expect(gestureCoordinator.canHandleGesture(.pan) == true)   // Allowed in navigation mode
        #expect(gestureCoordinator.canHandleGesture(.zoom) == true)  // Allowed in navigation mode
        
        // Test node selection
        let nodeID = UUID()
        selectionManager.selectNode(nodeID)
        #expect(selectionManager.selectedNodeIDs.contains(nodeID))
        
        // Test multi-selection
        selectionManager.enableMultiSelectMode()
        let nodeID2 = UUID()
        selectionManager.selectNode(nodeID2, addToSelection: true)
        #expect(selectionManager.selectedNodeIDs.count == 2)
        #expect(selectionManager.selectedNodeIDs.contains(nodeID))
        #expect(selectionManager.selectedNodeIDs.contains(nodeID2))
        
        // Test Apple Pencil tool switching
        pencilManager.selectTool(.marker)
        #expect(pencilManager.currentTool == .marker)
        #expect(pencilManager.strokeWidth == 8.0)
        #expect(pencilManager.strokeColor == .yellow)
        
        pencilManager.selectTool(.eraser)
        #expect(pencilManager.currentTool == .eraser)
        #expect(pencilManager.isDrawingMode == false)
        
        // Test gesture state management
        gestureManager.setZoomScale(2.0, animated: false)
        #expect(gestureManager.magnificationScale == 2.0)
        #expect(gestureManager.lastMagnificationScale == 2.0)
        
        let testOffset = CGSize(width: 100, height: 50)
        gestureManager.setPanOffset(testOffset, animated: false)
        #expect(gestureManager.panOffset == testOffset)
        #expect(gestureManager.lastPanOffset == testOffset)
        
        // Test coordinate conversion
        let screenPoint = CGPoint(x: 200, y: 150)
        let canvasPoint = gestureManager.convertPointToCanvas(screenPoint)
        let backToScreen = gestureManager.convertPointFromCanvas(canvasPoint)
        
        // Should be approximately equal (allowing for floating point precision)
        #expect(abs(backToScreen.x - screenPoint.x) < 0.1)
        #expect(abs(backToScreen.y - screenPoint.y) < 0.1)
        
        // Test reset functionality
        gestureCoordinator.resetAllGestures()
        #expect(gestureCoordinator.interactionMode == .navigation)
        #expect(gestureManager.magnificationScale == 1.0)
        #expect(gestureManager.panOffset == .zero)
        #expect(selectionManager.selectedNodeIDs.isEmpty)
        #expect(selectionManager.isEditingText == false)
        
        print("✅ Enhanced gesture system integration test passed!")
        print("   - Gesture coordination works correctly")
        print("   - Interaction modes switch properly")
        print("   - Node selection and multi-selection work")
        print("   - Apple Pencil tool switching works")
        print("   - Coordinate conversion is accurate")
        print("   - Reset functionality works")
    }
    
    @Test("Drag gesture enhancements work")
    func testDragGestureEnhancements() async {
        // Given
        let gestureManager = GestureManager()
        let selectionManager = NodeSelectionManager()
        
        // Test drag state tracking
        #expect(gestureManager.isDraggingNode == false)
        #expect(gestureManager.draggedNodeID == nil)
        
        // Test drag preview management
        selectionManager.startDragPreview(at: CGPoint(x: 100, y: 100))
        #expect(selectionManager.showDragPreview == true)
        #expect(selectionManager.dragPreviewPosition == CGPoint(x: 100, y: 100))
        
        selectionManager.updateDragPreview(to: CGPoint(x: 150, y: 150))
        #expect(selectionManager.dragPreviewPosition == CGPoint(x: 150, y: 150))
        
        selectionManager.endDragPreview()
        #expect(selectionManager.showDragPreview == false)
        #expect(selectionManager.dragPreviewPosition == .zero)
        
        // Test connection preview management
        selectionManager.startConnectionPreview(from: CGPoint(x: 50, y: 50))
        #expect(selectionManager.showConnectionPreview == true)
        #expect(selectionManager.connectionPreviewStart == CGPoint(x: 50, y: 50))
        
        selectionManager.updateConnectionPreview(to: CGPoint(x: 200, y: 200))
        #expect(selectionManager.connectionPreviewEnd == CGPoint(x: 200, y: 200))
        
        selectionManager.endConnectionPreview()
        #expect(selectionManager.showConnectionPreview == false)
        #expect(selectionManager.connectionPreviewStart == .zero)
        #expect(selectionManager.connectionPreviewEnd == .zero)
        
        print("✅ Drag gesture enhancements test passed!")
        print("   - Drag state tracking works")
        print("   - Drag preview management works")
        print("   - Connection preview management works")
    }
    
    @Test("Apple Pencil enhancements work")
    func testApplePencilEnhancements() async {
        // Given
        let pencilManager = ApplePencilManager()
        
        // Test enhanced pencil properties
        #expect(pencilManager.pencilPressure == 0.0)
        #expect(pencilManager.pencilAzimuth == 0.0)
        #expect(pencilManager.pencilAltitude == 0.0)
        #expect(pencilManager.isHoveringWithPencil == false)
        
        // Test tool switching with enhanced properties
        pencilManager.selectTool(.pen)
        #expect(pencilManager.currentTool == .pen)
        #expect(pencilManager.strokeWidth == 2.0)
        #expect(pencilManager.strokeColor == .black)
        #expect(pencilManager.isDrawingMode == true)
        
        pencilManager.selectTool(.pencil)
        #expect(pencilManager.currentTool == .pencil)
        #expect(pencilManager.strokeWidth == 1.5)
        #expect(pencilManager.strokeColor == .gray)
        
        pencilManager.selectTool(.marker)
        #expect(pencilManager.currentTool == .marker)
        #expect(pencilManager.strokeWidth == 8.0)
        #expect(pencilManager.strokeColor == .yellow)
        
        // Test drawing mode toggle
        pencilManager.toggleDrawingMode()
        #expect(pencilManager.isDrawingMode == false)
        #expect(pencilManager.currentTool == .eraser)
        
        pencilManager.toggleDrawingMode()
        #expect(pencilManager.isDrawingMode == true)
        #expect(pencilManager.currentTool == .pen)
        
        print("✅ Apple Pencil enhancements test passed!")
        print("   - Enhanced pencil properties work")
        print("   - Tool switching with properties works")
        print("   - Drawing mode toggle works")
    }
}