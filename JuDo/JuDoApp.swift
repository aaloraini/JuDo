import SwiftUI
import SwiftData

@main
struct JuDoApp: App {
    @Environment(\.openWindow) private var openWindow

    private let container: ModelContainer

    init() {
        do {
            let c = try ModelContainerFactory.make()
            DataMigration.migrateIfNeeded(container: c)
            container = c
        } catch {
            print("ModelContainer failed, using in-memory fallback: \(error)")
            let schema = Schema([Task.self])
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            guard let c = try? ModelContainer(for: schema, configurations: [fallback]) else {
                fatalError("Cannot create ModelContainer even in-memory: \(error)")
            }
            container = c
        }
    }

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(container: container)
                .onOpenURL { url in
                    handleURL(url)
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                _Concurrency.Task {
                    await SyncManager.shared.refreshAccountStatus()
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .windowList) {
                Button("Show JuDo") {
                    openWindow(id: "main")
                }
                .keyboardShortcut("o", modifiers: .command)
            }

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
        if url.scheme == "judo" && url.host == "add" {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .addTaskFromWidget, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let addTaskFromWidget = Notification.Name("addTaskFromWidget")
    static let showSearch = Notification.Name("showSearch")
}
