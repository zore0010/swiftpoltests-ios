import Combine
import Foundation

/// The question walker, a port of NeoValues' quiz.js. The categories are asked in order. Each category is a
/// tree of questions, and a path through it ends at a value.
final class NeoValuesQuiz: ObservableObject {
    struct Entry: Codable, Equatable {
        var categoryIndex: Int
        var nodeId: String
        var results: [String: String]
    }

    /// Everything needed to resume an unfinished quiz.
    struct Snapshot: Codable, Equatable {
        var categoryIndex: Int
        var nodeId: String
        var results: [String: String]
        var history: [Entry]

        static func decode(from text: String) -> Snapshot? {
            guard let data = text.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(Snapshot.self, from: data)
        }

        func encoded() -> String? {
            guard let data = try? JSONEncoder().encode(self) else { return nil }
            return String(data: data, encoding: .utf8)
        }
    }

    let data: NeoValuesData

    @Published private(set) var categoryIndex = 0
    @Published private(set) var nodeId = ""
    @Published private(set) var results: [String: String] = [:]
    @Published private(set) var history: [Entry] = []

    init(data: NeoValuesData, snapshot: Snapshot? = nil) {
        self.data = data
        if let snapshot, isValid(snapshot) {
            categoryIndex = snapshot.categoryIndex
            nodeId = snapshot.nodeId
            results = snapshot.results
            history = snapshot.history
        } else {
            reset()
        }
    }

    var isFinished: Bool {
        categoryIndex >= data.categories.count
    }

    var currentCategory: String? {
        guard categoryIndex >= 0, categoryIndex < data.categories.count else { return nil }
        return data.categories[categoryIndex]
    }

    var currentNode: NeoValuesNode? {
        guard let category = currentCategory else { return nil }
        return data.node(category, nodeId)
    }

    var snapshot: Snapshot {
        Snapshot(categoryIndex: categoryIndex, nodeId: nodeId, results: results, history: history)
    }

    /// Starts again from the first question.
    func reset() {
        categoryIndex = 0
        results = [:]
        history = []
        nodeId = data.categories.first.flatMap { data.firstNodeID($0) } ?? ""
    }

    /// Answers the current question. A next id that is not a question with options is a value.
    func choose(_ option: NeoValuesOption) {
        guard let category = currentCategory else { return }
        history.append(Entry(categoryIndex: categoryIndex, nodeId: nodeId, results: results))

        if let next = data.node(category, option.next), next.options != nil {
            nodeId = next.id
        } else {
            results[category] = option.next
            categoryIndex += 1
            if let following = currentCategory, let first = data.firstNodeID(following) {
                nodeId = first
            }
        }
    }

    /// Goes back one question. Returns false at the first question.
    @discardableResult
    func back() -> Bool {
        guard let last = history.popLast() else { return false }
        categoryIndex = last.categoryIndex
        results = last.results
        nodeId = last.nodeId
        return true
    }

    private func isValid(_ snapshot: Snapshot) -> Bool {
        let count = data.categories.count
        guard snapshot.categoryIndex >= 0, snapshot.categoryIndex < count,
              data.node(data.categories[snapshot.categoryIndex], snapshot.nodeId) != nil else {
            return false
        }
        for entry in snapshot.history {
            guard entry.categoryIndex >= 0, entry.categoryIndex < count,
                  data.node(data.categories[entry.categoryIndex], entry.nodeId) != nil else {
                return false
            }
        }
        return true
    }
}
