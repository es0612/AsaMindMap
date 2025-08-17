# AsaMindMap Makefile

.PHONY: help build test clean format lint setup

# デフォルトターゲット
help:
	@echo "AsaMindMap 開発用コマンド:"
	@echo "  setup   - 開発環境のセットアップ"
	@echo "  build   - プロジェクトのビルド"
	@echo "  test    - テストの実行"
	@echo "  format  - コードフォーマット (SwiftFormat)"
	@echo "  lint    - コード品質チェック (SwiftLint)"
	@echo "  clean   - ビルドキャッシュのクリア"

# 開発環境のセットアップ
setup:
	@echo "📦 パッケージ依存関係を解決中..."
	swift package resolve
	@echo "✅ セットアップ完了"

# プロジェクトのビルド
build:
	@echo "🔨 プロジェクトをビルド中..."
	swift build
	@echo "✅ ビルド完了"

# テストの実行
test:
	@echo "🧪 テストを実行中..."
	swift test
	@echo "✅ テスト完了"

# コードフォーマット
format:
	@echo "🎨 コードをフォーマット中..."
	@if command -v swiftformat >/dev/null 2>&1; then \
		swiftformat .; \
		echo "✅ フォーマット完了"; \
	else \
		echo "⚠️  SwiftFormatがインストールされていません"; \
		echo "   インストール: brew install swiftformat"; \
	fi

# コード品質チェック
lint:
	@echo "🔍 コード品質をチェック中..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint; \
		echo "✅ Lint完了"; \
	else \
		echo "⚠️  SwiftLintがインストールされていません"; \
		echo "   インストール: brew install swiftlint"; \
	fi

# 自動修正可能なLintエラーを修正
lint-fix:
	@echo "🔧 Lintエラーを自動修正中..."
	@if command -v swiftlint >/dev/null 2>&1; then \
		swiftlint --fix; \
		echo "✅ 自動修正完了"; \
	else \
		echo "⚠️  SwiftLintがインストールされていません"; \
	fi

# ビルドキャッシュのクリア
clean:
	@echo "🧹 ビルドキャッシュをクリア中..."
	swift package clean
	rm -rf .build
	@echo "✅ クリア完了"

# 全体的な品質チェック
check: lint test
	@echo "✅ 全ての品質チェックが完了しました"

# 開発用の完全なワークフロー
dev: format lint test
	@echo "✅ 開発ワークフローが完了しました"