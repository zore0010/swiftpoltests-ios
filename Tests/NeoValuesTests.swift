import SwiftUI
import XCTest
@testable import SwiftPolTest

/// Compares the native NeoValues code with the original JavaScript. Tests/neovalues-golden.json is written by
/// scripts/fetch-sources.sh, which runs NeoValues' own results.html scoring and quiz.js in Node.
final class NeoValuesTests: XCTestCase {
    private struct Golden: Decodable {
        struct Score: Decodable, Equatable {
            let label: String
            let matchPercentage: Int
            let identicalCount: Int
            let broaderCount: Int
            let totalRequired: Int
        }

        struct MatcherCase: Decodable {
            let answers: [String: String]
            let exact: String?
            let scored: [Score]
        }

        struct Step: Decodable {
            let action: String
            let index: Int?
            let categoryIndex: Int?
            let nodeId: String?
            let finished: Bool?
        }

        struct Run: Decodable {
            let seed: Int
            let steps: [Step]
            let results: [String: String]?
        }

        let matcher: [MatcherCase]
        let engine: [Run]
    }

    private func loadData() throws -> NeoValuesData {
        try NeoValuesData(folder: NeoValuesData.bundledFolder())
    }

    private func loadGolden() throws -> Golden {
        let url = try XCTUnwrap(Bundle(for: NeoValuesTests.self).url(forResource: "neovalues-golden", withExtension: "json"))
        return try JSONDecoder().decode(Golden.self, from: Data(contentsOf: url))
    }

    func testDataLoads() throws {
        let data = try loadData()
        XCTAssertEqual(data.categories.count, 9)
        XCTAssertEqual(data.ideologies.count, 228)
        for category in data.categories {
            XCTAssertNotNil(data.firstNodeID(category), category)
        }
    }

    func testMatcherAgreesWithTheOriginalCode() throws {
        let data = try loadData()
        let golden = try loadGolden()
        let matcher = NeoValuesMatcher(data: data)
        XCTAssertFalse(golden.matcher.isEmpty)

        for (index, expected) in golden.matcher.enumerated() {
            let match = matcher.match(expected.answers)
            XCTAssertEqual(match.exact?.name, expected.exact, "case \(index): exact match")

            let actual = match.closest.prefix(expected.scored.count).map {
                Golden.Score(
                    label: $0.name,
                    matchPercentage: $0.matchPercentage,
                    identicalCount: $0.identicalCount,
                    broaderCount: $0.broaderCount,
                    totalRequired: $0.totalRequired
                )
            }
            XCTAssertEqual(actual, expected.scored, "case \(index): closest matches")
        }
    }

    func testQuizAgreesWithTheOriginalCode() throws {
        let data = try loadData()
        let golden = try loadGolden()
        XCTAssertFalse(golden.engine.isEmpty)

        for run in golden.engine {
            let quiz = NeoValuesQuiz(data: data)
            for (number, step) in run.steps.enumerated() {
                let label = "run \(run.seed), step \(number)"
                if step.action == "back" {
                    XCTAssertTrue(quiz.back(), label)
                } else {
                    let options = try XCTUnwrap(quiz.currentNode?.options, label)
                    let index = try XCTUnwrap(step.index, label)
                    quiz.choose(options[index])
                }

                if step.finished == true {
                    XCTAssertTrue(quiz.isFinished, label)
                } else {
                    XCTAssertEqual(quiz.categoryIndex, step.categoryIndex, label)
                    XCTAssertEqual(quiz.nodeId, step.nodeId, label)
                }
            }
            XCTAssertTrue(quiz.isFinished, "run \(run.seed) finishes")
            XCTAssertEqual(quiz.results, run.results, "run \(run.seed) results")
        }
    }

    func testUnfinishedQuizResumesFromItsSnapshot() throws {
        let data = try loadData()
        let quiz = NeoValuesQuiz(data: data)
        for _ in 0..<5 {
            guard let option = quiz.currentNode?.options?.first else { break }
            quiz.choose(option)
        }

        let text = try XCTUnwrap(quiz.snapshot.encoded())
        let restored = NeoValuesQuiz(data: data, snapshot: NeoValuesQuiz.Snapshot.decode(from: text))
        XCTAssertEqual(restored.snapshot, quiz.snapshot)
        XCTAssertEqual(restored.nodeId, quiz.nodeId)

        // Going back after a restore works like going back before it.
        XCTAssertTrue(restored.back())
        XCTAssertTrue(quiz.back())
        XCTAssertEqual(restored.snapshot, quiz.snapshot)
    }

    func testBrokenSnapshotStartsOver() throws {
        let data = try loadData()
        let snapshot = NeoValuesQuiz.Snapshot(categoryIndex: 0, nodeId: "no such node", results: [:], history: [])
        let quiz = NeoValuesQuiz(data: data, snapshot: snapshot)
        XCTAssertEqual(quiz.categoryIndex, 0)
        XCTAssertTrue(quiz.history.isEmpty)
        XCTAssertNotNil(quiz.currentNode)
    }

    func testBackStopsAtTheFirstQuestion() throws {
        let quiz = NeoValuesQuiz(data: try loadData())
        XCTAssertFalse(quiz.back())
    }

    func testSummaryLinesAreReadable() throws {
        let data = try loadData()
        let golden = try loadGolden()
        let sample = try XCTUnwrap(golden.matcher.first { $0.exact != nil })
        let match = NeoValuesMatcher(data: data).match(sample.answers)
        let lines = NeoValuesSummary.lines(data: data, answers: sample.answers, match: match)
        XCTAssertEqual(lines.first?.hasPrefix(data.categoryTitle(data.categories[0]) + ": "), true)
        XCTAssertTrue(lines.contains("Ideology: " + (sample.exact ?? "")))
    }

    func testHexColors() {
        XCTAssertNotNil(Color(neoHex: "#372f53ff"))
    }
}
