import SwiftUI
import MindMapCore

// MARK: - Accessibility Configuration
public final class AccessibilityConfiguration: ObservableObject {
    
    // MARK: - Published Properties
    @Published public var dynamicTypeSize: DynamicTypeSize = .large
    @Published public var colorScheme: ColorScheme = .light
    @Published public var accessibilityContrast: AccessibilityContrast = .normal
    @Published public var voiceOverEnabled: Bool = false
    @Published public var switchControlEnabled: Bool = false
    
    // MARK: - Computed Properties
    public var currentColors: ColorAccessibilityInfo {
        return ColorAccessibilityHelper.getColors(
            for: colorScheme,
            contrast: accessibilityContrast
        )
    }
    
    public var currentFontSize: CGFloat {
        return DynamicTypeHelper.getNodeFontSize(for: dynamicTypeSize.contentSizeCategory)
    }
    
    public var minimumTapTargetSize: CGSize {
        return DynamicTypeHelper.getMinimumTapSize(for: dynamicTypeSize.contentSizeCategory)
    }
    
    // MARK: - Initialization
    public init() {}
    
    // MARK: - Methods
    public func updateFromEnvironment(_ environment: EnvironmentValues) {
        dynamicTypeSize = environment.dynamicTypeSize
        colorScheme = environment.colorScheme
        
        #if canImport(UIKit)
        accessibilityContrast = UIAccessibility.isDarkerSystemColorsEnabled ? .high : .normal
        voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        switchControlEnabled = UIAccessibility.isSwitchControlRunning
        #endif
    }
}

// MARK: - Accessibility View Modifier
public struct AccessibilityConfigurationModifier: ViewModifier {
    
    @StateObject private var config = AccessibilityConfiguration()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    
    public func body(content: Content) -> some View {
        content
            .environmentObject(config)
            .onReceive(NotificationCenter.default.publisher(for: .accessibilityElementFocusedNotification)) { _ in
                updateConfiguration()
            }
            .onReceive(NotificationCenter.default.publisher(for: .accessibilityLayoutChangedNotification)) { _ in
                updateConfiguration()
            }
            .onChange(of: dynamicTypeSize, perform: { _ in
                updateConfiguration()
            })
            .onChange(of: colorScheme, perform: { _ in
                updateConfiguration()
            })
    }
    
    private func updateConfiguration() {
        config.dynamicTypeSize = dynamicTypeSize
        config.colorScheme = colorScheme
        
        #if canImport(UIKit)
        config.accessibilityContrast = UIAccessibility.isDarkerSystemColorsEnabled ? .high : .normal
        config.voiceOverEnabled = UIAccessibility.isVoiceOverRunning
        config.switchControlEnabled = UIAccessibility.isSwitchControlRunning
        #endif
    }
}

// MARK: - View Extension
extension View {
    public func accessibilityConfigured() -> some View {
        modifier(AccessibilityConfigurationModifier())
    }
}

// MARK: - Dynamic Type Extension
extension DynamicTypeSize {
    var contentSizeCategory: ContentSizeCategory {
        switch self {
        case .xSmall: return .extraSmall
        case .small: return .small
        case .medium: return .medium
        case .large: return .large
        case .xLarge: return .extraLarge
        case .xxLarge: return .extraExtraLarge
        case .xxxLarge: return .extraExtraExtraLarge
        case .accessibility1: return .accessibilityMedium
        case .accessibility2: return .accessibilityLarge
        case .accessibility3: return .accessibilityExtraLarge
        case .accessibility4: return .accessibilityExtraExtraLarge
        case .accessibility5: return .accessibilityExtraExtraExtraLarge
        @unknown default: return .large
        }
    }
}