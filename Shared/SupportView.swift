import SwiftUI
import StoreKit
import Combine

struct SupportView: View {
    @StateObject private var store: StoreManager
    @StateObject private var leaderboard: LeaderboardManager
    @State private var showingNameSheet = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    init() {
        let leaderboard = LeaderboardManager()
        _leaderboard = StateObject(wrappedValue: leaderboard)
        _store = StateObject(wrappedValue: StoreManager { amount in
            try await leaderboard.addMon(amount)
        })
    }

    private var monIcon: String { colorScheme == .dark ? "Mon_Dark" : "Mon_Light" }

    var body: some View {
#if os(macOS)
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                Divider().padding(.horizontal, 20)
                tierSection
                Divider().padding(.horizontal, 20)
                leaderboardSection
            }
        }
        .frame(width: 480, height: 580)
#else
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    tierSection
                    leaderboardSection
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Support JuDo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
#endif
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 20) {
            Image(monIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .shadow(color: .orange.opacity(0.3), radius: 12, y: 4)

            VStack(spacing: 8) {
                Text("You make JuDo possible")
                    .font(.title2).bold()
                    .multilineTextAlignment(.center)
                Text("Every Mon goes directly into making JuDo\nbetter. Seriously, thank you.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            if leaderboard.currentUserEntry != nil {
                statsCard
            }

            HStack(spacing: 12) {
                Button {
                    showingNameSheet = true
                } label: {
                    Label(
                        leaderboard.currentUserEntry?.displayName != nil ? "Change Display Name" : "Set Your Name",
                        systemImage: "person.crop.circle"
                    )
                }
                .buttonStyle(.bordered)

                Link(destination: URL(string: "https://github.com/aaloraini/JuDo")!) {
                    Label("GitHub", systemImage: "arrow.up.right.square")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .sheet(isPresented: $showingNameSheet) {
            SetNameView(leaderboard: leaderboard)
        }
        .task {
            await store.loadProducts()
            await leaderboard.setup()
            await store.recoverUnfinished()
        }
    }

    private var statsCard: some View {
        HStack(spacing: 0) {
            statPill(
                value: "\(leaderboard.currentUserEntry?.totalMon ?? 0) Mon",
                label: "contributed",
                icon: monIcon
            )

            Divider().frame(height: 40)

            statPill(
                value: leaderboard.currentRank.map { "#\($0)" } ?? "--",
                label: "your rank",
                color: .orange
            )

            if let name = leaderboard.currentUserEntry?.displayName,
               name != "Anonymous" {
                Divider().frame(height: 40)
                statPill(value: name, label: "display name")
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private func statPill(value: String, label: String, icon: String? = nil, color: Color = .primary) -> some View {
        VStack(spacing: 3) {
            if let icon {
                HStack(spacing: 4) {
                    Image(icon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                    Text(value)
                        .font(.subheadline).bold()
                        .foregroundStyle(color)
                }
            } else {
                Text(value)
                    .font(.subheadline).bold()
                    .foregroundStyle(color)
                    .lineLimit(1)
            }
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tiers

    private var tierSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Buy Mon", subtitle: "One-time purchases, no subscription")

            if store.products.isEmpty {
                HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 24)
            } else {
                VStack(spacing: 10) {
                    ForEach(store.products, id: \.id) { product in
                        TierCard(product: product, store: store, monIcon: monIcon)
                    }
                }
            }

            if let error = store.purchaseError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
    }

    // MARK: - Leaderboard

    private var leaderboardSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Top Supporters", subtitle: "Thank you all, from the bottom of my heart")

            if leaderboard.isLoading && leaderboard.entries.isEmpty {
                HStack { Spacer(); ProgressView(); Spacer() }.padding(.vertical, 24)
            } else if leaderboard.entries.isEmpty {
                Text("No supporters yet -- you could be first!")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 0) {
                    ForEach(leaderboard.entries) { entry in
                        LeaderboardRow(
                            entry: entry,
                            isCurrentUser: entry.id == leaderboard.currentUserEntry?.id,
                            monIcon: monIcon
                        )
                        if entry.id != leaderboard.entries.last?.id {
                            Divider().padding(.leading, 60)
                        }
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.headline)
            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Tier Card

private struct TierCard: View {
    let product: Product
    let store: StoreManager
    let monIcon: String

    private var tier: MonTier? { MonTier.all.first(where: { $0.id == product.id }) }

    var body: some View {
        HStack(spacing: 12) {
            Image(monIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)

            Text(tier?.label ?? product.displayName)
                .font(.body).bold()

            Spacer()

            Button(product.displayPrice) {
                _Concurrency.Task {
                    await store.purchase(product)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.isPurchasing)
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Leaderboard Row

private struct LeaderboardRow: View {
    let entry: LeaderboardManager.Entry
    let isCurrentUser: Bool
    let monIcon: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(rankColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(rankLabel)
                    .font(.caption).bold()
                    .foregroundStyle(rankColor)
            }

            Text(entry.displayName)
                .font(.body)
                .fontWeight(isCurrentUser ? .semibold : .regular)
                .lineLimit(1)

            Spacer()

            HStack(spacing: 4) {
                Image(monIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14, height: 14)
                    .opacity(0.6)
                Text("\(entry.totalMon)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(isCurrentUser ? Color.accentColor.opacity(0.07) : .clear)
    }

    private var rankLabel: String {
        switch entry.rank {
        case 1: return "1st"
        case 2: return "2nd"
        case 3: return "3rd"
        default: return "#\(entry.rank)"
        }
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return Color(white: 0.55)
        case 3: return .orange
        default: return .secondary
        }
    }
}

// MARK: - Set Name Sheet

struct SetNameView: View {
    @ObservedObject var leaderboard: LeaderboardManager
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var validationError: String?
    @State private var isSaving = false
    @State private var saveError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Display name", text: $name)
                        .onChange(of: name) { _, value in
                            validationError = BadWordFilter.validate(value)
                        }
                } footer: {
                    if let msg = validationError {
                        Text(msg).foregroundStyle(.red)
                    } else {
                        Text("\(name.count)/\(BadWordFilter.maxLength)")
                            .foregroundStyle(.secondary)
                    }
                }

                if let days = leaderboard.daysUntilNameChange {
                    Section {
                        Label(
                            "Name can be changed again in \(days) day\(days == 1 ? "" : "s")",
                            systemImage: "clock"
                        )
                        .foregroundStyle(.secondary)
                    }
                }

                if let error = saveError {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Display Name")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(
                            name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            || validationError != nil
                            || isSaving
                            || leaderboard.daysUntilNameChange != nil
                        )
                }
            }
            .onAppear {
                if let current = leaderboard.currentUserEntry?.displayName, current != "Anonymous" {
                    name = current
                }
            }
        }
    }

    private func save() {
        isSaving = true
        saveError = nil
        _Concurrency.Task {
            do {
                try await leaderboard.setDisplayName(name)
                dismiss()
            } catch {
                saveError = error.localizedDescription
            }
            isSaving = false
        }
    }
}
