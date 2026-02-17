//
//  ToggleTaskIntent.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 10/02/2026.
//

import AppIntents
import Foundation

/// AppIntent to toggle task completion status from the widget
struct ToggleTaskIntent: AppIntent {
    
    static var title: LocalizedStringResource = "Toggle Task Completion"
    static var description = IntentDescription("Toggle the completion status of a task")
    
    @Parameter(title: "Task ID")
    var taskId: String
    
    init() {
        self.taskId = ""
    }
    
    init(taskId: UUID) {
        self.taskId = taskId.uuidString
    }
    
    func perform() async throws -> some IntentResult {
        print("[ToggleTaskIntent] Starting perform for taskId: \(taskId)")
        
        // Convert string back to UUID
        guard let uuid = UUID(uuidString: taskId) else {
            print("[ToggleTaskIntent] Failed to convert taskId to UUID")
            throw TaskIntentError.taskNotFound
        }
        
        // Load tasks
        print("[ToggleTaskIntent] Loading tasks...")
        var tasks = try TaskIntentHelpers.loadTasks()
        print("[ToggleTaskIntent] Loaded \(tasks.count) tasks")
        
        // Find the task
        guard let (_, index) = TaskIntentHelpers.findTask(withId: uuid, in: tasks) else {
            print("[ToggleTaskIntent] Task not found with ID: \(uuid)")
            throw TaskIntentError.taskNotFound
        }
        
        print("[ToggleTaskIntent] Found task at index \(index): \(tasks[index].title)")
        
        // Toggle completion status
        let wasCompleted = tasks[index].isCompleted
        tasks[index].isCompleted.toggle()
        print("[ToggleTaskIntent] Toggled completion: \(wasCompleted) -> \(tasks[index].isCompleted)")
        
        // Update timestamps
        tasks[index].updatedAt = Date()
        
        if tasks[index].isCompleted {
            // Set completedAt when marking as complete
            tasks[index].completedAt = Date()
        } else {
            // Clear completedAt when marking as incomplete
            tasks[index].completedAt = nil
        }
        
        // Save tasks
        print("[ToggleTaskIntent] Saving tasks...")
        try TaskIntentHelpers.saveTasks(tasks)
        print("[ToggleTaskIntent] Tasks saved successfully")
        
        // Reload widget
        print("[ToggleTaskIntent] Reloading widget...")
        TaskIntentHelpers.reloadWidget()
        print("[ToggleTaskIntent] Complete!")
        
        return .result()
    }
}
