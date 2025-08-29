import Foundation
import SwiftUI

public enum TemplateCategory: String, CaseIterable, Codable, Sendable {
    case business = "business"
    case education = "education"
    case creative = "creative"
    case personal = "personal"
    case planning = "planning"
    case research = "research"
    
    public var displayName: String {
        switch self {
        case .business:
            return "ビジネス"
        case .education:
            return "教育・学習"
        case .creative:
            return "クリエイティブ"
        case .personal:
            return "個人"
        case .planning:
            return "企画・計画"
        case .research:
            return "研究・調査"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .business:
            return "briefcase.fill"
        case .education:
            return "book.fill"
        case .creative:
            return "paintbrush.fill"
        case .personal:
            return "person.fill"
        case .planning:
            return "calendar.badge.plus"
        case .research:
            return "magnifyingglass"
        }
    }
    
    public var color: Color {
        switch self {
        case .business:
            return .blue
        case .education:
            return .green
        case .creative:
            return .purple
        case .personal:
            return .orange
        case .planning:
            return .red
        case .research:
            return .teal
        }
    }
    
    public var templateCount: Int {
        // This would be implemented to return actual count from repository
        return 0
    }
}