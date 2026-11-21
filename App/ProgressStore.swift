import Foundation

/// Stores unfinished answers and completed results for each test, in the app's own storage.
/// Progress is replaced after every answer. A finished result moves into the history and clears progress.
enum ProgressStore {
    struct HistoryEntry: Codable, Identifiable, Equatable {
        let id: UUID
        let date: Date
        /// The result as JSON text, exactly as the quiz sent it.
        let payload: String
    }

    enum StoreError: LocalizedError {
        case invalidJSON

        var errorDescription: String? {
            "The quiz sent data that is not valid JSON."
        }
    }

    private static var baseURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return support.appendingPathComponent("WKWVTests", isDirectory: true)
    }

    private static func folder(for testID: String) throws -> URL {
        let url = baseURL.appendingPathComponent(testID, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func progressURL(_ testID: String) throws -> URL {
        try folder(for: testID).appendingPathComponent("progress.json")
    }

    private static func historyURL(_ testID: String) throws -> URL {
        try folder(for: testID).appendingPathComponent("history.json")
    }

    // MARK: Progress

    static func loadProgress(_ testID: String) -> String? {
        guard let url = try? progressURL(testID),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return nil
        }
        return text
    }

    static func hasProgress(_ testID: String) -> Bool {
        loadProgress(testID) != nil
    }

    static func saveProgress(_ json: String, for testID: String) throws {
        try validate(json)
        try json.write(to: progressURL(testID), atomically: true, encoding: .utf8)
    }

    static func clearProgress(_ testID: String) {
        if let url = try? progressURL(testID) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: History

    /// Completed results, newest first.
    static func history(for testID: String) -> [HistoryEntry] {
        guard let url = try? historyURL(testID),
              let data = try? Data(contentsOf: url),
              let entries = try? JSONDecoder().decode([HistoryEntry].self, from: data) else {
            return []
        }
        return entries
    }

    /// Adds a finished result to the history and clears the unfinished progress for that test.
    static func recordCompletion(_ json: String, for testID: String) throws {
        try validate(json)
        var entries = history(for: testID)
        entries.insert(HistoryEntry(id: UUID(), date: Date(), payload: json), at: 0)
        let data = try JSONEncoder().encode(entries)
        try data.write(to: historyURL(testID), options: .atomic)
        clearProgress(testID)
    }

    static func deleteEntry(_ entry: HistoryEntry, for testID: String) throws {
        let remaining = history(for: testID).filter { $0.id != entry.id }
        let data = try JSONEncoder().encode(remaining)
        try data.write(to: historyURL(testID), options: .atomic)
    }

    /// Removes everything stored for a test. Used by tests.
    static func removeAll(for testID: String) {
        try? FileManager.default.removeItem(at: baseURL.appendingPathComponent(testID, isDirectory: true))
    }

    private static func validate(_ json: String) throws {
        guard let data = json.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            throw StoreError.invalidJSON
        }
    }
}
