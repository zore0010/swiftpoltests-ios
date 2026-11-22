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
        Self.upgradeLegacyAxesFiles()
        var newCounts: [String: Int] = [:]
        var newUnfinished: Set<String> = []
        for test in TestCatalog.all {
            newCounts[test.id] = Self.files(for: test.resultsFolder).count
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
        try save(lines: lines, date: Date(), for: test)
    }

    /// Writes a finished native quiz the same way, from lines it has already built.
    func completeNative(lines: [String], for test: TestDefinition) throws {
        try save(lines: lines, date: Date(), for: test)
    }

    private func save(lines: [String], date: Date, for test: TestDefinition) throws {
        let text = ResultFormat.markdown(title: test.resultsTitle, date: date, lines: lines)
        let name = Self.fileNamePrefix(for: date) + " " + ProgressStore.newID() + ".md"
        let url = try Self.folder(for: test.resultsFolder).appendingPathComponent(name)
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

    /// Older 12 Axes files listed raw codes such as "- fed: 45". Rewrite them in the readable format.
    static func upgradeLegacyAxesFiles() {
        for url in files(for: "axes") {
            guard let text = try? String(contentsOf: url, encoding: .utf8),
                  text.contains("\n- fed: ") else { continue }

            var values: [String: Double] = [:]
            var finished = ""
            for line in text.components(separatedBy: "\n") {
                if line.hasPrefix("Finished: ") {
                    finished = String(line.dropFirst("Finished: ".count))
                }
                guard line.hasPrefix("- ") else { continue }
                let parts = line.dropFirst(2).components(separatedBy: ": ")
                guard parts.count == 2,
                      let index = ResultFormat.axesCodes.firstIndex(of: parts[0]),
                      let value = Double(parts[1]) else { continue }
                values[ResultFormat.axesLetters[index]] = value
            }
            guard !values.isEmpty else { continue }

            let body = ResultFormat.markdownBody(title: "12 Axes", finished: finished,
                                                 lines: ResultFormat.axesLines(values: values))
            try? body.write(to: url, atomically: true, encoding: .utf8)
        }
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

    /// 12 Axes: the query keys and the short codes that older files used.
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
        markdownBody(title: title, finished: displayDate(date), lines: lines)
    }

    static func markdownBody(title: String, finished: String, lines: [String]) -> String {
        var text = "# " + title + "\n\n"
        text += "Finished: " + finished + "\n\n"
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

    /// One line per axis, for example "Structure: Centrist (Federal 45%, Unitary 55%)".
    static func axesLines(values: [String: Double]) -> [String] {
        var lines: [String] = []
        for axis in AxesSpec.axes {
            guard let score = values[axis.letter] else { continue }
            let band = AxesSpec.band(for: score, bands: axis.bands)
            let left = axis.left + " " + percent(score)
            let right = axis.right + " " + percent(100 - score)
            let label = band.isEmpty ? axis.name : axis.name + ": " + band
            lines.append(label + " (" + left + ", " + right + ")")
        }
        return lines
    }

    private static func percent(_ value: Double) -> String {
        String(format: "%g", value) + "%"
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
        var values: [String: Double] = [:]
        for item in items {
            if let value = Double(item.value ?? "") {
                values[item.name] = value
            }
        }
        return axesLines(values: values)
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "d MMM yyyy, HH:mm"
        return formatter
    }()
}
