import Foundation

/// Shared master/subtask completion semantics, used by both TaskManager (app)
/// and widget AppIntents (raw ModelContext), so all entry points behave identically.
enum TaskCompletion {
    /// When true, completing the last subtask auto-completes the master
    /// (and unchecking a subtask un-completes it).
    static let autoCompletesParent = true

    static func setCompleted(_ task: Task, _ done: Bool) {
        task.isCompleted = done
        task.completedAt = done ? Date() : nil
        task.updatedAt = Date()
    }

    /// Toggles a task. Toggling a master drives all its children to the same state;
    /// toggling a child may auto-complete or un-complete its parent.
    static func toggle(_ task: Task, children: (Task) -> [Task], parent: (Task) -> Task?) {
        let newValue = !task.isCompleted
        setCompleted(task, newValue)
        for child in children(task) where child.isCompleted != newValue {
            setCompleted(child, newValue)
        }
        if autoCompletesParent, let p = parent(task) {
            let siblings = children(p)
            let allDone = !siblings.isEmpty && siblings.allSatisfy(\.isCompleted)
            if p.isCompleted != allDone { setCompleted(p, allDone) }
        }
    }
}
