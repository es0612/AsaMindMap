# コードスタイルと規約

## 言語とコメント
- コードは英語で記述
- 日本語でのコメント・ドキュメントは適切に使用

## アーキテクチャ規約
- クリーンアーキテクチャの原則に従う
- ドメイン層はフレームワークに依存しない
- 依存性注入（DI）を使用
- テスト駆動開発（TDD）アプローチ

## Swift規約
- Swift 5.9+ の機能を活用
- SwiftLintルールに準拠（Tools/.swiftlint.yml）
- SwiftFormatに従ったフォーマット（Tools/.swiftformat）

## ファイル構成
```
AsaMindMap/
├── Package/                    # Swift Package（コアロジック）
├── App/                        # iOS アプリケーション  
├── Tools/                      # 開発ツール設定
└── .kiro/                      # Kiro設定
```

## テスト規約
- 全ての新機能にテストが必要
- 単体テスト：ドメインロジックとユースケース
- 統合テスト：データ層とビジネスロジック
- UIテスト：重要なユーザーシナリオ

## Git規約
- 機能ベースのコミット
- 英語でのコミットメッセージ
- feat: / fix: / refactor: / test: プレフィックス使用

## モジュール間依存
- MindMapCore: 他に依存しない
- MindMapUI: MindMapCore + DesignSystemに依存
- DataLayer: MindMapCore + NetworkLayerに依存
- NetworkLayer: 独立
- DesignSystem: 独立

## 品質基準
- 全てのpublic APIはテスト対象
- コードカバレッジの維持
- SwiftLint警告ゼロを目指す
- リリース前のフォーマットチェック必須