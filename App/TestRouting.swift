import Foundation

/// Locations inside the app bundle.
enum AppPaths {
    /// The Web folder that scripts/fetch-sources.sh fills, bundled as a folder reference.
    static var webRoot: URL {
        guard let url = Bundle.main.url(forResource: "Web", withExtension: nil) else {
            fatalError("Web/ is missing from the app bundle. Run scripts/fetch-sources.sh before xcodegen.")
        }
        return url
    }
}

/// Routing for the bundled quizzes. A request for app://<test>/<path> maps to Web/tests/<test>/<path>.
/// Each test has its own host, so each one gets its own web storage.
enum TestRouting {
    static let scheme = "app"

    static func startURL(for test: TestDefinition) -> URL {
        URL(string: scheme + "://" + test.id + "/" + test.entryPage)!
    }

    /// The file for a request, or nil for anything outside a known test folder.
    static func fileURL(for requestURL: URL, webRoot: URL, knownTests: Set<String>) -> URL? {
        guard requestURL.scheme == scheme, let host = requestURL.host, knownTests.contains(host) else {
            return nil
        }

        let root = webRoot
            .appendingPathComponent("tests", isDirectory: true)
            .appendingPathComponent(host, isDirectory: true)
            .standardizedFileURL

        var relative = requestURL.path.removingPercentEncoding ?? requestURL.path
        while relative.hasPrefix("/") {
            relative.removeFirst()
        }
        if relative.isEmpty {
            relative = "index.html"
        }

        let backslash = Character(Unicode.Scalar(UInt8(92)))
        let nul = Unicode.Scalar(UInt8(0))
        if relative.contains(backslash) || relative.unicodeScalars.contains(nul) {
            return nil
        }
        let parts = relative.split(separator: "/", omittingEmptySubsequences: false)
        if parts.contains(where: { $0 == "." || $0 == ".." || $0.isEmpty }) {
            return nil
        }

        let candidate = root.appendingPathComponent(relative).standardizedFileURL
        guard candidate.path.hasPrefix(root.path + "/") else { return nil }
        return candidate
    }

    static func mimeType(for fileURL: URL) -> String {
        switch fileURL.pathExtension.lowercased() {
        case "html", "htm": return "text/html; charset=utf-8"
        case "css": return "text/css; charset=utf-8"
        case "js": return "text/javascript; charset=utf-8"
        case "json": return "application/json; charset=utf-8"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "webp": return "image/webp"
        case "woff2": return "font/woff2"
        case "woff": return "font/woff"
        case "ttf": return "font/ttf"
        case "", "txt": return "text/plain; charset=utf-8"
        default: return "application/octet-stream"
        }
    }
}
