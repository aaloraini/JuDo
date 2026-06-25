import Foundation
import SwiftData

enum ModelContainerFactory {
    private static var sharedStoreURL: URL {
        let appGroup = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.aloraini.JuDo")
        let base = appGroup ?? FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("judo.store")
    }

    // Main app and iOS app: CloudKit sync with local fallback
    static func make() throws -> ModelContainer {
        let schema = Schema([Task.self])
        let storeURL = sharedStoreURL

        guard isCloudKitSyncEnabled else {
            let config = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: config)
        }

        do {
            return try makeCloudKitContainer(schema: schema, storeURL: storeURL)
        } catch {
            print("[JuDo] CloudKit container failed, falling back to local: \(error)")
            let config = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: config)
        }
    }

    private static var isCloudKitSyncEnabled: Bool {
        let defaults = UserDefaults(suiteName: SyncManager.suiteName)
        return defaults?.object(forKey: SyncManager.syncEnabledKey) as? Bool ?? true
    }

    private static func makeCloudKitContainer(schema: Schema, storeURL: URL) throws -> ModelContainer {
        let config = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .private("iCloud.com.aloraini.JuDo")
        )
        return try ModelContainer(for: schema, configurations: config)
    }

    // Widget provider and AppIntents: local store only, no CloudKit overhead
    static func makeWidget() throws -> ModelContainer {
        let schema = Schema([Task.self])
        let config = ModelConfiguration(schema: schema, url: sharedStoreURL)
        return try ModelContainer(for: schema, configurations: config)
    }
}
