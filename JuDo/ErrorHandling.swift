import Foundation
import SwiftUI
import Combine

// MARK: - Error Types

enum JuDoError: LocalizedError {
    case taskCreationFailed(String)
    case taskDeletionFailed(String)
    case taskUpdateFailed(String)
    case dataCorruption(String)
    case persistenceError(String)
    case widgetError(String)
    case appGroupsError(String)
    case unknownError(String)

    var errorDescription: String? {
        switch self {
        case .taskCreationFailed(let m):  return "Failed to create task: \(m)"
        case .taskDeletionFailed(let m):  return "Failed to delete task: \(m)"
        case .taskUpdateFailed(let m):    return "Failed to update task: \(m)"
        case .dataCorruption(let m):      return "Data corruption detected: \(m)"
        case .persistenceError(let m):    return "Failed to save data: \(m)"
        case .widgetError(let m):         return "Widget error: \(m)"
        case .appGroupsError(let m):      return "App Groups error: \(m)"
        case .unknownError(let m):        return "Unexpected error: \(m)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .taskCreationFailed:  return "Please try again or restart the app if the problem persists."
        case .taskDeletionFailed:  return "Please try again or check if the task still exists."
        case .taskUpdateFailed:    return "Please try again or restart the app if the problem persists."
        case .dataCorruption:      return "Please restart the app. If the problem continues, you may need to reinstall the app."
        case .persistenceError:    return "Please check your storage space and try again."
        case .widgetError:         return "Please try refreshing the widget or restart the app."
        case .appGroupsError:      return "Please restart the app and ensure widgets have proper permissions."
        case .unknownError:        return "Please restart the app and try again."
        }
    }
}

// MARK: - Error Manager

class ErrorManager: ObservableObject {
    static let shared = ErrorManager()

    @Published var currentError: JuDoError?
    @Published var showError = false

    private init() {}

    func handle(_ error: JuDoError) {
        DispatchQueue.main.async {
            self.currentError = error
            self.showError = true
            self.logError(error)
        }
    }

    func handle(_ error: Error) {
        if let juDoError = error as? JuDoError {
            handle(juDoError)
        } else {
            handle(JuDoError.unknownError(error.localizedDescription))
        }
    }

    func dismissError() {
        currentError = nil
        showError = false
    }

    private func logError(_ error: JuDoError) {
        #if DEBUG
        let timestamp = ISO8601DateFormatter().string(from: Date())
        print("[\(timestamp)] JuDoError: \(error.errorDescription ?? "Unknown error")")
        #endif
    }
}

// MARK: - TaskManager safe wrappers

extension TaskManager {
    func safeAddTask(title: String, priority: Priority? = nil, dueDate: Date? = nil, subtaskTitles: [String] = []) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            ErrorManager.shared.handle(JuDoError.taskCreationFailed("Task title is empty"))
            return
        }
        addTask(title: title, priority: priority, dueDate: dueDate, subtaskTitles: subtaskTitles)
    }

    func safeAddSubtask(to parent: Task, title: String) {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            ErrorManager.shared.handle(JuDoError.taskCreationFailed("Task title is empty"))
            return
        }
        addSubtask(to: parent, title: title)
    }

    func safeDeleteTask(_ task: Task) {
        deleteTask(task)
    }

    func safeToggleTaskCompletion(_ task: Task) {
        guard tasks.contains(where: { $0.id == task.id }) else {
            ErrorManager.shared.handle(JuDoError.taskUpdateFailed("Task not found"))
            return
        }
        toggleTaskCompletion(task)
    }

    func safeMoveTask(from source: IndexSet, to destination: Int) {
        moveTask(from: source, to: destination)
    }
}
