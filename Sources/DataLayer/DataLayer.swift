import Foundation
import NetworkLayer

// MARK: - DataLayer Module
public struct DataLayer {
    public static let version = "1.0.0"
    
    private init() {}
}

// MARK: - Public Interface
public extension DataLayer {
    /// DataLayerモジュールの初期化
    static func configure() {
        // データ層の依存性注入設定
        print("DataLayer module configured")
    }
}