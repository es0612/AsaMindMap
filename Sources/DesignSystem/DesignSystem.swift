import Foundation

// MARK: - DesignSystem Module
public struct DesignSystem {
    public static let version = "1.0.0"
    
    private init() {}
}

// MARK: - Color System (Basic colors without SwiftUI dependency)
public extension DesignSystem {
    enum Colors {
        public static let primaryHex = "#007AFF"
        public static let secondaryHex = "#8E8E93"
        public static let backgroundHex = "#FFFFFF"
        public static let surfaceHex = "#F2F2F7"
        public static let onPrimaryHex = "#FFFFFF"
        public static let onSecondaryHex = "#000000"
    }
}

// MARK: - Typography System (Basic font sizes)
public extension DesignSystem {
    enum Typography {
        public static let titleSize: CGFloat = 34
        public static let headlineSize: CGFloat = 17
        public static let bodySize: CGFloat = 17
        public static let captionSize: CGFloat = 12
    }
}

// MARK: - Spacing System
public extension DesignSystem {
    enum Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }
}