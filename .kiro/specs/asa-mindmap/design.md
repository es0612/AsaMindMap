# 設計ドキュメント

## 概要

AsaMindMapは、SwiftUIとCore Dataを基盤とするiOS向けマインドマップアプリケーションです。直感的なタッチジェスチャー、Apple Pencilサポート、iCloud同期機能を提供し、学生からビジネスプロフェッショナルまで幅広いユーザーのアイデア整理をサポートします。

## アーキテクチャ

### 全体アーキテクチャ

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Presentation  │    │    Business     │    │      Data       │
│     Layer       │◄──►│     Logic       │◄──►│     Layer       │
│   (SwiftUI)     │    │   (ViewModels)  │    │  (Core Data)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Gesture &     │    │   Canvas &      │    │   CloudKit      │
│   Input Layer   │    │   Drawing       │    │   Sync Layer    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

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
│           │                       ▲                        │
│           ▼                       │                        │
│  ┌─────────────────┐              │                        │
│  │  Repository     │              │                        │
│  │  Protocols      │──────────────┘                        │
│  └─────────────────┘                                       │
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

#### レイヤー責任

**Presentation Layer (MindMapUI)**
- SwiftUIビューとViewModels
- ユーザーインタラクション処理
- UI状態管理

**Domain Layer (MindMapCore)**
- ビジネスロジック（Use Cases）
- エンティティ定義
- リポジトリプロトコル

**Data Layer (DataLayer)**
- データ永続化
- 外部API通信
- リポジトリ実装

## コンポーネントと インターフェース

### 1. コアコンポーネント

#### MindMapCanvas
```swift
struct MindMapCanvas: View {
    @StateObject private var viewModel: MindMapViewModel
    @State private var canvasTransform: CGAffineTransform = .identity
    @State private var selectedNodes: Set<UUID> = []
    
    var body: some View {
        Canvas { context, size in
            // ノードとコネクションの描画
            drawNodes(context: context, size: size)
            drawConnections(context: context, size: size)
        }
        .gesture(combinedGestures)
        .onPencilDoubleTap { value in
            // Apple Pencilダブルタップ処理
        }
    }
}
```

#### NodeView
```swift
struct NodeView: View {
    @ObservedObject var node: Node
    @State private var isEditing: Bool = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(node.backgroundColor)
                .stroke(node.borderColor, lineWidth: 2)
            
            if isEditing {
                TextField("ノードテキスト", text: $node.text)
            } else {
                Text(node.text)
            }
        }
        .gesture(nodeGestures)
    }
}
```

### 2. ジェスチャーシステム

#### GestureManager
```swift
class GestureManager: ObservableObject {
    @Published var dragState: DragState = .inactive
    @Published var zoomScale: CGFloat = 1.0
    @Published var panOffset: CGSize = .zero
    
    // 複合ジェスチャーの管理
    var combinedGestures: some Gesture {
        SimultaneousGesture(
            dragGesture,
            SimultaneousGesture(
                magnificationGesture,
                rotationGesture
            )
        )
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .updating($dragState) { value, state, _ in
                state = .dragging(translation: value.translation)
            }
            .onEnded { value in
                handleDragEnd(value)
            }
    }
}
```

### 3. Apple Pencilサポート

#### PencilInputHandler
```swift
class PencilInputHandler: ObservableObject {
    @Published var isDrawingMode: Bool = false
    @Published var currentStroke: PKStroke?
    
    func handlePencilInput(_ value: PencilDoubleTapGestureValue) {
        switch preferredPencilDoubleTapAction {
        case .switchEraser:
            toggleEraserMode()
        case .switchPrevious:
            switchToPreviousTool()
        default:
            showToolPalette()
        }
    }
    
    func handlePencilSqueeze(_ phase: PencilSqueezeGesturePhase) {
        switch phase {
        case .began:
            showContextualPalette()
        case .ended:
            hideContextualPalette()
        }
    }
}
```

## データモデル

### Core Dataスキーマ

#### MindMap Entity
```swift
@objc(MindMap)
public class MindMap: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var rootNode: Node?
    @NSManaged public var nodes: NSSet?
    @NSManaged public var tags: NSSet?
    @NSManaged public var isShared: Bool
    @NSManaged public var shareURL: String?
}
```

#### Node Entity
```swift
@objc(Node)
public class Node: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var text: String
    @NSManaged public var position: CGPoint
    @NSManaged public var backgroundColor: UIColor
    @NSManaged public var textColor: UIColor
    @NSManaged public var fontSize: CGFloat
    @NSManaged public var isCollapsed: Bool
    @NSManaged public var isTask: Bool
    @NSManaged public var isCompleted: Bool
    @NSManaged public var mindMap: MindMap?
    @NSManaged public var parentNode: Node?
    @NSManaged public var childNodes: NSSet?
    @NSManaged public var media: NSSet?
    @NSManaged public var tags: NSSet?
}
```

#### Media Entity
```swift
@objc(Media)
public class Media: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var type: String // "image", "link", "sticker"
    @NSManaged public var data: Data?
    @NSManaged public var url: String?
    @NSManaged public var thumbnailData: Data?
    @NSManaged public var node: Node?
}
```

### CloudKit同期

#### CloudKitManager
```swift
class CloudKitManager: ObservableObject {
    private let container = CKContainer.default()
    private let privateDatabase: CKDatabase
    
    init() {
        privateDatabase = container.privateCloudDatabase
    }
    
    func syncMindMap(_ mindMap: MindMap) async throws {
        let record = CKRecord(recordType: "MindMap")
        record["title"] = mindMap.title
        record["createdAt"] = mindMap.createdAt
        record["updatedAt"] = mindMap.updatedAt
        
        try await privateDatabase.save(record)
    }
    
    func fetchMindMaps() async throws -> [CKRecord] {
        let query = CKQuery(recordType: "MindMap", predicate: NSPredicate(value: true))
        let result = try await privateDatabase.records(matching: query)
        return result.matchResults.compactMap { try? $0.1.get() }
    }
}
```

## エラーハンドリング

### エラー定義
```swift
enum MindMapError: LocalizedError {
    case nodeCreationFailed
    case saveOperationFailed
    case syncConflict
    case exportFailed(format: String)
    case importFailed(reason: String)
    
    var errorDescription: String? {
        switch self {
        case .nodeCreationFailed:
            return "ノードの作成に失敗しました"
        case .saveOperationFailed:
            return "保存に失敗しました"
        case .syncConflict:
            return "同期中に競合が発生しました"
        case .exportFailed(let format):
            return "\(format)形式でのエクスポートに失敗しました"
        case .importFailed(let reason):
            return "インポートに失敗しました: \(reason)"
        }
    }
}
```

### エラーハンドリング戦略
```swift
class ErrorHandler: ObservableObject {
    @Published var currentError: MindMapError?
    @Published var showErrorAlert: Bool = false
    
    func handle(_ error: MindMapError) {
        currentError = error
        showErrorAlert = true
        
        // ログ記録
        Logger.shared.log(error: error)
        
        // 自動回復の試行
        attemptRecovery(for: error)
    }
    
    private func attemptRecovery(for error: MindMapError) {
        switch error {
        case .saveOperationFailed:
            // 自動保存の再試行
            retryAutoSave()
        case .syncConflict:
            // 競合解決ダイアログの表示
            showConflictResolution()
        default:
            break
        }
    }
}
```

## TDD戦略とTidy First開発アプローチ

### TDD開発サイクル（t-wada流）

#### Red-Green-Refactor サイクル
```
🔴 Red    → 失敗するテストを書く
🟢 Green  → テストを通す最小限のコードを書く  
🔵 Refactor → コードを整理する（Tidy First）
```

#### TDD実践例
```swift
// 1. 🔴 Red: 失敗するテストから始める
@Test("ノード作成時にIDが自動生成される")
func testNodeCreationGeneratesID() {
    // Given
    let text = "テストノード"
    let position = CGPoint(x: 100, y: 100)
    
    // When
    let node = Node(text: text, position: position)
    
    // Then
    #expect(node.id != nil)
    #expect(node.text == text)
    #expect(node.position == position)
}

// 2. 🟢 Green: テストを通す最小限の実装
struct Node {
    let id: UUID
    let text: String
    let position: CGPoint
    
    init(text: String, position: CGPoint) {
        self.id = UUID()
        self.text = text
        self.position = position
    }
}

// 3. 🔵 Refactor: Tidy Firstでコードを整理
```

### Tidy First原則の適用

#### 1. 整理（Tidying）と機能変更の分離
```swift
// ❌ 悪い例: 整理と機能変更を同時に行う
func addChildNode(_ child: Node) {
    // 整理: 変数名を改善
    let currentChildren = self.childNodes
    // 機能変更: 新しい検証ロジック追加
    guard !currentChildren.contains(child) else { return }
    currentChildren.append(child)
}

// ✅ 良い例: まず整理のみ
func addChildNode(_ child: Node) {
    let currentChildren = self.childNodes  // 整理: 明確な変数名
    childNodes.append(child)
}

// 次のコミットで機能変更
func addChildNode(_ child: Node) {
    let currentChildren = self.childNodes
    guard !currentChildren.contains(child) else { return }  // 機能追加
    childNodes.append(child)
}
```

#### 2. 小さな整理の積み重ね
```swift
// Phase 1: 変数名の整理
class MindMapViewModel: ObservableObject {
    @Published private var mindMapData: MindMap  // nodes → mindMapData
    @Published private var selectedNodeIDs: Set<UUID>  // selection → selectedNodeIDs
}

// Phase 2: メソッド抽出
extension MindMapViewModel {
    private func validateNodePosition(_ position: CGPoint) -> Bool {
        // 位置検証ロジックを抽出
    }
    
    private func notifyNodeChange() {
        // 変更通知ロジックを抽出
    }
}

// Phase 3: 責任の分離
protocol NodeValidator {
    func validate(position: CGPoint) -> ValidationResult
}

class CanvasNodeValidator: NodeValidator {
    func validate(position: CGPoint) -> ValidationResult {
        // 実装
    }
}
```

### テスト戦略

#### テストピラミッド
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

#### 1. 単体テスト（Domain Layer中心）
```swift
// Domain Layer Tests (高速・独立)
struct CreateNodeUseCaseTests {
    
    @Test("ノード作成の正常系")
    func testCreateNodeSuccess() async throws {
        // Given
        let mockRepository = MockMindMapRepository()
        let useCase = CreateNodeUseCase(repository: mockRepository)
        let request = CreateNodeRequest(
            text: "新しいノード",
            position: CGPoint(x: 100, y: 100),
            parentID: nil
        )
        
        // When
        let result = try await useCase.execute(request)
        
        // Then
        #expect(result.node.text == "新しいノード")
        #expect(result.node.position == CGPoint(x: 100, y: 100))
        #expect(mockRepository.saveCallCount == 1)
    }
    
    @Test("無効な位置でのノード作成")
    func testCreateNodeInvalidPosition() async {
        // Given
        let mockRepository = MockMindMapRepository()
        let useCase = CreateNodeUseCase(repository: mockRepository)
        let request = CreateNodeRequest(
            text: "テスト",
            position: CGPoint(x: -100, y: -100), // 無効な位置
            parentID: nil
        )
        
        // When & Then
        await #expect(throws: NodeCreationError.invalidPosition) {
            try await useCase.execute(request)
        }
    }
}

// Use Case実装例
struct CreateNodeUseCase {
    private let repository: MindMapRepositoryProtocol
    private let validator: NodeValidatorProtocol
    
    init(repository: MindMapRepositoryProtocol, validator: NodeValidatorProtocol = DefaultNodeValidator()) {
        self.repository = repository
        self.validator = validator
    }
    
    func execute(_ request: CreateNodeRequest) async throws -> CreateNodeResponse {
        // 1. バリデーション
        try validator.validate(position: request.position)
        
        // 2. エンティティ作成
        let node = Node(
            id: UUID(),
            text: request.text,
            position: request.position,
            parentID: request.parentID
        )
        
        // 3. 永続化
        try await repository.save(node)
        
        return CreateNodeResponse(node: node)
    }
}
```

#### 2. 統合テスト（Module間連携）
```swift
struct MindMapIntegrationTests {
    
    @Test("ノード作成からUI更新までの統合フロー")
    func testNodeCreationIntegrationFlow() async throws {
        // Given
        let container = DIContainer()
        let viewModel = MindMapViewModel(container: container)
        
        // When
        await viewModel.createNode(at: CGPoint(x: 100, y: 100), text: "統合テスト")
        
        // Then
        #expect(viewModel.nodes.count == 1)
        #expect(viewModel.nodes.first?.text == "統合テスト")
        #expect(viewModel.isLoading == false)
    }
}
```

#### 3. Contract Testing（Repository層）
```swift
protocol MindMapRepositoryTestContract {
    var repository: MindMapRepositoryProtocol { get }
}

extension MindMapRepositoryTestContract {
    
    @Test("ノード保存と取得の契約テスト")
    func testSaveAndRetrieveNode() async throws {
        // Given
        let node = Node(id: UUID(), text: "テスト", position: .zero)
        
        // When
        try await repository.save(node)
        let retrievedNode = try await repository.findByID(node.id)
        
        // Then
        #expect(retrievedNode?.id == node.id)
        #expect(retrievedNode?.text == node.text)
    }
}

// 実装テスト
struct CoreDataRepositoryTests: MindMapRepositoryTestContract {
    let repository: MindMapRepositoryProtocol = CoreDataMindMapRepository()
}

struct InMemoryRepositoryTests: MindMapRepositoryTestContract {
    let repository: MindMapRepositoryProtocol = InMemoryMindMapRepository()
}
```

#### 4. UIテスト（E2E）
```swift
struct MindMapUITests {
    
    @Test("ユーザージャーニー: マインドマップ作成から共有まで")
    func testCompleteUserJourney() async throws {
        let app = XCUIApplication()
        app.launch()
        
        // 1. 新しいマインドマップ作成
        app.buttons["新しいマインドマップ"].tap()
        
        // 2. 中央ノード編集
        let canvas = app.otherElements["mindMapCanvas"]
        canvas.tap()
        
        let textField = app.textFields.firstMatch
        textField.typeText("メインアイデア")
        app.buttons["完了"].tap()
        
        // 3. 子ノード追加
        canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)).tap()
        app.textFields.firstMatch.typeText("サブアイデア1")
        app.buttons["完了"].tap()
        
        // 4. 共有機能テスト
        app.buttons["共有"].tap()
        #expect(app.sheets.firstMatch.exists)
        
        // 5. 検証
        #expect(app.staticTexts["メインアイデア"].exists)
        #expect(app.staticTexts["サブアイデア1"].exists)
    }
    
    @Test("Apple Pencil統合テスト")
    func testApplePencilIntegration() async throws {
        let app = XCUIApplication()
        app.launch()
        
        let canvas = app.otherElements["mindMapCanvas"]
        
        // Apple Pencilダブルタップシミュレーション
        canvas.doubleTap()
        
        // ツールパレット表示確認
        #expect(app.otherElements["toolPalette"].exists)
        
        // 描画モード切り替え
        app.buttons["描画モード"].tap()
        #expect(app.staticTexts["描画モード有効"].exists)
    }
}
```

### 依存性注入（DI）コンテナ

#### DIContainer実装
```swift
protocol DIContainerProtocol {
    func resolve<T>(_ type: T.Type) -> T
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
}

class DIContainer: DIContainerProtocol {
    private var factories: [String: () -> Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        guard let factory = factories[key] else {
            fatalError("Type \(type) not registered")
        }
        return factory() as! T
    }
}

// DI設定
extension DIContainer {
    static func configure() -> DIContainer {
        let container = DIContainer()
        
        // Repository
        container.register(MindMapRepositoryProtocol.self) {
            CoreDataMindMapRepository()
        }
        
        // Use Cases
        container.register(CreateNodeUseCaseProtocol.self) {
            CreateNodeUseCase(
                repository: container.resolve(MindMapRepositoryProtocol.self)
            )
        }
        
        // ViewModels
        container.register(MindMapViewModel.self) {
            MindMapViewModel(
                createNodeUseCase: container.resolve(CreateNodeUseCaseProtocol.self),
                updateNodeUseCase: container.resolve(UpdateNodeUseCaseProtocol.self)
            )
        }
        
        return container
    }
}
```

#### 5. パフォーマンステスト
```swift
struct MindMapPerformanceTests {
    
    @Test("大量ノード作成パフォーマンス")
    func testLargeNodeSetPerformance() async throws {
        let repository = InMemoryMindMapRepository()
        let useCase = CreateNodeUseCase(repository: repository)
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // 1000ノードを並行作成
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<1000 {
                group.addTask {
                    let request = CreateNodeRequest(
                        text: "ノード \(i)",
                        position: CGPoint(x: Double(i % 50) * 10, y: Double(i / 50) * 10),
                        parentID: nil
                    )
                    try? await useCase.execute(request)
                }
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        let nodes = try await repository.findAll()
        
        #expect(nodes.count == 1000)
        #expect(timeElapsed < 2.0) // 2秒以内で完了
    }
    
    @Test("メモリ使用量テスト")
    func testMemoryUsage() async throws {
        let repository = InMemoryMindMapRepository()
        
        // 初期メモリ使用量
        let initialMemory = getMemoryUsage()
        
        // 大量データ作成
        for i in 0..<10000 {
            let node = Node(
                id: UUID(),
                text: "大量データテスト \(i)",
                position: CGPoint(x: Double(i), y: Double(i))
            )
            try await repository.save(node)
        }
        
        // メモリ使用量チェック
        let finalMemory = getMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        #expect(memoryIncrease < 100_000_000) // 100MB以下
    }
    
    private func getMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        return kerr == KERN_SUCCESS ? info.resident_size : 0
    }
}
```

### 継続的リファクタリング戦略

#### Tidy Firstチェックリスト
```swift
// 🔍 コードレビュー時のTidy Firstチェックリスト

// ✅ 1. 読みやすさの改善
// - 変数名は意図を表現しているか？
// - メソッド名は動作を明確に示しているか？
// - マジックナンバーは定数化されているか？

// ✅ 2. 構造の改善
// - メソッドは単一責任を持っているか？
// - クラスのサイズは適切か？
// - 依存関係は明確か？

// ✅ 3. 重複の除去
// - 同じロジックが複数箇所にないか？
// - 共通化できる処理はないか？

// ✅ 4. 条件分岐の簡素化
// - ネストが深すぎないか？
// - 早期リターンを使えないか？
// - ポリモーフィズムで置き換えられないか？

// 実践例
// ❌ Before: 複雑な条件分岐
func validateNode(_ node: Node) -> Bool {
    if node.text.isEmpty {
        return false
    } else {
        if node.position.x < 0 || node.position.y < 0 {
            return false
        } else {
            if node.text.count > 100 {
                return false
            } else {
                return true
            }
        }
    }
}

// ✅ After: 早期リターンで簡素化
func validateNode(_ node: Node) -> Bool {
    guard !node.text.isEmpty else { return false }
    guard node.position.x >= 0 && node.position.y >= 0 else { return false }
    guard node.text.count <= 100 else { return false }
    return true
}

// 🔄 Further refactoring: バリデーションルールの分離
protocol NodeValidationRule {
    func validate(_ node: Node) -> ValidationResult
}

struct TextNotEmptyRule: NodeValidationRule {
    func validate(_ node: Node) -> ValidationResult {
        node.text.isEmpty ? .failure("テキストが空です") : .success
    }
}

struct PositionValidRule: NodeValidationRule {
    func validate(_ node: Node) -> ValidationResult {
        node.position.x >= 0 && node.position.y >= 0 
            ? .success 
            : .failure("位置が無効です")
    }
}

struct NodeValidator {
    private let rules: [NodeValidationRule]
    
    init(rules: [NodeValidationRule]) {
        self.rules = rules
    }
    
    func validate(_ node: Node) -> ValidationResult {
        for rule in rules {
            let result = rule.validate(node)
            if case .failure = result {
                return result
            }
        }
        return .success
    }
}
```

## セキュリティとプライバシー

### データ暗号化
- Core Dataストアの暗号化
- CloudKit同期時のエンドツーエンド暗号化
- 共有リンクの一時的なアクセストークン

### プライバシー保護
- ユーザーデータの最小限収集
- 分析データの匿名化
- GDPR/CCPA準拠のデータ削除機能

## パフォーマンス最適化

### メモリ管理
- 大量ノード時の遅延読み込み
- 画像メディアの適応的品質調整
- バックグラウンド時のメモリ解放

### 描画最適化
- Canvas描画の差分更新
- ビューポート外ノードの描画スキップ
- Apple Pencil入力の最適化されたストローク処理

## 国際化とアクセシビリティ

### 多言語サポート
- 日本語、英語、中国語（簡体字・繁体字）
- 右から左への言語サポート（アラビア語、ヘブライ語）
- 地域固有の日付・数値フォーマット

### アクセシビリティ
- VoiceOverサポート
- Dynamic Typeサポート
- 高コントラストモード対応
- スイッチコントロール対応

## モダンSwift開発フロー

### プロジェクト構造（モジュラーアーキテクチャ）

```
AsaMindMap/
├── App/                          # メインアプリケーションバンドル
│   ├── AsaMindMapApp.swift
│   ├── ContentView.swift
│   └── Info.plist
├── Core/                         # ローカルSwiftパッケージ
│   ├── Package.swift
│   ├── Sources/
│   │   ├── MindMapCore/         # コアビジネスロジック
│   │   ├── MindMapUI/           # UI コンポーネント
│   │   ├── DataLayer/           # データ管理
│   │   ├── NetworkLayer/        # ネットワーク処理
│   │   └── DesignSystem/        # デザインシステム
│   └── Tests/
│       ├── MindMapCoreTests/
│       ├── MindMapUITests/
│       └── DataLayerTests/
├── .swiftlint.yml               # SwiftLint設定
├── .swiftformat                 # SwiftFormat設定
├── Package.swift                # ルートパッケージ定義
└── AsaMindMap.xcodeproj
```

### Core Package.swift
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Core",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "MindMapCore", targets: ["MindMapCore"]),
        .library(name: "MindMapUI", targets: ["MindMapUI"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
        .library(name: "NetworkLayer", targets: ["NetworkLayer"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    dependencies: [
        .package(url: "https://github.com/realm/SwiftLint", from: "0.54.0"),
        .package(url: "https://github.com/nicklockwood/SwiftFormat", from: "0.52.0")
    ],
    targets: [
        // MARK: - Core Business Logic
        .target(
            name: "MindMapCore",
            dependencies: ["DataLayer"],
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "MindMapCoreTests",
            dependencies: ["MindMapCore"]
        ),
        
        // MARK: - UI Components
        .target(
            name: "MindMapUI",
            dependencies: ["MindMapCore", "DesignSystem"],
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "MindMapUITests",
            dependencies: ["MindMapUI"]
        ),
        
        // MARK: - Data Layer
        .target(
            name: "DataLayer",
            dependencies: ["NetworkLayer"],
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: ["DataLayer"]
        ),
        
        // MARK: - Network Layer
        .target(
            name: "NetworkLayer",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "NetworkLayerTests",
            dependencies: ["NetworkLayer"]
        ),
        
        // MARK: - Design System
        .target(
            name: "DesignSystem",
            plugins: [.plugin(name: "SwiftLintPlugin", package: "SwiftLint")]
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        )
    ]
)
```

### コード品質ツール

#### SwiftLint設定 (.swiftlint.yml)
```yaml
# SwiftLint設定
included:
  - App
  - Core/Sources
  - Core/Tests

excluded:
  - Core/Tests/*/Resources
  - "*.generated.swift"

analyzer_rules:
  - unused_declaration
  - unused_import

opt_in_rules:
  - array_init
  - closure_end_indentation
  - closure_spacing
  - collection_alignment
  - contains_over_filter_count
  - empty_count
  - empty_string
  - enum_case_associated_values_count
  - explicit_init
  - extension_access_modifier
  - fallthrough
  - fatal_error_message
  - file_header
  - first_where
  - force_unwrapping
  - implicitly_unwrapped_optional
  - joined_default_parameter
  - literal_expression_end_indentation
  - multiline_arguments
  - multiline_function_chains
  - multiline_literal_brackets
  - multiline_parameters
  - nimble_operator
  - no_space_in_method_call
  - operator_usage_whitespace
  - overridden_super_call
  - pattern_matching_keywords
  - prefer_self_type_over_type_of_self
  - redundant_nil_coalescing
  - redundant_type_annotation
  - strict_fileprivate
  - switch_case_alignment
  - toggle_bool
  - trailing_closure
  - unneeded_parentheses_in_closure_argument
  - vertical_parameter_alignment_on_call
  - vertical_whitespace_closing_braces
  - vertical_whitespace_opening_braces
  - yoda_condition

disabled_rules:
  - todo
  - line_length

custom_rules:
  no_objcMembers:
    name: "@objcMembers"
    regex: "@objcMembers"
    message: "@objcMembersの使用は避けてください"
    severity: warning

# ルール設定
type_body_length:
  warning: 300
  error: 400

function_body_length:
  warning: 50
  error: 100

cyclomatic_complexity:
  warning: 10
  error: 20

nesting:
  type_level:
    warning: 2
    error: 3
  statement_level:
    warning: 5
    error: 10

identifier_name:
  min_length:
    warning: 2
    error: 1
  max_length:
    warning: 40
    error: 50
  excluded:
    - id
    - x
    - y
    - z
```

#### SwiftFormat設定 (.swiftformat)
```
# SwiftFormat設定

# インデント
--indent 4
--tabwidth 4
--smarttabs enabled

# 改行とスペース
--linebreaks lf
--maxwidth 120
--wraparguments before-first
--wrapparameters before-first
--wrapcollections before-first
--closingparen balanced
--trimwhitespace always

# インポート
--importgrouping testable-bottom
--sortedimports true

# その他のフォーマット
--semicolons never
--commas always
--decimalgrouping 3,4
--binarygrouping 4,8
--octalgrouping 4,8
--hexgrouping 4,8
--fractiongrouping disabled
--exponentgrouping disabled
--hexliteralcase lowercase
--exponentcase lowercase

# 有効なルール
--enable isEmpty
--enable sortedImports
--enable duplicateImports
--enable unusedArguments
--enable hoistPatternLet
--enable redundantSelf
--enable redundantPattern
--enable redundantGet
--enable redundantParens
--enable redundantVoidReturnType
--enable redundantNilInit
--enable redundantLet
--enable redundantExtensionACL
--enable redundantFileprivate
--enable redundantRawValues
--enable redundantInit
--enable redundantBreak
--enable redundantClosure
--enable redundantBackticks
--enable redundantObjc
--enable redundantType
--enable andOperator
--enable anyObjectProtocol
--enable assertionFailures
--enable blankLinesAroundMark
--enable blankLinesBetweenScopes
--enable braces
--enable conditionalAssignment
--enable consecutiveBlankLines
--enable consecutiveSpaces
--enable duplicateImports
--enable elseOnSameLine
--enable emptyBraces
--enable enumNamespaces
--enable extensionAccessControl
--enable fileHeader
--enable hoistPatternLet
--enable indent
--enable initCoderUnavailable
--enable leadingDelimiters
--enable linebreakAtEndOfFile
--enable linebreaks
--enable markTypes
--enable modifierOrder
--enable numberFormatting
--enable organizeDeclarations
--enable preferKeyPath
--enable redundantBreak
--enable redundantClosure
--enable redundantExtensionACL
--enable redundantFileprivate
--enable redundantGet
--enable redundantInit
--enable redundantLet
--enable redundantNilInit
--enable redundantObjc
--enable redundantParens
--enable redundantPattern
--enable redundantRawValues
--enable redundantReturn
--enable redundantSelf
--enable redundantType
--enable redundantVoidReturnType
--enable semicolons
--enable sortedImports
--enable spaceAroundBraces
--enable spaceAroundBrackets
--enable spaceAroundComments
--enable spaceAroundGenerics
--enable spaceAroundOperators
--enable spaceAroundParens
--enable spaceInsideBraces
--enable spaceInsideBrackets
--enable spaceInsideComments
--enable spaceInsideGenerics
--enable spaceInsideParens
--enable strongOutlets
--enable strongifiedSelf
--enable todos
--enable trailingClosures
--enable trailingCommas
--enable trailingSpace
--enable typeSugar
--enable unusedArguments
--enable void
--enable wrap
--enable wrapArguments
--enable wrapAttributes
--enable wrapMultilineStatementBraces
--enable yodaConditions

# 無効なルール
--disable blankLinesAtEndOfScope
--disable blankLinesAtStartOfScope
```

### 高速テスト実行

#### swift-testingの採用
```swift
// MindMapCoreTests/NodeTests.swift
import Testing
@testable import MindMapCore

struct NodeTests {
    
    @Test("ノード作成テスト")
    func testNodeCreation() {
        // Given
        let text = "テストノード"
        let position = CGPoint(x: 100, y: 100)
        
        // When
        let node = Node(text: text, position: position)
        
        // Then
        #expect(node.text == text)
        #expect(node.position == position)
        #expect(node.id != UUID())
    }
    
    @Test("子ノード追加テスト")
    func testAddChildNode() {
        // Given
        let parentNode = Node(text: "親ノード", position: .zero)
        let childNode = Node(text: "子ノード", position: CGPoint(x: 50, y: 50))
        
        // When
        parentNode.addChild(childNode)
        
        // Then
        #expect(parentNode.children.contains(childNode))
        #expect(childNode.parent == parentNode)
    }
    
    @Test("ノード削除テスト", arguments: [true, false])
    func testNodeDeletion(withChildren: Bool) {
        // Given
        let parentNode = Node(text: "親ノード", position: .zero)
        let childNode = Node(text: "子ノード", position: CGPoint(x: 50, y: 50))
        
        if withChildren {
            parentNode.addChild(childNode)
        }
        
        // When & Then
        if withChildren {
            #expect(throws: NodeError.hasChildren) {
                try parentNode.delete()
            }
        } else {
            #expect(throws: Never.self) {
                try parentNode.delete()
            }
        }
    }
}
```

#### パフォーマンステスト
```swift
// MindMapCoreTests/PerformanceTests.swift
import Testing
@testable import MindMapCore

struct PerformanceTests {
    
    @Test("大量ノード作成パフォーマンス")
    func testLargeNodeCreationPerformance() {
        let nodeCount = 1000
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        var nodes: [Node] = []
        for i in 0..<nodeCount {
            let node = Node(
                text: "ノード \(i)",
                position: CGPoint(x: Double(i % 50) * 10, y: Double(i / 50) * 10)
            )
            nodes.append(node)
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        #expect(nodes.count == nodeCount)
        #expect(timeElapsed < 1.0) // 1秒以内で完了することを期待
    }
}
```

### 開発ワークフロー

#### Makefileによる自動化
```makefile
# Makefile
.PHONY: setup lint format test test-core build clean

# 初期セットアップ
setup:
	@echo "🔧 プロジェクトセットアップ中..."
	brew install swiftlint swiftformat
	@echo "✅ セットアップ完了"

# リント実行
lint:
	@echo "🔍 SwiftLint実行中..."
	swiftlint lint --strict
	@echo "✅ リント完了"

# フォーマット実行
format:
	@echo "🎨 SwiftFormat実行中..."
	swiftformat .
	@echo "✅ フォーマット完了"

# 全テスト実行
test:
	@echo "🧪 全テスト実行中..."
	xcodebuild test -scheme AsaMindMap -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
	@echo "✅ テスト完了"

# コアモジュールのみテスト（高速）
test-core:
	@echo "⚡ コアモジュールテスト実行中..."
	cd Core && swift test
	@echo "✅ コアテスト完了"

# ビルド
build:
	@echo "🔨 ビルド中..."
	xcodebuild build -scheme AsaMindMap -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
	@echo "✅ ビルド完了"

# クリーンアップ
clean:
	@echo "🧹 クリーンアップ中..."
	xcodebuild clean -scheme AsaMindMap
	rm -rf .build
	@echo "✅ クリーンアップ完了"

# CI/CD用の全チェック
ci: lint test
	@echo "🚀 CI/CDチェック完了"
```

#### GitHub Actions設定
```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  lint-and-format:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: "5.9"
    
    - name: Install tools
      run: |
        brew install swiftlint swiftformat
    
    - name: SwiftLint
      run: swiftlint lint --strict
    
    - name: SwiftFormat check
      run: swiftformat --lint .

  test-core-modules:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Swift
      uses: swift-actions/setup-swift@v1
      with:
        swift-version: "5.9"
    
    - name: Test Core Modules
      run: |
        cd Core
        swift test --parallel

  test-ios:
    runs-on: macos-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Select Xcode
      run: sudo xcode-select -s /Applications/Xcode_15.2.app
    
    - name: Test iOS
      run: |
        xcodebuild test \
          -scheme AsaMindMap \
          -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
          -enableCodeCoverage YES
    
    - name: Upload coverage reports
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml
```

### 追加の開発ツール

#### Periphery（未使用コード検出）
```yaml
# .periphery.yml
workspace: AsaMindMap.xcworkspace
schemes:
  - AsaMindMap
targets:
  - AsaMindMap
  - MindMapCore
  - MindMapUI
  - DataLayer
  - NetworkLayer
  - DesignSystem

# 除外設定
exclude:
  - "*.generated.swift"
  - "**/Tests/**"

# 設定
retain_public: true
retain_objc_accessible: true
disable_update_check: true
```

#### Pre-commit hooks
```bash
#!/bin/sh
# .git/hooks/pre-commit

echo "🔍 Pre-commit チェック実行中..."

# SwiftFormat実行
echo "🎨 SwiftFormat実行中..."
swiftformat .

# SwiftLint実行
echo "🔍 SwiftLint実行中..."
swiftlint lint --strict --quiet

if [ $? -ne 0 ]; then
    echo "❌ SwiftLintエラーが検出されました。修正してからコミットしてください。"
    exit 1
fi

# コアモジュールテスト実行
echo "⚡ コアモジュールテスト実行中..."
cd Core && swift test --quiet

if [ $? -ne 0 ]; then
    echo "❌ テストが失敗しました。修正してからコミットしてください。"
    exit 1
fi

echo "✅ Pre-commitチェック完了"
```

### 開発フロー統合

#### 日々の開発サイクル
```bash
# 1. 機能開発開始
make setup                    # 環境セットアップ
git checkout -b feature/node-editing

# 2. TDD サイクル
# 🔴 Red: テスト作成
swift test --filter NodeEditingTests  # 失敗確認

# 🟢 Green: 実装
swift test --filter NodeEditingTests  # 成功確認

# 🔵 Refactor: Tidy First
make format                   # コードフォーマット
make lint                     # リント実行
swift test                    # 全テスト実行

# 3. 統合確認
make test-core               # 高速コアテスト
make test                    # 全テスト（UI含む）

# 4. コミット
git add .
git commit -m "feat: ノード編集機能追加

- TDD で NodeEditingUseCase を実装
- バリデーションルールを分離
- UI コンポーネントを追加"
```

#### コードレビュー観点
```markdown
## レビューチェックリスト

### 🧪 テスト品質
- [ ] テストファーストで開発されているか？
- [ ] テストが仕様を表現しているか？
- [ ] エッジケースがカバーされているか？

### 🏗️ アーキテクチャ
- [ ] 依存関係が適切な方向か？
- [ ] 単一責任原則が守られているか？
- [ ] インターフェースが適切に定義されているか？

### 🧹 Tidy First
- [ ] 整理と機能変更が分離されているか？
- [ ] 変数・メソッド名が意図を表現しているか？
- [ ] 重複コードが除去されているか？

### 📱 iOS特有
- [ ] メモリリークがないか？
- [ ] UIの応答性が保たれているか？
- [ ] アクセシビリティが考慮されているか？
```

この統合された設計により、以下の利点が得られます：

## 🎯 設計の利点

### 1. **持続可能な開発**
- **TDD**: バグの早期発見と仕様の明確化
- **Tidy First**: 技術的負債の蓄積防止
- **クリーンアーキテクチャ**: 変更に強い設計

### 2. **開発効率**
- **高速テスト**: `swift test`でシミュレータ不要
- **モジュラー設計**: 並行開発とコード再利用
- **自動化**: リント・フォーマット・テストの自動実行

### 3. **品質保証**
- **多層テスト**: 単体→統合→E2Eの包括的テスト
- **継続的リファクタリング**: コード品質の維持
- **依存性注入**: テスタビリティの向上

### 4. **チーム開発**
- **明確な責任分離**: レイヤー間の独立性
- **統一されたコーディング規約**: SwiftLint/SwiftFormat
- **レビュー観点の標準化**: Tidy Firstチェックリスト

### 5. **iOS特化最適化**
- **SwiftUI + Combine**: リアクティブUI
- **Core Data + CloudKit**: データ永続化と同期
- **Apple Pencil**: ネイティブ描画体験