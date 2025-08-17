# AsaMindMap

AsaMindMapは、ユーザーがアイデアを視覚的に整理・共有できるiOS向けマインドマップアプリケーションです。

## プロジェクト構造

このプロジェクトは、モジュラーアーキテクチャを採用し、Swift Package ManagerとXcodeプロジェクトを分離した構成になっています。

### フォルダ構成

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
├── .kiro/                      # Kiro設定
└── README.md                   # プロジェクト全体のREADME
```

### 各モジュールの責任

#### MindMapCore
- ビジネスロジック（Use Cases）
- エンティティ定義
- DIコンテナ
- エラーハンドリング
- ログ機能

#### MindMapUI
- SwiftUIビューとViewModels
- ユーザーインタラクション処理
- UI状態管理

#### DataLayer
- データ永続化
- Core Data管理
- CloudKit同期

#### NetworkLayer
- HTTP通信
- API クライアント
- ネットワークエラーハンドリング

#### DesignSystem
- カラーシステム
- タイポグラフィ
- スペーシング
- 共通UIコンポーネント

## 開発環境

### 必要要件
- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

### セットアップ

1. リポジトリをクローン
```bash
git clone <repository-url>
cd AsaMindMap
```

2. パッケージの依存関係を解決
```bash
swift package resolve
```

3. テストの実行
```bash
swift test
```

### コード品質

#### SwiftLint
プロジェクトではSwiftLintを使用してコード品質を維持しています。

```bash
# SwiftLintの実行
swiftlint

# 自動修正
swiftlint --fix
```

#### SwiftFormat
コードフォーマットにはSwiftFormatを使用しています。

```bash
# SwiftFormatの実行
swiftformat .
```

## アーキテクチャ

### クリーンアーキテクチャ + MVVM

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                        │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   SwiftUI Views │    │   ViewModels    │                │
│  │   (Canvas,      │◄──►│  (Presenters)   │                │
│  │   NodeView)     │    │                 │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Domain Layer                              │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │   Use Cases     │    │    Entities     │                │
│  │ (Interactors)   │◄──►│  (MindMap,      │                │
│  │                 │    │   Node, Media)  │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Data Layer                              │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  Repository     │    │   Data Sources  │                │
│  │ Implementations │◄──►│  (Core Data,    │                │
│  │                 │    │   CloudKit)     │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

### 依存性注入

プロジェクトでは独自のDIコンテナを使用して依存性注入を管理しています。

```swift
let container = DIContainer.configure()
let service = container.resolve(SomeServiceProtocol.self)
```

## テスト戦略

### TDD（テスト駆動開発）

プロジェクトではTDDアプローチを採用しています：

1. 🔴 Red: 失敗するテストを書く
2. 🟢 Green: テストを通す最小限のコードを書く
3. 🔵 Refactor: コードを整理する（Tidy First）

### テストピラミッド

```
        ┌─────────────────┐
        │   E2E Tests     │  少数・高価値
        │   (UI Tests)    │
        └─────────────────┘
      ┌───────────────────────┐
      │  Integration Tests    │  中程度
      │  (Module Tests)       │
      └───────────────────────┘
    ┌─────────────────────────────┐
    │      Unit Tests             │  多数・高速
    │   (Domain Logic Tests)      │
    └─────────────────────────────┘
```

## ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。