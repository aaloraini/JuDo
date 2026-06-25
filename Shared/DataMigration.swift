import Foundation
import SwiftData

// Legacy Codable struct — used only for one-time migration from v2.1.x UserDefaults JSON
private struct LegacyTask: Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var order: Int
    var priority: String?
    var dueDate: Date?
    var notes: String?
    var createdAt: Date
    var updatedAt: Date
    var completedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, isCompleted, order, priority, dueDate, notes, createdAt, updatedAt, completedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self,   forKey: .id)
        title       = try c.decode(String.self, forKey: .title)
        isCompleted = try c.decode(Bool.self,   forKey: .isCompleted)
        order       = try c.decode(Int.self,    forKey: .order)
        priority    = try c.decodeIfPresent(String.self, forKey: .priority)
        dueDate     = try c.decodeIfPresent(Date.self,   forKey: .dueDate)
        notes       = try c.decodeIfPresent(String.self, forKey: .notes)
        createdAt   = try c.decodeIfPresent(Date.self,   forKey: .createdAt)  ?? Date()
        updatedAt   = try c.decodeIfPresent(Date.self,   forKey: .updatedAt)  ?? Date()
        completedAt = try c.decodeIfPresent(Date.self,   forKey: .completedAt)
    }
}

enum DataMigration {
    private static let migrationFlagKey = "swiftdata_migration_v1_done"
    private static let suiteName = "group.com.aloraini.JuDo"

    static func migrateIfNeeded(container: ModelContainer) {
        let defaults = UserDefaults(suiteName: suiteName)!
        guard !defaults.bool(forKey: migrationFlagKey) else { return }
        defer { defaults.set(true, forKey: migrationFlagKey) }

        guard
            let data = defaults.data(forKey: "tasks"),
            let legacy = try? JSONDecoder().decode([LegacyTask].self, from: data),
            !legacy.isEmpty
        else { return }

        let context = ModelContext(container)
        for old in legacy {
            let task = Task(
                title: old.title,
                order: old.order,
                priority: old.priority.flatMap { Priority(rawValue: $0) },
                dueDate: old.dueDate,
                notes: old.notes
            )
            task.id          = old.id
            task.isCompleted = old.isCompleted
            task.createdAt   = old.createdAt
            task.updatedAt   = old.updatedAt
            task.completedAt = old.completedAt
            context.insert(task)
        }

        try? context.save()
    }
}
