import Foundation

/// The quiz's own state for an unfinished test, plus when its session started.
struct UnfinishedSession: Codable, Equatable {
    let id: String
    let startedAt: Date
    /// The quiz's state, as the JSON text the page sent.
    let state: String
    /// The quiz page the state came from, such as quiz.html. Missing in sessions saved before this was recorded.
    let page: String?
}

/// One unfinished session per test, kept in the app's private storage.
/// It is replaced after every answer, and deleted when the test is finished or started over.
enum ProgressStore {
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

    private static func fileURL(for testID: String) throws -> URL {
        let folder = baseURL.appendingPathComponent(testID, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("session.json")
    }

    static func load(_ testID: String) -> UnfinishedSession? {
        guard let url = try? fileURL(for: testID),
              let data = try? Data(contentsOf: url) else {
            return nil
        }
        return try? JSONDecoder().decode(UnfinishedSession.self, from: data)
    }

    /// Saves the quiz's state. The first save of a run starts a new session, and later saves keep its id.
    /// A save without a page keeps the page of the session.
    static func save(state: String, page: String? = nil, for testID: String) throws {
        try validateJSON(state)
        let current = load(testID)
        let session = UnfinishedSession(
            id: current?.id ?? newID(),
            startedAt: current?.startedAt ?? Date(),
            state: state,
            page: page ?? current?.page
        )
        let data = try JSONEncoder().encode(session)
        try data.write(to: try fileURL(for: testID), options: .atomic)
    }

    static func clear(_ testID: String) {
        if let url = try? fileURL(for: testID) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Removes everything stored for a test. Used by tests.
    static func removeAll(for testID: String) {
        try? FileManager.default.removeItem(at: baseURL.appendingPathComponent(testID, isDirectory: true))
    }

    static func newID() -> String {
        String(UUID().uuidString.prefix(8)).lowercased()
    }

    static func validateJSON(_ json: String) throws {
        guard let data = json.data(using: .utf8),
              (try? JSONSerialization.jsonObject(with: data)) != nil else {
            throw StoreError.invalidJSON
        }
    }
}
