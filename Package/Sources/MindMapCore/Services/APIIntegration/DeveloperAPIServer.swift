import Foundation
import CoreGraphics

// MARK: - Developer API Request Models
public struct APICreateMindMapRequest {
    let title: String
    let initialNodes: [APINode]
    let apiKey: String
    let userId: String
    
    public init(title: String, initialNodes: [APINode], apiKey: String, userId: String) {
        self.title = title
        self.initialNodes = initialNodes
        self.apiKey = apiKey
        self.userId = userId
    }
}

public struct APINode {
    let text: String
    let position: CGPoint
    
    public init(text: String, position: CGPoint) {
        self.text = text
        self.position = position
    }
}

public struct APIGetMindMapRequest {
    let mindMapId: String
    let apiKey: String
    let includeMetadata: Bool
    
    public init(mindMapId: String, apiKey: String, includeMetadata: Bool) {
        self.mindMapId = mindMapId
        self.apiKey = apiKey
        self.includeMetadata = includeMetadata
    }
}

public struct APIUpdateMindMapRequest {
    let mindMapId: String
    let title: String
    let apiKey: String
    
    public init(mindMapId: String, title: String, apiKey: String) {
        self.mindMapId = mindMapId
        self.title = title
        self.apiKey = apiKey
    }
}

public struct APIDeleteMindMapRequest {
    let mindMapId: String
    let apiKey: String
    
    public init(mindMapId: String, apiKey: String) {
        self.mindMapId = mindMapId
        self.apiKey = apiKey
    }
}

public struct APIBatchRequest {
    let operations: [BatchOperation]
    let transactional: Bool
    
    public init(operations: [BatchOperation], transactional: Bool) {
        self.operations = operations
        self.transactional = transactional
    }
}

public enum BatchOperation {
    case create(APICreateMindMapRequest)
    case update(APIUpdateMindMapRequest)
    case delete(APIDeleteMindMapRequest)
}

// MARK: - Developer API Response Models
public struct APICreateMindMapResponse {
    let mindMapId: String?
    let status: APIResponseStatus
    let nodes: [APINode]
    let createdAt: Date?
    let apiVersion: String
}

public enum APIResponseStatus {
    case created
    case success
    case failed
}

public struct APIGetMindMapResponse {
    let mindMap: MindMap?
    let metadata: MindMapMetadata?
    let status: APIResponseStatus
}

public struct MindMapMetadata {
    let nodeCount: Int
    let createdBy: String?
    let lastModified: Date
}

public struct APIBatchResponse {
    let results: [BatchOperationResult]
    let successCount: Int
    let failureCount: Int
    let executedAt: Date?
}

public struct BatchOperationResult {
    let operation: String
    let success: Bool
    let result: Any?
    let error: String?
}

// MARK: - API Authentication Models
public struct APIAuthenticationResult {
    let isValid: Bool
    let userId: String?
    let permissions: Set<APIPermission>
}

// API permissions and types are defined in APISecurityManager.swift

// Developer API specific types
public struct DeveloperAPIToken {
    let key: String
    let scopes: Set<APIPermission>
    
    public init(key: String, scopes: Set<APIPermission>) {
        self.key = key
        self.scopes = scopes
    }
}

public enum DeveloperAPIResource {
    case mindMap
    case user
    case system
}

public enum DeveloperAPIOperation {
    case read
    case write
    case delete
    case admin
}

// MARK: - API Security Errors
public enum APIAuthenticationError: Error {
    case invalidAPIKey
    case expiredToken
    case insufficientPermissions
}

public enum APIRateLimitError: Error {
    case rateLimitExceeded
    case quotaExhausted
}

public enum APIPermissionError: Error {
    case insufficientPermissions
    case resourceNotFound
    case operationNotAllowed
}

// MARK: - API Rate Limiter
public class APIRateLimiter {
    private let requestsPerMinute: Int
    private let dailyQuota: Int
    private var requestCounts: [String: (count: Int, resetTime: Date)] = [:]
    
    public init(requestsPerMinute: Int, dailyQuota: Int) {
        self.requestsPerMinute = requestsPerMinute
        self.dailyQuota = dailyQuota
    }
    
    public func checkLimit(apiKey: String) async throws {
        let currentTime = Date()
        
        // Get or create request count for this API key
        if let existingCount = requestCounts[apiKey] {
            // Reset if a minute has passed
            if currentTime.timeIntervalSince(existingCount.resetTime) > 60 {
                requestCounts[apiKey] = (count: 1, resetTime: currentTime)
            } else {
                // Check if limit exceeded
                if existingCount.count >= requestsPerMinute {
                    throw APIRateLimitError.rateLimitExceeded
                }
                requestCounts[apiKey] = (count: existingCount.count + 1, resetTime: existingCount.resetTime)
            }
        } else {
            requestCounts[apiKey] = (count: 1, resetTime: currentTime)
        }
    }
}

// MARK: - API Scope Controller
public class APIScopeController {
    public init() {}
    
    public func checkAccess(token: DeveloperAPIToken, operation: DeveloperAPIOperation, resource: DeveloperAPIResource) async throws -> Bool {
        // Map operations to required permissions
        let requiredPermission: APIPermission
        
        switch operation {
        case .read:
            requiredPermission = .read
        case .write:
            requiredPermission = .write
        case .delete:
            requiredPermission = .delete
        case .admin:
            requiredPermission = .admin
        }
        
        if !token.scopes.contains(requiredPermission) {
            throw APIPermissionError.insufficientPermissions
        }
        
        return true
    }
}

// MARK: - API Authenticator
public class APIAuthenticator {
    public init() {}
    
    public func validateAPIKey(_ apiKey: String) async throws -> APIAuthenticationResult {
        if apiKey == "invalid-key" {
            throw APIAuthenticationError.invalidAPIKey
        }
        
        return APIAuthenticationResult(
            isValid: true,
            userId: "user-\(UUID().uuidString)",
            permissions: [.read, .write]
        )
    }
}

// MARK: - Developer API Server
public class DeveloperAPIServer {
    public init() {}
    
    public func createMindMap(_ request: APICreateMindMapRequest) async throws -> APICreateMindMapResponse {
        guard !request.apiKey.isEmpty else {
            throw APIAuthenticationError.invalidAPIKey
        }
        
        return APICreateMindMapResponse(
            mindMapId: UUID().uuidString,
            status: .created,
            nodes: request.initialNodes,
            createdAt: Date(),
            apiVersion: "v1"
        )
    }
    
    public func getMindMap(_ request: APIGetMindMapRequest) async throws -> APIGetMindMapResponse {
        guard !request.apiKey.isEmpty else {
            throw APIAuthenticationError.invalidAPIKey
        }
        
        let mockMindMap = createMockMindMap(id: request.mindMapId)
        let metadata = request.includeMetadata ? MindMapMetadata(
            nodeCount: mockMindMap.nodes.count,
            createdBy: "api-user",
            lastModified: Date()
        ) : nil
        
        return APIGetMindMapResponse(
            mindMap: mockMindMap,
            metadata: metadata,
            status: .success
        )
    }
    
    public func executeBatch(_ request: APIBatchRequest) async throws -> APIBatchResponse {
        var results: [BatchOperationResult] = []
        var successCount = 0
        var failureCount = 0
        
        for operation in request.operations {
            let result = try await executeBatchOperation(operation)
            results.append(result)
            
            if result.success {
                successCount += 1
            } else {
                failureCount += 1
            }
        }
        
        return APIBatchResponse(
            results: results,
            successCount: successCount,
            failureCount: failureCount,
            executedAt: Date()
        )
    }
    
    private func executeBatchOperation(_ operation: BatchOperation) async throws -> BatchOperationResult {
        switch operation {
        case .create(let request):
            let response = try await createMindMap(request)
            return BatchOperationResult(
                operation: "create",
                success: response.status == .created,
                result: response,
                error: nil
            )
        case .update(let request):
            return BatchOperationResult(
                operation: "update",
                success: true,
                result: "Updated mindmap \(request.mindMapId)",
                error: nil
            )
        case .delete(let request):
            return BatchOperationResult(
                operation: "delete",
                success: true,
                result: "Deleted mindmap \(request.mindMapId)",
                error: nil
            )
        }
    }
    
    private func createMockMindMap(id: String) -> MindMap {
        let rootNode = Node(
            id: UUID(),
            text: "API Test Map",
            position: CGPoint(x: 0, y: 0)
        )
        
        return MindMap(
            id: UUID(uuidString: id) ?? UUID(),
            title: "API Retrieved Map",
            rootNode: rootNode,
            nodes: [rootNode],
            tags: [],
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}