# タスク完了時のガイドライン

## 必須実行コマンド

### 1. コード品質チェック（必須）
```bash
# コードフォーマット
make format

# Lintチェック
make lint

# テストの実行
make test
```

### 2. 推奨ワークフロー
```bash
# 開発用の完全なワークフロー（すべてを一度に実行）
make dev
```

### 3. エラーがある場合
```bash
# Lintエラーの自動修正
make lint-fix

# 再度チェック
make check
```

## タスク完了の基準

### コード品質
- [ ] SwiftLint警告・エラーがゼロ
- [ ] SwiftFormatでフォーマットが適用済み
- [ ] 全てのテストが通過

### テスト要件
- [ ] 新機能に対応する単体テストを作成
- [ ] 既存テストが全て通過
- [ ] 統合テストが必要な場合は実装

### ドキュメント
- [ ] 必要に応じてコメントを更新
- [ ] APIの変更がある場合は適切にドキュメント化

### Git準備
- [ ] コミット前に品質チェック完了
- [ ] 適切なコミットメッセージ
- [ ] 関連ファイルがすべてステージング済み

## トラブルシューティング

### SwiftLint/SwiftFormatが見つからない場合
```bash
# Homebrewでインストール
brew install swiftlint swiftformat
```

### テストが失敗する場合
1. 依存関係の確認：`make setup`
2. クリーンビルド：`make clean && make build`
3. テストの詳細確認：`cd Package && swift test --verbose`

### ビルドエラーの場合
1. Swift Package依存関係の更新：`cd Package && swift package update`
2. Xcodeでのクリーンビルド（アプリ部分）

## 完了確認チェックリスト
- [ ] `make dev` が成功
- [ ] 全てのテストが通過
- [ ] コード品質チェックをクリア
- [ ] 機能要件を満たしている
- [ ] エラーハンドリングが適切
- [ ] アクセシビリティが考慮されている（UI変更の場合）