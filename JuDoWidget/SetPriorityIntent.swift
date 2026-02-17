//
//  SetPriorityIntent.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 10/02/2026.
//

import AppIntents
import Foundation

/// AppIntent to set task priority from the widget
struct SetPriorityIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Set Task Priority"
    static var description = IntentDescription("Change the priority level of a task")
    
    @Parameter(title: "Task ID")
    var taskId: String
    
    @Parameter(title: "Priority")
    var priority: PriorityIntentValue
    
    init() {
        self.taskId = ""
        self.priority = .none
    }
    
    init(taskId: UUID, priority: PriorityIntentValue) {
        self.taskId = taskId.uuidString
        self.priority = priority
    }
    
    func perform() async throws -> some IntentResult {
        print("[SetPriorityIntent] Starting perform for taskId: \(taskId), priority: \(priority)")
        
        // Convert string back to UUID
        guard let uuid = UUID(uuidString: taskId) else {
            print("[SetPriorityIntent] Failed to convert taskId to UUID")
            throw TaskIntentError.taskNotFound
        }
        
        // Load tasks
        print("[SetPriorityIntent] Loading tasks...")
        var tasks = try TaskIntentHelpers.loadTasks()
        print("[SetPriorityIntent] Loaded \(tasks.count) tasks")
        
        // Find the task
        guard let (_, index) = TaskIntentHelpers.findTask(withId: uuid, in: tasks) else {
            print("[SetPriorityIntent] Task not found with ID: \(uuid)")
            throw TaskIntentError.taskNotFound
        }
        
        print("[SetPriorityIntent] Found task at index \(index): \(tasks[index].title)")
        
        // Update priority
        let oldPriority = tasks[index].priority
        tasks[index].priority = priority.toPriority()
        print("[SetPriorityIntent] Updated priority: \(String(describing: oldPriority)) -> \(String(describing: tasks[index].priority))")
        
        // Update timestamp
        tasks[index].updatedAt = Date()
        
        // Save tasks
        print("[SetPriorityIntent] Saving tasks...")
        try TaskIntentHelpers.saveTasks(tasks)
        print("[SetPriorityIntent] Tasks saved successfully")
        
        // Reload widget
        print("[SetPriorityIntent] Reloading widget...")
        TaskIntentHelpers.reloadWidget()
        print("[SetPriorityIntent] Complete!")
        
        return .result()
    }
}

// MARK: - Priority Intent Value

/// AppIntent-compatible priority enum
enum PriorityIntentValue: String, AppEnum {
    case high = "high"
    case medium = "medium"
    case low = "low"
    case none = "none"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Priority")
    
    static var caseDisplayRepresentations: [PriorityIntentValue: DisplayRepresentation] = [
        .high: DisplayRepresentation(title: "High", subtitle: "🔴"),
        .medium: DisplayRepresentation(title: "Medium", subtitle: "🟠"),
        .low: DisplayRepresentation(title: "Low", subtitle: "⚪️"),
        .none: DisplayRepresentation(title: "None", subtitle: "")
    ]
    
    /// Convert to Task Priority
    func toPriority() -> Priority? {
        switch self {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        case .none: return nil
        }
    }
    
    /// Create from Task Priority
    static func from(_ priority: Priority?) -> PriorityIntentValue {
        guard let priority = priority else { return .none }
        switch priority {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
    
    /// Get next priority in cycle: High → Medium → Low → None → High
    func next() -> PriorityIntentValue {
        switch self {
        case .high: return .medium
        case .medium: return .low
        case .low: return .none
        case .none: return .high
        }
    }
}
