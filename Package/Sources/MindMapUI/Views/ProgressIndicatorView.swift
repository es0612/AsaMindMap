import SwiftUI
import MindMapCore

// MARK: - Progress Indicator View
@available(iOS 16.0, macOS 14.0, *)
public struct ProgressIndicatorView: View {
    
    // MARK: - Properties
    let progress: ProgressData
    let style: ProgressStyle
    let size: ProgressSize
    let showDetails: Bool
    let onTap: (() -> Void)?
    
    // MARK: - Initializers
    public init(
        progress: ProgressData,
        style: ProgressStyle = .circular,
        size: ProgressSize = .medium,
        showDetails: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.progress = progress
        self.style = style
        self.size = size
        self.showDetails = showDetails
        self.onTap = onTap
    }
    
    // MARK: - Body
    public var body: some View {
        Group {
            switch style {
            case .circular:
                circularProgress
            case .linear:
                linearProgress
            case .ring:
                ringProgress
            case .minimal:
                minimalProgress
            }
        }
        .onTapGesture {
            onTap?()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
    }
    
    // MARK: - Circular Progress
    @ViewBuilder
    private var circularProgress: some View {
        VStack(spacing: size.spacing) {
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: size.strokeWidth)
                    .frame(width: size.circularSize, height: size.circularSize)
                
                // Progress Circle
                Circle()
                    .trim(from: 0, to: progress.percentage / 100)
                    .stroke(
                        progressColor,
                        style: StrokeStyle(
                            lineWidth: size.strokeWidth,
                            lineCap: .round
                        )
                    )
                    .frame(width: size.circularSize, height: size.circularSize)
                    .rotationEffect(.degrees(-90))
                    .optimizedAnimation(AnimationConfiguration.progressUpdate(), value: progress.percentage)
                
                // Center Content
                VStack(spacing: 2) {
                    if showDetails || size.showCenterText {
                        Text("\(Int(progress.percentage))%")
                            .font(.system(size: size.centerTextSize, weight: .bold))
                            .foregroundColor(progressColor)
                    }
                    
                    if showDetails {
                        Text("\(progress.completed)/\(progress.total)")
                            .font(.system(size: size.centerSubtextSize, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if showDetails {
                progressDetails
            }
        }
    }
    
    // MARK: - Linear Progress
    @ViewBuilder
    private var linearProgress: some View {
        VStack(spacing: size.spacing) {
            if showDetails {
                HStack {
                    Text("進捗")
                        .font(.system(size: size.labelTextSize, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Text("\(Int(progress.percentage))%")
                        .font(.system(size: size.labelTextSize, weight: .bold))
                        .foregroundColor(progressColor)
                }
            }
            
            ZStack(alignment: .leading) {
                // Background Bar
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: size.barHeight)
                
                // Progress Bar
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(progressColor)
                    .frame(width: size.linearWidth * (progress.percentage / 100), height: size.barHeight)
                    .optimizedAnimation(AnimationConfiguration.progressUpdate(), value: progress.percentage)
            }
            .frame(width: size.linearWidth)
            
            if showDetails {
                progressDetails
            }
        }
    }
    
    // MARK: - Ring Progress
    @ViewBuilder
    private var ringProgress: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(Color.gray.opacity(0.1), lineWidth: size.ringWidth)
                .frame(width: size.ringSize, height: size.ringSize)
            
            // Progress Ring
            Circle()
                .trim(from: 0, to: progress.percentage / 100)
                .stroke(
                    progressColor,
                    style: StrokeStyle(
                        lineWidth: size.ringWidth,
                        lineCap: .round
                    )
                )
                .frame(width: size.ringSize, height: size.ringSize)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress.percentage)
            
            // Center Icon or Text
            if showDetails {
                VStack(spacing: 1) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: size.iconSize))
                        .foregroundColor(progressColor)
                        .opacity(progress.percentage == 100 ? 1 : 0.3)
                    
                    Text("\(progress.completed)/\(progress.total)")
                        .font(.system(size: size.centerSubtextSize, weight: .medium))
                        .foregroundColor(.secondary)
                }
            } else {
                Text("\(Int(progress.percentage))%")
                    .font(.system(size: size.centerTextSize, weight: .bold))
                    .foregroundColor(progressColor)
            }
        }
    }
    
    // MARK: - Minimal Progress
    @ViewBuilder
    private var minimalProgress: some View {
        HStack(spacing: 4) {
            Image(systemName: progressIcon)
                .font(.system(size: size.iconSize))
                .foregroundColor(progressColor)
            
            if showDetails {
                Text("\(progress.completed)/\(progress.total)")
                    .font(.system(size: size.labelTextSize, weight: .medium))
                    .foregroundColor(.primary)
            } else {
                Text("\(Int(progress.percentage))%")
                    .font(.system(size: size.labelTextSize, weight: .medium))
                    .foregroundColor(progressColor)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(progressColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
    }
    
    // MARK: - Progress Details
    @ViewBuilder
    private var progressDetails: some View {
        HStack(spacing: 8) {
            Label("\(progress.completed) 完了", systemImage: "checkmark.circle")
                .font(.system(size: size.detailTextSize))
                .foregroundColor(.green)
            
            Label("\(progress.remaining) 残り", systemImage: "circle")
                .font(.system(size: size.detailTextSize))
                .foregroundColor(.orange)
        }
    }
    
    // MARK: - Computed Properties
    private var progressColor: Color {
        switch progress.percentage {
        case 0..<25:
            return .red
        case 25..<50:
            return .orange
        case 50..<75:
            return .blue
        case 75..<100:
            return .green
        default:
            return .green
        }
    }
    
    private var progressIcon: String {
        switch progress.percentage {
        case 0:
            return "circle"
        case 1..<100:
            return "clock"
        default:
            return "checkmark.circle.fill"
        }
    }
    
    // MARK: - Accessibility
    private var accessibilityLabel: String {
        return "タスク進捗"
    }
    
    private var accessibilityValue: String {
        return "\(progress.completed)個中\(progress.total)個完了、\(Int(progress.percentage))パーセント"
    }
}

// MARK: - Progress Data
public struct ProgressData {
    public let total: Int
    public let completed: Int
    public let percentage: Double
    
    public var remaining: Int {
        return total - completed
    }
    
    public init(total: Int, completed: Int) {
        self.total = max(0, total)
        self.completed = max(0, min(completed, total))
        self.percentage = total > 0 ? (Double(self.completed) / Double(total)) * 100.0 : 0.0
    }
    
    public init(from response: GetBranchProgressResponse) {
        self.total = response.totalTasks
        self.completed = response.completedTasks
        self.percentage = response.progressPercentage
    }
}

// MARK: - Progress Style
public enum ProgressStyle {
    case circular
    case linear
    case ring
    case minimal
}

// MARK: - Progress Size
public enum ProgressSize {
    case small
    case medium
    case large
    
    var circularSize: CGFloat {
        switch self {
        case .small: return 40
        case .medium: return 60
        case .large: return 80
        }
    }
    
    var ringSize: CGFloat {
        switch self {
        case .small: return 24
        case .medium: return 32
        case .large: return 40
        }
    }
    
    var ringWidth: CGFloat {
        switch self {
        case .small: return 3
        case .medium: return 4
        case .large: return 5
        }
    }
    
    var linearWidth: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 120
        case .large: return 160
        }
    }
    
    var barHeight: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    var strokeWidth: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    var centerTextSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 14
        case .large: return 18
        }
    }
    
    var centerSubtextSize: CGFloat {
        switch self {
        case .small: return 6
        case .medium: return 8
        case .large: return 10
        }
    }
    
    var labelTextSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }
    
    var detailTextSize: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return 10
        case .large: return 12
        }
    }
    
    var iconSize: CGFloat {
        switch self {
        case .small: return 10
        case .medium: return 12
        case .large: return 14
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    var cornerRadius: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return 6
        case .large: return 8
        }
    }
    
    var showCenterText: Bool {
        switch self {
        case .small: return false
        case .medium, .large: return true
        }
    }
}

// MARK: - Branch Progress View
@available(iOS 16.0, macOS 14.0, *)
public struct BranchProgressView: View {
    
    // MARK: - Properties
    let nodeId: UUID
    let progress: ProgressData?
    let style: ProgressStyle
    let size: ProgressSize
    let showWhenEmpty: Bool
    let onTap: (() -> Void)?
    
    // MARK: - Initializers
    public init(
        nodeId: UUID,
        progress: ProgressData? = nil,
        style: ProgressStyle = .ring,
        size: ProgressSize = .small,
        showWhenEmpty: Bool = false,
        onTap: (() -> Void)? = nil
    ) {
        self.nodeId = nodeId
        self.progress = progress
        self.style = style
        self.size = size
        self.showWhenEmpty = showWhenEmpty
        self.onTap = onTap
    }
    
    // MARK: - Body
    public var body: some View {
        Group {
            if let progress = progress, (progress.total > 0 || showWhenEmpty) {
                ProgressIndicatorView(
                    progress: progress,
                    style: style,
                    size: size,
                    showDetails: false,
                    onTap: onTap
                )
            }
        }
    }
}

// MARK: - Preview
@available(iOS 16.0, macOS 14.0, *)
struct ProgressIndicatorView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleProgress = ProgressData(total: 10, completed: 7)
        let emptyProgress = ProgressData(total: 0, completed: 0)
        let completedProgress = ProgressData(total: 5, completed: 5)
        
        VStack(spacing: 20) {
            // Circular Progress
            HStack(spacing: 20) {
                ProgressIndicatorView(progress: sampleProgress, style: .circular, size: .small)
                ProgressIndicatorView(progress: sampleProgress, style: .circular, size: .medium)
                ProgressIndicatorView(progress: sampleProgress, style: .circular, size: .large, showDetails: true)
            }
            
            // Linear Progress
            VStack(spacing: 10) {
                ProgressIndicatorView(progress: sampleProgress, style: .linear, size: .medium)
                ProgressIndicatorView(progress: sampleProgress, style: .linear, size: .large, showDetails: true)
            }
            
            // Ring Progress
            HStack(spacing: 20) {
                ProgressIndicatorView(progress: sampleProgress, style: .ring, size: .small)
                ProgressIndicatorView(progress: completedProgress, style: .ring, size: .medium, showDetails: true)
                ProgressIndicatorView(progress: emptyProgress, style: .ring, size: .small)
            }
            
            // Minimal Progress
            VStack(spacing: 10) {
                ProgressIndicatorView(progress: sampleProgress, style: .minimal, size: .small)
                ProgressIndicatorView(progress: completedProgress, style: .minimal, size: .medium, showDetails: true)
            }
            
            Spacer()
        }
        .padding()
    }
}