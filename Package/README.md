# AsaMindMap Swift Package

AsaMindMapアプリケーションのコアロジックを提供するSwift Packageです。

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
- API クライアント
- ネットワークエラーハンドリング

### DesignSystem
- カラーシステム
- タイポグラフィ
- スペーシング
- 共通UIコンポーネント

## 開発

### テスト実行
```bash
swift test
```

### ビルド
```bash
swift build
```

## アーキテクチャ

クリーンアーキテクチャ + MVVMパターンを採用し、各モジュールが明確な責任を持つように設計されています。