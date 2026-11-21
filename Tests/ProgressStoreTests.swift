import XCTest
@testable import WKWVTests

final class ProgressStoreTests: XCTestCase {
    private let testID = "test-" + UUID().uuidString

    override func tearDown() {
        ProgressStore.removeAll(for: testID)
        try? FileManager.default.removeItem(at: ResultStore.rootFolder.appendingPathComponent(testID, isDirectory: true))
        super.tearDown()
    }

    func testSaveLoadClear() throws {
        XCTAssertNil(ProgressStore.load(testID))
        try ProgressStore.save(state: #"{"qn":3}"#, for: testID)
        XCTAssertEqual(ProgressStore.load(testID)?.state, #"{"qn":3}"#)
        ProgressStore.clear(testID)
        XCTAssertNil(ProgressStore.load(testID))
    }

    func testSessionKeepsItsIdAcrossSaves() throws {
        try ProgressStore.save(state: #"{"qn":1}"#, for: testID)
        let first = ProgressStore.load(testID)
        try ProgressStore.save(state: #"{"qn":2}"#, for: testID)
        let second = ProgressStore.load(testID)
        XCTAssertEqual(first?.id, second?.id)
        XCTAssertEqual(first?.startedAt, second?.startedAt)
        XCTAssertEqual(second?.state, #"{"qn":2}"#)
    }

    func testInvalidJSONIsRejected() {
        XCTAssertThrowsError(try ProgressStore.save(state: "not json", for: testID))
    }

    func testFinishingWritesAReadableFileAndClearsProgress() throws {
        let test = TestDefinition(id: testID, title: "Test", subtitle: "", entryPage: "index.html", credits: "", license: "")
        try ProgressStore.save(state: #"{"qn":1}"#, for: testID)
        try ResultStore.shared.complete(payload: #"{"query":"?a=50&b=60"}"#, for: test)
        XCTAssertNil(ProgressStore.load(testID))

        let files = ResultStore.files(for: testID)
        XCTAssertEqual(files.count, 1)
        let text = try String(contentsOf: files[0], encoding: .utf8)
        XCTAssertTrue(text.hasPrefix("# Test"))
        XCTAssertTrue(text.contains("- fed: 50"))
        XCTAssertTrue(text.contains("- dem: 60"))
    }

    func testNeoValuesLinesFollowTheQuizOrder() throws {
        let payload = #"{"results":{"culture":"civil_liberalism","economics":"laissez_faire"}}"#
        let lines = try ResultFormat.lines(payload: payload)
        XCTAssertEqual(lines, ["Economics: Laissez faire", "Culture: Civil liberalism"])
    }

    func testAxesLinesUseAxisCodes() throws {
        let lines = try ResultFormat.lines(payload: #"{"query":"?a=50&l=80"}"#)
        XCTAssertEqual(lines, ["fed: 50", "acc: 80"])
    }

    func testFileNameDateRoundTrips() {
        let url = URL(fileURLWithPath: "/x/" + ResultStore.fileNamePrefix(for: Date()) + " abcd.md")
        XCTAssertNotNil(ResultStore.date(for: url))
    }
}
