# Technology Stack

## Architecture Overview

AsaMindMapは**クリーンアーキテクチャ + MVVM**パターンを採用し、モジュラー設計によって保守性と拡張性を確保しています。Swift Package Managerを活用したモノレポ構成で、複数のライブラリモジュールに分離した設計です。

### アーキテクチャ図
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

## Platform & Runtime

### iOS Platform
- **Target Platform**: iOS 16.0+
- **Device Support**: iPhone, iPad (Native)
- **Orientation**: Portrait/Landscape adaptive
- **Screen Compatibility**: All iPhone/iPad sizes
- **Apple Pencil**: Full support for iPad models

### macOS Support (Future)
- **Target Platform**: macOS 13.0+
- **Mac Catalyst**: Considered for future releases
- **Native macOS**: SwiftUI compatibility

## Programming Language & Frameworks

### Core Language
- **Swift 5.9+**: Primary development language
- **Swift Package Manager**: Dependency management
- **Xcode 15.0+**: Development environment

### UI Framework
- **SwiftUI**: Primary UI framework
- **UIKit Integration**: Limited legacy support
- **Canvas API**: Custom drawing and visualization
- **Combine**: Reactive programming patterns

### Data & Persistence
- **Core Data**: Primary persistence layer
- **CloudKit**: iCloud synchronization
- **UserDefaults**: App settings storage
- **Keychain**: Secure credential storage

## External Dependencies

### Current Dependencies
**No external dependencies** - プロジェクトは意図的にゼロ依存を維持しています

### Rationale for Zero Dependencies
- **Security**: 外部ライブラリのセキュリティリスク排除
- **Stability**: バージョン競合やメンテナンス問題の回避
- **Performance**: 最適化されたネイティブ実装
- **Size**: アプリサイズの最小化

### Future Consideration Dependencies
将来的に検討される可能性のある依存関係：
- **Firebase Analytics**: ユーザー行動分析（オプション）
- **RevenueCat**: サブスクリプション管理（収益化時）
- **Lottie**: 高度なアニメーション（UX向上時）

## Module Architecture

### Package Structure
```
Package/
├── MindMapCore/         # ドメイン層・ビジネスロジック
├── MindMapUI/           # プレゼンテーション層
├── DataLayer/           # データ永続化
├── NetworkLayer/        # 通信処理（将来用）
└── DesignSystem/        # UI/UXコンポーネント
```

### Module Dependencies
```
MindMapUI → MindMapCore + DesignSystem
DataLayer → MindMapCore + NetworkLayer
NetworkLayer → (独立)
DesignSystem → (独立)
MindMapCore → (独立)
```

## Development Environment

### Required Tools
- **Xcode 15.0+**: 統合開発環境
- **SwiftLint**: コード品質チェック
- **SwiftFormat**: コードフォーマッター
- **iOS Simulator**: テスト実行環境

### Optional Tools
- **SF Symbols**: システムアイコン利用
- **Instruments**: パフォーマンス分析
- **Reality Composer**: 将来のAR機能用

## Common Commands

### Package Management
```bash
# パッケージ依存関係解決
cd Package && swift package resolve

# パッケージビルド
cd Package && swift build

# パッケージテスト実行
cd Package && swift test
```

### Code Quality
```bash
# コードフォーマット実行
make format

# Lint実行
make lint

# Lint自動修正
make lint-fix
```

### Application Build
```bash
# パッケージビルド
make build

# iOSアプリビルド
make build-app

# 統合テスト実行
make test
```

### Development Workflow
```bash
# 開発用完全ワークフロー
make dev  # format + lint + test

# 品質チェック
make check  # lint + test

# クリーンアップ
make clean
```

## Environment Variables

### Xcode Configuration
- **SWIFT_VERSION**: 5.9
- **IPHONEOS_DEPLOYMENT_TARGET**: 16.0
- **MACOSX_DEPLOYMENT_TARGET**: 13.0

### Build Settings
- **ENABLE_BITCODE**: NO (iOS 16+)
- **SWIFT_COMPILATION_MODE**: Optimize for Speed (Release)
- **GCC_OPTIMIZATION_LEVEL**: Optimize for Speed (Release)
- **SWIFT_ACTIVE_COMPILATION_CONDITIONS**: DEBUG (Debug builds)
- **OTHER_SWIFT_FLAGS**: Performance optimization flags

### Development vs Production
```bash
# 開発環境
DEBUG=1
DEVELOPMENT_TEAM=<YOUR_TEAM_ID>

# 本番環境
RELEASE=1
PROVISIONING_PROFILE=<PRODUCTION_PROFILE>
```

## Data Architecture

### Core Data Schema
- **MindMapEntity**: マインドマップ本体
- **NodeEntity**: ノード情報
- **MediaEntity**: 添付メディア
- **TagEntity**: タグ情報

### CloudKit Integration
- **Private Database**: ユーザー個人データ
- **Public Database**: 共有コンテンツ（将来）
- **Shared Database**: 招待ベース共有（将来）

### Repository Pattern
```swift
protocol MindMapRepositoryProtocol {
    func save(_ mindMap: MindMap) async throws
    func fetch(id: UUID) async throws -> MindMap?
    func fetchAll() async throws -> [MindMap]
    func delete(id: UUID) async throws
}
```

## Dependency Injection

### DIContainer Implementation
```swift
let container = DIContainer.configure()
let repository = container.resolve(MindMapRepositoryProtocol.self)
let useCase = container.resolve(CreateMindMapUseCase.self)
```

### Service Registration
- **Repository層**: データアクセス抽象化
- **UseCase層**: ビジネスロジック実装
- **Service層**: ドメインサービス提供

## Testing Strategy

### Test Architecture
```
Tests/
├── Unit Tests/          # 高速・孤立したテスト
├── Integration Tests/   # モジュール間テスト
└── UI Tests/           # End-to-Endテスト
```

### Testing Frameworks
- **XCTest**: 標準テストフレームワーク
- **Quick/Nimble**: 未使用（ゼロ依存維持）
- **XCUITest**: UIテスト自動化

### Test Doubles
- **Mock Repositories**: データ層テスト用
- **In-Memory Storage**: 統合テスト用
- **Stub Services**: サービス層テスト用

## Performance Considerations

### Memory Management
- **ARC**: 自動参照カウント活用
- **Weak References**: 循環参照回避
- **Value Types**: Struct/Enum優先使用

### Rendering Optimization
- **SwiftUI Canvas**: 効率的な描画API
- **Lazy Loading**: 大量データの遅延読み込み
- **Background Processing**: メインスレッド負荷軽減

### Battery Efficiency
- **Core Animation**: GPU活用のアニメーション
- **Timer Management**: 適切なタイマー管理
- **Background Modes**: 必要最小限の背景処理

## Security & Privacy

### Data Protection
- **Core Data Encryption**: 端末内データ暗号化
- **Keychain**: 認証情報の安全な保存
- **App Transport Security**: HTTPS通信強制

### Privacy Compliance
- **Privacy Manifest**: App Store要件対応
- **Tracking Transparency**: ユーザー同意管理
- **Data Minimization**: 最小限のデータ収集

## Build & Deployment

### Xcode Build Configuration
- **Debug**: 開発時設定（最適化なし）
- **Release**: 本番設定（最適化あり）
- **Archive**: App Store配布用設定

### Code Signing
- **Development**: 開発チーム署名
- **Distribution**: App Store配布署名
- **Provisioning Profiles**: デバイス・環境別設定

### Continuous Integration (Future)
- **GitHub Actions**: 自動ビルド・テスト
- **Fastlane**: 配布自動化（検討中）
- **TestFlight**: ベータ版配布

## Monitoring & Analytics

### Performance Monitoring
- **MetricKit**: システムパフォーマンス測定
- **Instruments**: 開発時プロファイリング
- **Crash Reporting**: システム標準クラッシュ報告

### User Analytics (Future)
- **App Analytics**: App Store Connect標準
- **Custom Events**: 重要操作の追跡
- **Funnel Analysis**: ユーザーフロー分析