import Foundation
import SwiftData
import WidgetKit

enum TaskIntentHelpers {
    static func makeContext() throws -> ModelContext {
        let container = try ModelContainerFactory.makeWidget()
        return ModelContext(container)
    }

    static func findTask(id: UUID, in context: ModelContext) throws -> Task? {
        let descriptor = FetchDescriptor<Task>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }

    static func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
    }
}

// MARK: - Error Types

enum TaskIntentError: Error, LocalizedError {
    case taskNotFound
    case contextUnavailable

    var errorDescription: String? {
        switch self {
        case .taskNotFound:        return "Task not found"
        case .contextUnavailable:  return "Unable to access task storage"
        }
    }
}
