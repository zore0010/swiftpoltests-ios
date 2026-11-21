import XCTest
@testable import WKWVTests

final class ProgressStoreTests: XCTestCase {
    private let testID = "test-" + UUID().uuidString

    override func tearDown() {
        ProgressStore.removeAll(for: testID)
        super.tearDown()
    }

    func testProgressIsSavedLoadedAndCleared() throws {
        XCTAssertNil(ProgressStore.loadProgress(testID))
        try ProgressStore.saveProgress(#"{"qn":3}"#, for: testID)
        XCTAssertEqual(ProgressStore.loadProgress(testID), #"{"qn":3}"#)
        XCTAssertTrue(ProgressStore.hasProgress(testID))

        ProgressStore.clearProgress(testID)
        XCTAssertNil(ProgressStore.loadProgress(testID))
    }

    func testInvalidJSONIsRejected() {
        XCTAssertThrowsError(try ProgressStore.saveProgress("not json", for: testID))
        XCTAssertThrowsError(try ProgressStore.recordCompletion("{broken", for: testID))
    }

    func testCompletionGoesToHistoryNewestFirstAndClearsProgress() throws {
        try ProgressStore.saveProgress(#"{"qn":1}"#, for: testID)
        try ProgressStore.recordCompletion(#"{"query":"?a=50"}"#, for: testID)
        try ProgressStore.recordCompletion(#"{"query":"?a=60"}"#, for: testID)

        let history = ProgressStore.history(for: testID)
        XCTAssertEqual(history.count, 2)
        XCTAssertEqual(history[0].payload, #"{"query":"?a=60"}"#)
        XCTAssertNil(ProgressStore.loadProgress(testID))
    }

    func testDeletingAnEntryKeepsTheOthers() throws {
        try ProgressStore.recordCompletion(#"{"query":"?a=1"}"#, for: testID)
        try ProgressStore.recordCompletion(#"{"query":"?a=2"}"#, for: testID)
        let history = ProgressStore.history(for: testID)

        try ProgressStore.deleteEntry(history[0], for: testID)
        let remaining = ProgressStore.history(for: testID)
        XCTAssertEqual(remaining.count, 1)
        XCTAssertEqual(remaining[0].payload, #"{"query":"?a=1"}"#)
    }
}
