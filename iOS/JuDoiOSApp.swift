import SwiftUI
import SwiftData

@main
struct JuDoiOSApp: App {
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
        WindowGroup {
            TaskListView(container: container)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                _Concurrency.Task {
                    await SyncManager.shared.refreshAccountStatus()
                }
            }
        }
    }
}
