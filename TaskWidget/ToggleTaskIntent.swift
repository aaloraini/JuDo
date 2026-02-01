//
//  ToggleTaskIntent.swift
//  TaskWidget
//
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import AppIntents
import WidgetKit
import Foundation

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Task"
    static var description = IntentDescription("Toggle completion of a task")
    
    @Parameter(title: "Task ID", description: "ID of the task to toggle")
    var taskID: String
    
    init() {}
    
    init(taskID: String) {
        self.taskID = taskID
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<Bool> {
        guard let uuid = UUID(uuidString: taskID) else {
            throw NSError(domain: "ToggleTaskIntent", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Invalid task ID"])
        }
        
        // Get current state before toggling
        let (items, _) = await DataStore.shared.load()
        let _ = items.first { $0.id == uuid }?.isDone ?? false // Store for feedback (not used in widget)
        
        // Toggle the task
        let updatedItems = await DataStore.shared.toggleTask(with: uuid)
        let success = updatedItems.contains { $0.id == uuid }
        
        // Note: Widget extensions cannot use NSHapticFeedbackManager or NSSound
        // These would need to be triggered from the main app if desired
        
        // Refresh widget UI
        WidgetCenter.shared.reloadTimelines(ofKind: "TaskWidget")

        return .result(value: success)
    }
}
