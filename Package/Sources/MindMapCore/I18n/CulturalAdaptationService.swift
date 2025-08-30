import Foundation

// MARK: - Cultural Adaptation Service

public class CulturalAdaptationService: ObservableObject {
    
    // MARK: - Private Properties
    
    private var dateFormatters: [String: DateFormatter] = [:]
    private var timeFormatters: [String: DateFormatter] = [:]
    private var numberFormatters: [String: NumberFormatter] = [:]
    private var currencyFormatters: [String: NumberFormatter] = [:]
    private var percentFormatters: [String: NumberFormatter] = [:]
    
    // MARK: - Initialization
    
    public init() {
        setupFormatters()
    }
    
    // MARK: - Date Formatting
    
    public func formatDate(_ date: Date, for language: SupportedLanguage) -> String {
        let locale = Locale(identifier: language.languageCode)
        let formatter = dateFormatters[language.languageCode] ?? createDateFormatter(for: locale)
        return formatter.string(from: date)
    }
    
    public func formatTime(_ date: Date, for language: SupportedLanguage) -> String {
        let locale = Locale(identifier: language.languageCode)
        let formatter = timeFormatters[language.languageCode] ?? createTimeFormatter(for: locale)
        return formatter.string(from: date)
    }
    
    // MARK: - Number Formatting
    
    public func formatNumber(_ number: Double, for language: SupportedLanguage) -> String {
        let locale = Locale(identifier: language.languageCode)
        let formatter = numberFormatters[language.languageCode] ?? createNumberFormatter(for: locale)
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    public func formatCurrency(_ amount: Double, for language: SupportedLanguage) -> String {
        let locale = Locale(identifier: language.languageCode)
        let formatter = currencyFormatters[language.languageCode] ?? createCurrencyFormatter(for: locale)
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
    }
    
    public func formatPercentage(_ percentage: Double, for language: SupportedLanguage) -> String {
        let locale = Locale(identifier: language.languageCode)
        let formatter = percentFormatters[language.languageCode] ?? createPercentFormatter(for: locale)
        return formatter.string(from: NSNumber(value: percentage)) ?? "\(percentage)%"
    }
    
    // MARK: - Specialized Formatting
    
    public func formatExportFileName(_ title: String, date: Date, for language: SupportedLanguage) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let cleanTitle = title.replacingOccurrences(of: " ", with: "_")
        return "\(cleanTitle)_\(dateString).pdf"
    }
    
    public func formatNodeCountDescription(_ count: Int, for language: SupportedLanguage) -> String {
        switch language {
        case .japanese:
            return "\(count)個のノード"
        case .english:
            return count == 1 ? "\(count) node" : "\(count) nodes"
        case .chineseSimplified:
            return "\(count)个节点"
        case .korean:
            return "\(count)개 노드"
        default:
            return "\(count) nodes"
        }
    }
    
    public func formatTaskProgressDescription(completed: Int, total: Int, for language: SupportedLanguage) -> String {
        switch language {
        case .japanese:
            return "\(total)個中\(completed)個完了"
        case .english:
            return "\(completed) of \(total) completed"
        case .chineseSimplified:
            return "已完成 \(completed)/\(total)"
        case .korean:
            return "\(total)개 중 \(completed)개 완료"
        default:
            return "\(completed) of \(total) completed"
        }
    }
    
    public func formatList(_ items: [String], for language: SupportedLanguage) -> String {
        let separator = listSeparator(for: language)
        return items.joined(separator: separator)
    }
    
    public func weekdayOrder(for language: SupportedLanguage) -> [Weekday] {
        switch language {
        case .arabic:
            // Week starts on Saturday in many Arabic countries
            return [.saturday, .sunday, .monday, .tuesday, .wednesday, .thursday, .friday]
        case .english, .japanese, .chineseSimplified, .korean:
            // Week starts on Sunday in these locales
            return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        default:
            return [.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday]
        }
    }
    
    // MARK: - Private Methods
    
    private func setupFormatters() {
        let supportedLanguages: [SupportedLanguage] = [.japanese, .english, .chineseSimplified, .korean, .arabic, .hebrew, .french, .german]
        
        for language in supportedLanguages {
            let locale = Locale(identifier: language.languageCode)
            
            dateFormatters[language.languageCode] = createDateFormatter(for: locale)
            timeFormatters[language.languageCode] = createTimeFormatter(for: locale)
            numberFormatters[language.languageCode] = createNumberFormatter(for: locale)
            currencyFormatters[language.languageCode] = createCurrencyFormatter(for: locale)
            percentFormatters[language.languageCode] = createPercentFormatter(for: locale)
        }
    }
    
    private func createDateFormatter(for locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter
    }
    
    private func createTimeFormatter(for locale: Locale) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }
    
    private func createNumberFormatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        return formatter
    }
    
    private func createCurrencyFormatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .currency
        
        // Special handling for Japanese Yen (no decimal places)
        if locale.language.languageCode?.identifier == "ja" {
            formatter.maximumFractionDigits = 0
        }
        
        return formatter
    }
    
    private func createPercentFormatter(for locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .percent
        return formatter
    }
    
    private func listSeparator(for language: SupportedLanguage) -> String {
        switch language {
        case .japanese, .chineseSimplified:
            return "、"
        case .arabic:
            return "، "
        case .english, .korean, .french, .german, .hebrew:
            return ", "
        }
    }
}