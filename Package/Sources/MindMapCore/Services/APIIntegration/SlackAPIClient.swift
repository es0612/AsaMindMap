import Foundation

// MARK: - Slack API Models
public struct SlackPostRequest {
    let channelId: String
    let mindMap: MindMap
    let format: SlackMessageFormat
}

public enum SlackMessageFormat {
    case interactiveMessage
    case plainText
    case blocks
}

public struct SlackPostResult {
    let messageId: String?
    let timestamp: String?
    let channel: String
    let attachments: [SlackAttachment]
}

public struct SlackAttachment {
    let id: String
    let title: String
    let content: String
}

public struct SlackWorkflowRequest {
    let triggerId: String
    let mindMap: MindMap
    let workflowType: SlackWorkflowType
}

public enum SlackWorkflowType {
    case taskCreation
    case notification
    case approval
}

public struct SlackWorkflowResult {
    let workflowId: String?
    let status: SlackWorkflowStatus
    let createdTasks: [SlackTask]
}

public enum SlackWorkflowStatus {
    case executed
    case pending
    case failed
}

public struct SlackTask {
    let id: String
    let title: String
    let assignee: String?
    let dueDate: Date?
}

// MARK: - Rate Limited API Client
public class RateLimitedAPIClient {
    private let client: SlackAPIClient
    private let maxRequestsPerMinute: Int
    private var requestCount = 0
    private var lastResetTime = Date()
    
    public init(client: SlackAPIClient, maxRequestsPerMinute: Int) {
        self.client = client
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }
    
    public func postMindMap(_ request: SlackPostRequest) async throws -> SlackPostResult {
        // レート制限チェック
        let currentTime = Date()
        if currentTime.timeIntervalSince(lastResetTime) > 60 {
            requestCount = 0
            lastResetTime = currentTime
        }
        
        if requestCount >= maxRequestsPerMinute {
            throw APIError.rateLimitExceeded
        }
        
        requestCount += 1
        return try await client.postMindMap(request)
    }
}

// MARK: - Slack API Client
public class SlackAPIClient {
    private let botToken: String
    
    public init(botToken: String) {
        self.botToken = botToken
    }
    
    public func postMindMap(_ request: SlackPostRequest) async throws -> SlackPostResult {
        guard !botToken.isEmpty else {
            throw APIError.authenticationFailed
        }
        
        return SlackPostResult(
            messageId: "msg-\(UUID().uuidString)",
            timestamp: "\(Date().timeIntervalSince1970)",
            channel: request.channelId,
            attachments: [
                SlackAttachment(
                    id: "att-\(UUID().uuidString)",
                    title: request.mindMap.title,
                    content: "Mind map with \(request.mindMap.nodes.count) nodes"
                )
            ]
        )
    }
    
    public func triggerWorkflow(_ request: SlackWorkflowRequest) async throws -> SlackWorkflowResult {
        guard !botToken.isEmpty else {
            throw APIError.authenticationFailed
        }
        
        let tasks = request.mindMap.nodes.map { node in
            SlackTask(
                id: "task-\(UUID().uuidString)",
                title: node.text,
                assignee: nil,
                dueDate: nil
            )
        }
        
        return SlackWorkflowResult(
            workflowId: "workflow-\(UUID().uuidString)",
            status: .executed,
            createdTasks: tasks
        )
    }
}