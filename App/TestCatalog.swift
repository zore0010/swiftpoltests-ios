import Foundation

/// One quiz in the menu. Its files live in Web/tests/<id>, and it starts at `entryPage`.
/// Native quizzes have no files of their own.
struct TestDefinition: Identifiable, Hashable {
    enum Kind: Hashable {
        /// A quiz page shown in a WKWebView.
        case web
        /// A quiz built with SwiftUI.
        case native
    }

    let id: String
    let title: String
    let subtitle: String
    let entryPage: String
    let credits: String
    let license: String
    var kind: Kind = .web
    /// Only primary tests are listed under Saved results and in the credits.
    var isPrimary: Bool = true
    /// Where finished results go, when it is not the test's own folder.
    var resultsFolderOverride: String?
    var resultsTitleOverride: String?

    var resultsFolder: String {
        resultsFolderOverride ?? id
    }

    var resultsTitle: String {
        resultsTitleOverride ?? title
    }
}

enum TestCatalog {
    private static let mit8values = "MIT. The license text is bundled with the quiz."
    private static let neomediavalist = "neomediavalist (https://github.com/neomediavalist), CC BY-NC-SA 4.0."

    static let all: [TestDefinition] = [
        TestDefinition(
            id: "neovalues-native",
            title: "NeoValues",
            subtitle: "Nine categories, a values profile, and the closest ideology",
            entryPage: "",
            credits: "NeoValues by neomediavalist (https://github.com/neomediavalist/neovalues). Bundled from the fork https://github.com/zore0010/neovalues. This version is rebuilt natively from the same questions, descriptions and matching rules.",
            license: "CC BY-NC-SA 4.0",
            kind: .native,
            resultsFolderOverride: "neovalues"
        ),
        TestDefinition(
            id: "neovalues",
            title: "NeoValues (web)",
            subtitle: "The original NeoValues web pages",
            entryPage: "index.html",
            credits: "NeoValues by neomediavalist (https://github.com/neomediavalist/neovalues). Bundled from the fork https://github.com/zore0010/neovalues.",
            license: "CC BY-NC-SA 4.0",
            isPrimary: false,
            resultsTitleOverride: "NeoValues"
        ),
        TestDefinition(
            id: "axes",
            title: "12 Axes",
            subtitle: "Twelve political axes, with ideologies, countries, and figures",
            entryPage: "index.html",
            credits: "12Axes quiz from the politicaltests project (https://github.com/politicaltests/politicaltests.github.io), copyright (c) 2020 8values (SapplyValues).",
            license: "MIT (full text bundled with the quiz)"
        ),
        TestDefinition(
            id: "auth",
            title: "AuthValues",
            subtitle: "A values quiz from the politicaltests project",
            entryPage: "index.html",
            credits: "AuthValues quiz from the politicaltests project (https://github.com/politicaltests/politicaltests.github.io), copyright (c) 2020 8values (SapplyValues).",
            license: "MIT (full text bundled with the quiz)"
        ),
        TestDefinition(
            id: "inf",
            title: "InfValues",
            subtitle: "A values quiz from the politicaltests project",
            entryPage: "index.html",
            credits: "InfValues quiz from the politicaltests project (https://github.com/politicaltests/politicaltests.github.io), copyright (c) 2020 8values (SapplyValues).",
            license: "MIT (full text bundled with the quiz)"
        ),
        TestDefinition(
            id: "rightvalues",
            title: "RightValues",
            subtitle: "A values quiz with ideologies and images",
            entryPage: "index.html",
            credits: "RightValues (https://github.com/rightvaluestest/rightvaluestest.github.io).",
            license: "MIT (full text bundled with the quiz)"
        ),
        TestDefinition(
            id: "10groups",
            title: "10Groups",
            subtitle: "Ten categories of political belief",
            entryPage: "index.html",
            credits: "10Groups (https://github.com/10Groups/10groups.github.io), from the original 8values.",
            license: "MIT (full text bundled with the quiz)"
        ),
        TestDefinition(
            id: "8dreams",
            title: "8Dreams",
            subtitle: "A values quiz from the 8values project",
            entryPage: "index.html",
            credits: "8Dreams (https://github.com/8Dreams/8dreams.github.io), copyright (c) 2017 8values.",
            license: "MIT (full text bundled with the quiz)"
        ),
        TestDefinition(
            id: "theovalues",
            title: "TheoValues",
            subtitle: "A values quiz by neomediavalist",
            entryPage: "index.html",
            credits: "TheoValues by neomediavalist (https://github.com/neomediavalist/theovalues).",
            license: "CC BY-NC-SA 4.0"
        ),
        TestDefinition(
            id: "religioquest",
            title: "ReligioQuest",
            subtitle: "A values quiz by neomediavalist",
            entryPage: "index.html",
            credits: "ReligioQuest by neomediavalist (https://github.com/neomediavalist/ReligioQuest).",
            license: "CC BY-NC-SA 4.0"
        ),
        TestDefinition(
            id: "mytests",
            title: "MyTests",
            subtitle: "A collection of quizzes by neomediavalist",
            entryPage: "index.html",
            credits: "MyTests by neomediavalist (https://github.com/neomediavalist/mytests).",
            license: "CC BY-NC-SA 4.0"
        )
    ]

    /// The tests that are served from the Web folder.
    static var ids: Set<String> {
        Set(all.filter { $0.kind == .web }.map { $0.id })
    }

    /// The tests listed under Saved results and in the credits.
    static var primary: [TestDefinition] {
        all.filter { $0.isPrimary }
    }
}
