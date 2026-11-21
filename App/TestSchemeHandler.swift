import Foundation
import WebKit

/// Serves each quiz from its own folder. WebKit calls this on the main thread, and every response is synchronous.
final class TestSchemeHandler: NSObject, WKURLSchemeHandler {
    private let webRoot: URL
    private let knownTests: Set<String>

    init(webRoot: URL, knownTests: Set<String>) {
        self.webRoot = webRoot
        self.knownTests = knownTests
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        let requestURL = urlSchemeTask.request.url

        guard let requestURL,
              let fileURL = TestRouting.fileURL(for: requestURL, webRoot: webRoot, knownTests: knownTests),
              isRegularFile(fileURL),
              let data = try? Data(contentsOf: fileURL) else {
            respond(urlSchemeTask, url: requestURL, status: 404,
                    mime: "text/plain; charset=utf-8", body: Data("Not found".utf8))
            return
        }

        respond(urlSchemeTask, url: requestURL, status: 200,
                mime: TestRouting.mimeType(for: fileURL), body: data)
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Nothing to cancel: responses are complete before this can run.
    }

    private func isRegularFile(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
    }

    private func respond(_ task: WKURLSchemeTask, url: URL?, status: Int, mime: String, body: Data) {
        let responseURL = url ?? URL(string: TestRouting.scheme + "://neovalues/")!
        let response = HTTPURLResponse(
            url: responseURL,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: [
                "Content-Type": mime,
                "Content-Length": String(body.count),
                "Cache-Control": "no-store"
            ]
        )!
        task.didReceive(response)
        task.didReceive(body)
        task.didFinish()
    }
}
