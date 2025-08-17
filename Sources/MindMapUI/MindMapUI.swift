import SwiftUI
import MindMapCore

// MARK: - MindMapUI Module
public struct MindMapUI {
    public static let version = "1.0.0"
    
    private init() {}
}

// MARK: - Public Interface
public extension MindMapUI {
    /// MindMapUIモジュールの初期化
    static func configure(with container: DIContainerProtocol) {
        // UI関連の依存性注入設定
        Logger.shared.info("MindMapUI module configured", category: "initialization")
    }
}