import Foundation
import Combine

// MARK: - Supported Languages

public enum SupportedLanguage: String, CaseIterable, Codable {
    case japanese = "ja"
    case english = "en"
    case chineseSimplified = "zh-Hans"
    case korean = "ko"
    case arabic = "ar"
    case hebrew = "he"
    case french = "fr"
    case german = "de"
    
    public var languageCode: String {
        return self.rawValue
    }
    
    public var displayName: String {
        switch self {
        case .japanese: return "日本語"
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        case .korean: return "한국어"
        case .arabic: return "العربية"
        case .hebrew: return "עברית"
        case .french: return "Français"
        case .german: return "Deutsch"
        }
    }
    
    public var nativeName: String {
        return displayName
    }
    
    public var flagEmoji: String {
        switch self {
        case .japanese: return "🇯🇵"
        case .english: return "🇺🇸"
        case .chineseSimplified: return "🇨🇳"
        case .korean: return "🇰🇷"
        case .arabic: return "🇸🇦"
        case .hebrew: return "🇮🇱"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        }
    }
    
    public static func from(languageCode: String) -> SupportedLanguage? {
        return SupportedLanguage.allCases.first { $0.languageCode == languageCode }
    }
}

// MARK: - Layout Direction

public enum LayoutDirection: String, Codable {
    case leftToRight = "ltr"
    case rightToLeft = "rtl"
}

// MARK: - Text Alignment

public enum TextAlignment: String, Codable {
    case leading = "leading"
    case center = "center"
    case trailing = "trailing"
}

// MARK: - Swipe Direction

public enum SwipeDirection: String, CaseIterable {
    case up = "up"
    case down = "down"
    case left = "left"
    case right = "right"
}

// MARK: - Connection Direction

public enum ConnectionDirection: String, Codable {
    case topToBottom = "topToBottom"
    case leftToRight = "leftToRight"
    case topLeftToBottomRight = "topLeftToBottomRight"
    case topRightToBottomLeft = "topRightToBottomLeft"
}

// MARK: - Weekday

public enum Weekday: Int, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

// MARK: - Localization Error

public enum LocalizationError: LocalizedError, Equatable {
    case localizationFileNotFound(String)
    case localizationKeyNotFound(String)
    case unsupportedLanguage(String)
    
    public var errorDescription: String? {
        switch self {
        case .localizationFileNotFound(let language):
            return "Localization file not found for language: \(language)"
        case .localizationKeyNotFound(let key):
            return "Localization key not found: \(key)"
        case .unsupportedLanguage(let language):
            return "Unsupported language: \(language)"
        }
    }
}

// MARK: - Localization Configuration

public struct LocalizationConfiguration {
    public let fallbackLanguage: SupportedLanguage
    public let supportedLanguages: [SupportedLanguage]
    public let enableRTLSupport: Bool
    public let enableCulturalAdaptation: Bool
    
    public init(
        fallbackLanguage: SupportedLanguage = .english,
        supportedLanguages: [SupportedLanguage] = [.japanese, .english, .chineseSimplified, .korean],
        enableRTLSupport: Bool = true,
        enableCulturalAdaptation: Bool = true
    ) {
        self.fallbackLanguage = fallbackLanguage
        self.supportedLanguages = supportedLanguages
        self.enableRTLSupport = enableRTLSupport
        self.enableCulturalAdaptation = enableCulturalAdaptation
    }
    
    public static let `default` = LocalizationConfiguration()
}