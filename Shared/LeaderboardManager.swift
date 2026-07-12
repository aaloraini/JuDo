import CloudKit
import Combine
import Foundation

@MainActor
final class LeaderboardManager: ObservableObject {
    @Published var entries: [Entry] = []
    @Published var currentUserEntry: Entry?
    @Published var isLoading = false
    @Published var errorMessage: String?

    struct Entry: Identifiable, Equatable {
        let id: String
        var displayName: String
        var totalMon: Int
        var lastNameChange: Date?
        var rank: Int = 0
    }

    private let ckContainer = CKContainer(identifier: "iCloud.com.aloraini.JuDo")
    private var db: CKDatabase { ckContainer.publicCloudDatabase }
    private var userRecordID: CKRecord.ID?
    private let cooldownDays = 7

    var currentRank: Int? {
        guard let current = currentUserEntry else { return nil }
        return entries.first(where: { $0.id == current.id })?.rank
    }

    var daysUntilNameChange: Int? {
        guard let last = currentUserEntry?.lastNameChange else { return nil }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? cooldownDays
        let remaining = cooldownDays - days
        return remaining > 0 ? remaining : nil
    }

    func setup() async {
        await fetchUser()
        await fetchLeaderboard()
    }

    func fetchLeaderboard() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let query = CKQuery(recordType: "Supporter", predicate: NSPredicate(format: "totalMon > 0"))
        query.sortDescriptors = [NSSortDescriptor(key: "totalMon", ascending: false)]

        do {
            let result = try await db.records(matching: query, resultsLimit: 50)
            var fetched: [Entry] = []
            for (_, res) in result.matchResults {
                if let record = try? res.get() {
                    fetched.append(Entry(record))
                }
            }
            entries = fetched.enumerated().map { i, e in
                var ranked = e; ranked.rank = i + 1; return ranked
            }
            syncCurrentUserRank()
        } catch {
            errorMessage = "Could not load leaderboard"
        }
    }

    func addMon(_ amount: Int) async throws {
        if userRecordID == nil { await fetchUser() }
        guard let userRecordID else { throw LBError.notSignedIn }
        let record = await fetchOrNew(id: supporterID(for: userRecordID))
        let current = record["totalMon"] as? Int ?? 0
        record["totalMon"] = current + amount
        record["lastUpdated"] = Date()
        if record["displayName"] == nil { record["displayName"] = "Anonymous" }
        let saved = try await db.save(record)
        currentUserEntry = Entry(saved)
        await fetchLeaderboard()
    }

    func setDisplayName(_ name: String) async throws {
        if let error = BadWordFilter.validate(name) { throw LBError.invalidName(error) }
        if let days = daysUntilNameChange { throw LBError.cooldown(days) }
        guard let userRecordID else { throw LBError.notSignedIn }
        let record = await fetchOrNew(id: supporterID(for: userRecordID))
        record["displayName"] = name
        record["lastNameChange"] = Date()
        record["lastUpdated"] = Date()
        let saved = try await db.save(record)
        currentUserEntry = Entry(saved)
    }

    // MARK: - Private

    private func fetchUser() async {
        guard let id = try? await ckContainer.userRecordID() else { return }
        userRecordID = id
        if let record = try? await db.record(for: supporterID(for: id)) {
            currentUserEntry = Entry(record)
        }
    }

    private func supporterID(for userID: CKRecord.ID) -> CKRecord.ID {
        CKRecord.ID(recordName: "s_\(userID.recordName)")
    }

    private func fetchOrNew(id: CKRecord.ID) async -> CKRecord {
        (try? await db.record(for: id)) ?? CKRecord(recordType: "Supporter", recordID: id)
    }

    private func syncCurrentUserRank() {
        guard let current = currentUserEntry,
              let match = entries.first(where: { $0.id == current.id }) else { return }
        currentUserEntry = match
    }
}

private extension LeaderboardManager.Entry {
    init(_ record: CKRecord) {
        self.init(
            id: record.recordID.recordName,
            displayName: record["displayName"] as? String ?? "Anonymous",
            totalMon: record["totalMon"] as? Int ?? 0,
            lastNameChange: record["lastNameChange"] as? Date
        )
    }
}

enum LBError: LocalizedError {
    case notSignedIn
    case invalidName(String)
    case cooldown(Int)

    var errorDescription: String? {
        switch self {
        case .notSignedIn:         return "Sign in to iCloud to join the leaderboard"
        case .invalidName(let m):  return m
        case .cooldown(let days):  return "You can change your name in \(days) day\(days == 1 ? "" : "s")"
        }
    }
}
