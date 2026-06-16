import SwiftUI

struct SyncStatusView: View {
    @StateObject private var syncManager = SyncManager()
    @Environment(\.dismiss) private var dismiss
    @State private var initialSyncEnabled: Bool?

    var body: some View {
#if os(macOS)
        content
            .frame(width: 380, height: 320)
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
            Image(systemName: syncManager.status.symbolName)
                .font(.system(size: 40))
                .foregroundStyle(statusColor)
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

    private var statusColor: Color {
        switch syncManager.status {
        case .synced:      return .green
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
}

#Preview {
    SyncStatusView()
}
