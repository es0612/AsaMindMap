import SwiftUI
import MindMapCore
import Combine

// MARK: - Gesture Coordinator
@available(iOS 16.0, macOS 14.0, *)
@MainActor
public final class GestureCoordinator: ObservableObject {
    
    // MARK: - Managers
    @Published public var gestureManager: GestureManager
    @Published public var pencilManager: ApplePencilManager
    @Published public var selectionManager: NodeSelectionManager
    
    // MARK: - Gesture State
    @Published public var activeGestureType: GestureType = .none
    @Published public var isGestureActive: Bool = false
    
    // MARK: - Interaction Mode
    @Published public var interactionMode: InteractionMode = .navigation
    
    public enum InteractionMode: Equatable {
        case navigation    // Pan, zoom, select
        case drawing      // Apple Pencil drawing
        case editing      // Text editing
        case selection    // Multi-selection
    }
    
    public enum GestureType: Equatable {
        case none
        case pan
        case zoom
        case tap
        case doubleTap
        case longPress
        case drag
        case pencilDraw
        case pencilErase
        case multiSelect
    }
    
    // MARK: - Configuration
    public struct GestureConfiguration {
        public var enablePencilGestures: Bool = true
        public var enableMultiTouch: Bool = true
        public var enableKeyboardShortcuts: Bool = true
        public var minimumDragDistance: CGFloat = 10
        public var longPressDelay: TimeInterval = 0.5
        public var doubleTapDelay: TimeInterval = 0.3
        
        public init() {}
    }
    
    @Published public var configuration = GestureConfiguration()
    
    // MARK: - Callbacks
    public var onInteractionModeChanged: ((InteractionMode) -> Void)?
    public var onGestureStateChanged: ((GestureType, Bool) -> Void)?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    public init(
        gestureManager: GestureManager? = nil,
        pencilManager: ApplePencilManager? = nil,
        selectionManager: NodeSelectionManager? = nil
    ) {
        self.gestureManager = gestureManager ?? GestureManager()
        self.pencilManager = pencilManager ?? ApplePencilManager()
        self.selectionManager = selectionManager ?? NodeSelectionManager()
        
        setupGestureCoordination()
        setupInteractionModeObservation()
    }
    
    // MARK: - Setup
    private func setupGestureCoordination() {
        // Coordinate gesture manager callbacks
        gestureManager.onPanChanged = { [weak self] offset in
            self?.handlePanGesture(offset: offset, phase: .changed)
        }
        
        gestureManager.onPanEnded = { [weak self] offset in
            self?.handlePanGesture(offset: offset, phase: .ended)
        }
        
        gestureManager.onZoomChanged = { [weak self] scale in
            self?.handleZoomGesture(scale: scale, phase: .changed)
        }
        
        gestureManager.onZoomEnded = { [weak self] scale in
            self?.handleZoomGesture(scale: scale, phase: .ended)
        }
        
        gestureManager.onNodeTap = { [weak self] nodeID in
            self?.handleNodeTap(nodeID: nodeID)
        }
        
        gestureManager.onNodeDoubleTap = { [weak self] nodeID in
            self?.handleNodeDoubleTap(nodeID: nodeID)
        }
        
        gestureManager.onNodeLongPress = { [weak self] nodeID in
            self?.handleNodeLongPress(nodeID: nodeID)
        }
        
        // Coordinate pencil manager callbacks
        pencilManager.onPencilDoubleTap = { [weak self] in
            self?.handlePencilDoubleTap()
        }
        
        pencilManager.onPencilSqueeze = { [weak self] phase in
            self?.handlePencilSqueeze(phase: phase)
        }
        
        // Disabled PencilKit integration for now
        // #if canImport(PencilKit)
        // pencilManager.onDrawingChanged = { [weak self] drawing in
        //     self?.handleDrawingChanged(drawing: drawing)
        // }
        // #endif
        
        pencilManager.onHandwritingRecognized = { [weak self] text in
            self?.handleHandwritingRecognized(text: text)
        }
        
        // Coordinate selection manager callbacks
        selectionManager.onSelectionChanged = { [weak self] selectedIDs in
            self?.handleSelectionChanged(selectedIDs: selectedIDs)
        }
        
        selectionManager.onEditingStarted = { [weak self] nodeID in
            self?.handleEditingStarted(nodeID: nodeID)
        }
        
        selectionManager.onEditingEnded = { [weak self] nodeID, text in
            self?.handleEditingEnded(nodeID: nodeID, text: text)
        }
        
        // Coordinate drag callbacks
        gestureManager.onNodeDragStarted = { [weak self] nodeID, position in
            self?.handleNodeDragStarted(nodeID: nodeID, position: position)
        }
        
        gestureManager.onNodeDragChanged = { [weak self] nodeID, startPos, currentPos in
            self?.handleNodeDragChanged(nodeID: nodeID, startPosition: startPos, currentPosition: currentPos)
        }
        
        gestureManager.onNodeDragEnded = { [weak self] nodeID, startPos, endPos in
            self?.handleNodeDragEnded(nodeID: nodeID, startPosition: startPos, endPosition: endPos)
        }
        
        // Canvas double tap is handled through the regular double tap callback
        gestureManager.onDoubleTap = { [weak self] in
            self?.handleCanvasDoubleTap(at: .zero)
        }
    }
    
    private func setupInteractionModeObservation() {
        // Observe pencil drawing mode changes
        pencilManager.$isDrawingMode
            .sink { [weak self] isDrawing in
                if isDrawing {
                    self?.setInteractionMode(.drawing)
                } else if self?.interactionMode == .drawing {
                    self?.setInteractionMode(.navigation)
                }
            }
            .store(in: &cancellables)
        
        // Observe text editing changes
        selectionManager.$isEditingText
            .sink { [weak self] isEditing in
                if isEditing {
                    self?.setInteractionMode(.editing)
                } else if self?.interactionMode == .editing {
                    self?.setInteractionMode(.navigation)
                }
            }
            .store(in: &cancellables)
        
        // Observe multi-select mode changes
        selectionManager.$multiSelectMode
            .sink { [weak self] isMultiSelect in
                if isMultiSelect {
                    self?.setInteractionMode(.selection)
                } else if self?.interactionMode == .selection {
                    self?.setInteractionMode(.navigation)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Interaction Mode Management
    public func setInteractionMode(_ mode: InteractionMode) {
        guard interactionMode != mode else { return }
        
        let previousMode = interactionMode
        interactionMode = mode
        
        // Handle mode transitions
        handleInteractionModeTransition(from: previousMode, to: mode)
        
        onInteractionModeChanged?(mode)
    }
    
    private func handleInteractionModeTransition(from: InteractionMode, to: InteractionMode) {
        // Clean up previous mode
        switch from {
        case .drawing:
            // Finalize any ongoing drawing
            break
        case .editing:
            // End text editing if active
            if selectionManager.isEditingText {
                selectionManager.endEditingNode()
            }
        case .selection:
            // Exit multi-select mode
            selectionManager.disableMultiSelectMode()
        case .navigation:
            break
        }
        
        // Setup new mode
        switch to {
        case .drawing:
            pencilManager.isDrawingMode = true
        case .editing:
            // Text editing setup handled by selection manager
            break
        case .selection:
            selectionManager.enableMultiSelectMode()
        case .navigation:
            pencilManager.isDrawingMode = false
        }
    }
    
    // MARK: - Gesture Handlers
    private func handlePanGesture(offset: CGSize, phase: GesturePhase) {
        switch interactionMode {
        case .navigation:
            setActiveGesture(.pan, active: phase != .ended)
        case .drawing:
            // Pan gestures are disabled in drawing mode
            break
        case .editing, .selection:
            // Limited pan gestures in these modes
            setActiveGesture(.pan, active: phase != .ended)
        }
    }
    
    private func handleZoomGesture(scale: CGFloat, phase: GesturePhase) {
        switch interactionMode {
        case .navigation, .selection:
            setActiveGesture(.zoom, active: phase != .ended)
        case .drawing, .editing:
            // Zoom gestures are disabled in these modes
            break
        }
    }
    
    private func handleNodeTap(nodeID: UUID) {
        setActiveGesture(.tap, active: true)
        
        switch interactionMode {
        case .navigation:
            selectionManager.selectNode(nodeID)
        case .selection:
            selectionManager.selectNode(nodeID, addToSelection: true)
        case .editing:
            // Switch to editing this node
            selectionManager.startEditingNode(nodeID)
        case .drawing:
            // Tap gestures are disabled in drawing mode
            break
        }
        
        setActiveGesture(.tap, active: false)
    }
    
    private func handleNodeDoubleTap(nodeID: UUID) {
        setActiveGesture(.doubleTap, active: true)
        
        switch interactionMode {
        case .navigation, .selection:
            // Start editing the node
            selectionManager.startEditingNode(nodeID)
            setInteractionMode(.editing)
        case .editing:
            // Already editing, ignore
            break
        case .drawing:
            // Double tap gestures are disabled in drawing mode
            break
        }
        
        setActiveGesture(.doubleTap, active: false)
    }
    
    private func handleNodeLongPress(nodeID: UUID) {
        setActiveGesture(.longPress, active: true)
        
        switch interactionMode {
        case .navigation:
            // Show context menu
            selectionManager.showContextMenu(at: .zero, for: [nodeID])
        case .selection:
            // Add to selection and show context menu
            selectionManager.selectNode(nodeID, addToSelection: true)
            selectionManager.showContextMenu(at: .zero)
        case .editing, .drawing:
            // Long press gestures are disabled in these modes
            break
        }
        
        setActiveGesture(.longPress, active: false)
    }
    
    private func handlePencilDoubleTap() {
        guard configuration.enablePencilGestures else { return }
        
        // Toggle between drawing and navigation modes
        if interactionMode == .drawing {
            setInteractionMode(.navigation)
        } else {
            setInteractionMode(.drawing)
        }
    }
    
    private func handlePencilSqueeze(phase: ApplePencilManager.PencilSqueezePhase) {
        guard configuration.enablePencilGestures else { return }
        
        switch phase {
        case .began:
            // Show tool palette or context menu
            break
        case .changed:
            // Update tool selection
            break
        case .ended:
            // Finalize tool selection
            break
        }
    }
    
    // Disabled PencilKit functionality for now
    // #if canImport(PencilKit)
    // private func handleDrawingChanged(drawing: PKDrawing) {
    //     setActiveGesture(.pencilDraw, active: !drawing.strokes.isEmpty)
    // }
    // #endif
    
    private func handleHandwritingRecognized(text: String) {
        // Handle recognized handwriting text
        // This could create a new node or update existing text
    }
    
    private func handleSelectionChanged(selectedIDs: Set<UUID>) {
        // Update gesture behavior based on selection
        if selectedIDs.isEmpty && interactionMode == .selection {
            setInteractionMode(.navigation)
        }
    }
    
    private func handleEditingStarted(nodeID: UUID) {
        setInteractionMode(.editing)
    }
    
    private func handleEditingEnded(nodeID: UUID, text: String) {
        setInteractionMode(.navigation)
    }
    
    // MARK: - Drag Gesture Handlers
    private func handleNodeDragStarted(nodeID: UUID, position: CGPoint) {
        setActiveGesture(.drag, active: true)
        
        switch interactionMode {
        case .navigation, .selection:
            // Start node repositioning or connection creation
            selectionManager.onNodeDragStarted?(nodeID, position)
            
            // Determine if this should be a connection drag or position drag
            // For now, we'll use a simple heuristic: if dragging from edge, create connection
            let dragDistance = 20.0 // pixels from center to consider edge drag
            // This would be implemented with actual node bounds checking
            
        case .editing, .drawing:
            // Drag gestures are limited in these modes
            break
        }
    }
    
    private func handleNodeDragChanged(nodeID: UUID, startPosition: CGPoint, currentPosition: CGPoint) {
        switch interactionMode {
        case .navigation, .selection:
            let dragDistance = sqrt(pow(currentPosition.x - startPosition.x, 2) + pow(currentPosition.y - startPosition.y, 2))
            
            if dragDistance > 50 { // Threshold for connection creation
                // Show connection preview
                selectionManager.startConnectionPreview(from: startPosition)
                selectionManager.updateConnectionPreview(to: currentPosition)
                selectionManager.onConnectionDragChanged?(nodeID, startPosition, currentPosition)
            } else {
                // Show node repositioning preview
                selectionManager.startDragPreview(at: currentPosition)
                selectionManager.onNodeDragChanged?(nodeID, startPosition, currentPosition)
            }
            
        case .editing, .drawing:
            break
        }
    }
    
    private func handleNodeDragEnded(nodeID: UUID, startPosition: CGPoint, endPosition: CGPoint) {
        setActiveGesture(.drag, active: false)
        
        switch interactionMode {
        case .navigation, .selection:
            let dragDistance = sqrt(pow(endPosition.x - startPosition.x, 2) + pow(endPosition.y - startPosition.y, 2))
            
            if dragDistance > 50 {
                // End connection creation
                selectionManager.endConnectionPreview()
                // Find target node at end position (would be implemented with hit testing)
                let targetNodeID: UUID? = nil // Hit test would determine this
                selectionManager.onConnectionDragEnded?(nodeID, startPosition, endPosition, targetNodeID)
            } else {
                // End node repositioning
                selectionManager.endDragPreview()
                selectionManager.onNodeDragEnded?(nodeID, startPosition, endPosition)
            }
            
        case .editing, .drawing:
            break
        }
    }
    
    private func handleCanvasDoubleTap(at position: CGPoint) {
        switch interactionMode {
        case .navigation:
            // Fit to screen or create new node
            break
        case .selection:
            // Exit selection mode
            setInteractionMode(.navigation)
        case .editing, .drawing:
            // No action in these modes
            break
        }
    }
    
    // MARK: - Gesture State Management
    private func setActiveGesture(_ type: GestureType, active: Bool) {
        if active {
            activeGestureType = type
            isGestureActive = true
        } else if activeGestureType == type {
            activeGestureType = .none
            isGestureActive = false
        }
        
        onGestureStateChanged?(type, active)
    }
    
    // MARK: - Keyboard Shortcuts
    public func handleKeyboardShortcut(_ key: String, modifiers: KeyboardModifiers) -> Bool {
        guard configuration.enableKeyboardShortcuts else { return false }
        
        // Handle mode-specific shortcuts
        switch interactionMode {
        case .navigation, .selection:
            return selectionManager.handleKeyboardShortcut(key, modifiers: modifiers)
        case .editing:
            // Handle text editing shortcuts
            return handleEditingKeyboardShortcut(key, modifiers: modifiers)
        case .drawing:
            // Handle drawing shortcuts
            return handleDrawingKeyboardShortcut(key, modifiers: modifiers)
        }
    }
    
    private func handleEditingKeyboardShortcut(_ key: String, modifiers: KeyboardModifiers) -> Bool {
        switch (key.lowercased(), modifiers) {
        case ("escape", []):
            selectionManager.cancelEditing()
            return true
        case ("return", []), ("enter", []):
            selectionManager.endEditingNode()
            return true
        default:
            return false
        }
    }
    
    private func handleDrawingKeyboardShortcut(_ key: String, modifiers: KeyboardModifiers) -> Bool {
        switch (key.lowercased(), modifiers) {
        case ("escape", []):
            setInteractionMode(.navigation)
            return true
        case ("z", .command):
            pencilManager.undoLastStroke()
            return true
        case ("c", .command):
            pencilManager.clearDrawing()
            return true
        default:
            return false
        }
    }
    
    // MARK: - Utility Methods
    public func resetAllGestures() {
        gestureManager.resetGestureState()
        selectionManager.clearSelection()
        selectionManager.cancelEditing()
        pencilManager.clearDrawing()
        setInteractionMode(.navigation)
    }
    
    public func canHandleGesture(_ type: GestureType) -> Bool {
        switch (interactionMode, type) {
        case (.navigation, _):
            return true
        case (.drawing, .pencilDraw), (.drawing, .pencilErase):
            return true
        case (.editing, .tap), (.editing, .doubleTap):
            return true
        case (.selection, .tap), (.selection, .longPress), (.selection, .pan), (.selection, .zoom):
            return true
        default:
            return false
        }
    }
}

// MARK: - Gesture Phase
public enum GesturePhase {
    case began
    case changed
    case ended
    case cancelled
}

// MARK: - Keyboard Modifiers
public struct KeyboardModifiers: OptionSet, Equatable {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let command = KeyboardModifiers(rawValue: 1 << 0)
    public static let shift = KeyboardModifiers(rawValue: 1 << 1)
    public static let option = KeyboardModifiers(rawValue: 1 << 2)
    public static let control = KeyboardModifiers(rawValue: 1 << 3)
}