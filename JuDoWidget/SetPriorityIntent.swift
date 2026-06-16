import AppIntents
import Foundation
import SwiftData

struct SetPriorityIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Task Priority"
    static var description = IntentDescription("Change the priority level of a task")

    @Parameter(title: "Task ID")
    var taskId: String

    @Parameter(title: "Priority")
    var priority: PriorityIntentValue

    init() { self.taskId = ""; self.priority = .none }
    init(taskId: UUID, priority: PriorityIntentValue) {
        self.taskId = taskId.uuidString
        self.priority = priority
    }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskId) else { throw TaskIntentError.taskNotFound }

        let context = try TaskIntentHelpers.makeContext()
        guard let task = try TaskIntentHelpers.findTask(id: uuid, in: context) else {
            throw TaskIntentError.taskNotFound
        }

        task.priority = priority.toPriority()
        task.updatedAt = Date()
        try context.save()

        TaskIntentHelpers.reloadWidget()
        return .result()
    }
}

// MARK: - PriorityIntentValue

enum PriorityIntentValue: String, AppEnum {
    case high = "high"
    case medium = "medium"
    case low = "low"
    case none = "none"

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Priority")
    static var caseDisplayRepresentations: [PriorityIntentValue: DisplayRepresentation] = [
        .high:   DisplayRepresentation(title: "High",   subtitle: "🔴"),
        .medium: DisplayRepresentation(title: "Medium", subtitle: "🟠"),
        .low:    DisplayRepresentation(title: "Low",    subtitle: "⚪️"),
        .none:   DisplayRepresentation(title: "None",   subtitle: ""),
    ]

    func toPriority() -> Priority? {
        switch self {
        case .high:   return .high
        case .medium: return .medium
        case .low:    return .low
        case .none:   return nil
        }
    }

    static func from(_ priority: Priority?) -> PriorityIntentValue {
        switch priority {
        case .high:   return .high
        case .medium: return .medium
        case .low:    return .low
        case nil:     return .none
        }
    }

    func next() -> PriorityIntentValue {
        switch self {
        case .high:   return .medium
        case .medium: return .low
        case .low:    return .none
        case .none:   return .high
        }
    }
}
