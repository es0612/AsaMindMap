//
//  ContentView.swift
//  AsaMindMap
//  
//  Created on 2025/08/17
//

import SwiftUI
import CoreData
import DesignSystem
import MindMapCore

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appViewModel: AppViewModel

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    var body: some View {
        NavigationView {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // ヘッダー
                Text("AsaMindMap")
                    .font(.system(size: DesignSystem.Typography.titleSize, weight: .bold))
                    .foregroundColor(Color(hex: DesignSystem.Colors.primaryHex))
                    .padding(.top, DesignSystem.Spacing.xl)
                
                // メインコンテンツエリア
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("マインドマップでアイデアを整理しよう")
                        .font(.system(size: DesignSystem.Typography.headlineSize, weight: .semibold))
                        .foregroundColor(Color(hex: DesignSystem.Colors.onSecondaryHex))
                        .multilineTextAlignment(.center)
                    
                    Text("開発中...")
                        .font(.system(size: DesignSystem.Typography.bodySize))
                        .foregroundColor(Color(hex: DesignSystem.Colors.secondaryHex))
                        .padding(.top, DesignSystem.Spacing.sm)
                    
                    // 既存のCore Dataリスト（開発用）
                    List {
                        ForEach(items) { item in
                            NavigationLink {
                                Text("Item at \(item.timestamp!, formatter: itemFormatter)")
                            } label: {
                                Text(item.timestamp!, formatter: itemFormatter)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .frame(maxHeight: 200)
                    .background(Color(hex: DesignSystem.Colors.surfaceHex))
                    .cornerRadius(8)
                }
                .padding(.horizontal, DesignSystem.Spacing.lg)
                
                Spacer()
                
                // 開発用ボタン
                Button(action: addItem) {
                    Label("テストアイテム追加", systemImage: "plus")
                        .font(.system(size: DesignSystem.Typography.bodySize))
                        .foregroundColor(Color(hex: DesignSystem.Colors.onPrimaryHex))
                        .padding()
                        .background(Color(hex: DesignSystem.Colors.primaryHex))
                        .cornerRadius(8)
                }
                .padding(.bottom, DesignSystem.Spacing.lg)
                
                // フッター
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text("Version 1.0.0")
                        .font(.system(size: DesignSystem.Typography.captionSize))
                        .foregroundColor(Color(hex: DesignSystem.Colors.secondaryHex))
                    
                    Text("Powered by Swift & SwiftUI")
                        .font(.system(size: DesignSystem.Typography.captionSize))
                        .foregroundColor(Color(hex: DesignSystem.Colors.secondaryHex))
                }
                .padding(.bottom, DesignSystem.Spacing.lg)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(hex: DesignSystem.Colors.backgroundHex))
        }
        .onAppear {
            Logger.shared.info("ContentView が表示されました", category: "ui")
        }
    }

    private func addItem() {
        withAnimation {
            let newItem = Item(context: viewContext)
            newItem.timestamp = Date()

            do {
                try viewContext.save()
                Logger.shared.info("新しいアイテムが追加されました", category: "data")
            } catch {
                let nsError = error as NSError
                Logger.shared.error("アイテム追加エラー: \(nsError.localizedDescription)", category: "data")
            }
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
                Logger.shared.info("アイテムが削除されました", category: "data")
            } catch {
                let nsError = error as NSError
                Logger.shared.error("アイテム削除エラー: \(nsError.localizedDescription)", category: "data")
            }
        }
    }
}

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .medium
    return formatter
}()

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environmentObject(AppViewModel(container: DIContainer.configure()))
}
