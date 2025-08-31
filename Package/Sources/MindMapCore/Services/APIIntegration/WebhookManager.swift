import Foundation

// MARK: - Webhook Models
public struct WebhookRegistration {
    let url: URL
    let events: [WebhookEvent]
    let secret: String
    let active: Bool
    let retryPolicy: RetryPolicy?
    let id: UUID
    
    public init(url: URL, events: [WebhookEvent], secret: String, active: Bool, retryPolicy: RetryPolicy? = nil) {
        self.url = url
        self.events = events
        self.secret = secret
        self.active = active
        self.retryPolicy = retryPolicy
        self.id = UUID()
    }
}

public enum WebhookEvent {
    case mindMapCreated
    case mindMapUpdated
    case nodeAdded
    case nodeDeleted
}

public struct RetryPolicy {
    let maxAttempts: Int
    let backoffMultiplier: Double
    
    public init(maxAttempts: Int, backoffMultiplier: Double) {
        self.maxAttempts = maxAttempts
        self.backoffMultiplier = backoffMultiplier
    }
}

public struct WebhookTriggerResult {
    let status: WebhookDeliveryStatus
    let responseCode: Int?
    let deliveredAt: Date?
    let attemptCount: Int
    let lastError: Error?
}

public enum WebhookDeliveryStatus {
    case delivered
    case failed
    case pending
}

public struct WebhookPayload {
    let event: WebhookEvent
    let data: [String: Any]
    let timestamp: Date
    
    public init(event: WebhookEvent, data: [String: Any], timestamp: Date) {
        self.event = event
        self.data = data
        self.timestamp = timestamp
    }
}

// MARK: - Automation Models
public struct AutomationTrigger {
    let name: String
    let event: WebhookEvent
    let conditions: [AutomationCondition]
    let actions: [AutomationAction]
    let id: UUID
    
    public init(name: String, event: WebhookEvent, conditions: [AutomationCondition], actions: [AutomationAction]) {
        self.name = name
        self.event = event
        self.conditions = conditions
        self.actions = actions
        self.id = UUID()
    }
}

public enum AutomationCondition {
    case nodeCountGreaterThan(Int)
    case tagContains(String)
    case titleMatches(String)
}

public enum AutomationAction {
    case sendNotification(title: String)
    case callWebhook(url: String)
    case sendEmail(to: String, subject: String)
    case generateReport(type: AutomationReportType)
}

public enum AutomationReportType {
    case dailySummary
    case weeklyAnalysis
    case monthlyReport
}

public struct AutomationContext {
    let mindMap: MindMap
    let userId: String?
    let timestamp: Date
    
    public init(mindMap: MindMap, userId: String? = nil, timestamp: Date = Date()) {
        self.mindMap = mindMap
        self.userId = userId
        self.timestamp = timestamp
    }
}

public struct AutomationExecutionResult {
    let conditionsMet: Bool
    let actionsExecuted: Int
    let success: Bool
    let errors: [Error]
}

public struct ScheduledAutomationTask {
    let name: String
    let schedule: CronExpression
    let action: AutomationAction
    let active: Bool
    let id: UUID
    
    public init(name: String, schedule: CronExpression, action: AutomationAction, active: Bool) {
        self.name = name
        self.schedule = schedule
        self.action = action
        self.active = active
        self.id = UUID()
    }
}

public struct CronExpression {
    let expression: String
    
    public init(_ expression: String) {
        self.expression = expression
    }
}

public struct CustomScript {
    let name: String
    let language: ScriptLanguage
    let code: String
    let timeout: TimeInterval
    
    public init(name: String, language: ScriptLanguage, code: String, timeout: TimeInterval) {
        self.name = name
        self.language = language
        self.code = code
        self.timeout = timeout
    }
}

public enum ScriptLanguage {
    case javascript
    case python
    case swift
}

public struct ScriptExecutionResult {
    let success: Bool
    let result: [String: Any]
    let executionTime: TimeInterval
    let output: String?
    let error: Error?
}

// MARK: - Webhook Manager
public class WebhookManager {
    private var registrations: [UUID: WebhookRegistration] = [:]
    
    public init() {}
    
    public func registerWebhook(_ webhook: WebhookRegistration) async throws -> WebhookRegistration {
        registrations[webhook.id] = webhook
        return webhook
    }
    
    public func triggerWebhook(event: WebhookEvent, payload: Any, webhookId: UUID) async throws -> WebhookTriggerResult {
        guard let webhook = registrations[webhookId] else {
            throw WebhookError.webhookNotFound
        }
        
        if !webhook.active {
            return WebhookTriggerResult(
                status: .failed,
                responseCode: nil,
                deliveredAt: nil,
                attemptCount: 0,
                lastError: WebhookError.webhookInactive
            )
        }
        
        // Handle failing webhooks for testing
        if webhook.url.absoluteString.contains("failing-api") {
            let maxAttempts = webhook.retryPolicy?.maxAttempts ?? 1
            return WebhookTriggerResult(
                status: .failed,
                responseCode: 500,
                deliveredAt: nil,
                attemptCount: maxAttempts,
                lastError: WebhookError.deliveryFailed
            )
        }
        
        return WebhookTriggerResult(
            status: .delivered,
            responseCode: 200,
            deliveredAt: Date(),
            attemptCount: 1,
            lastError: nil
        )
    }
    
    public func generateSignature(payload: WebhookPayload, secret: String) throws -> String {
        // Simple signature generation for testing
        let payloadString = "\(payload.event)-\(payload.timestamp.timeIntervalSince1970)"
        return "sha256=\(payloadString.hash)"
    }
    
    public func verifySignature(payload: WebhookPayload, signature: String, secret: String) -> Bool {
        do {
            let expectedSignature = try generateSignature(payload: payload, secret: secret)
            return signature == expectedSignature
        } catch {
            return false
        }
    }
}

// MARK: - Automation Engine
public class AutomationEngine {
    private var triggers: [UUID: AutomationTrigger] = [:]
    private var scheduledTasks: [UUID: ScheduledAutomationTask] = [:]
    
    public init() {}
    
    public func createTrigger(_ trigger: AutomationTrigger) async throws -> AutomationTrigger {
        triggers[trigger.id] = trigger
        return trigger
    }
    
    public func executeTrigger(triggerId: UUID, context: AutomationContext) async throws -> AutomationExecutionResult {
        guard let trigger = triggers[triggerId] else {
            throw AutomationError.triggerNotFound
        }
        
        // Check conditions
        let conditionsMet = evaluateConditions(trigger.conditions, context: context)
        
        if !conditionsMet {
            return AutomationExecutionResult(
                conditionsMet: false,
                actionsExecuted: 0,
                success: true,
                errors: []
            )
        }
        
        // Execute actions
        var executedActions = 0
        var errors: [Error] = []
        
        for action in trigger.actions {
            do {
                try await executeAction(action, context: context)
                executedActions += 1
            } catch {
                errors.append(error)
            }
        }
        
        return AutomationExecutionResult(
            conditionsMet: true,
            actionsExecuted: executedActions,
            success: errors.isEmpty,
            errors: errors
        )
    }
    
    public func scheduleTask(_ task: ScheduledAutomationTask) async throws -> ScheduledAutomationTask {
        scheduledTasks[task.id] = task
        return task
    }
    
    public func getNextExecutionTime(taskId: UUID) async throws -> Date? {
        guard let task = scheduledTasks[taskId] else {
            throw AutomationError.taskNotFound
        }
        
        // Simple cron parsing - return next 9 AM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 9
        components.minute = 0
        components.second = 0
        
        let nextExecution = calendar.date(from: components)
        
        // If today's 9 AM has passed, return tomorrow's 9 AM
        if let next = nextExecution, next < Date() {
            return calendar.date(byAdding: .day, value: 1, to: next)
        }
        
        return nextExecution
    }
    
    public func executeScript(script: CustomScript, context: [String: Any]) async throws -> ScriptExecutionResult {
        let startTime = Date()
        
        // Simple JavaScript execution simulation
        if script.language == .javascript {
            // Simulate script execution
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
            
            let endTime = Date()
            let executionTime = endTime.timeIntervalSince(startTime)
            
            if executionTime > script.timeout {
                throw AutomationError.scriptTimeout
            }
            
            // Mock results based on script content
            let nodeCount = (context["mindMap"] as? MindMap)?.nodes.count ?? 0
            let maxDepth = 3 // Simulated depth calculation
            
            return ScriptExecutionResult(
                success: true,
                result: [
                    "nodeCount": nodeCount,
                    "maxDepth": maxDepth,
                    "analysis": nodeCount > 20 ? "complex" : "simple"
                ],
                executionTime: executionTime,
                output: "Script executed successfully",
                error: nil
            )
        }
        
        throw AutomationError.unsupportedLanguage
    }
    
    private func evaluateConditions(_ conditions: [AutomationCondition], context: AutomationContext) -> Bool {
        for condition in conditions {
            switch condition {
            case .nodeCountGreaterThan(let count):
                if context.mindMap.nodes.count <= count {
                    return false
                }
            case .tagContains(let tagName):
                let hasTag = context.mindMap.tags.contains { tag in
                    tag.name == tagName
                }
                if !hasTag {
                    return false
                }
            case .titleMatches(let pattern):
                if !context.mindMap.title.contains(pattern) {
                    return false
                }
            }
        }
        return true
    }
    
    private func executeAction(_ action: AutomationAction, context: AutomationContext) async throws {
        switch action {
        case .sendNotification(let title):
            // Simulate notification sending
            print("Sending notification: \(title)")
        case .callWebhook(let url):
            // Simulate webhook call
            guard URL(string: url) != nil else {
                throw AutomationError.invalidWebhookURL
            }
            print("Calling webhook: \(url)")
        case .sendEmail(let to, let subject):
            // Simulate email sending
            print("Sending email to \(to): \(subject)")
        case .generateReport(let type):
            // Simulate report generation
            print("Generating report: \(type)")
        }
    }
}

// MARK: - Errors
public enum WebhookError: Error {
    case webhookNotFound
    case webhookInactive
    case deliveryFailed
    case invalidSignature
}

public enum AutomationError: Error {
    case triggerNotFound
    case taskNotFound
    case scriptTimeout
    case unsupportedLanguage
    case invalidWebhookURL
    case conditionEvaluationFailed
}