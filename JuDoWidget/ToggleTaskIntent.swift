import AppIntents
import Foundation
import SwiftData

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task Completion"
    static var description = IntentDescription("Toggle the completion status of a task")

    @Parameter(title: "Task ID")
    var taskId: String

    init() { self.taskId = "" }
    init(taskId: UUID) { self.taskId = taskId.uuidString }

    func perform() async throws -> some IntentResult {
        guard let uuid = UUID(uuidString: taskId) else { throw TaskIntentError.taskNotFound }

        let context = try TaskIntentHelpers.makeContext()
        guard let task = try TaskIntentHelpers.findTask(id: uuid, in: context) else {
            throw TaskIntentError.taskNotFound
        }

        task.isCompleted.toggle()
        task.updatedAt = Date()
        task.completedAt = task.isCompleted ? Date() : nil
        try context.save()

        TaskIntentHelpers.reloadWidget()
        return .result()
    }
}
