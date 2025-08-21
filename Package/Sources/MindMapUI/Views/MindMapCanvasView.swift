import SwiftUI
import MindMapCore

// MARK: - Mind Map Canvas View
@available(iOS 16.0, macOS 14.0, *)
public struct MindMapCanvasView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: MindMapViewModel
    @StateObject private var gestureCoordinator = GestureCoordinator()
    @State private var canvasSize: CGSize = .zero
    @State private var drawingEngine = CanvasDrawingEngine()
    
    // MARK: - Gesture Managers (accessed through coordinator)
    private var gestureManager: GestureManager { gestureCoordinator.gestureManager }
    private var pencilManager: ApplePencilManager { gestureCoordinator.pencilManager }
    private var selectionManager: NodeSelectionManager { gestureCoordinator.selectionManager }
    
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
    
    public init(viewModel: MindMapViewModel, gestureCoordinator: GestureCoordinator) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._gestureCoordinator = StateObject(wrappedValue: gestureCoordinator)
    }
    
    // MARK: - Body
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundLayer
                
                // Main Canvas with SwiftUI Canvas
                canvasLayer
                
                // Interactive Node Overlay
                nodeOverlay
                
                // Apple Pencil Drawing Overlay (disabled for now)
                // if gestureCoordinator.interactionMode == .drawing {
                //     pencilDrawingOverlay
                // }
                
                // Selection Overlay
                selectionOverlay
                
                // Drag Preview Overlay
                dragPreviewOverlay
                
                // Connection Preview Overlay
                connectionPreviewOverlay
                
                // Context Menu
                if selectionManager.showContextMenu {
                    contextMenuOverlay
                }
            }
            .clipped()
            .selectionGesture(selectionManager: selectionManager, nodes: viewModel.nodes)
            .onAppear {
                canvasSize = geometry.size
                setupGestureCoordination()
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
                selectionManager.updateSelectionBounds(with: viewModel.nodes)
            }
            .onReceive(gestureCoordinator.$interactionMode) { mode in
                handleInteractionModeChange(mode)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("マインドマップキャンバス")
        .accessibilityHint(accessibilityHint)
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
    
    // MARK: - Background Layer
    @ViewBuilder
    private var backgroundLayer: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(gestureManager.makeCombinedCanvasGestures())
            .onTapGesture(count: 2, coordinateSpace: .local) { location in
                handleDoubleTapOnCanvas(at: location)
            }
    }
    
    // MARK: - Canvas Layer
    @ViewBuilder
    private var canvasLayer: some View {
        Canvas { context, size in
            drawCanvasContent(context: context, size: size)
        }
        .scaleEffect(gestureManager.magnificationScale)
        .offset(gestureManager.panOffset)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.panOffset)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.magnificationScale)
    }
    
    // MARK: - Node Overlay
    @ViewBuilder
    private var nodeOverlay: some View {
        ZStack {
            ForEach(viewModel.nodes, id: \.id) { node in
                NodeView(
                    node: node,
                    isSelected: selectionManager.selectedNodeIDs.contains(node.id),
                    isEditing: selectionManager.editingNodeID == node.id,
                    isFocused: viewModel.isNodeInFocusedBranch(node.id),
                    isFocusMode: viewModel.isFocusMode,
                    media: viewModel.getMediaForNode(node.id),
                    onAddMedia: {
                        viewModel.showMediaPicker(for: node.id)
                    },
                    onMediaTap: { media in
                        // Handle media tap - could open media viewer
                    },
                    onRemoveMedia: { media in
                        viewModel.removeMediaFromNode(media, nodeID: node.id)
                    }
                )
                .position(node.position)
                .gesture(makeNodeGestures(nodeID: node.id))
                .zIndex(selectionManager.selectedNodeIDs.contains(node.id) ? 2 : 1)
                .opacity(getNodeOpacity(node))
                .scaleEffect(getNodeScale(node))
                .animation(.easeInOut(duration: 0.2), value: selectionManager.selectedNodeIDs.contains(node.id))
                .animation(.easeInOut(duration: 0.3), value: viewModel.isNodeInFocusedBranch(node.id))
            }
        }
        .scaleEffect(gestureManager.magnificationScale)
        .offset(gestureManager.panOffset)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.panOffset)
        .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.8), value: gestureManager.magnificationScale)
    }
    
    // MARK: - Pencil Drawing Overlay (disabled for now)
    @ViewBuilder
    private var pencilDrawingOverlay: some View {
        // PencilKit functionality will be implemented later
        EmptyView()
    }
    
    // MARK: - Selection Overlay
    @ViewBuilder
    private var selectionOverlay: some View {
        if !selectionManager.selectedNodeIDs.isEmpty && selectionManager.selectionBounds != .zero {
            Rectangle()
                .stroke(Color.blue, lineWidth: 2)
                .background(Color.blue.opacity(0.1))
                .frame(
                    width: selectionManager.selectionBounds.width,
                    height: selectionManager.selectionBounds.height
                )
                .position(
                    x: selectionManager.selectionBounds.midX,
                    y: selectionManager.selectionBounds.midY
                )
                .scaleEffect(gestureManager.magnificationScale)
                .offset(gestureManager.panOffset)
                .animation(.easeInOut(duration: 0.2), value: selectionManager.selectionBounds)
        }
    }
    
    // MARK: - Drag Preview Overlay
    @ViewBuilder
    private var dragPreviewOverlay: some View {
        if selectionManager.showDragPreview {
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: 60, height: 60)
                .position(selectionManager.dragPreviewPosition)
                .scaleEffect(gestureManager.magnificationScale)
                .offset(gestureManager.panOffset)
                .animation(.easeInOut(duration: 0.1), value: selectionManager.dragPreviewPosition)
        }
    }
    
    // MARK: - Connection Preview Overlay
    @ViewBuilder
    private var connectionPreviewOverlay: some View {
        if selectionManager.showConnectionPreview {
            Canvas { context, size in
                var path = Path()
                path.move(to: selectionManager.connectionPreviewStart)
                path.addLine(to: selectionManager.connectionPreviewEnd)
                
                context.stroke(
                    path,
                    with: .color(.blue.opacity(0.7)),
                    style: StrokeStyle(lineWidth: 3, dash: [5, 5])
                )
                
                // Draw arrow at end
                let arrowSize: CGFloat = 10
                let angle = atan2(
                    selectionManager.connectionPreviewEnd.y - selectionManager.connectionPreviewStart.y,
                    selectionManager.connectionPreviewEnd.x - selectionManager.connectionPreviewStart.x
                )
                
                var arrowPath = Path()
                let arrowTip = selectionManager.connectionPreviewEnd
                arrowPath.move(to: arrowTip)
                arrowPath.addLine(to: CGPoint(
                    x: arrowTip.x - arrowSize * cos(angle - .pi/6),
                    y: arrowTip.y - arrowSize * sin(angle - .pi/6)
                ))
                arrowPath.move(to: arrowTip)
                arrowPath.addLine(to: CGPoint(
                    x: arrowTip.x - arrowSize * cos(angle + .pi/6),
                    y: arrowTip.y - arrowSize * sin(angle + .pi/6)
                ))
                
                context.stroke(arrowPath, with: .color(.blue.opacity(0.7)), lineWidth: 3)
            }
            .scaleEffect(gestureManager.magnificationScale)
            .offset(gestureManager.panOffset)
            .allowsHitTesting(false)
        }
    }
    
    // MARK: - Context Menu Overlay
    @ViewBuilder
    private var contextMenuOverlay: some View {
        VStack {
            contextMenuContent
        }
        .background(Color.primary.colorInvert())
        .cornerRadius(8)
        .shadow(radius: 8)
        .position(selectionManager.contextMenuPosition)
        .transition(.scale.combined(with: .opacity))
        .zIndex(100)
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
    
    // MARK: - Gesture Creation
    @ViewBuilder
    private func makeCanvasGestures() -> some View {
        switch gestureCoordinator.interactionMode {
        case .navigation, .selection:
            Color.clear.gesture(gestureManager.makeCombinedCanvasGestures())
        case .drawing:
            // Limited gestures in drawing mode
            Color.clear.gesture(gestureManager.makeMagnificationGesture())
        case .editing:
            // No canvas gestures in editing mode
            Color.clear.gesture(TapGesture().onEnded { _ in })
        }
    }
    
    private func makeNodeGestures(nodeID: UUID) -> some Gesture {
        // For now, just return the combined gestures regardless of mode
        return gestureManager.makeCombinedNodeGestures(nodeID: nodeID)
    }
    
    // MARK: - Gesture Coordination Setup
    private func setupGestureCoordination() {
        // Connect view model to selection manager
        selectionManager.onSelectionChanged = { [weak viewModel] selectedIDs in
            viewModel?.selectedNodeIDs = selectedIDs
        }
        
        selectionManager.onEditingStarted = { [weak viewModel] nodeID in
            viewModel?.startEditingNode(nodeID)
        }
        
        selectionManager.onEditingEnded = { [weak viewModel] nodeID, text in
            // Update node text - this will be implemented in the ViewModel
            // viewModel?.updateNodeText(nodeID, text: text)
        }
        
        selectionManager.onNodeAction = { [weak viewModel] action, nodeIDs in
            handleNodeAction(action, nodeIDs: nodeIDs)
        }
        
        // Connect drag callbacks
        selectionManager.onNodeDragStarted = { nodeID, position in
            // Handle node drag started
        }
        
        selectionManager.onNodeDragChanged = { nodeID, startPos, currentPos in
            // Handle node drag changed
        }
        
        selectionManager.onNodeDragEnded = { nodeID, startPos, endPos in
            // Handle node drag ended
        }
        
        selectionManager.onConnectionDragEnded = { sourceID, startPos, endPos, targetID in
            // Handle connection drag ended
        }
        
        // Connect pencil manager to view model
        pencilManager.onHandwritingRecognized = { [weak viewModel] text in
            // Create a new node with recognized text - this will be implemented
            // if let position = gestureManager.convertPointToCanvas(CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)) {
            //     viewModel?.createNode(at: position, text: text)
            // }
        }
        
        // Setup gesture coordinator callbacks
        gestureCoordinator.onInteractionModeChanged = { mode in
            // Handle interaction mode changes
        }
        
        gestureCoordinator.onGestureStateChanged = { type, active in
            // Handle gesture state changes
        }
    }
    
    // MARK: - Gesture Handlers
    private func handleDoubleTapOnCanvas(at location: CGPoint) {
        let canvasPoint = gestureManager.convertPointToCanvas(location)
        
        if viewModel.isFocusMode {
            viewModel.exitFocusMode()
        } else {
            // Create new node at double-tap location (Requirement 2.2 alternative)
            // This will be implemented when the ViewModel supports it
            // viewModel.createNode(at: canvasPoint, text: "新しいノード")
            
            // For now, just fit to screen
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
    
    // MARK: - Node Appearance Helpers
    private func getNodeOpacity(_ node: Node) -> Double {
        if gestureCoordinator.interactionMode == .drawing {
            return 0.7 // Dim nodes in drawing mode
        } else if viewModel.isFocusMode {
            return viewModel.isNodeInFocusedBranch(node.id) ? 1.0 : 0.3
        } else {
            return 1.0
        }
    }
    
    private func getNodeScale(_ node: Node) -> CGFloat {
        if selectionManager.selectedNodeIDs.contains(node.id) {
            return 1.05
        } else if selectionManager.highlightedNodeID == node.id {
            return 1.1
        } else {
            return 1.0
        }
    }
    
    // MARK: - Context Menu Content
    @ViewBuilder
    private var contextMenuContent: some View {
        VStack(spacing: 0) {
            contextMenuButton("編集", systemImage: "pencil") {
                if let nodeID = selectionManager.selectedNodeIDs.first {
                    selectionManager.startEditingNode(nodeID)
                }
                selectionManager.hideContextMenu()
            }
            
            Divider()
            
            contextMenuButton("子ノード追加", systemImage: "plus.circle") {
                selectionManager.performAction(.addChild)
                selectionManager.hideContextMenu()
            }
            
            contextMenuButton("兄弟ノード追加", systemImage: "plus.square") {
                selectionManager.performAction(.addSibling)
                selectionManager.hideContextMenu()
            }
            
            Divider()
            
            contextMenuButton("コピー", systemImage: "doc.on.doc") {
                selectionManager.performAction(.copy)
                selectionManager.hideContextMenu()
            }
            
            contextMenuButton("削除", systemImage: "trash", destructive: true) {
                selectionManager.performAction(.delete)
                selectionManager.hideContextMenu()
            }
        }
        .padding(.vertical, 8)
    }
    
    @ViewBuilder
    private func contextMenuButton(
        _ title: String,
        systemImage: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(destructive ? .red : .primary)
                Text(title)
                    .foregroundColor(destructive ? .red : .primary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Node Action Handler
    private func handleNodeAction(_ action: NodeSelectionManager.NodeAction, nodeIDs: Set<UUID>) {
        switch action {
        case .delete:
            // Delete nodes - will be implemented in ViewModel
            break
        case .duplicate:
            // Implement node duplication
            break
        case .copy:
            // Implement copy to clipboard
            break
        case .cut:
            // Implement cut to clipboard
            break
        case .paste:
            // Implement paste from clipboard
            break
        case .addChild:
            // Add child node - will be implemented in ViewModel
            break
        case .addSibling:
            // Add sibling node - will be implemented in ViewModel
            break
        case .convertToTask:
            // Convert to task - will be implemented in ViewModel
            break
        case .addTag, .addMedia, .changeColor, .changeFont, .group, .ungroup:
            // These will be implemented in future tasks
            break
        }
    }
    
    // MARK: - Position Calculation Helpers
    private func calculateChildNodePosition(parentID: UUID) -> CGPoint {
        guard let parentNode = viewModel.nodes.first(where: { $0.id == parentID }) else {
            return CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
        }
        
        // For now, just use a simple count - this will be properly implemented later
        let childCount = 0
        let angle = Double(childCount) * 0.5 // Spread children around parent
        let distance: CGFloat = 120
        
        return CGPoint(
            x: parentNode.position.x + CGFloat(cos(angle)) * distance,
            y: parentNode.position.y + CGFloat(sin(angle)) * distance
        )
    }
    
    private func calculateSiblingNodePosition(siblingID: UUID) -> CGPoint {
        guard let siblingNode = viewModel.nodes.first(where: { $0.id == siblingID }) else {
            return CGPoint(x: canvasSize.width/2, y: canvasSize.height/2)
        }
        
        // Place sibling node nearby
        return CGPoint(
            x: siblingNode.position.x + 150,
            y: siblingNode.position.y
        )
    }
    
    // MARK: - Interaction Mode Handler
    private func handleInteractionModeChange(_ mode: GestureCoordinator.InteractionMode) {
        switch mode {
        case .navigation:
            // Enable all navigation gestures
            break
        case .drawing:
            // Show drawing tools
            break
        case .editing:
            // Focus on text editing
            break
        case .selection:
            // Enable multi-selection
            break
        }
    }
    
    // MARK: - Accessibility
    private var accessibilityHint: String {
        switch gestureCoordinator.interactionMode {
        case .navigation:
            return "ピンチでズーム、ドラッグで移動、ダブルタップで全体表示"
        case .drawing:
            return "Apple Pencilで描画、ダブルタップでナビゲーションモードに切り替え"
        case .editing:
            return "テキスト編集中、Escapeキーで終了"
        case .selection:
            return "複数選択モード、タップで選択追加"
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