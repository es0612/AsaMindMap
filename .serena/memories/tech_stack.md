# 技術スタック

## プラットフォーム
- iOS 16.0+
- macOS 13.0+（Swift Package部分）

## 開発環境
- Xcode 15.0+
- Swift 5.9+
- Swift Package Manager

## アーキテクチャ
- クリーンアーキテクチャ
- MVVM パターン
- モジュラーアーキテクチャ

## UI フレームワーク
- SwiftUI (メインUI)
- Core Animation (描画最適化)
- Canvas API (描画エンジン)

## データ層
- Core Data (ローカル永続化)
- CloudKit (クラウド同期)

## テスト
- XCTest (単体テスト)
- XCUITest (UIテスト)
- TDD アプローチ

## モジュール構成
### MindMapCore
- ビジネスロジック（Use Cases）
- エンティティ定義
- DIコンテナ
- エラーハンドリング
- ログ機能

### MindMapUI
- SwiftUIビューとViewModels
- ユーザーインタラクション処理
- UI状態管理

### DataLayer
- データ永続化
- Core Data管理
- CloudKit同期

### NetworkLayer
- HTTP通信
- APIクライアント
- ネットワークエラーハンドリング

### DesignSystem
- カラーシステム
- タイポグラフィ
- スペーシング
- 共通UIコンポーネント

## 開発ツール
- SwiftLint (コード品質)
- SwiftFormat (コードフォーマット)
- Makefile (開発コマンド)