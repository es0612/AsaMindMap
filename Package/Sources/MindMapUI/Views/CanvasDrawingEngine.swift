import SwiftUI
import MindMapCore

// MARK: - Canvas Drawing Engine
@available(iOS 16.0, macOS 14.0, *)
public struct CanvasDrawingEngine {
    
    // MARK: - Drawing Configuration
    public struct DrawingConfig {
        public let connectionLineWidth: CGFloat
        public let connectionColor: Color
        public let focusedConnectionColor: Color
        public let unfocusedOpacity: Double
        public let connectionStyle: ConnectionStyle
        public let nodeSpacing: CGFloat
        public let branchSpacing: CGFloat
        
        public init(
            connectionLineWidth: CGFloat = 2.0,
            connectionColor: Color = .primary,
            focusedConnectionColor: Color = .blue,
            unfocusedOpacity: Double = 0.3,
            connectionStyle: ConnectionStyle = .curved,
            nodeSpacing: CGFloat = 120.0,
            branchSpacing: CGFloat = 80.0
        ) {
            self.connectionLineWidth = connectionLineWidth
            self.connectionColor = connectionColor
            self.focusedConnectionColor = focusedConnectionColor
            self.unfocusedOpacity = unfocusedOpacity
            self.connectionStyle = connectionStyle
            self.nodeSpacing = nodeSpacing
            self.branchSpacing = branchSpacing
        }
    }
    
    public enum ConnectionStyle {
        case straight
        case curved
        case organic
    }
    
    // MARK: - Properties
    private let config: DrawingConfig
    
    // MARK: - Initialization
    public init(config: DrawingConfig = DrawingConfig()) {
        self.config = config
    }
    
    // MARK: - Drawing Methods
    public func drawConnections(
        context: GraphicsContext,
        nodes: [Node],
        focusedBranchID: UUID?,
        isFocusMode: Bool,
        transform: CGAffineTransform
    ) {
        for node in nodes {
            guard let parentID = node.parentID,
                  let parentNode = nodes.first(where: { $0.id == parentID }) else {
                continue
            }
            
            let isInFocusedBranch = isNodeInFocusedBranch(
                nodeID: node.id,
                focusedBranchID: focusedBranchID,
                nodes: nodes
            )
            
            drawConnection(
                context: context,
                from: parentNode.position,
                to: node.position,
                isInFocusedBranch: isInFocusedBranch,
                isFocusMode: isFocusMode,
                transform: transform
            )
        }
    }
    
    private func drawConnection(
        context: GraphicsContext,
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        isInFocusedBranch: Bool,
        isFocusMode: Bool,
        transform: CGAffineTransform
    ) {
        let transformedStart = startPoint.applying(transform)
        let transformedEnd = endPoint.applying(transform)
        
        let path = createConnectionPath(from: transformedStart, to: transformedEnd)
        
        let strokeColor = isInFocusedBranch ? config.focusedConnectionColor : config.connectionColor
        let opacity = (isFocusMode && !isInFocusedBranch) ? config.unfocusedOpacity : 1.0
        let lineWidth = isInFocusedBranch ? config.connectionLineWidth * 1.5 : config.connectionLineWidth
        
        context.stroke(
            path,
            with: .color(strokeColor.opacity(opacity)),
            lineWidth: lineWidth
        )
        
        // Add connection arrow if needed
        if isInFocusedBranch {
            drawConnectionArrow(
                context: context,
                from: transformedStart,
                to: transformedEnd,
                color: strokeColor.opacity(opacity)
            )
        }
    }
    
    private func createConnectionPath(from startPoint: CGPoint, to endPoint: CGPoint) -> Path {
        var path = Path()
        
        switch config.connectionStyle {
        case .straight:
            path.move(to: startPoint)
            path.addLine(to: endPoint)
            
        case .curved:
            path.move(to: startPoint)
            
            let controlPoint1 = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * 0.5,
                y: startPoint.y
            )
            let controlPoint2 = CGPoint(
                x: startPoint.x + (endPoint.x - startPoint.x) * 0.5,
                y: endPoint.y
            )
            
            path.addCurve(
                to: endPoint,
                control1: controlPoint1,
                control2: controlPoint2
            )
            
        case .organic:
            path.move(to: startPoint)
            
            let distance = sqrt(pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2))
            let curvature = min(distance * 0.3, 50.0)
            
            let midPoint = CGPoint(
                x: (startPoint.x + endPoint.x) / 2,
                y: (startPoint.y + endPoint.y) / 2
            )
            
            let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
            let perpAngle = angle + .pi / 2
            
            let controlPoint = CGPoint(
                x: midPoint.x + cos(perpAngle) * curvature * 0.3,
                y: midPoint.y + sin(perpAngle) * curvature * 0.3
            )
            
            path.addQuadCurve(to: endPoint, control: controlPoint)
        }
        
        return path
    }
    
    private func drawConnectionArrow(
        context: GraphicsContext,
        from startPoint: CGPoint,
        to endPoint: CGPoint,
        color: Color
    ) {
        let angle = atan2(endPoint.y - startPoint.y, endPoint.x - startPoint.x)
        let arrowLength: CGFloat = 8
        let arrowAngle: CGFloat = .pi / 6
        
        let arrowPoint1 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle - arrowAngle),
            y: endPoint.y - arrowLength * sin(angle - arrowAngle)
        )
        
        let arrowPoint2 = CGPoint(
            x: endPoint.x - arrowLength * cos(angle + arrowAngle),
            y: endPoint.y - arrowLength * sin(angle + arrowAngle)
        )
        
        var arrowPath = Path()
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: arrowPoint1)
        arrowPath.move(to: endPoint)
        arrowPath.addLine(to: arrowPoint2)
        
        context.stroke(arrowPath, with: .color(color), lineWidth: 1.5)
    }
    
    // MARK: - Node Layout Helpers
    public func calculateOptimalNodePositions(
        nodes: [Node],
        rootNodeID: UUID?,
        canvasSize: CGSize
    ) -> [UUID: CGPoint] {
        guard let rootID = rootNodeID,
              let _ = nodes.first(where: { $0.id == rootID }) else {
            return [:]
        }
        
        var positions: [UUID: CGPoint] = [:]
        let centerPoint = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        
        // Position root node at center
        positions[rootID] = centerPoint
        
        // Calculate positions for child nodes
        let childNodes = nodes.filter { $0.parentID == rootID }
        layoutChildNodes(
            childNodes: childNodes,
            parentPosition: centerPoint,
            allNodes: nodes,
            positions: &positions,
            level: 1
        )
        
        return positions
    }
    
    private func layoutChildNodes(
        childNodes: [Node],
        parentPosition: CGPoint,
        allNodes: [Node],
        positions: inout [UUID: CGPoint],
        level: Int
    ) {
        guard !childNodes.isEmpty else { return }
        
        let angleStep = (2 * .pi) / Double(childNodes.count)
        let radius = config.nodeSpacing * Double(level)
        
        for (index, child) in childNodes.enumerated() {
            let angle = Double(index) * angleStep
            let position = CGPoint(
                x: parentPosition.x + CGFloat(Darwin.cos(angle) * radius),
                y: parentPosition.y + CGFloat(Darwin.sin(angle) * radius)
            )
            
            positions[child.id] = position
            
            // Recursively layout grandchildren
            let grandChildren = allNodes.filter { $0.parentID == child.id }
            if !grandChildren.isEmpty {
                layoutChildNodes(
                    childNodes: grandChildren,
                    parentPosition: position,
                    allNodes: allNodes,
                    positions: &positions,
                    level: level + 1
                )
            }
        }
    }
    
    // MARK: - Focus and Branch Helpers
    private func isNodeInFocusedBranch(
        nodeID: UUID,
        focusedBranchID: UUID?,
        nodes: [Node]
    ) -> Bool {
        guard let focusedID = focusedBranchID else { return true }
        
        if nodeID == focusedID {
            return true
        }
        
        // Check if node is a descendant of focused branch
        return isDescendantOf(nodeID: nodeID, ancestorID: focusedID, nodes: nodes)
    }
    
    private func isDescendantOf(nodeID: UUID, ancestorID: UUID, nodes: [Node]) -> Bool {
        guard let node = nodes.first(where: { $0.id == nodeID }),
              let parentID = node.parentID else {
            return false
        }
        
        if parentID == ancestorID {
            return true
        }
        
        return isDescendantOf(nodeID: parentID, ancestorID: ancestorID, nodes: nodes)
    }
    
    // MARK: - Canvas Bounds Calculation
    public func calculateContentBounds(nodes: [Node]) -> CGRect {
        guard !nodes.isEmpty else { return .zero }
        
        let positions = nodes.map { $0.position }
        let minX = positions.map { $0.x }.min() ?? 0
        let maxX = positions.map { $0.x }.max() ?? 0
        let minY = positions.map { $0.y }.min() ?? 0
        let maxY = positions.map { $0.y }.max() ?? 0
        
        let padding: CGFloat = 100
        
        return CGRect(
            x: minX - padding,
            y: minY - padding,
            width: maxX - minX + padding * 2,
            height: maxY - minY + padding * 2
        )
    }
    
    // MARK: - Animation Helpers
    public func createFitToScreenTransform(
        contentBounds: CGRect,
        screenSize: CGSize,
        maxScale: CGFloat = 2.0
    ) -> (scale: CGFloat, offset: CGSize) {
        let padding: CGFloat = 50
        let availableWidth = screenSize.width - padding * 2
        let availableHeight = screenSize.height - padding * 2
        
        let scaleX = availableWidth / contentBounds.width
        let scaleY = availableHeight / contentBounds.height
        let scale = min(scaleX, scaleY, maxScale)
        
        let centerX = contentBounds.midX
        let centerY = contentBounds.midY
        
        let offset = CGSize(
            width: screenSize.width / 2 - centerX * scale,
            height: screenSize.height / 2 - centerY * scale
        )
        
        return (scale: scale, offset: offset)
    }
}