import SwiftUI

struct SyncStatusView: View {
    @ObservedObject private var syncManager = SyncManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var initialSyncEnabled: Bool?

    var body: some View {
#if os(macOS)
        content
            .frame(width: 380, height: 380)
#else
        NavigationStack {
            content
                .navigationTitle("iCloud Sync")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
#endif
    }

    private var content: some View {
        VStack(spacing: 24) {
            statusSection

            Toggle("Sync Tasks via iCloud", isOn: $syncManager.isSyncEnabled)
                .padding(.horizontal, 24)

            if let initialSyncEnabled, initialSyncEnabled != syncManager.isSyncEnabled {
                restartNotice
            }

            widgetNote

            Spacer()
        }
        .padding(.top, 28)
        .task {
            if initialSyncEnabled == nil {
                initialSyncEnabled = syncManager.isSyncEnabled
            }
            await syncManager.refreshAccountStatus()
        }
    }

    private var statusSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Image(systemName: syncManager.status.symbolName)
                    .font(.system(size: 40))
                    .foregroundStyle(statusColor)
                    .opacity(isSyncing ? 0.5 : 1.0)

                if isSyncing {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            Text(syncManager.status.title)
                .font(.title3).bold()
            Text(syncManager.status.detail)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
        }
        .padding(.horizontal, 24)
    }

    private var isSyncing: Bool {
        if case .syncing = syncManager.status { return true }
        return false
    }

    private var statusColor: Color {
        switch syncManager.status {
        case .synced:      return .green
        case .syncing:     return .blue
        case .error:       return .red
        case .localOnly:   return .orange
        case .off:         return .secondary
        case .unavailable: return .orange
        }
    }

    private var restartNotice: some View {
        VStack(spacing: 12) {
            Label("Restart JuDo for this change to take effect.", systemImage: "arrow.clockwise")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)

#if os(macOS)
            Button("Quit JuDo") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.bordered)
#endif
        }
        .padding(.horizontal, 24)
    }

    private var widgetNote: some View {
        Group {
            if syncManager.isSyncEnabled {
                Label("Changes made via the widget sync when the app is opened.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 320)
                    .padding(.horizontal, 24)
            }
        }
    }
}

#Preview {
    SyncStatusView()
}
