# 推奨コマンド

## セットアップ
```bash
# 開発環境のセットアップ
make setup
```

## ビルドとテスト
```bash
# プロジェクトのビルド（Swift Package）
make build

# iOSアプリのビルド
make build-app

# テストの実行
make test
```

## コード品質
```bash
# コードフォーマット
make format

# コード品質チェック（SwiftLint）
make lint

# Lintエラーの自動修正
make lint-fix

# 全体的な品質チェック（lint + test）
make check

# 開発用の完全なワークフロー（format + lint + test）
make dev
```

## クリーンアップ
```bash
# ビルドキャッシュのクリア
make clean
```

## 直接コマンド（必要に応じて）
```bash
# Swift Package関連
cd Package && swift package resolve
cd Package && swift build
cd Package && swift test

# SwiftLint関連
swiftlint --config Tools/.swiftlint.yml Package/Sources Package/Tests App/AsaMindMap
swiftlint --fix --config Tools/.swiftlint.yml Package/Sources Package/Tests App/AsaMindMap

# SwiftFormat関連
swiftformat Package/Sources Package/Tests App/AsaMindMap --config Tools/.swiftformat
```

## 重要な注意点
- SwiftLint・SwiftFormatのインストールが必要（brew install swiftlint swiftformat）
- コマンドはプロジェクトルートディレクトリで実行する
- タスク完了時は必ずlint・formatを実行する