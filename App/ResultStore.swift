import Combine
import Foundation

enum ResultError: LocalizedError {
    case unreadable

    var errorDescription: String? {
        "The result could not be read."
    }
}

/// Finished results, saved as plain Markdown files in Documents/Political Tests/<test>.
/// The Files app shows that folder, so results can be read and shared without the app.
final class ResultStore: ObservableObject {
    static let shared = ResultStore()

    /// How many finished results each test has.
    @Published private(set) var counts: [String: Int] = [:]
    /// Tests that have an unfinished session.
    @Published private(set) var unfinished: Set<String> = []

    private init() {
        reload()
    }

    static var rootFolder: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Political Tests", isDirectory: true)
    }

    static func folder(for testID: String) throws -> URL {
        let url = rootFolder.appendingPathComponent(testID, isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// Re-reads everything from disk. Called when the menu appears and when a test closes.
    func reload() {
        var newCounts: [String: Int] = [:]
        var newUnfinished: Set<String> = []
        for test in TestCatalog.all {
            newCounts[test.id] = Self.files(for: test.id).count
            if ProgressStore.load(test.id) != nil {
                newUnfinished.insert(test.id)
            }
        }
        counts = newCounts
        unfinished = newUnfinished
    }

    /// Finished results for one test, newest first.
    static func files(for testID: String) -> [URL] {
        guard let dir = try? folder(for: testID),
              let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return []
        }
        return items
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }

    /// Writes a finished quiz as a Markdown file, then clears the unfinished session for that test.
    func complete(payload: String, for test: TestDefinition) throws {
        let lines = try ResultFormat.lines(payload: payload)
        let date = Date()
        let text = ResultFormat.markdown(title: test.title, date: date, lines: lines)
        let name = Self.fileNamePrefix(for: date) + " " + ProgressStore.newID() + ".md"
        let url = try Self.folder(for: test.id).appendingPathComponent(name)
        try text.write(to: url, atomically: true, encoding: .utf8)
        ProgressStore.clear(test.id)
        reload()
    }

    func delete(_ url: URL) {
        try? FileManager.default.removeItem(at: url)
        reload()
    }

    /// The date a result was finished, read from its file name.
    static func date(for url: URL) -> Date? {
        let prefix = String(url.lastPathComponent.prefix(19))
        return fileDateFormatter.date(from: prefix)
    }

    static func fileNamePrefix(for date: Date) -> String {
        fileDateFormatter.string(from: date)
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH-mm-ss"
        return formatter
    }()
}

/// Turns a quiz's finished state into the lines and Markdown a person reads.
enum ResultFormat {
    /// NeoValues categories, in the order the quiz asks them.
    static let neovaluesCategories = [
        "economics", "resource_management", "culture", "authority", "nation",
        "foreign", "technology", "social_control", "territorial_organization"
    ]

    /// 12 Axes: the query keys a to l, in order, and the short names the source gives them.
    static let axesLetters = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l"]
    static let axesCodes = ["fed", "dem", "glo", "mil", "fre", "equ", "sec", "pro", "mul", "plan", "tra", "acc"]

    static func lines(payload: String) throws -> [String] {
        guard let data = payload.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ResultError.unreadable
        }
        if object["results"] != nil {
            return try neovaluesLines(object)
        }
        if object["query"] != nil {
            return try axesLines(object)
        }
        throw ResultError.unreadable
    }

    static func markdown(title: String, date: Date, lines: [String]) -> String {
        var text = "# " + title + "\n\n"
        text += "Finished: " + displayDate(date) + "\n\n"
        text += lines.map { "- " + $0 }.joined(separator: "\n") + "\n"
        return text
    }

    static func displayDate(_ date: Date) -> String {
        displayFormatter.string(from: date)
    }

    /// "laissez_faire" becomes "Laissez faire".
    static func prettify(_ id: String) -> String {
        let spaced = id.replacingOccurrences(of: "_", with: " ")
        guard let first = spaced.first else { return spaced }
        return String(first).uppercased() + spaced.dropFirst()
    }

    private static func neovaluesLines(_ object: [String: Any]) throws -> [String] {
        guard let results = object["results"] as? [String: String] else {
            throw ResultError.unreadable
        }
        let ordered = neovaluesCategories.filter { results[$0] != nil }
        let rest = results.keys.filter { !neovaluesCategories.contains($0) }.sorted()
        return (ordered + rest).map { category in
            prettify(category) + ": " + prettify(results[category] ?? "")
        }
    }

    private static func axesLines(_ object: [String: Any]) throws -> [String] {
        guard let query = object["query"] as? String,
              let components = URLComponents(string: "https://localhost/results" + query),
              let items = components.queryItems else {
            throw ResultError.unreadable
        }
        var values: [String: String] = [:]
        for item in items {
            values[item.name] = item.value ?? ""
        }
        var lines: [String] = []
        for index in 0..<min(axesLetters.count, axesCodes.count) {
            if let value = values[axesLetters[index]] {
                lines.append(axesCodes[index] + ": " + value)
            }
        }
        return lines
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()
}
