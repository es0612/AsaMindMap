//
//  AsaMindMapApp.swift
//  AsaMindMap
//  
//  Created on 2025/08/17
//


import SwiftUI

@main
struct AsaMindMapApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
