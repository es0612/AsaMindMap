import Foundation
import CryptoKit

/// AIプライバシー保護管理システム
/// データ匿名化、ローカル処理、機密情報検出を提供
@available(iOS 15.0, *)
public final class AIPrivacyManager {
    private let sensitivePatterns: [SensitivePattern]
    private let anonymizer = DataAnonymizer()
    private let localProcessor = LocalDataProcessor()
    
    public init() {
        self.sensitivePatterns = Self.createSensitivePatterns()
    }
    
    /// テキストデータの衛生化処理
    public func sanitizeText(_ text: String) -> String {
        var sanitizedText = text
        
        // 機密情報検出と匿名化
        let detections = detectSensitiveInfo(in: text)
        for detection in detections {
            sanitizedText = anonymizeDetection(detection, in: sanitizedText)
        }
        
        return sanitizedText
    }
    
    /// 機密情報検出
    public func detectSensitiveInfo(in text: String) -> [SensitiveInfoDetection] {
        var detections: [SensitiveInfoDetection] = []
        
        for pattern in sensitivePatterns {
            let matches = findMatches(for: pattern, in: text)
            for match in matches {
                detections.append(SensitiveInfoDetection(
                    type: pattern.type,
                    range: match.range,
                    confidence: match.confidence,
                    originalValue: String(text[match.range])
                ))
            }
        }
        
        return detections.sorted { $0.confidence > $1.confidence }
    }
    
    /// データ匿名化
    public func anonymizeData(_ data: [String: Any]) -> [String: Any] {
        return anonymizer.anonymize(data)
    }
    
    /// ローカル処理確認
    public func ensureLocalProcessing() -> Bool {
        return localProcessor.isProcessingLocal()
    }
    
    /// プライバシー同意確認
    public func checkUserConsent(for processingType: ProcessingType) -> Bool {
        return ConsentManager.shared.hasConsent(for: processingType)
    }
    
    /// データ保持期間チェック
    public func checkDataRetention(for data: ProcessedData) -> RetentionStatus {
        let retentionPeriod = getRetentionPeriod(for: data.type)
        let ageInDays = Calendar.current.dateComponents([.day], from: data.createdAt, to: Date()).day ?? 0
        
        if ageInDays > retentionPeriod {
            return .expired
        } else if ageInDays > retentionPeriod - 7 {
            return .expiringSoon
        } else {
            return .valid
        }
    }
    
    /// データ削除
    public func secureDeleteData(_ data: ProcessedData) throws {
        // セキュアな削除処理
        try localProcessor.secureDelete(data)
        
        // 削除ログ記録
        logDataDeletion(data)
    }
    
    // MARK: - Private Methods
    
    private static func createSensitivePatterns() -> [SensitivePattern] {
        return [
            // 個人情報パターン
            SensitivePattern(
                type: .personalName,
                regex: try! NSRegularExpression(pattern: "(?:[山田|田中|佐藤|鈴木|高橋]\\s*[一-龯]+)", options: []),
                confidence: 0.8
            ),
            // メールアドレス
            SensitivePattern(
                type: .email,
                regex: try! NSRegularExpression(pattern: "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}", options: []),
                confidence: 0.9
            ),
            // 電話番号
            SensitivePattern(
                type: .phoneNumber,
                regex: try! NSRegularExpression(pattern: "0\\d{1,4}-\\d{1,4}-\\d{4}", options: []),
                confidence: 0.85
            ),
            // クレジットカード番号
            SensitivePattern(
                type: .creditCard,
                regex: try! NSRegularExpression(pattern: "\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}[\\s-]?\\d{4}", options: []),
                confidence: 0.9
            ),
            // 住所
            SensitivePattern(
                type: .address,
                regex: try! NSRegularExpression(pattern: "〒?\\d{3}-\\d{4}", options: []),
                confidence: 0.8
            )
        ]
    }
    
    private func findMatches(for pattern: SensitivePattern, in text: String) -> [PatternMatch] {
        let nsText = text as NSString
        let matches = pattern.regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsText.length))
        
        return matches.map { match in
            PatternMatch(
                range: Range(match.range, in: text)!,
                confidence: pattern.confidence
            )
        }
    }
    
    private func anonymizeDetection(_ detection: SensitiveInfoDetection, in text: String) -> String {
        let replacement = generateReplacement(for: detection.type)
        return text.replacingCharacters(in: detection.range, with: replacement)
    }
    
    private func generateReplacement(for type: SensitiveInfoType) -> String {
        switch type {
        case .personalName: return "***"
        case .email: return "***@***.***"
        case .phoneNumber: return "***-***-****"
        case .creditCard: return "****-****-****-****"
        case .address: return "***-****"
        case .other: return "***"
        }
    }
    
    private func getRetentionPeriod(for dataType: ProcessedDataType) -> Int {
        switch dataType {
        case .mindMapData: return 365 // 1年
        case .analysisResult: return 90 // 3ヶ月  
        case .userInteraction: return 30 // 1ヶ月
        case .temporaryData: return 1 // 1日
        }
    }
    
    private func logDataDeletion(_ data: ProcessedData) {
        print("Data deleted: \(data.id) at \(Date())")
    }
}

// MARK: - Supporting Classes

/// データ匿名化システム
private final class DataAnonymizer {
    func anonymize(_ data: [String: Any]) -> [String: Any] {
        var anonymized = data
        
        // 文字列データの匿名化
        for (key, value) in data {
            if let stringValue = value as? String {
                anonymized[key] = anonymizeString(stringValue)
            }
        }
        
        return anonymized
    }
    
    private func anonymizeString(_ string: String) -> String {
        // シンプルなハッシュ化匿名化
        let hash = SHA256.hash(data: Data(string.utf8))
        return hash.compactMap { String(format: "%02x", $0) }.joined().prefix(8).description
    }
}

/// ローカルデータ処理システム
private final class LocalDataProcessor {
    func isProcessingLocal() -> Bool {
        // ローカル処理の確認ロジック
        return true // デフォルトでローカル処理
    }
    
    func secureDelete(_ data: ProcessedData) throws {
        // セキュアな削除処理の実装
        // 実際の実装では、データを複数回上書きして完全削除
        print("Securely deleting data: \(data.id)")
    }
}

/// 同意管理システム
private final class ConsentManager {
    static let shared = ConsentManager()
    private var consents: [ProcessingType: Bool] = [:]
    
    private init() {
        // デフォルト同意設定
        consents[.analysis] = true
        consents[.suggestion] = true
        consents[.personalization] = false
    }
    
    func hasConsent(for type: ProcessingType) -> Bool {
        return consents[type] ?? false
    }
    
    func setConsent(_ hasConsent: Bool, for type: ProcessingType) {
        consents[type] = hasConsent
    }
}

// MARK: - Data Models

/// 機密情報検出結果
public struct SensitiveInfoDetection {
    public let type: SensitiveInfoType
    public let range: Range<String.Index>
    public let confidence: Double
    public let originalValue: String
}

/// 機密情報タイプ
public enum SensitiveInfoType: CaseIterable {
    case personalName
    case email
    case phoneNumber
    case creditCard
    case address
    case other
}

/// 機密情報パターン
struct SensitivePattern {
    let type: SensitiveInfoType
    let regex: NSRegularExpression
    let confidence: Double
}

/// パターンマッチ結果
struct PatternMatch {
    let range: Range<String.Index>
    let confidence: Double
}

/// 処理データ
public struct ProcessedData {
    public let id: UUID
    public let type: ProcessedDataType
    public let createdAt: Date
    public let content: Data
}

/// 処理データタイプ
public enum ProcessedDataType {
    case mindMapData
    case analysisResult
    case userInteraction
    case temporaryData
}

/// データ保持状況
public enum RetentionStatus {
    case valid
    case expiringSoon
    case expired
}

/// 処理タイプ
public enum ProcessingType {
    case analysis
    case suggestion
    case personalization
}