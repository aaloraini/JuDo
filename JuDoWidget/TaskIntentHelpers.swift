//
//  TaskIntentHelpers.swift
//  JuDoWidget
//
//  Created by Abdulhakim Aloraini on 10/02/2026.
//

import Foundation
import WidgetKit

/// Shared utilities for AppIntents to interact with task data
enum TaskIntentHelpers {
    
    // MARK: - Constants
    
    static let suiteName = "group.com.aloraini.JuDo"
    static let tasksKey = "tasks"
    
    // MARK: - Task Loading
    
    /// Load tasks from shared UserDefaults
    static func loadTasks() throws -> [Task] {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName) else {
            throw TaskIntentError.sharedDefaultsUnavailable
        }
        
        guard let data = sharedDefaults.data(forKey: tasksKey) else {
            // No tasks yet - return empty array
            return []
        }
        
        do {
            let tasks = try JSONDecoder().decode([Task].self, from: data)
            return tasks
        } catch {
            throw TaskIntentError.decodingFailed(error)
        }
    }
    
    // MARK: - Task Saving
    
    /// Save tasks to shared UserDefaults
    static func saveTasks(_ tasks: [Task]) throws {
        guard let sharedDefaults = UserDefaults(suiteName: suiteName) else {
            throw TaskIntentError.sharedDefaultsUnavailable
        }
        
        do {
            let data = try JSONEncoder().encode(tasks)
            sharedDefaults.set(data, forKey: tasksKey)
            
            // Force synchronization
            sharedDefaults.synchronize()
        } catch {
            throw TaskIntentError.encodingFailed(error)
        }
    }
    
    // MARK: - Widget Reload
    
    /// Reload widget timeline to reflect changes
    static func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: "JuDoWidget")
    }
    
    // MARK: - Task Finding
    
    /// Find task by ID in array
    static func findTask(withId id: UUID, in tasks: [Task]) -> (task: Task, index: Int)? {
        guard let index = tasks.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return (tasks[index], index)
    }
}

// MARK: - Error Types

enum TaskIntentError: Error, LocalizedError {
    case sharedDefaultsUnavailable
    case taskNotFound
    case decodingFailed(Error)
    case encodingFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .sharedDefaultsUnavailable:
            return "Unable to access shared storage"
        case .taskNotFound:
            return "Task not found"
        case .decodingFailed(let error):
            return "Failed to load tasks: \(error.localizedDescription)"
        case .encodingFailed(let error):
            return "Failed to save tasks: \(error.localizedDescription)"
        }
    }
}
