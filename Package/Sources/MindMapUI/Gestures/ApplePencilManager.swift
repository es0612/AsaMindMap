import SwiftUI
import Combine

#if canImport(UIKit)
import UIKit
#endif

#if canImport(PencilKit)
import PencilKit
#endif

// MARK: - Apple Pencil Manager
@available(iOS 16.0, macOS 14.0, *)
@MainActor
public final class ApplePencilManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var isDrawingMode: Bool = false
    @Published public var isApplePencilConnected: Bool = false
    @Published public var currentTool: PencilTool = .pen
    @Published public var strokeColor: Color = .black
    @Published public var strokeWidth: CGFloat = 2.0
    @Published public var isHandwritingRecognitionEnabled: Bool = true
    @Published public var pencilPressure: CGFloat = 0.0
    @Published public var pencilAzimuth: CGFloat = 0.0
    @Published public var pencilAltitude: CGFloat = 0.0
    @Published public var isHoveringWithPencil: Bool = false
    
    // MARK: - Drawing State
    #if canImport(PencilKit)
    @Published public var currentDrawing: PKDrawing = PKDrawing()
    @Published public var handwritingStrokes: [PKStroke] = []
    #else
    @Published public var currentDrawing: String = "" // Placeholder
    @Published public var handwritingStrokes: [String] = [] // Placeholder
    #endif
    
    // MARK: - Pencil Tools
    public enum PencilTool: CaseIterable {
        case pen
        case pencil
        case marker
        case eraser
        
        public var displayName: String {
            switch self {
            case .pen: return "ペン"
            case .pencil: return "鉛筆"
            case .marker: return "マーカー"
            case .eraser: return "消しゴム"
            }
        }
        
        public var systemImage: String {
            switch self {
            case .pen: return "pencil"
            case .pencil: return "pencil.tip"
            case .marker: return "highlighter"
            case .eraser: return "eraser"
            }
        }
    }
    
    // MARK: - Callbacks
    #if canImport(PencilKit)
    public var onDrawingChanged: ((PKDrawing) -> Void)?
    #else
    public var onDrawingChanged: ((String) -> Void)?
    #endif
    public var onHandwritingRecognized: ((String) -> Void)?
    public var onPencilDoubleTap: (() -> Void)?
    public var onPencilSqueeze: ((PencilSqueezePhase) -> Void)?
    public var onPencilHoverStarted: ((CGPoint) -> Void)?
    public var onPencilHoverMoved: ((CGPoint) -> Void)?
    public var onPencilHoverEnded: (() -> Void)?
    public var onPencilPressureChanged: ((CGFloat) -> Void)?
    
    public enum PencilSqueezePhase: Equatable {
        case began
        case changed
        case ended
    }
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    #if canImport(UIKit)
    private var pencilInteraction: UIPencilInteraction?
    #endif
    
    // MARK: - Initialization
    public init() {
        setupApplePencilDetection()
        setupDrawingObservation()
    }
    
    // MARK: - Apple Pencil Detection
    private func setupApplePencilDetection() {
        #if canImport(UIKit)
        // Check if Apple Pencil is available
        if UIPencilInteraction.preferredTapAction != .ignore {
            isApplePencilConnected = true
            setupPencilInteraction()
        }
        
        // Monitor pencil connection changes
        NotificationCenter.default.publisher(for: .UIPencilInteractionDidTap)
            .sink { [weak self] _ in
                self?.handlePencilDoubleTap()
            }
            .store(in: &cancellables)
        
        // Monitor pencil preference changes
        NotificationCenter.default.publisher(for: UIPencilInteraction.preferredTapActionDidChangeNotification)
            .sink { [weak self] _ in
                self?.updatePencilPreferences()
            }
            .store(in: &cancellables)
        #endif
    }
    
    #if canImport(UIKit)
    private func updatePencilPreferences() {
        // Update pencil settings based on user preferences
        let preferredAction = UIPencilInteraction.preferredTapAction
        
        switch preferredAction {
        case .switchEraser:
            // Configure for eraser switching
            break
        case .switchPrevious:
            // Configure for tool switching
            break
        case .showColorPalette:
            // Configure for color palette
            break
        default:
            break
        }
    }
    #endif
    
    #if canImport(UIKit)
    private func setupPencilInteraction() {
        pencilInteraction = UIPencilInteraction()
        pencilInteraction?.delegate = PencilInteractionDelegate(manager: self)
    }
    #endif
    
    // MARK: - Drawing Observation
    private func setupDrawingObservation() {
        $currentDrawing
            .dropFirst()
            .sink { [weak self] drawing in
                self?.onDrawingChanged?(drawing)
                self?.processHandwritingRecognition(from: drawing)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Tool Management
    public func selectTool(_ tool: PencilTool) {
        currentTool = tool
        
        // Update drawing mode based on tool
        isDrawingMode = tool != .eraser
        
        // Configure tool properties
        switch tool {
        case .pen:
            strokeWidth = 2.0
            strokeColor = .black
        case .pencil:
            strokeWidth = 1.5
            strokeColor = .gray
        case .marker:
            strokeWidth = 8.0
            strokeColor = .yellow
        case .eraser:
            isDrawingMode = false
        }
    }
    
    public func toggleDrawingMode() {
        isDrawingMode.toggle()
        
        if !isDrawingMode {
            currentTool = .eraser
        } else {
            currentTool = .pen
        }
    }
    
    // MARK: - Pencil Gesture Handling
    public func handlePencilDoubleTap() {
        // Default behavior: switch between pen and eraser
        switch currentTool {
        case .eraser:
            selectTool(.pen)
        default:
            selectTool(.eraser)
        }
        
        onPencilDoubleTap?()
    }
    
    public func handlePencilSqueeze(phase: PencilSqueezePhase) {
        switch phase {
        case .began:
            // Show tool palette or context menu
            break
        case .changed:
            // Update tool selection based on squeeze intensity
            break
        case .ended:
            // Finalize tool selection
            break
        }
        
        onPencilSqueeze?(phase)
    }
    
    // MARK: - Drawing Operations
    #if canImport(PencilKit)
    public func addStroke(_ stroke: PKStroke) {
        currentDrawing.strokes.append(stroke)
        
        // Check if this stroke might be handwriting
        if isHandwritingRecognitionEnabled && isHandwritingStroke(stroke) {
            handwritingStrokes.append(stroke)
        }
    }
    
    public func removeStroke(at index: Int) {
        guard index < currentDrawing.strokes.count else { return }
        currentDrawing.strokes.remove(at: index)
    }
    
    public func clearDrawing() {
        currentDrawing = PKDrawing()
        handwritingStrokes.removeAll()
    }
    
    public func undoLastStroke() {
        guard !currentDrawing.strokes.isEmpty else { return }
        let removedStroke = currentDrawing.strokes.removeLast()
        
        // Remove from handwriting strokes if present
        handwritingStrokes.removeAll { stroke in
            stroke.path.creationDate == removedStroke.path.creationDate
        }
    }
    #else
    public func addStroke(_ stroke: String) {
        // Placeholder implementation
    }
    
    public func removeStroke(at index: Int) {
        // Placeholder implementation
    }
    
    public func clearDrawing() {
        currentDrawing = ""
        handwritingStrokes.removeAll()
    }
    
    public func undoLastStroke() {
        // Placeholder implementation
    }
    #endif
    
    // MARK: - Handwriting Recognition
    #if canImport(PencilKit)
    private func isHandwritingStroke(_ stroke: PKStroke) -> Bool {
        // Simple heuristic: strokes that are more horizontal and have text-like characteristics
        let path = stroke.path
        guard path.count > 2 else { return false }
        
        let startPoint = path[0].location
        let endPoint = path[path.count - 1].location
        
        let width = abs(endPoint.x - startPoint.x)
        let height = abs(endPoint.y - startPoint.y)
        
        // Consider it handwriting if it's more horizontal than vertical
        return width > height && width > 20
    }
    
    private func processHandwritingRecognition(from drawing: PKDrawing) {
        guard isHandwritingRecognitionEnabled && !handwritingStrokes.isEmpty else { return }
        
        // Create a drawing with only handwriting strokes
        let handwritingDrawing = PKDrawing(strokes: handwritingStrokes)
        
        // Perform handwriting recognition
        recognizeHandwriting(from: handwritingDrawing) { [weak self] recognizedText in
            if !recognizedText.isEmpty {
                self?.onHandwritingRecognized?(recognizedText)
                // Clear handwriting strokes after recognition
                self?.handwritingStrokes.removeAll()
            }
        }
    }
    
    private func recognizeHandwriting(from drawing: PKDrawing, completion: @escaping (String) -> Void) {
        #if canImport(UIKit)
        // Use Vision framework for handwriting recognition
        let request = VNRecognizeTextRequest { request, error in
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion("")
                return
            }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: " ")
            
            DispatchQueue.main.async {
                completion(recognizedText)
            }
        }
        
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        // Convert drawing to image for Vision processing
        let image = drawing.image(from: drawing.bounds, scale: 1.0)
        guard let cgImage = image.cgImage else {
            completion("")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try? handler.perform([request])
        #else
        completion("")
        #endif
    }
    
    #endif
    
    // MARK: - Utility Methods
    #if canImport(PencilKit)
    public func createPKInkingTool() -> PKInkingTool {
        let inkType: PKInkingTool.InkType
        
        switch currentTool {
        case .pen:
            inkType = .pen
        case .pencil:
            inkType = .pencil
        case .marker:
            inkType = .marker
        case .eraser:
            inkType = .pen // Eraser is handled separately
        }
        
        #if canImport(UIKit)
        return PKInkingTool(inkType, color: UIColor(strokeColor), width: strokeWidth)
        #else
        return PKInkingTool(inkType, color: NSColor(strokeColor), width: strokeWidth)
        #endif
    }
    
    public func createPKEraserTool() -> PKEraserTool {
        return PKEraserTool(.bitmap)
    }
    
    #if canImport(UIKit)
    public func exportDrawingAsImage() -> UIImage? {
        return currentDrawing.image(from: currentDrawing.bounds, scale: UIScreen.main.scale)
    }
    #endif
    #endif
}

// MARK: - Pencil Interaction Delegate
#if canImport(UIKit)
@available(iOS 16.0, *)
private class PencilInteractionDelegate: NSObject, UIPencilInteractionDelegate {
    weak var manager: ApplePencilManager?
    
    init(manager: ApplePencilManager) {
        self.manager = manager
        super.init()
    }
    
    func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        manager?.handlePencilDoubleTap()
    }
}
#endif

// MARK: - Vision Framework Import
#if canImport(Vision)
import Vision
#endif