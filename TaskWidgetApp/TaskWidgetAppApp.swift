//
//  TaskWidgetAppApp.swift
//  TaskWidgetApp
//
//  Main application entry point and deep link handling
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import SwiftUI

@main
struct TaskWidgetAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }

    private func handleDeepLink(_ url: URL) {
        // Handle the deep link from widget
        if url.scheme == "taskwidget" && url.host == "add" {
            // Post notification to focus text field
            NotificationCenter.default.post(name: NSNotification.Name("FocusTaskField"), object: nil)
        }
    }
}
