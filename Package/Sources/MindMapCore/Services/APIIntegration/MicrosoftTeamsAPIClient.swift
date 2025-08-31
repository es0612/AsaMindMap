import Foundation

// MARK: - Microsoft Teams API Models
public struct TeamsPostRequest {
    let teamId: String
    let channelId: String
    let mindMap: MindMap
    let includeAttachment: Bool
}

public struct TeamsPostResult {
    let messageId: String?
    let attachmentId: String?
    let webUrl: String
}

public struct TeamsPlannerRequest {
    let planId: String
    let mindMap: MindMap
    let bucketStrategy: BucketStrategy
}

public enum BucketStrategy {
    case byTopicLevel
    case byTag
    case single
}

public struct TeamsPlannerResult {
    let createdTasks: [PlannerTask]
    let buckets: [PlannerBucket]
    let planId: String
}

public struct PlannerTask {
    let id: String
    let title: String
    let bucketId: String
    let progress: Int
}

public struct PlannerBucket {
    let id: String
    let name: String
    let planId: String
}

// MARK: - OAuth Authentication Models
public struct OAuthRequest {
    let provider: OAuthProvider
    let clientId: String
    let redirectURI: String
    let scopes: [String]?
    
    public init(provider: OAuthProvider, clientId: String, redirectURI: String, scopes: [String]? = nil) {
        self.provider = provider
        self.clientId = clientId
        self.redirectURI = redirectURI
        self.scopes = scopes
    }
}

public enum OAuthProvider {
    case notion
    case slack
    case microsoftTeams
}

public struct OAuthResult {
    let accessToken: String?
    let refreshToken: String?
    let expiresAt: Date?
    let scopes: [String]
    let teamId: String?
    let userId: String?
}

// MARK: - OAuth Manager
public class OAuthManager {
    public init() {}
    
    public func authenticateUser(_ request: OAuthRequest) async throws -> OAuthResult {
        // 最小実装：プロバイダーに応じた基本的な認証結果を返す
        switch request.provider {
        case .notion:
            return OAuthResult(
                accessToken: "notion-access-token-\(UUID().uuidString)",
                refreshToken: "notion-refresh-token-\(UUID().uuidString)",
                expiresAt: Date().addingTimeInterval(3600),
                scopes: ["read", "write"],
                teamId: nil,
                userId: nil
            )
        case .slack:
            return OAuthResult(
                accessToken: "slack-access-token-\(UUID().uuidString)",
                refreshToken: "slack-refresh-token-\(UUID().uuidString)",
                expiresAt: Date().addingTimeInterval(3600),
                scopes: request.scopes ?? ["channels:write", "files:write", "chat:write"],
                teamId: "team-\(UUID().uuidString)",
                userId: "user-\(UUID().uuidString)"
            )
        case .microsoftTeams:
            return OAuthResult(
                accessToken: "teams-access-token-\(UUID().uuidString)",
                refreshToken: "teams-refresh-token-\(UUID().uuidString)",
                expiresAt: Date().addingTimeInterval(3600),
                scopes: ["https://graph.microsoft.com/Team.ReadWrite.All"],
                teamId: "team-\(UUID().uuidString)",
                userId: "user-\(UUID().uuidString)"
            )
        }
    }
}

// MARK: - Microsoft Teams API Client
public class MicrosoftTeamsAPIClient {
    private let accessToken: String
    
    public init(accessToken: String) {
        self.accessToken = accessToken
    }
    
    public func postMindMap(_ request: TeamsPostRequest) async throws -> TeamsPostResult {
        guard !accessToken.isEmpty else {
            throw APIError.authenticationFailed
        }
        
        return TeamsPostResult(
            messageId: "teams-msg-\(UUID().uuidString)",
            attachmentId: request.includeAttachment ? "attachment-\(UUID().uuidString)" : nil,
            webUrl: "https://teams.microsoft.com/l/message/\(request.teamId)/\(request.channelId)"
        )
    }
    
    public func syncWithPlanner(_ request: TeamsPlannerRequest) async throws -> TeamsPlannerResult {
        guard !accessToken.isEmpty else {
            throw APIError.authenticationFailed
        }
        
        let buckets = [
            PlannerBucket(
                id: "bucket-\(UUID().uuidString)",
                name: "Mind Map Tasks",
                planId: request.planId
            )
        ]
        
        let tasks = request.mindMap.nodes.map { node in
            PlannerTask(
                id: "task-\(UUID().uuidString)",
                title: node.text,
                bucketId: buckets.first!.id,
                progress: 0
            )
        }
        
        return TeamsPlannerResult(
            createdTasks: tasks,
            buckets: buckets,
            planId: request.planId
        )
    }
}