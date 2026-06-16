import Foundation

enum TaskSortOption: String, CaseIterable, Codable, Sendable {
    case manual = "Manual"
    case priority = "Priority"
    case dueDate = "Due Date"
    case created = "Created"
    case updated = "Updated"
}
