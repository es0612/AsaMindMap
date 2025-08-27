import SwiftUI
import Combine
#if os(iOS)
import UIKit
#endif

// MARK: - Animation Configuration
/// 統一されたアニメーション設定とパフォーマンス最適化
public struct AnimationConfiguration {
    
    // MARK: - Standard Durations
    public static let quickTransition: Double = 0.1
    public static let standardTransition: Double = 0.2  
    public static let slowTransition: Double = 0.3
    public static let longTransition: Double = 0.5
    public static let extendedTransition: Double = 0.8
    
    // MARK: - Standard Curves
    public static let easeInOut = Animation.easeInOut
    public static let easeIn = Animation.easeIn
    public static let easeOut = Animation.easeOut
    public static let spring = Animation.interactiveSpring(response: 0.4, dampingFraction: 0.8)
    public static let bouncy = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.6)
    
    // MARK: - Optimized Animations
    /// ノード選択用の最適化されたアニメーション
    public static func nodeSelection(duration: Double = standardTransition) -> Animation {
        .easeInOut(duration: duration)
    }
    
    /// キャンバス操作用のスプリングアニメーション  
    public static func canvasInteraction(response: Double = 0.4, damping: Double = 0.8) -> Animation {
        .interactiveSpring(response: response, dampingFraction: damping)
    }
    
    /// メディアの表示・非表示用アニメーション
    public static func mediaPresentation(duration: Double = standardTransition) -> Animation {
        .easeInOut(duration: duration)
    }
    
    /// プログレス表示用のスムーズなアニメーション
    public static func progressUpdate(duration: Double = longTransition) -> Animation {
        .easeInOut(duration: duration)
    }
    
    /// UIトランジション用の組み合わせアニメーション
    public static var uiTransition: AnyTransition {
        .asymmetric(
            insertion: .scale.combined(with: .opacity),
            removal: .scale.combined(with: .opacity)
        )
    }
}

// MARK: - Performance-Optimized Animation Modifier
/// アニメーションパフォーマンスを最適化するカスタムViewModifier
public struct OptimizedAnimationModifier<Value: Equatable>: ViewModifier {
    let animation: Animation
    let value: Value
    let isEnabled: Bool
    
    public init(animation: Animation, value: Value, enabled: Bool = true) {
        self.animation = animation
        self.value = value
        self.isEnabled = enabled
    }
    
    public func body(content: Content) -> some View {
        if isEnabled {
            content.animation(animation, value: value)
        } else {
            content
        }
    }
}

// MARK: - View Extension
public extension View {
    /// パフォーマンス最適化されたアニメーション
    func optimizedAnimation<V: Equatable>(_ animation: Animation, value: V, enabled: Bool = true) -> some View {
        modifier(OptimizedAnimationModifier(animation: animation, value: value, enabled: enabled))
    }
    
    /// 条件付きアニメーション（パフォーマンス設定に基づく）
    func conditionalAnimation<V: Equatable>(_ animation: Animation, value: V, condition: Bool = true) -> some View {
        optimizedAnimation(animation, value: value, enabled: condition)
    }
}

// MARK: - Animation Performance Manager
/// アニメーションパフォーマンスを管理するクラス
@MainActor
public class AnimationPerformanceManager: ObservableObject {
    @Published public var animationsEnabled = true
    @Published public var reducedMotionEnabled = false
    
    private var performanceTimer: Timer?
    private var frameTimestamps: [CFTimeInterval] = []
    private let maxTimestampCount = 60
    
    public init() {
        // システムのモーション設定を監視
        if #available(iOS 14.0, macOS 11.0, *) {
            setupAccessibilityObserver()
        }
        startPerformanceMonitoring()
    }
    
    deinit {
        performanceTimer?.invalidate()
    }
    
    // MARK: - Performance Monitoring
    private func startPerformanceMonitoring() {
        performanceTimer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.recordFrameTimestamp()
            }
        }
    }
    
    private func recordFrameTimestamp() {
        let timestamp = CACurrentMediaTime()
        frameTimestamps.append(timestamp)
        
        if frameTimestamps.count > maxTimestampCount {
            frameTimestamps.removeFirst()
        }
        
        // 低フレームレートを検出したらアニメーションを調整
        if frameTimestamps.count >= 30 {
            let averageFrameRate = calculateAverageFrameRate()
            if averageFrameRate < 45.0 {
                optimizeForLowPerformance()
            }
        }
    }
    
    private func calculateAverageFrameRate() -> Double {
        guard frameTimestamps.count > 1 else { return 60.0 }
        
        let totalTime = frameTimestamps.last! - frameTimestamps.first!
        let frameCount = frameTimestamps.count - 1
        
        return Double(frameCount) / totalTime
    }
    
    private func optimizeForLowPerformance() {
        // パフォーマンスが低下している場合の最適化
        if !reducedMotionEnabled {
            reducedMotionEnabled = true
            print("🔧 Animation performance optimized: Reduced motion enabled")
        }
    }
    
    @available(iOS 14.0, macOS 11.0, *)
    private func setupAccessibilityObserver() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        }
        
        reducedMotionEnabled = UIAccessibility.isReduceMotionEnabled
        #else
        // macOSでは基本的にアニメーション有効
        reducedMotionEnabled = false
        #endif
    }
    
    // MARK: - Animation Optimization
    public func optimizedAnimation(_ baseAnimation: Animation) -> Animation {
        if reducedMotionEnabled {
            return .easeInOut(duration: 0.1) // 非常に短いアニメーション
        } else {
            return baseAnimation
        }
    }
    
    public func shouldUseAnimation() -> Bool {
        return animationsEnabled && !reducedMotionEnabled
    }
}