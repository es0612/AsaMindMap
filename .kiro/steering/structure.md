# Project Structure

## Root Directory Organization

```
AsaMindMap/
├── Package/                    # Swift Package（コアロジック）
│   ├── Sources/               # ソースコード
│   ├── Tests/                 # パッケージテスト
│   ├── Package.swift          # パッケージ定義
│   └── README.md             # パッケージドキュメント
├── App/                       # iOS アプリケーション
│   ├── AsaMindMap.xcodeproj  # Xcodeプロジェクト
│   ├── AsaMindMap/           # アプリソースコード
│   ├── AsaMindMapTests/      # アプリテスト
│   └── AsaMindMapUITests/    # UIテスト
├── Tools/                     # 開発ツール設定
│   ├── .swiftlint.yml        # SwiftLint設定
│   ├── .swiftformat          # SwiftFormat設定
│   └── Makefile              # 開発コマンド
├── .kiro/                     # Kiro設定
│   ├── steering/             # ステアリング文書
│   └── specs/               # 仕様書
├── CLAUDE.md                 # Claude Code設定
├── Makefile                  # ルート開発コマンド
├── LICENSE                   # ライセンス
└── README.md                 # プロジェクト全体のREADME
```

### Directory Purposes

#### `/Package/` - Core Logic Package
Swift Package Managerで管理されるコアロジックパッケージ。アプリ本体から独立してテスト・ビルド可能。

#### `/App/` - iOS Application
Xcodeプロジェクトとアプリケーション固有のコード。Packageへの依存を持つ薄いレイヤー。

#### `/Tools/` - Development Tools
開発品質を保つためのツール設定。SwiftLint、SwiftFormat、その他の設定ファイル。

#### `/.kiro/` - Spec-Driven Development
Kiro方式の仕様駆動開発用ディレクトリ。ステアリング文書と機能仕様を管理。

## Package Module Structure

### Sources Directory Organization

```
Package/Sources/
├── MindMapCore/              # ドメイン層・ビジネスロジック
│   ├── Common/              # 共通ユーティリティ
│   ├── DIContainer.swift    # 依存性注入コンテナ
│   ├── Entities/           # ドメインエンティティ
│   ├── Repositories/       # リポジトリプロトコル
│   ├── Services/           # ドメインサービス
│   ├── UseCases/           # ユースケース実装
│   └── Validation/         # バリデーションルール
├── MindMapUI/               # プレゼンテーション層
│   ├── Gestures/           # ジェスチャー管理
│   ├── ViewModels/         # ViewModel実装
│   └── Views/              # SwiftUIビュー
├── DataLayer/               # データ永続化層
│   ├── CoreData/           # Core Data実装
│   └── Repositories/       # リポジトリ実装
├── NetworkLayer/            # ネットワーク層
│   └── NetworkLayer.swift  # 通信処理
└── DesignSystem/            # デザインシステム
    └── DesignSystem.swift  # UIコンポーネント
```

### Module Responsibilities

#### MindMapCore (Domain Layer)
- **Entities**: ビジネスロジックの核となるドメインオブジェクト
- **UseCases**: アプリケーションのビジネス要件を実装
- **Services**: 複雑なドメインロジックを封装
- **Repositories**: データアクセスの抽象化
- **Validation**: ビジネスルールの検証

#### MindMapUI (Presentation Layer)
- **Views**: SwiftUIによるユーザーインターフェース
- **ViewModels**: プレゼンテーションロジックとステート管理
- **Gestures**: タッチ・ペンシル操作の制御

#### DataLayer (Infrastructure Layer)
- **CoreData**: ローカルデータ永続化
- **Repositories**: ドメイン層リポジトリの具象実装
- **CloudKit**: クラウド同期機能

#### NetworkLayer (Infrastructure Layer)
- **HTTP Client**: 外部API通信（将来用）
- **Error Handling**: ネットワークエラー処理

#### DesignSystem (UI Foundation)
- **Colors**: アプリ全体のカラーパレット
- **Typography**: フォントとテキストスタイル
- **Spacing**: レイアウトスペーシング定義
- **Components**: 再利用可能UIコンポーネント

## Test Structure Organization

### Test Directory Layout

```
Package/Tests/
├── MindMapCoreTests/         # ドメイン層テスト
│   ├── Entities/            # エンティティテスト
│   ├── UseCases/            # ユースケーステスト
│   ├── Mocks/               # モックオブジェクト
│   └── TestHelpers/         # テストユーティリティ
├── MindMapUITests/           # プレゼンテーション層テスト
│   ├── ViewModels/          # ViewModelテスト
│   ├── Views/               # Viewテスト
│   └── Gestures/            # ジェスチャーテスト
├── DataLayerTests/           # データ層テスト
│   └── Repositories/        # リポジトリテスト
├── NetworkLayerTests/        # ネットワーク層テスト
└── DesignSystemTests/        # デザインシステムテスト
```

### Test Categories

#### Unit Tests (単体テスト)
- **Fast**: 高速実行（<100ms）
- **Isolated**: 外部依存なし
- **Predictable**: 決定的な結果

#### Integration Tests (統合テスト)
- **Module Integration**: モジュール間連携テスト
- **Data Flow**: データフロー全体テスト
- **Real Dependencies**: 実際の依存関係使用

#### UI Tests (UIテスト)
- **User Scenarios**: ユーザーシナリオテスト
- **Cross-Platform**: iPhone/iPad対応確認
- **Accessibility**: アクセシビリティ機能テスト

## File Naming Conventions

### Swift Files
- **Entities**: `MindMap.swift`, `Node.swift`
- **Protocols**: `MindMapRepositoryProtocol.swift`
- **Implementations**: `CoreDataMindMapRepository.swift`
- **Use Cases**: `CreateMindMapUseCase.swift`
- **ViewModels**: `MindMapViewModel.swift`
- **Views**: `MindMapCanvasView.swift`

### Test Files
- **Unit Tests**: `NodeTests.swift`, `CreateMindMapUseCaseTests.swift`
- **Mock Objects**: `MockMindMapRepository.swift`
- **Test Helpers**: `TestHelpers.swift`

### Resource Files
- **Core Data**: `MindMapDataModel.xcdatamodeld`
- **Assets**: `Assets.xcassets`
- **Info Files**: `Info.plist`

## Import Organization

### Import Hierarchy
```swift
// 1. System Frameworks (alphabetical)
import Combine
import Foundation
import SwiftUI

// 2. Internal Modules (dependency order)
import MindMapCore
import DesignSystem

// 3. Testable imports (test files only)
@testable import MindMapCore
```

### Import Guidelines
- **Foundation First**: Foundation/SwiftUIを最初に
- **Third-Party**: 外部ライブラリ（現在未使用）
- **Internal Modules**: プロジェクト内モジュール
- **@testable**: テストファイルでのみ使用

## Code Organization Patterns

### Entity Structure
```swift
// MARK: - Entity Definition
struct MindMap: Identifiable, Codable {
    let id: UUID
    var title: String
    var nodes: [Node]
    
    // MARK: - Initialization
    init(title: String) { ... }
    
    // MARK: - Business Logic
    func addNode(_ node: Node) -> MindMap { ... }
    
    // MARK: - Validation
    var isValid: Bool { ... }
}

// MARK: - Extensions
extension MindMap: Equatable { ... }
extension MindMap: Hashable { ... }
```

### UseCase Structure
```swift
// MARK: - Protocol Definition
protocol CreateMindMapUseCaseProtocol {
    func execute(title: String) async throws -> MindMap
}

// MARK: - Implementation
final class CreateMindMapUseCase: CreateMindMapUseCaseProtocol {
    // MARK: - Dependencies
    private let repository: MindMapRepositoryProtocol
    
    // MARK: - Initialization
    init(repository: MindMapRepositoryProtocol) { ... }
    
    // MARK: - Public Methods
    func execute(title: String) async throws -> MindMap { ... }
    
    // MARK: - Private Methods
    private func validateTitle(_ title: String) throws { ... }
}
```

### ViewModel Structure
```swift
// MARK: - ViewModel
@MainActor
final class MindMapViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var mindMap: MindMap?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private let createUseCase: CreateMindMapUseCaseProtocol
    
    // MARK: - Initialization
    init(createUseCase: CreateMindMapUseCaseProtocol) { ... }
    
    // MARK: - Public Methods
    func createMindMap(title: String) async { ... }
    
    // MARK: - Private Methods
    private func handleError(_ error: Error) { ... }
}
```

## Key Architectural Principles

### 1. Dependency Inversion
- **Protocol Oriented**: プロトコルベースの抽象化
- **Constructor Injection**: コンストラクタインジェクション
- **No Singletons**: シングルトンパターンの回避

### 2. Single Responsibility
- **Small Classes**: 単一責任の小さなクラス
- **Pure Functions**: 副作用のない関数
- **Clear Naming**: 目的が明確な命名

### 3. Immutability Preference
- **Value Types**: Struct/Enumの積極利用
- **Copy-on-Write**: 必要時のみコピー
- **Functional Approach**: 関数型プログラミング要素

### 4. Error Handling
- **Result Type**: 明示的なエラーハンドリング
- **Typed Errors**: 型安全なエラー定義
- **Graceful Degradation**: 段階的機能縮退

### 5. Testability
- **Protocol Mocking**: プロトコルベースのモック
- **Dependency Injection**: テスト用依存注入
- **Pure Logic**: テスト可能なピュアロジック

## Git Workflow Patterns

### Branch Naming
- **feature/**: `feature/media-attachment-support`
- **bugfix/**: `bugfix/canvas-rendering-issue`
- **refactor/**: `refactor/repository-pattern`
- **docs/**: `docs/api-documentation`

### Commit Message Format
```
type(scope): description

Examples:
feat(core): implement media attachment for nodes
fix(ui): resolve canvas rendering performance issue
refactor(data): extract repository interface
docs(readme): update installation instructions
test(core): add unit tests for node validation
```

### File Organization Best Practices

#### Group Related Functionality
- **Feature Folders**: 関連機能をフォルダでグループ化
- **Layer Separation**: アーキテクチャ層ごとの明確な分離
- **Test Proximity**: テストを実装に近い場所に配置

#### Avoid Deep Nesting
- **Maximum 3-4 Levels**: 深すぎる階層の回避
- **Flat When Possible**: 可能な限りフラットな構造
- **Logical Grouping**: 論理的なグループ化優先

#### Consistent Structure
- **Naming Patterns**: 一貫した命名パターン
- **File Templates**: ファイルテンプレートの活用
- **Documentation**: 構造の文書化