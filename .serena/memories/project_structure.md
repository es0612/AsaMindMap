# プロジェクト構造

## ディレクトリ構成

```
AsaMindMap/
├── Package/                    # Swift Package（コアロジック）
│   ├── Sources/
│   │   ├── MindMapCore/        # コアビジネスロジック
│   │   ├── MindMapUI/          # UIコンポーネント
│   │   ├── DataLayer/          # データ管理
│   │   ├── NetworkLayer/       # ネットワーク処理
│   │   └── DesignSystem/       # デザインシステム
│   ├── Tests/                  # パッケージテスト
│   ├── Package.swift           # パッケージ定義
│   └── README.md
├── App/                        # iOS アプリケーション
│   ├── AsaMindMap.xcodeproj    # Xcodeプロジェクト
│   ├── AsaMindMap/             # アプリソースコード
│   ├── AsaMindMapTests/        # アプリテスト
│   └── AsaMindMapUITests/      # UIテスト
├── Tools/                      # 開発ツール設定
│   ├── .swiftlint.yml         # SwiftLint設定
│   ├── .swiftformat           # SwiftFormat設定
│   └── Makefile               # 開発コマンド
├── .kiro/                      # Kiro設定（仕様管理）
│   └── specs/                 # 仕様書
│       └── asa-mindmap/       # 現在の仕様
├── .claude/                   # Claude Code設定
├── CLAUDE.md                  # プロジェクト指示書
├── README.md                  # プロジェクト全体のREADME
├── Makefile                   # メインMakefile
└── LICENSE                    # ライセンス
```

## モジュールの責任範囲

### MindMapCore（中心モジュール）
- ドメインエンティティ（MindMap, Node, Media, Tag）
- ビジネスロジック（Use Cases）
- DIコンテナ
- エラーハンドリング
- ログ機能

### MindMapUI
- SwiftUIビューとViewModels
- ユーザーインタラクション処理
- UI状態管理
- キャンバス描画システム

### DataLayer
- Core Data管理
- CloudKit同期
- リポジトリパターン実装
- データ永続化

### NetworkLayer
- HTTP通信
- APIクライアント
- ネットワークエラーハンドリング

### DesignSystem
- カラーシステム
- タイポグラフィ
- スペーシング定義
- 共通UIコンポーネント

## 開発の進め方
1. 仕様書の確認（.kiro/specs/asa-mindmap/）
2. Swift Packageでの実装
3. iOSアプリでの統合
4. テストとコード品質チェック

## 重要なファイル
- `Package/Package.swift`: モジュール定義と依存関係
- `Makefile`: 開発コマンド
- `Tools/.swiftlint.yml`: コード品質ルール
- `Tools/.swiftformat`: フォーマット設定
- `.kiro/specs/asa-mindmap/`: 現在の開発仕様