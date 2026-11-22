import XCTest
@testable import SwiftPolTest

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
        try ResultStore.shared.complete(payload: #"{"results":{"economics":"laissez_faire"}}"#, for: test)
        XCTAssertNil(ProgressStore.load(testID))

        let files = ResultStore.files(for: testID)
        XCTAssertEqual(files.count, 1)
        let text = try String(contentsOf: files[0], encoding: .utf8)
        XCTAssertTrue(text.hasPrefix("# Test"))
        XCTAssertTrue(text.contains("- Economics: Laissez faire"))
    }

    func testNeoValuesLinesFollowTheQuizOrder() throws {
        let payload = #"{"results":{"culture":"civil_liberalism","economics":"laissez_faire"}}"#
        let lines = try ResultFormat.lines(payload: payload)
        XCTAssertEqual(lines, ["Economics: Laissez faire", "Culture: Civil liberalism"])
    }

    func testAxesLinesAreReadable() throws {
        let lines = try ResultFormat.lines(payload: #"{"query":"?a=45&b=55"}"#)
        XCTAssertEqual(lines, [
            "Structure: Centrist (Federal 45%, Unitary 55%)",
            "Representation: Centrist (Democracy 55%, Authority 45%)"
        ])
    }

    func testAxisBandsMatchTheSource() {
        let bands = AxesSpec.axes[0].bands
        XCTAssertEqual(AxesSpec.band(for: 95, bands: bands), "Confederal")
        XCTAssertEqual(AxesSpec.band(for: 50, bands: bands), "Centrist")
        XCTAssertEqual(AxesSpec.band(for: 5, bands: bands), "Extremely Centralized")
    }

    func testFileNameDateRoundTrips() {
        let url = URL(fileURLWithPath: "/x/" + ResultStore.fileNamePrefix(for: Date()) + " abcd.md")
        XCTAssertNotNil(ResultStore.date(for: url))
    }
}
