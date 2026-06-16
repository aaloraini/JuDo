import Foundation

enum BadWordFilter {
    static let maxLength = 20
    static let minLength = 2

    private static let blocked: [String] = [
        "fuck", "shit", "bitch", "cunt", "dick", "cock", "pussy", "ass",
        "nigger", "nigga", "faggot", "fag", "retard", "whore", "slut",
        "bastard", "asshole", "arsehole", "motherfucker"
    ]

    static func validate(_ name: String) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count < minLength { return "Name must be at least \(minLength) characters" }
        if trimmed.count > maxLength { return "Name must be \(maxLength) characters or less" }
        let lower = trimmed.lowercased()
        if blocked.contains(where: { lower.contains($0) }) { return "Name contains inappropriate content" }
        return nil
    }
}
