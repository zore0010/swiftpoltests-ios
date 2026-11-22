import Foundation

// The NeoValues data the native screens use. scripts/export-neovalues.js writes it as JSON
// into Generated/neovalues/ from the filtered, pinned NeoValues sources.

struct NeoValuesOption: Decodable, Equatable {
    let text: String
    let next: String
}

/// One question. A node without options is a leaf: its id is a value.
struct NeoValuesNode: Decodable, Equatable {
    let id: String
    let text: String?
    let options: [NeoValuesOption]?
}

struct NeoValuesValue: Decodable, Identifiable, Equatable {
    let id: String
    let name: String
    let description: String?
}

struct NeoValuesCategory: Decodable, Identifiable, Equatable {
    let id: String
    let title: String
    let values: [NeoValuesValue]
}

struct NeoValuesRequirement: Decodable, Identifiable, Equatable {
    let category: String
    let allowed: [String]

    var id: String { category }
}

struct NeoValuesIdeology: Decodable, Identifiable, Equatable {
    let name: String
    let group: String?
    let color: String?
    /// In the order of the original data, which the matching code depends on.
    let requirements: [NeoValuesRequirement]
    let description: String?

    var id: String { name }
}

struct NeoValuesSubGroup: Decodable, Equatable {
    let group: String
    let values: [String]
}

struct NeoValuesMatching: Decodable, Equatable {
    /// Per category, the groups in the original order.
    let subCategories: [String: [NeoValuesSubGroup]]
    let incompatible: [String: [String]]
}

private struct NeoValuesQuestionsFile: Decodable {
    let categories: [String]
    let questions: [String: [NeoValuesNode]]
}

final class NeoValuesData {
    enum LoadError: LocalizedError {
        case missingFolder
        case unreadable(String)

        var errorDescription: String? {
            switch self {
            case .missingFolder:
                return "The NeoValues data is missing from the app bundle. Run scripts/fetch-sources.sh before xcodegen."
            case .unreadable(let detail):
                return "The NeoValues data could not be read (" + detail + ")."
            }
        }
    }

    /// The quiz's categories, in the order it asks them.
    let categories: [String]
    let categoryInfo: [NeoValuesCategory]
    let ideologies: [NeoValuesIdeology]
    let matching: NeoValuesMatching

    private let nodes: [String: [String: NeoValuesNode]]
    private let firstIDs: [String: String]
    private let titles: [String: String]
    private let valuesByCategory: [String: [String: NeoValuesValue]]

    /// Loaded once from the app bundle.
    static let bundled: Result<NeoValuesData, Error> = Result {
        try NeoValuesData(folder: try NeoValuesData.bundledFolder())
    }

    static func bundledFolder() throws -> URL {
        guard let root = Bundle.main.url(forResource: "Generated", withExtension: nil) else {
            throw LoadError.missingFolder
        }
        return root.appendingPathComponent("neovalues", isDirectory: true)
    }

    init(folder: URL) throws {
        let questions = try Self.read(NeoValuesQuestionsFile.self, "questions.json", in: folder)
        let info = try Self.read([NeoValuesCategory].self, "values.json", in: folder)
        let ideologyList = try Self.read([NeoValuesIdeology].self, "ideologies.json", in: folder)
        let matchingData = try Self.read(NeoValuesMatching.self, "matching.json", in: folder)

        var nodeMap: [String: [String: NeoValuesNode]] = [:]
        var first: [String: String] = [:]
        for category in questions.categories {
            let list = questions.questions[category] ?? []
            var map: [String: NeoValuesNode] = [:]
            // Like the original quiz, a repeated id keeps the last node.
            for node in list {
                map[node.id] = node
            }
            nodeMap[category] = map
            if let firstNode = list.first {
                first[category] = firstNode.id
            }
        }

        var titleMap: [String: String] = [:]
        var valueMap: [String: [String: NeoValuesValue]] = [:]
        for category in info {
            titleMap[category.id] = category.title
            var values: [String: NeoValuesValue] = [:]
            for value in category.values {
                values[value.id] = value
            }
            valueMap[category.id] = values
        }

        self.categories = questions.categories
        self.categoryInfo = info
        self.ideologies = ideologyList
        self.matching = matchingData
        self.nodes = nodeMap
        self.firstIDs = first
        self.titles = titleMap
        self.valuesByCategory = valueMap
    }

    private static func read<T: Decodable>(_ type: T.Type, _ name: String, in folder: URL) throws -> T {
        do {
            let data = try Data(contentsOf: folder.appendingPathComponent(name))
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw LoadError.unreadable(name + ": " + error.localizedDescription)
        }
    }

    func node(_ category: String, _ id: String) -> NeoValuesNode? {
        nodes[category]?[id]
    }

    func firstNodeID(_ category: String) -> String? {
        firstIDs[category]
    }

    func categoryTitle(_ category: String) -> String {
        titles[category] ?? ResultFormat.prettify(category)
    }

    func value(_ category: String, _ id: String) -> NeoValuesValue? {
        valuesByCategory[category]?[id]
    }

    func valueName(_ category: String, _ id: String) -> String {
        valuesByCategory[category]?[id]?.name ?? id.replacingOccurrences(of: "_", with: " ")
    }
}
