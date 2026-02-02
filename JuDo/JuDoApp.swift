//
//  JuDoApp.swift
//  JuDo
//
//  Created by Abdulhakim Aloraini on 02/02/2026.
//

import SwiftUI

@main
struct JuDoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Add Task") {
                    NotificationCenter.default.post(name: .addTaskFromWidget, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        if url.scheme == "judo" && url.host == "add" {
            NotificationCenter.default.post(name: .addTaskFromWidget, object: nil)
        }
    }
}

extension Notification.Name {
    static let addTaskFromWidget = Notification.Name("addTaskFromWidget")
}
