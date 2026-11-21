import XCTest
@testable import WKWVTests

final class TestRoutingTests: XCTestCase {
    private let webRoot = URL(fileURLWithPath: "/tmp/wkwv-web", isDirectory: true)
    private let known: Set<String> = ["neovalues", "axes"]

    func testStartURLIsTheEntryPageOfTheTest() {
        XCTAssertEqual(TestRouting.startURL(for: TestCatalog.all[0]).absoluteString, "app://neovalues/index.html")
    }

    func testRequestMapsIntoTheTestFolder() {
        let url = TestRouting.fileURL(for: URL(string: "app://axes/longquiz.html")!,
                                      webRoot: webRoot, knownTests: known)
        XCTAssertEqual(url?.path, "/tmp/wkwv-web/tests/axes/longquiz.html")
    }

    func testRootMapsToIndex() {
        let url = TestRouting.fileURL(for: URL(string: "app://axes/")!, webRoot: webRoot, knownTests: known)
        XCTAssertEqual(url?.lastPathComponent, "index.html")
    }

    func testUnknownHostAndSchemeAreRejected() {
        XCTAssertNil(TestRouting.fileURL(for: URL(string: "app://other/index.html")!,
                                         webRoot: webRoot, knownTests: known))
        XCTAssertNil(TestRouting.fileURL(for: URL(string: "https://axes/index.html")!,
                                         webRoot: webRoot, knownTests: known))
    }

    func testParentDirectoryStaysInsideTheTestFolder() {
        // The 12Axes pages refer to ../icons, which is outside the test folder. It must not resolve there.
        let url = TestRouting.fileURL(for: URL(string: "app://axes/../icons/12axes.png")!,
                                      webRoot: webRoot, knownTests: known)
        XCTAssertNil(url)
    }

    func testMimeTypes() {
        XCTAssertEqual(TestRouting.mimeType(for: URL(fileURLWithPath: "index.html")), "text/html; charset=utf-8")
        XCTAssertEqual(TestRouting.mimeType(for: URL(fileURLWithPath: "questions.js")), "text/javascript; charset=utf-8")
        XCTAssertEqual(TestRouting.mimeType(for: URL(fileURLWithPath: "LICENSE-MIT.txt")), "text/plain; charset=utf-8")
        XCTAssertEqual(TestRouting.mimeType(for: URL(fileURLWithPath: "mystery.bin")), "application/octet-stream")
    }
}
