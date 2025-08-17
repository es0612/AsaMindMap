//
//  AsaMindMapApp.swift
//  AsaMindMap
//  
//  Created on 2025/08/17
//

import SwiftUI
import MindMapCore
import MindMapUI
import DesignSystem

@main
struct AsaMindMapApp: App {
    let persistenceController = PersistenceController.shared
    private let container: DIContainer
    
    init() {
        // DIコンテナの設定
        self.container = DIContainer.configure()
        
        // 各モジュールの初期化
        MindMapUI.configure(with: container)
        
        // ログ出力
        Logger.shared.info("AsaMindMap アプリケーションが開始されました", category: "app")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(AppViewModel(container: container))
        }
    }
}

// MARK: - App ViewModel
class AppViewModel: ObservableObject {
    private let container: DIContainer
    
    init(container: DIContainer) {
        self.container = container
        Logger.shared.info("AppViewModel が初期化されました", category: "viewmodel")
    }
}
