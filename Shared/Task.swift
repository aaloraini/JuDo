import Foundation
import Combine
import SwiftData

@Model
final class Task {
    var id: UUID = UUID()
    var title: String = ""
    var isCompleted: Bool = false
    var order: Int = 0
    var priorityRaw: String? = nil
    var dueDate: Date? = nil
    var notes: String? = nil
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    var completedAt: Date? = nil
    var parentId: UUID? = nil

    // Computed wrapper — not stored, not synced to CloudKit
    var priority: Priority? {
        get { priorityRaw.flatMap { Priority(rawValue: $0) } }
        set { priorityRaw = newValue?.rawValue }
    }

    init(
        title: String,
        order: Int,
        priority: Priority? = nil,
        dueDate: Date? = nil,
        notes: String? = nil,
        parentId: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.order = order
        self.priorityRaw = priority?.rawValue
        self.dueDate = dueDate
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.completedAt = nil
        self.parentId = parentId
    }

    var isOverdue: Bool {
        guard let dueDate, !isCompleted else { return false }
        return dueDate < Date()
    }

    var isDueToday: Bool {
        guard let dueDate else { return false }
        return Calendar.current.isDateInToday(dueDate)
    }

    var isDueThisWeek: Bool {
        guard let dueDate else { return false }
        let now = Date()
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        return dueDate >= now && dueDate <= weekFromNow
    }
}
