//
//  SettingsView.swift
//  TaskWidgetApp
//
//  Application settings and preferences interface
//  Created by Abdulhakim Aloraini on 13/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @AppStorage("widgetRefreshRate") private var widgetRefreshRate = 30
    @AppStorage("enableHaptics") private var enableHaptics = true
    @AppStorage("enableSounds") private var enableSounds = false

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            AppearanceSettingsView()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "wrench.and.screwdriver")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("showInMenuBar") private var showInMenuBar = false
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("enableHaptics") private var enableHaptics = true

    var body: some View {
        Form {
            Toggle("Show in Menu Bar", isOn: $showInMenuBar)
                .help("Show a menu bar icon for quick access")

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .help("Automatically start the app when you log in")

            Toggle("Haptic Feedback", isOn: $enableHaptics)
                .help("Provide haptic feedback when toggling tasks")

            Divider()

            LabeledContent("Version") {
                Text("1.0.0")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("accentColor") private var accentColor = "blue"
    @AppStorage("theme") private var theme = "auto"
    @AppStorage("compactMode") private var compactMode = false

    let colors = ["blue", "green", "purple", "orange", "red"]
    let themes = ["auto", "light", "dark"]

    var body: some View {
        Form {
            Picker("Accent Color", selection: $accentColor) {
                ForEach(colors, id: \.self) { color in
                    Label(color.capitalized, systemImage: "circle.fill")
                        .foregroundColor(Color(color))
                }
            }

            Picker("Theme", selection: $theme) {
                ForEach(themes, id: \.self) { theme in
                    Text(theme.capitalized)
                }
            }

            Toggle("Compact Mode", isOn: $compactMode)
                .help("Use more compact spacing in lists")

            Divider()

            Button("Reset to Defaults") {
                accentColor = "blue"
                theme = "auto"
                compactMode = false
            }
        }
        .padding()
    }
}

struct AdvancedSettingsView: View {
    @AppStorage("widgetRefreshRate") private var widgetRefreshRate = 30
    @AppStorage("exportFormat") private var exportFormat = "plain"
    @AppStorage("debugMode") private var debugMode = false

    var body: some View {
        Form {
            LabeledContent("Widget Refresh") {
                Picker("", selection: $widgetRefreshRate) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("60 minutes").tag(60)
                    Text("Manual").tag(0)
                }
                .labelsHidden()
                .frame(width: 150)
            }

            Picker("Export Format", selection: $exportFormat) {
                Text("Plain Text").tag("plain")
                Text("Markdown").tag("markdown")
                Text("JSON").tag("json")
                Text("CSV").tag("csv")
            }

            Toggle("Debug Mode", isOn: $debugMode)
                .help("Show debugging information")

            if debugMode {
                Divider()

                Button("Clear All Data") {
                    // Implement data clearing
                }
                .foregroundColor(.red)
            }
        }
        .padding()
    }
}
