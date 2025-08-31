import Testing
import Foundation
@testable import MindMapCore

/// 開発者向けAPI・Webhook・自動化機能テストスイート
/// 外部開発者向けのAPI機能とWebhook統合のTDDテスト
@Suite("開発者向けAPI統合テスト")
struct DeveloperAPITests {
    
    // MARK: - Developer API Tests
    
    @Test("開発者API: マインドマップ作成API")
    func testDeveloperAPICreateMindMap() async throws {
        // Given
        let apiServer = DeveloperAPIServer()
        let apiRequest = APICreateMindMapRequest(
            title: "API経由で作成",
            initialNodes: [
                APINode(text: "ルートノード", position: CGPoint(x: 0, y: 0)),
                APINode(text: "子ノード1", position: CGPoint(x: 100, y: 50))
            ],
            apiKey: "dev-api-key-123",
            userId: "user-456"
        )
        
        // When
        let response = try await apiServer.createMindMap(apiRequest)
        
        // Then
        #expect(response.mindMapId != nil)
        #expect(response.status == .created)
        #expect(response.nodes.count == 2)
        #expect(response.createdAt != nil)
        #expect(response.apiVersion == "v1")
    }
    
    @Test("開発者API: マインドマップ取得API")
    func testDeveloperAPIGetMindMap() async throws {
        // Given
        let apiServer = DeveloperAPIServer()
        let existingMindMapId = "mindmap-789"
        let apiRequest = APIGetMindMapRequest(
            mindMapId: existingMindMapId,
            apiKey: "dev-api-key-123",
            includeMetadata: true
        )
        
        // When
        let response = try await apiServer.getMindMap(apiRequest)
        
        // Then
        #expect(response.mindMap != nil)
        #expect(response.mindMap?.id.uuidString == existingMindMapId)
        #expect(response.metadata?.nodeCount > 0)
        #expect(response.metadata?.createdBy != nil)
        #expect(response.status == .success)
    }
    
    @Test("開発者API: バッチ操作API")
    func testDeveloperAPIBatchOperations() async throws {
        // Given
        let apiServer = DeveloperAPIServer()
        let batchRequest = APIBatchRequest(
            operations: [
                .create(APICreateMindMapRequest(title: "バッチ1", initialNodes: [], apiKey: "dev-api-key-123", userId: "user-456")),
                .update(APIUpdateMindMapRequest(mindMapId: "existing-123", title: "更新済み", apiKey: "dev-api-key-123")),
                .delete(APIDeleteMindMapRequest(mindMapId: "old-456", apiKey: "dev-api-key-123"))
            ],
            transactional: true
        )
        
        // When
        let response = try await apiServer.executeBatch(batchRequest)
        
        // Then
        #expect(response.results.count == 3)
        #expect(response.successCount == 3)
        #expect(response.failureCount == 0)
        #expect(response.executedAt != nil)
    }
    
    // MARK: - Webhook System Tests
    
    @Test("Webhook: イベント登録とトリガー")
    func testWebhookEventRegistrationAndTrigger() async throws {
        // Given
        let webhookManager = WebhookManager()
        let webhook = WebhookRegistration(
            url: URL(string: "https://api.example.com/webhooks/mindmap")!,
            events: [.mindMapCreated, .mindMapUpdated, .nodeAdded],
            secret: "webhook-secret-123",
            active: true
        )
        
        // When
        let registeredWebhook = try await webhookManager.registerWebhook(webhook)
        let mindMap = createTestMindMap()
        let triggerResult = try await webhookManager.triggerWebhook(
            event: .mindMapCreated,
            payload: mindMap,
            webhookId: registeredWebhook.id
        )
        
        // Then
        #expect(registeredWebhook.id != nil)
        #expect(triggerResult.status == .delivered)
        #expect(triggerResult.responseCode == 200)
        #expect(triggerResult.deliveredAt != nil)
    }
    
    @Test("Webhook: リトライメカニズム")
    func testWebhookRetryMechanism() async throws {
        // Given
        let webhookManager = WebhookManager()
        let failingWebhook = WebhookRegistration(
            url: URL(string: "https://failing-api.example.com/webhook")!,
            events: [.mindMapCreated],
            secret: "test-secret",
            active: true,
            retryPolicy: RetryPolicy(maxAttempts: 3, backoffMultiplier: 2.0)
        )
        
        // When
        let registeredWebhook = try await webhookManager.registerWebhook(failingWebhook)
        let mindMap = createTestMindMap()
        let triggerResult = try await webhookManager.triggerWebhook(
            event: .mindMapCreated,
            payload: mindMap,
            webhookId: registeredWebhook.id
        )
        
        // Then
        #expect(triggerResult.attemptCount == 3)
        #expect(triggerResult.status == .failed)
        #expect(triggerResult.lastError != nil)
    }
    
    @Test("Webhook: 署名検証")
    func testWebhookSignatureVerification() async throws {
        // Given
        let webhookManager = WebhookManager()
        let secret = "super-secret-key"
        let payload = WebhookPayload(
            event: .mindMapCreated,
            data: ["mindMapId": "test-123"],
            timestamp: Date()
        )
        
        // When
        let signature = try webhookManager.generateSignature(payload: payload, secret: secret)
        let isValid = webhookManager.verifySignature(
            payload: payload,
            signature: signature,
            secret: secret
        )
        
        // Then
        #expect(signature.isEmpty == false)
        #expect(isValid == true)
    }
    
    // MARK: - Automation System Tests
    
    @Test("自動化: トリガー作成と実行")
    func testAutomationTriggerCreation() async throws {
        // Given
        let automationEngine = AutomationEngine()
        let trigger = AutomationTrigger(
            name: "新規マップ作成時の通知",
            event: .mindMapCreated,
            conditions: [
                .nodeCountGreaterThan(5),
                .tagContains("important")
            ],
            actions: [
                .sendNotification(title: "重要なマップが作成されました"),
                .callWebhook(url: "https://api.example.com/notify")
            ]
        )
        
        // When
        let createdTrigger = try await automationEngine.createTrigger(trigger)
        let mindMap = createTestMindMapWithTags(["important"])
        let executionResult = try await automationEngine.executeTrigger(
            triggerId: createdTrigger.id,
            context: AutomationContext(mindMap: mindMap)
        )
        
        // Then
        #expect(createdTrigger.id != nil)
        #expect(executionResult.conditionsMet == true)
        #expect(executionResult.actionsExecuted == 2)
        #expect(executionResult.success == true)
    }
    
    @Test("自動化: スケジュール実行")
    func testAutomationScheduledExecution() async throws {
        // Given
        let automationEngine = AutomationEngine()
        let scheduledTask = ScheduledAutomationTask(
            name: "毎日のマップ集計",
            schedule: CronExpression("0 9 * * *"), // 毎日9時
            action: .generateReport(type: .dailySummary),
            active: true
        )
        
        // When
        let createdTask = try await automationEngine.scheduleTask(scheduledTask)
        let nextExecution = try await automationEngine.getNextExecutionTime(taskId: createdTask.id)
        
        // Then
        #expect(createdTask.id != nil)
        #expect(nextExecution != nil)
        #expect(createdTask.active == true)
    }
    
    @Test("自動化: カスタムスクリプト実行")
    func testAutomationCustomScriptExecution() async throws {
        // Given
        let automationEngine = AutomationEngine()
        let customScript = CustomScript(
            name: "マップ構造解析",
            language: .javascript,
            code: """
                function analyzeMindMap(mindMap) {
                    const nodeCount = mindMap.nodes.length;
                    const maxDepth = calculateMaxDepth(mindMap.rootNode);
                    return {
                        nodeCount: nodeCount,
                        maxDepth: maxDepth,
                        analysis: nodeCount > 20 ? "complex" : "simple"
                    };
                }
                
                function calculateMaxDepth(node, depth = 0) {
                    if (!node.children || node.children.length === 0) {
                        return depth;
                    }
                    return Math.max(...node.children.map(child => calculateMaxDepth(child, depth + 1)));
                }
            """,
            timeout: 10.0
        )
        
        // When
        let scriptResult = try await automationEngine.executeScript(
            script: customScript,
            context: ["mindMap": createTestMindMap()]
        )
        
        // Then
        #expect(scriptResult.success == true)
        #expect(scriptResult.result["nodeCount"] != nil)
        #expect(scriptResult.result["maxDepth"] != nil)
        #expect(scriptResult.result["analysis"] != nil)
        #expect(scriptResult.executionTime < 10.0)
    }
    
    // MARK: - API Security Tests
    
    @Test("API認証: APIキー検証")
    func testAPIKeyAuthentication() async throws {
        // Given
        let apiAuthenticator = APIAuthenticator()
        let validApiKey = "valid-api-key-123"
        let invalidApiKey = "invalid-key"
        
        // When
        let validResult = try await apiAuthenticator.validateAPIKey(validApiKey)
        
        // Then
        #expect(validResult.isValid == true)
        #expect(validResult.userId != nil)
        #expect(validResult.permissions.contains(.read))
        #expect(validResult.permissions.contains(.write))
        
        // Invalid key test
        await #expect(throws: APIAuthenticationError.invalidAPIKey) {
            try await apiAuthenticator.validateAPIKey(invalidApiKey)
        }
    }
    
    @Test("API制限: レート制限とクォータ")
    func testAPIRateLimitingAndQuota() async throws {
        // Given
        let rateLimiter = APIRateLimiter(
            requestsPerMinute: 60,
            dailyQuota: 1000
        )
        let apiKey = "test-api-key"
        
        // When
        var successfulRequests = 0
        var rateLimitedRequests = 0
        
        for _ in 1...70 {
            do {
                try await rateLimiter.checkLimit(apiKey: apiKey)
                successfulRequests += 1
            } catch APIRateLimitError.rateLimitExceeded {
                rateLimitedRequests += 1
            }
        }
        
        // Then
        #expect(successfulRequests == 60)
        #expect(rateLimitedRequests == 10)
    }
    
    @Test("API権限: スコープベースアクセス制御")
    func testAPIScopeBasedAccessControl() async throws {
        // Given
        let accessController = APIScopeController()
        let readOnlyToken = APIToken(
            key: "readonly-token",
            scopes: [.read, .list]
        )
        let fullAccessToken = APIToken(
            key: "full-access-token",
            scopes: [.read, .write, .delete, .admin]
        )
        
        // When & Then
        let readAccess = try await accessController.checkAccess(
            token: readOnlyToken,
            operation: .read,
            resource: .mindMap
        )
        #expect(readAccess == true)
        
        await #expect(throws: APIPermissionError.insufficientPermissions) {
            try await accessController.checkAccess(
                token: readOnlyToken,
                operation: .delete,
                resource: .mindMap
            )
        }
        
        let deleteAccess = try await accessController.checkAccess(
            token: fullAccessToken,
            operation: .delete,
            resource: .mindMap
        )
        #expect(deleteAccess == true)
    }
    
    // MARK: - Helper Methods
    
    private func createTestMindMap() -> MindMap {
        let rootNode = Node(
            id: UUID(),
            text: "Developer API Test",
            position: CGPoint(x: 0, y: 0)
        )
        
        let childNode = Node(
            id: UUID(),
            text: "API Integration",
            position: CGPoint(x: 100, y: 50)
        )
        
        rootNode.children.append(childNode)
        
        return MindMap(
            id: UUID(),
            title: "Developer API Test Map",
            rootNode: rootNode,
            nodes: [rootNode, childNode],
            tags: ["api", "test"],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    private func createTestMindMapWithTags(_ tags: [String]) -> MindMap {
        let mindMap = createTestMindMap()
        mindMap.tags = tags.map { Tag(id: UUID(), name: $0, color: "#FF0000") }
        return mindMap
    }
}