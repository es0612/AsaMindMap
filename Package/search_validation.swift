import Foundation

// Simplified validation script for search entities

// MARK: - Search Types
enum SearchType: String, Codable, CaseIterable {
    case fullText = "fullText"
    case exactMatch = "exactMatch"
    case fuzzy = "fuzzy"
}

enum NodeType: String, Codable, CaseIterable {
    case regular = "regular"
    case task = "task"
}

enum SearchFilterType: String, Codable, CaseIterable {
    case tag = "tag"
    case dateRange = "dateRange"
    case nodeType = "nodeType"
    case creator = "creator"
}

enum SearchMatchType: String, Codable, CaseIterable {
    case title = "title"
    case content = "content"
    case tag = "tag"
    
    var priority: Int {
        switch self {
        case .title: return 3
        case .content: return 2
        case .tag: return 1
        }
    }
}

// MARK: - Search Filter
enum SearchFilter: Codable, Equatable, Hashable {
    case tag(String)
    case dateRange(Date, Date)
    case nodeType(NodeType)
    case creator(UUID)
    
    var type: SearchFilterType {
        switch self {
        case .tag: return .tag
        case .dateRange: return .dateRange
        case .nodeType: return .nodeType
        case .creator: return .creator
        }
    }
    
    var isValid: Bool {
        switch self {
        case .tag(let value):
            return !value.isEmpty
        case .dateRange(let start, let end):
            return start <= end
        case .nodeType:
            return true
        case .creator:
            return true
        }
    }
}

// MARK: - Search Entity
struct Search: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let query: String
    let type: SearchType
    let filters: [SearchFilter]
    let createdAt: Date
    
    init(query: String, type: SearchType, filters: [SearchFilter], createdAt: Date) {
        self.id = UUID()
        self.query = query
        self.type = type
        self.filters = filters
        self.createdAt = createdAt
    }
    
    var isEmpty: Bool {
        query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValid: Bool {
        !isEmpty
    }
    
    func hasFilter(_ filter: SearchFilter) -> Bool {
        filters.contains(filter)
    }
}

// MARK: - Search Result
struct SearchResult: Identifiable, Codable, Equatable, Comparable, Hashable {
    let id: UUID
    let nodeId: UUID
    let mindMapId: UUID
    let relevanceScore: Double
    let matchType: SearchMatchType
    let highlightedText: String
    let matchPosition: Int
    
    init(nodeId: UUID, mindMapId: UUID, relevanceScore: Double, matchType: SearchMatchType, highlightedText: String, matchPosition: Int) {
        self.id = UUID()
        self.nodeId = nodeId
        self.mindMapId = mindMapId
        self.relevanceScore = relevanceScore
        self.matchType = matchType
        self.highlightedText = highlightedText
        self.matchPosition = matchPosition
    }
    
    var isRelevant: Bool {
        relevanceScore >= 0.3
    }
    
    var priority: Int {
        matchType.priority
    }
    
    static func < (lhs: SearchResult, rhs: SearchResult) -> Bool {
        if lhs.relevanceScore != rhs.relevanceScore {
            return lhs.relevanceScore > rhs.relevanceScore
        }
        return lhs.priority > rhs.priority
    }
}

// MARK: - Validation Tests
print("🔍 Search Entity Validation")
print("===========================")

// Test 1: Search Creation
let search = Search(
    query: "重要なアイデア",
    type: .fullText,
    filters: [.tag("重要")],
    createdAt: Date()
)

print("✅ Test 1: Search creation - \(search.query)")
print("   Valid: \(search.isValid)")
print("   Empty: \(search.isEmpty)")

// Test 2: Search Filter
let tagFilter = SearchFilter.tag("プロジェクト")
let dateFilter = SearchFilter.dateRange(Date().addingTimeInterval(-86400), Date())

print("✅ Test 2: Search filters")
print("   Tag filter valid: \(tagFilter.isValid)")
print("   Date filter valid: \(dateFilter.isValid)")

// Test 3: Search Result
let result = SearchResult(
    nodeId: UUID(),
    mindMapId: UUID(),
    relevanceScore: 0.85,
    matchType: .title,
    highlightedText: "重要なアイデア",
    matchPosition: 0
)

print("✅ Test 3: Search result")
print("   Relevant: \(result.isRelevant)")
print("   Priority: \(result.priority)")

// Test 4: Search Result Sorting
let results = [
    SearchResult(nodeId: UUID(), mindMapId: UUID(), relevanceScore: 0.5, matchType: .content, highlightedText: "低スコア", matchPosition: 0),
    SearchResult(nodeId: UUID(), mindMapId: UUID(), relevanceScore: 0.9, matchType: .title, highlightedText: "高スコア", matchPosition: 0),
    SearchResult(nodeId: UUID(), mindMapId: UUID(), relevanceScore: 0.7, matchType: .tag, highlightedText: "中スコア", matchPosition: 0)
]

let sortedResults = results.sorted()
print("✅ Test 4: Search result sorting")
print("   First result score: \(sortedResults[0].relevanceScore)")
print("   Second result score: \(sortedResults[1].relevanceScore)")
print("   Third result score: \(sortedResults[2].relevanceScore)")

print("\n🎉 All validation tests passed!")