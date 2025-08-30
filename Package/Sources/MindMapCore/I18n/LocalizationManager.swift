import Foundation
import Combine

// MARK: - Localization Manager

public class LocalizationManager: ObservableObject {
    
    // MARK: - Properties
    
    @Published public private(set) var currentLanguage: SupportedLanguage
    public let languageDidChangePublisher = PassthroughSubject<SupportedLanguage, Never>()
    
    private let configuration: LocalizationConfiguration
    private var localizedStrings: [String: [String: String]] = [:]
    
    public var currentLocale: Locale {
        return Locale(identifier: currentLanguage.languageCode)
    }
    
    // MARK: - Initialization
    
    public init(configuration: LocalizationConfiguration = .default) {
        self.configuration = configuration
        self.currentLanguage = Self.detectSystemLanguage(from: configuration.supportedLanguages) ?? configuration.fallbackLanguage
        self.loadLocalizedStrings()
    }
    
    // MARK: - Public Methods
    
    @discardableResult
    public func setLanguage(_ language: SupportedLanguage) -> Bool {
        guard configuration.supportedLanguages.contains(language) else {
            // Fallback to default language
            if currentLanguage != configuration.fallbackLanguage {
                currentLanguage = configuration.fallbackLanguage
                languageDidChangePublisher.send(currentLanguage)
            }
            return false
        }
        
        currentLanguage = language
        languageDidChangePublisher.send(language)
        loadLocalizedStrings()
        return true
    }
    
    public func localizedString(for key: String) -> String {
        let languageCode = currentLanguage.languageCode
        
        // Try current language
        if let languageStrings = localizedStrings[languageCode],
           let localizedString = languageStrings[key] {
            return localizedString
        }
        
        // Fallback to English
        if let englishStrings = localizedStrings[configuration.fallbackLanguage.languageCode],
           let fallbackString = englishStrings[key] {
            return fallbackString
        }
        
        // Return key if no localization found (for testing/development)
        return key
    }
    
    public func pluralizedString(for key: String, count: Int) -> String {
        let baseKey = key
        let pluralKey = "\(key).plural"
        
        if count == 1 {
            let singular = localizedString(for: baseKey)
            return "\(count) \(singular)"
        } else {
            let plural = localizedString(for: pluralKey)
            if plural != pluralKey {
                return "\(count) \(plural)"
            } else {
                // Fallback to base key with 's' suffix
                let base = localizedString(for: baseKey)
                return "\(count) \(base)s"
            }
        }
    }
    
    // MARK: - Private Methods
    
    private static func detectSystemLanguage(from supportedLanguages: [SupportedLanguage]) -> SupportedLanguage? {
        let preferredLanguages = Locale.preferredLanguages
        
        for preferred in preferredLanguages {
            let languageCode = String(preferred.prefix(2))
            if let supported = supportedLanguages.first(where: { $0.languageCode.hasPrefix(languageCode) }) {
                return supported
            }
        }
        
        return nil
    }
    
    private func loadLocalizedStrings() {
        // Load localized strings for all supported languages
        // In a real implementation, this would load from bundle resources
        
        localizedStrings = [
            "ja": [
                "mindmap.create.title": "マインドマップを作成",
                "common.cancel": "キャンセル",
                "node.count": "ノード",
                "node.count.plural": "ノード"
            ],
            "en": [
                "mindmap.create.title": "Create Mind Map",
                "common.cancel": "Cancel",
                "node.count": "node",
                "node.count.plural": "nodes"
            ],
            "zh-Hans": [
                "mindmap.create.title": "创建思维导图",
                "common.cancel": "取消",
                "node.count": "节点",
                "node.count.plural": "节点"
            ],
            "ko": [
                "mindmap.create.title": "마인드맵 만들기",
                "common.cancel": "취소",
                "node.count": "개",
                "node.count.plural": "개"
            ]
        ]
    }
}