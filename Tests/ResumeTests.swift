import XCTest
@testable import SwiftPolTest

/// Resume: the session keeps the quiz page it was on, and the web view opens that page.
final class ResumeTests: XCTestCase {
    private let testID = "resume-" + String(UUID().uuidString.prefix(8)).lowercased()

    override func tearDown() {
        ProgressStore.removeAll(for: testID)
        super.tearDown()
    }

    private func webTest() -> TestDefinition {
        TestDefinition(id: testID, title: "Test", subtitle: "", entryPage: "index.html", credits: "", license: "")
    }

    func testSessionKeepsThePageItWasSavedOn() throws {
        try ProgressStore.save(state: #"{"qn":2}"#, page: "longquiz.html", for: testID)
        XCTAssertEqual(ProgressStore.load(testID)?.page, "longquiz.html")
    }

    func testLaterSavesKeepThePage() throws {
        try ProgressStore.save(state: #"{"qn":2}"#, page: "quiz.html", for: testID)
        try ProgressStore.save(state: #"{"qn":3}"#, for: testID)
        XCTAssertEqual(ProgressStore.load(testID)?.page, "quiz.html")
    }

    func testResumeOpensTheSavedQuizPage() throws {
        try ProgressStore.save(state: #"{"qn":2}"#, page: "longquiz.html", for: testID)
        XCTAssertEqual(TestWebView.startURL(for: webTest()).absoluteString, "app://\(testID)/longquiz.html")
    }

    func testWithoutASessionTheTestOpensItsEntryPage() {
        XCTAssertEqual(TestWebView.startURL(for: webTest()).absoluteString, "app://\(testID)/index.html")
    }

    func testAPageOutsideTheQuizIsNotOpened() throws {
        try ProgressStore.save(state: #"{"qn":2}"#, page: "../secret.html", for: testID)
        XCTAssertEqual(TestWebView.startURL(for: webTest()).absoluteString, "app://\(testID)/index.html")
    }
}
