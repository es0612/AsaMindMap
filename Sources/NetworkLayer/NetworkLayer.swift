import Foundation

// MARK: - NetworkLayer Module
public struct NetworkLayer {
    public static let version = "1.0.0"
    
    private init() {}
}

// MARK: - Public Interface
public extension NetworkLayer {
    /// NetworkLayerモジュールの初期化
    static func configure() {
        // ネットワーク層の初期化設定
        print("NetworkLayer module configured")
    }
}