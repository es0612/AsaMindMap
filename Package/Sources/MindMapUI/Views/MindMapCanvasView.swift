import SwiftUI
import MindMapCore

// MARK: - Mind Map Canvas View
@available(iOS 16.0, macOS 14.0, *)
public struct MindMapCanvasView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: MindMapViewModel
    @StateObject private var gestureManager = GestureManager()
    @State private var canvasSize: CGSize = .zero
    @State private var drawingEngine = CanvasDrawingEngine()
    
    // MARK: - Canvas Configuration
    private let canvasConfig = CanvasDrawingEngine.DrawingConfig(
        connectionLineWidth: 2.0,
        connectionColor: .primary,
        focusedConnectionColor: .blue,
        unfocusedOpacity: 0.3,
        connectionStyle: .curved,
        nodeSpacing: 120.0,
        branchSpacing: 80.0
    )
    
    // MARK: - Initialization
    public init(container: DIContainerProtocol) {
        self._viewModel = StateObject(wrappedValue: MindMapViewModel(container: container))
    }
    
    public init(viewModel: MindMapViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    // MARK: - Body
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.clear
                    .contentShape(Rectangle())
                    .gesture(gestureManager.makeCombinedCanvasGestures())
                    .onTapGesture(count: 2) {
                        handleDoubleTapOnCanvas()
                    }
                
                // Main Canvas with SwiftUI Canvas
                Canvas { context, size in
                    drawCanvasContent(context: context, size: size)
                }
                .scaleEffect(gestureManager.magnificationScale)
                .offset(gestureManager.panOffset)
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.panOffset)
                .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.magnificationScale)
                
                // Interactive Node Overlay
                nodeOverlay
                    .scaleEffect(gestureManager.magnificationScale)
                    .offset(gestureManager.panOffset)
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.panOffset)
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.magnificationScale)
            }
            .clipped()
            .onAppear {
                canvasSize = geometry.size
                setupGestureCallbacks()
                setupDrawingEngine()
                
                // Create initial mind map if none exists
                if viewModel.mindMap == nil {
                    viewModel.createNewMindMap()
                }
            }
            .onChange(of: geometry.size) { newSize in
                canvasSize = newSize
                updateCanvasLayout()
            }
            .onChange(of: viewModel.nodes) { _ in
                updateCanvasLayout()
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("マインドマップキャンバス")
        .accessibilityHint("ピンチでズーム、ドラッグで移動、ダブルタップで全体表示")
    }
    
    // MARK: - Canvas Drawing
    private func drawCanvasContent(context: GraphicsContext, size: CGSize) {
        // Draw background grid if needed
        drawBackgroundGrid(context: context, size: size)
        
        // Draw connections using the drawing engine
        drawingEngine.drawConnections(
            context: context,
            nodes: viewModel.nodes,
            focusedBranchID: viewModel.focusedBranchID,
            isFocusMode: viewModel.isFocusMode,
            transform: .identity // Transform is handled by SwiftUI
        )
    }
    
    private func drawBackgroundGrid(context: GraphicsContext, size: CGSize) {
        let gridSpacing: CGFloat = 50
        let gridColor = Color.gray.opacity(0.1)
        
        // Only draw grid when zoomed in enough
        guard gestureManager.magnificationScale > 1.2 else { return }
        
        var path = Path()
        
        // Vertical lines
        var x: CGFloat = 0
        while x <= size.width {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            x += gridSpacing
        }
        
        // Horizontal lines
        var y: CGFloat = 0
        while y <= size.height {
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: size.width, y: y))
            y += gridSpacing
        }
        
        context.stroke(path, with: .color(gridColor), lineWidth: 0.5)
    }
    
    // MARK: - Node Overlay
    @ViewBuilder
    private var nodeOverlay: some View {
        ZStack {
            ForEach(viewModel.nodes, id: \.id) { node in
                NodeView(
                    node: node,
                    isSelected: viewModel.selectedNodeIDs.contains(node.id),
                    isEditing: viewModel.editingNodeID == node.id,
                    isFocused: viewModel.isNodeInFocusedBranch(node.id),
                    isFocusMode: viewModel.isFocusMode
                )
                .position(node.position)
                .gesture(gestureManager.makeCombinedNodeGestures(nodeID: node.id))
                .zIndex(viewModel.selectedNodeIDs.contains(node.id) ? 2 : 1)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedNodeIDs.contains(node.id))
                .animation(.easeInOut(duration: 0.3), value: viewModel.isNodeInFocusedBranch(node.id))
            }
        }
    }
    
    // MARK: - Setup Methods
    private func setupDrawingEngine() {
        drawingEngine = CanvasDrawingEngine(config: canvasConfig)
    }
    
    private func updateCanvasLayout() {
        // Update node positions if needed for optimal layout
        guard !viewModel.nodes.isEmpty, canvasSize != .zero else { return }
        
        // Calculate optimal positions for new nodes
        let optimalPositions = drawingEngine.calculateOptimalNodePositions(
            nodes: viewModel.nodes,
            rootNodeID: viewModel.mindMap?.rootNodeID,
            canvasSize: canvasSize
        )
        
        // Update positions for nodes that don't have positions yet
        for (nodeID, position) in optimalPositions {
            if let nodeIndex = viewModel.nodes.firstIndex(where: { $0.id == nodeID }) {
                let node = viewModel.nodes[nodeIndex]
                if node.position == .zero {
                    viewModel.updateNodePosition(nodeID, position: position)
                }
            }
        }
    }
    
    // MARK: - Gesture Setup
    private func setupGestureCallbacks() {
        gestureManager.onPanChanged = { offset in
            viewModel.panOffset = offset
        }
        
        gestureManager.onZoomChanged = { scale in
            viewModel.zoomScale = scale
        }
        
        gestureManager.onDoubleTap = {
            handleDoubleTapOnCanvas()
        }
        
        gestureManager.onNodeTap = { nodeID in
            handleNodeTap(nodeID)
        }
        
        gestureManager.onNodeDoubleTap = { nodeID in
            handleNodeDoubleTap(nodeID)
        }
        
        gestureManager.onNodeLongPress = { nodeID in
            handleNodeLongPress(nodeID)
        }
    }
    
    // MARK: - Gesture Handlers
    private func handleDoubleTapOnCanvas() {
        if viewModel.isFocusMode {
            viewModel.exitFocusMode()
        } else {
            viewModel.fitToScreen()
            fitCanvasToScreen()
        }
    }
    
    private func handleNodeTap(_ nodeID: UUID) {
        if viewModel.isFocusMode {
            viewModel.exitFocusMode()
        } else {
            viewModel.selectNode(nodeID)
        }
    }
    
    private func handleNodeDoubleTap(_ nodeID: UUID) {
        viewModel.startEditingNode(nodeID)
    }
    
    private func handleNodeLongPress(_ nodeID: UUID) {
        // Focus on the branch containing this node
        viewModel.focusOnBranch(nodeID)
        
        // Center the canvas on this node
        if let node = viewModel.nodes.first(where: { $0.id == nodeID }) {
            gestureManager.animateToCenter(on: node.position, screenSize: canvasSize)
        }
    }
    
    // MARK: - Canvas Operations
    private func fitCanvasToScreen() {
        guard !viewModel.nodes.isEmpty else { return }
        
        let contentBounds = drawingEngine.calculateContentBounds(nodes: viewModel.nodes)
        let transform = drawingEngine.createFitToScreenTransform(
            contentBounds: contentBounds,
            screenSize: canvasSize,
            maxScale: 2.0
        )
        
        // Animate to fit content
        withAnimation(.easeInOut(duration: 0.6)) {
            gestureManager.setZoomScale(transform.scale, animated: false)
            gestureManager.setPanOffset(transform.offset, animated: false)
        }
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 16.0, macOS 14.0, *)
struct MindMapCanvasView_Previews: PreviewProvider {
    static var previews: some View {
        MindMapCanvasView(container: DIContainer.configure())
            .previewDisplayName("Mind Map Canvas")
    }
}
#endif