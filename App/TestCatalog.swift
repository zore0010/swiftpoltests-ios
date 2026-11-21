import Foundation

/// One quiz in the menu. Its files live in Web/tests/<id>, and it starts at `entryPage`.
struct TestDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let entryPage: String
    let credits: String
    let license: String
}

enum TestCatalog {
    static let all: [TestDefinition] = [
        TestDefinition(
            id: "neovalues",
            title: "NeoValues",
            subtitle: "Nine categories, a values profile, and the closest ideology",
            entryPage: "index.html",
            credits: "NeoValues by neomediavalist (https://github.com/neomediavalist/neovalues). Bundled from the fork https://github.com/zore0010/neovalues.",
            license: "CC BY-NC-SA 4.0"
        ),
        TestDefinition(
            id: "axes",
            title: "12 Axes",
            subtitle: "Twelve political axes, with ideologies, countries, and figures",
            entryPage: "index.html",
            credits: "12Axes quiz from the politicaltests project (https://github.com/politicaltests/politicaltests.github.io), copyright (c) 2020 8values (SapplyValues).",
            license: "MIT (full text bundled with the quiz)"
        )
    ]

    static var ids: Set<String> {
        Set(all.map { $0.id })
    }
}
