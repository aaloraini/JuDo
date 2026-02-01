//
//  AddTaskIntent.swift
//  TaskWidget
//
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import AppIntents
import WidgetKit
import Foundation
import AppKit

struct AddTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Task"
    static var description = IntentDescription("Open the main app to add a new task")
    
    init() {}
    
    func perform() async throws -> some IntentResult {
        // Open the main app using URL scheme
        if let url = URL(string: "taskwidget://add") {
            await NSWorkspace.shared.open(url)
        }
        
        return .result()
    }
}
