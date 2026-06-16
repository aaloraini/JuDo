import CloudKit
import Combine
import SwiftUI

@MainActor
final class SyncManager: ObservableObject {
    static let containerIdentifier = "iCloud.com.aloraini.JuDo"
    static let syncEnabledKey = "iCloudSyncEnabled"
    static let suiteName = "group.com.aloraini.JuDo"

    @Published var accountStatus: CKAccountStatus = .couldNotDetermine

    @AppStorage(SyncManager.syncEnabledKey, store: UserDefaults(suiteName: SyncManager.suiteName))
    var isSyncEnabled: Bool = true

    enum Status {
        case synced
        case off
        case unavailable

        var title: String {
            switch self {
            case .synced:      return "Synced to iCloud"
            case .off:         return "iCloud Sync Off"
            case .unavailable: return "iCloud Unavailable"
            }
        }

        var detail: String {
            switch self {
            case .synced:
                return "Your tasks are backed up and kept in sync across your devices."
            case .off:
                return "Your tasks are stored only on this device."
            case .unavailable:
                return "Sign in to iCloud in System Settings to sync your tasks."
            }
        }

        var symbolName: String {
            switch self {
            case .synced:      return "icloud.fill"
            case .off:         return "icloud.slash"
            case .unavailable: return "exclamationmark.icloud"
            }
        }
    }

    var status: Status {
        guard isSyncEnabled else { return .off }
        return accountStatus == .available ? .synced : .unavailable
    }

    func refreshAccountStatus() async {
        let container = CKContainer(identifier: Self.containerIdentifier)
        accountStatus = (try? await container.accountStatus()) ?? .couldNotDetermine
    }
}
