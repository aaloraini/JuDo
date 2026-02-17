//
//  Task.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import Foundation

enum Priority: String, Codable, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var sortValue: Int {
        switch self {
        case .high: return 3
        case .medium: return 2
        case .low: return 1
        }
    }
}

struct Task: Codable, Identifiable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int
    
    // v2 fields (all optional for backward compatibility)
    var priority: Priority?
    var dueDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?
    
    init(title: String, order: Int, priority: Priority? = nil, dueDate: Date? = nil, notes: String? = nil) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.order = order
        self.priority = priority
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil
    }
    
    // Backward-compatible decoder for v1 tasks
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode required v1 fields
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        order = try container.decode(Int.self, forKey: .order)
        
        // Decode optional v2 fields with defaults
        priority = try container.decodeIfPresent(Priority.self, forKey: .priority)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt)
    }
    
    // Helper computed properties
    var isOverdue: Bool {
        guard let dueDate = dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }
    
    var isDueToday: Bool {
        guard let dueDate = dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }
    
    var isDueThisWeek: Bool {
        guard let dueDate = dueDate else { return false }
        let calendar = Calendar.current
        let now = Date()
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        return dueDate >= now && dueDate <= weekFromNow
    }
}
