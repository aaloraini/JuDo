import Foundation
import SwiftData

enum ModelContainerFactory {
    static private(set) var isCloudKitActive: Bool = false
    static private(set) var containerError: String?

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

        isCloudKitActive = false
        containerError = nil

        guard isCloudKitSyncEnabled else {
            let config = ModelConfiguration(schema: schema, url: storeURL)
            return try ModelContainer(for: schema, configurations: config)
        }

        do {
            let container = try makeCloudKitContainer(schema: schema, storeURL: storeURL)
            isCloudKitActive = true
            return container
        } catch {
            print("[JuDo] CloudKit container failed: \(error)")
            // Incompatible store (e.g. schema change between TestFlight and App Store).
            // Delete and retry; CloudKit will re-sync the data.
            deleteStoreFiles(at: storeURL)
            do {
                let container = try makeCloudKitContainer(schema: schema, storeURL: storeURL)
                isCloudKitActive = true
                print("[JuDo] CloudKit container succeeded after store reset")
                return container
            } catch {
                print("[JuDo] CloudKit container failed after store reset, falling back to local: \(error)")
                containerError = error.localizedDescription
                let config = ModelConfiguration(schema: schema, url: storeURL)
                return try ModelContainer(for: schema, configurations: config)
            }
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

    private static func deleteStoreFiles(at storeURL: URL) {
        let fm = FileManager.default
        let dir = storeURL.deletingLastPathComponent()
        let baseName = storeURL.lastPathComponent
        for suffix in ["", "-shm", "-wal"] {
            try? fm.removeItem(at: dir.appendingPathComponent(baseName + suffix))
        }
        let ckAssets = dir.appendingPathComponent(baseName.replacingOccurrences(of: ".store", with: "_ckAssets"))
        try? fm.removeItem(at: ckAssets)
    }

    // Widget provider and AppIntents: local store only, no CloudKit overhead
    static func makeWidget() throws -> ModelContainer {
        let schema = Schema([Task.self])
        let config = ModelConfiguration(schema: schema, url: sharedStoreURL)
        return try ModelContainer(for: schema, configurations: config)
    }
}
