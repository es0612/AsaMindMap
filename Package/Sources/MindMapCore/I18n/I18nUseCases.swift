import Foundation
import Combine

// MARK: - Localization Use Cases

public protocol LocalizationUseCaseProtocol {
    func getCurrentLanguage() -> SupportedLanguage
    func setLanguage(_ language: SupportedLanguage) -> Bool
    func getSupportedLanguages() -> [SupportedLanguage]
    func localizedString(for key: String) -> String
    func pluralizedString(for key: String, count: Int) -> String
    var languageDidChangePublisher: AnyPublisher<SupportedLanguage, Never> { get }
}

public class LocalizationUseCase: LocalizationUseCaseProtocol {
    private let localizationManager: LocalizationManager
    
    public init(localizationManager: LocalizationManager) {
        self.localizationManager = localizationManager
    }
    
    public func getCurrentLanguage() -> SupportedLanguage {
        return localizationManager.currentLanguage
    }
    
    public func setLanguage(_ language: SupportedLanguage) -> Bool {
        return localizationManager.setLanguage(language)
    }
    
    public func getSupportedLanguages() -> [SupportedLanguage] {
        return [.japanese, .english, .chineseSimplified, .korean]
    }
    
    public func localizedString(for key: String) -> String {
        return localizationManager.localizedString(for: key)
    }
    
    public func pluralizedString(for key: String, count: Int) -> String {
        return localizationManager.pluralizedString(for: key, count: count)
    }
    
    public var languageDidChangePublisher: AnyPublisher<SupportedLanguage, Never> {
        return localizationManager.languageDidChangePublisher.eraseToAnyPublisher()
    }
}

// MARK: - RTL Layout Use Cases

public protocol RTLLayoutUseCaseProtocol {
    func getCurrentLayoutDirection() -> LayoutDirection
    func isRTLLanguage(_ language: SupportedLanguage) -> Bool
    func adjustMindMapLayout(_ mindMap: MindMap, for language: SupportedLanguage) -> MindMap
    func getTextAlignment(for language: SupportedLanguage) -> TextAlignment
    func adjustSwipeDirection(_ direction: SwipeDirection, for language: SupportedLanguage) -> SwipeDirection
}

public class RTLLayoutUseCase: RTLLayoutUseCaseProtocol {
    private let rtlLayoutManager: RTLLayoutManager
    private let localizationManager: LocalizationManager
    private var cancellables = Set<AnyCancellable>()
    
    public init(rtlLayoutManager: RTLLayoutManager, localizationManager: LocalizationManager) {
        self.rtlLayoutManager = rtlLayoutManager
        self.localizationManager = localizationManager
        
        // Set initial layout direction based on current language
        rtlLayoutManager.setLayoutDirection(for: localizationManager.currentLanguage)
        
        // Listen for language changes
        localizationManager.languageDidChangePublisher
            .sink { [weak rtlLayoutManager] language in
                rtlLayoutManager?.setLayoutDirection(for: language)
            }
            .store(in: &cancellables)
    }
    
    public func getCurrentLayoutDirection() -> LayoutDirection {
        return rtlLayoutManager.currentLayoutDirection
    }
    
    public func isRTLLanguage(_ language: SupportedLanguage) -> Bool {
        return rtlLayoutManager.isRTLLanguage(language)
    }
    
    public func adjustMindMapLayout(_ mindMap: MindMap, for language: SupportedLanguage) -> MindMap {
        let direction = rtlLayoutManager.layoutDirection(for: language)
        return rtlLayoutManager.adjustMindMapLayout(mindMap, for: direction)
    }
    
    public func getTextAlignment(for language: SupportedLanguage) -> TextAlignment {
        let direction = rtlLayoutManager.layoutDirection(for: language)
        return rtlLayoutManager.textAlignment(for: direction)
    }
    
    public func adjustSwipeDirection(_ direction: SwipeDirection, for language: SupportedLanguage) -> SwipeDirection {
        let layoutDirection = rtlLayoutManager.layoutDirection(for: language)
        return rtlLayoutManager.adjustSwipeDirection(direction, for: layoutDirection)
    }
}

// MARK: - Cultural Adaptation Use Cases

public protocol CulturalAdaptationUseCaseProtocol {
    func formatDate(_ date: Date, for language: SupportedLanguage?) -> String
    func formatTime(_ date: Date, for language: SupportedLanguage?) -> String
    func formatNumber(_ number: Double, for language: SupportedLanguage?) -> String
    func formatCurrency(_ amount: Double, for language: SupportedLanguage?) -> String
    func formatPercentage(_ percentage: Double, for language: SupportedLanguage?) -> String
    func formatNodeCountDescription(_ count: Int, for language: SupportedLanguage?) -> String
    func formatTaskProgressDescription(completed: Int, total: Int, for language: SupportedLanguage?) -> String
    func formatExportFileName(_ title: String, date: Date, for language: SupportedLanguage?) -> String
}

public class CulturalAdaptationUseCase: CulturalAdaptationUseCaseProtocol {
    private let culturalAdaptationService: CulturalAdaptationService
    private let localizationManager: LocalizationManager
    
    public init(culturalAdaptationService: CulturalAdaptationService, localizationManager: LocalizationManager) {
        self.culturalAdaptationService = culturalAdaptationService
        self.localizationManager = localizationManager
    }
    
    public func formatDate(_ date: Date, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatDate(date, for: targetLanguage)
    }
    
    public func formatTime(_ date: Date, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatTime(date, for: targetLanguage)
    }
    
    public func formatNumber(_ number: Double, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatNumber(number, for: targetLanguage)
    }
    
    public func formatCurrency(_ amount: Double, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatCurrency(amount, for: targetLanguage)
    }
    
    public func formatPercentage(_ percentage: Double, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatPercentage(percentage, for: targetLanguage)
    }
    
    public func formatNodeCountDescription(_ count: Int, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatNodeCountDescription(count, for: targetLanguage)
    }
    
    public func formatTaskProgressDescription(completed: Int, total: Int, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatTaskProgressDescription(completed: completed, total: total, for: targetLanguage)
    }
    
    public func formatExportFileName(_ title: String, date: Date, for language: SupportedLanguage? = nil) -> String {
        let targetLanguage = language ?? localizationManager.currentLanguage
        return culturalAdaptationService.formatExportFileName(title, date: date, for: targetLanguage)
    }
}

// MARK: - Comprehensive I18n Use Case

public protocol I18nUseCaseProtocol {
    var localization: LocalizationUseCaseProtocol { get }
    var rtlLayout: RTLLayoutUseCaseProtocol { get }
    var culturalAdaptation: CulturalAdaptationUseCaseProtocol { get }
}

public class I18nUseCase: I18nUseCaseProtocol {
    public let localization: LocalizationUseCaseProtocol
    public let rtlLayout: RTLLayoutUseCaseProtocol
    public let culturalAdaptation: CulturalAdaptationUseCaseProtocol
    
    public init(
        localization: LocalizationUseCaseProtocol,
        rtlLayout: RTLLayoutUseCaseProtocol,
        culturalAdaptation: CulturalAdaptationUseCaseProtocol
    ) {
        self.localization = localization
        self.rtlLayout = rtlLayout
        self.culturalAdaptation = culturalAdaptation
    }
}