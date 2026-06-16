import SwiftUI
import SwiftData

@main
struct JuDoiOSApp: App {
    private let container: ModelContainer = {
        do {
            return try ModelContainerFactory.make()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            TaskListView(container: container)
        }
    }
}
