import CloudKit
import CoreData
import Combine
import SwiftUI

@MainActor
final class SyncManager: ObservableObject {
    static let shared = SyncManager()
    static let containerIdentifier = "iCloud.com.aloraini.JuDo"
    static let syncEnabledKey = "iCloudSyncEnabled"
    static let suiteName = "group.com.aloraini.JuDo"

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var lastSyncDate: Date?
    @Published var isSyncing: Bool = false
    @Published var lastError: String?

    @AppStorage(SyncManager.syncEnabledKey, store: UserDefaults(suiteName: SyncManager.suiteName))
    var isSyncEnabled: Bool = true

    enum Status {
        case synced(lastSync: Date?)
        case syncing
        case error(String)
        case localOnly(reason: String?)
        case off
        case unavailable

        var title: String {
            switch self {
            case .synced:      return "Synced to iCloud"
            case .syncing:     return "Syncing..."
            case .error:       return "Sync Error"
            case .localOnly:   return "Local Only"
            case .off:         return "iCloud Sync Off"
            case .unavailable: return "iCloud Unavailable"
            }
        }

        var detail: String {
            switch self {
            case .synced(let lastSync):
                if let date = lastSync {
                    let formatter = RelativeDateTimeFormatter()
                    formatter.unitsStyle = .full
                    return "Last synced \(formatter.localizedString(for: date, relativeTo: Date()))"
                }
                return "Your tasks are backed up and kept in sync across your devices."
            case .syncing:
                return "Syncing your tasks with iCloud..."
            case .error(let message):
                return message
            case .localOnly(let reason):
                return reason ?? "iCloud sync could not start. Your tasks are stored only on this device."
            case .off:
                return "Your tasks are stored only on this device."
            case .unavailable:
                return "Sign in to iCloud in System Settings to sync your tasks."
            }
        }

        var symbolName: String {
            switch self {
            case .synced:      return "icloud.fill"
            case .syncing:     return "arrow.triangle.2.circlepath.icloud"
            case .error:       return "exclamationmark.icloud"
            case .localOnly:   return "icloud.slash"
            case .off:         return "icloud.slash"
            case .unavailable: return "exclamationmark.icloud"
            }
        }
    }

    var status: Status {
        guard isSyncEnabled else { return .off }
        guard accountStatus == .available else { return .unavailable }
        guard ModelContainerFactory.isCloudKitActive else {
            return .localOnly(reason: ModelContainerFactory.containerError)
        }
        if isSyncing { return .syncing }
        if let error = lastError { return .error(error) }
        return .synced(lastSync: lastSyncDate)
    }

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleCloudKitEvent(_:)),
            name: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil
        )
    }

    @objc private func handleCloudKitEvent(_ notification: Notification) {
        guard let event = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                as? NSPersistentCloudKitContainer.Event else { return }

        if let error = event.error, event.endDate != nil {
            print("[JuDo Sync] failed: \(error)")
        }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if event.endDate == nil {
                self.isSyncing = true
            } else {
                self.isSyncing = false
                if event.succeeded {
                    self.lastSyncDate = event.endDate
                    self.lastError = nil
                } else if let error = event.error {
                    self.lastError = error.localizedDescription
                }
            }
        }
    }

    func refreshAccountStatus() async {
        let container = CKContainer(identifier: Self.containerIdentifier)
        accountStatus = (try? await container.accountStatus()) ?? .couldNotDetermine
    }
}
