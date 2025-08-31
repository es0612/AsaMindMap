import Testing
import Foundation
@testable import MindMapCore

/// サードパーティAPI統合テストスイート
/// Notion・Slack・Teams API統合機能のTDDテスト
@Suite("サードパーティAPI統合テスト")
struct ThirdPartyAPIIntegrationTests {
    
    // MARK: - Notion API Integration Tests
    
    @Test("Notion API: マインドマップエクスポートとページ作成")
    func testNotionAPIExportMindMap() async throws {
        // Given
        let notionClient = NotionAPIClient(apiKey: "test-api-key")
        let mindMap = createTestMindMap()
        let exportRequest = NotionExportRequest(
            databaseId: "test-database-id",
            mindMap: mindMap,
            format: .hierarchicalPage
        )
        
        // When
        let result = try await notionClient.exportMindMap(exportRequest)
        
        // Then
        #expect(result.pageId != nil)
        #expect(result.status == .success)
        #expect(result.notionURL.contains("notion.so"))
    }
    
    @Test("Notion API: データベース作成とマインドマップ同期")
    func testNotionAPIDatabaseSync() async throws {
        // Given
        let notionClient = NotionAPIClient(apiKey: "test-api-key")
        let mindMap = createTestMindMap()
        let syncRequest = NotionSyncRequest(
            workspaceId: "test-workspace",
            mindMap: mindMap,
            syncDirection: .bidirectional
        )
        
        // When
        let result = try await notionClient.syncMindMap(syncRequest)
        
        // Then
        #expect(result.syncedNodes.count == mindMap.nodes.count)
        #expect(result.conflicts.isEmpty)
        #expect(result.lastSyncTimestamp != nil)
    }
    
    // MARK: - Slack API Integration Tests
    
    @Test("Slack API: チャンネルへのマインドマップ投稿")
    func testSlackAPIPostMindMap() async throws {
        // Given
        let slackClient = SlackAPIClient(botToken: "xoxb-test-token")
        let mindMap = createTestMindMap()
        let postRequest = SlackPostRequest(
            channelId: "C1234567890",
            mindMap: mindMap,
            format: .interactiveMessage
        )
        
        // When
        let result = try await slackClient.postMindMap(postRequest)
        
        // Then
        #expect(result.messageId != nil)
        #expect(result.timestamp != nil)
        #expect(result.channel == "C1234567890")
        #expect(result.attachments.count > 0)
    }
    
    @Test("Slack API: ワークフロー統合とタスク作成")
    func testSlackAPIWorkflowIntegration() async throws {
        // Given
        let slackClient = SlackAPIClient(botToken: "xoxb-test-token")
        let mindMap = createTestMindMap()
        let workflowRequest = SlackWorkflowRequest(
            triggerId: "trigger-test-123",
            mindMap: mindMap,
            workflowType: .taskCreation
        )
        
        // When
        let result = try await slackClient.triggerWorkflow(workflowRequest)
        
        // Then
        #expect(result.workflowId != nil)
        #expect(result.status == .executed)
        #expect(result.createdTasks.count > 0)
    }
    
    // MARK: - Microsoft Teams API Integration Tests
    
    @Test("Teams API: チーム投稿とファイル添付")
    func testTeamsAPIPostWithAttachment() async throws {
        // Given
        let teamsClient = MicrosoftTeamsAPIClient(accessToken: "test-access-token")
        let mindMap = createTestMindMap()
        let postRequest = TeamsPostRequest(
            teamId: "team-test-123",
            channelId: "channel-test-456",
            mindMap: mindMap,
            includeAttachment: true
        )
        
        // When
        let result = try await teamsClient.postMindMap(postRequest)
        
        // Then
        #expect(result.messageId != nil)
        #expect(result.attachmentId != nil)
        #expect(result.webUrl.contains("teams.microsoft.com"))
    }
    
    @Test("Teams API: プランナー統合とタスク同期")
    func testTeamsAPIPlannerSync() async throws {
        // Given
        let teamsClient = MicrosoftTeamsAPIClient(accessToken: "test-access-token")
        let mindMap = createTestMindMap()
        let plannerRequest = TeamsPlannerRequest(
            planId: "plan-test-789",
            mindMap: mindMap,
            bucketStrategy: .byTopicLevel
        )
        
        // When
        let result = try await teamsClient.syncWithPlanner(plannerRequest)
        
        // Then
        #expect(result.createdTasks.count > 0)
        #expect(result.buckets.count > 0)
        #expect(result.planId == "plan-test-789")
    }
    
    // MARK: - OAuth認証統合テスト
    
    @Test("OAuth認証: Notion認証フロー")
    func testNotionOAuthFlow() async throws {
        // Given
        let oauthManager = OAuthManager()
        let authRequest = OAuthRequest(
            provider: .notion,
            clientId: "test-client-id",
            redirectURI: "asamindmap://oauth/notion"
        )
        
        // When
        let result = try await oauthManager.authenticateUser(authRequest)
        
        // Then
        #expect(result.accessToken != nil)
        #expect(result.refreshToken != nil)
        #expect(result.expiresAt != nil)
        #expect(result.scopes.contains("read"))
        #expect(result.scopes.contains("write"))
    }
    
    @Test("OAuth認証: Slack認証とスコープ確認")
    func testSlackOAuthWithScopes() async throws {
        // Given
        let oauthManager = OAuthManager()
        let authRequest = OAuthRequest(
            provider: .slack,
            clientId: "test-slack-client",
            redirectURI: "asamindmap://oauth/slack",
            scopes: ["channels:write", "files:write", "chat:write"]
        )
        
        // When
        let result = try await oauthManager.authenticateUser(authRequest)
        
        // Then
        #expect(result.teamId != nil)
        #expect(result.userId != nil)
        #expect(result.scopes.contains("channels:write"))
        #expect(result.scopes.contains("files:write"))
        #expect(result.scopes.contains("chat:write"))
    }
    
    // MARK: - エラーハンドリングテスト
    
    @Test("API統合エラー: 認証失敗処理")
    func testAPIAuthenticationErrors() async throws {
        // Given
        let invalidNotionClient = NotionAPIClient(apiKey: "invalid-key")
        let mindMap = createTestMindMap()
        let exportRequest = NotionExportRequest(
            databaseId: "test-database-id",
            mindMap: mindMap,
            format: .hierarchicalPage
        )
        
        // When & Then
        await #expect(throws: APIError.authenticationFailed) {
            try await invalidNotionClient.exportMindMap(exportRequest)
        }
    }
    
    @Test("API統合エラー: レート制限処理")
    func testAPIRateLimitHandling() async throws {
        // Given
        let slackClient = SlackAPIClient(botToken: "test-token")
        let rateLimitedClient = RateLimitedAPIClient(client: slackClient, maxRequestsPerMinute: 1)
        let mindMap = createTestMindMap()
        let requests = Array(repeating: SlackPostRequest(
            channelId: "C1234567890",
            mindMap: mindMap,
            format: .interactiveMessage
        ), count: 5)
        
        // When & Then
        for (index, request) in requests.enumerated() {
            if index >= 1 {
                await #expect(throws: APIError.rateLimitExceeded) {
                    try await rateLimitedClient.postMindMap(request)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestMindMap() -> MindMap {
        let rootNode = Node(
            id: UUID(),
            text: "API統合テスト",
            position: CGPoint(x: 0, y: 0)
        )
        
        let childNode1 = Node(
            id: UUID(),
            text: "Notion連携",
            position: CGPoint(x: 100, y: 50)
        )
        
        let childNode2 = Node(
            id: UUID(),
            text: "Slack統合",
            position: CGPoint(x: 100, y: -50)
        )
        
        rootNode.children.append(childNode1)
        rootNode.children.append(childNode2)
        
        return MindMap(
            id: UUID(),
            title: "API統合テストマップ",
            rootNode: rootNode,
            nodes: [rootNode, childNode1, childNode2],
            tags: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}