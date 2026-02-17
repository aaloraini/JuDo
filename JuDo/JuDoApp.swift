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
                .onOpenURL { url in
                    handleURL(url)
                }
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
            
            CommandGroup(after: .textEditing) {
                Button("Find Tasks") {
                    NotificationCenter.default.post(name: .showSearch, object: nil)
                }
                .keyboardShortcut("f", modifiers: .command)
            }
        }
    }
    
    private func handleURL(_ url: URL) {
        print("Received URL: \(url)")
        
        if url.scheme == "judo" && url.host == "add" {
            print("Opening add task dialog from widget")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .addTaskFromWidget, object: nil)
            }
        } else {
            print("Unsupported URL scheme or host: \(url.scheme ?? "nil")://\(url.host ?? "nil")")
        }
    }
}

extension Notification.Name {
    static let addTaskFromWidget = Notification.Name("addTaskFromWidget")
    static let showSearch = Notification.Name("showSearch")
}
