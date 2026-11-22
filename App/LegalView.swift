import SwiftUI

/// The legal documents of this repository. scripts/fetch-sources.sh copies them into Generated/legal
/// at build time, so the app always shows the same text as the files in the repository.
enum LegalDocument: String, CaseIterable, Identifiable {
    case privacy
    case notice
    case license
    case attribution

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: return "Privacy policy"
        case .notice: return "Legal notice"
        case .license: return "License"
        case .attribution: return "Credits and attribution"
        }
    }

    var fileName: String {
        switch self {
        case .privacy: return "PRIVACY.md"
        case .notice: return "LEGAL_NOTICE.md"
        case .license: return "LICENSE"
        case .attribution: return "ATTRIBUTION.md"
        }
    }

    var isMarkdown: Bool {
        self != .license
    }

    func text() -> String? {
        guard let root = Bundle.main.url(forResource: "Generated", withExtension: nil) else { return nil }
        let url = root
            .appendingPathComponent("legal", isDirectory: true)
            .appendingPathComponent(fileName)
        return try? String(contentsOf: url, encoding: .utf8)
    }
}

/// The few Markdown elements the documents use.
enum MarkdownBlock: Equatable {
    case heading(level: Int, text: String)
    case bullet(String)
    case paragraph(String)
    case divider

    static func parse(_ markdown: String) -> [MarkdownBlock] {
        var blocks: [MarkdownBlock] = []
        for raw in markdown.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty {
                continue
            }
            if line == "---" {
                blocks.append(.divider)
            } else if line.hasPrefix("[English](") {
                // The language links at the top of the legal notice. Both sections follow in order.
                continue
            } else if line.hasPrefix("### ") {
                blocks.append(.heading(level: 3, text: String(line.dropFirst(4))))
            } else if line.hasPrefix("## ") {
                blocks.append(.heading(level: 2, text: String(line.dropFirst(3))))
            } else if line.hasPrefix("# ") {
                blocks.append(.heading(level: 1, text: String(line.dropFirst(2))))
            } else if line.hasPrefix("- ") {
                blocks.append(.bullet(String(line.dropFirst(2))))
            } else {
                blocks.append(.paragraph(line))
            }
        }
        return blocks
    }
}

struct MarkdownDocumentView: View {
    let blocks: [MarkdownBlock]

    init(markdown: String) {
        blocks = MarkdownBlock.parse(markdown)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                    row(for: block)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .textSelection(.enabled)
        }
    }

    @ViewBuilder
    private func row(for block: MarkdownBlock) -> some View {
        switch block {
        case .heading(let level, let text):
            Text(inline(text))
                .font(font(for: level))
                .padding(.top, level == 1 ? 0 : 6)
        case .bullet(let text):
            HStack(alignment: .top, spacing: 8) {
                Text("•")
                Text(inline(text))
            }
        case .paragraph(let text):
            Text(inline(text))
        case .divider:
            Divider()
        }
    }

    private func font(for level: Int) -> Font {
        switch level {
        case 1: return Font.title2.bold()
        case 2: return Font.title3.bold()
        default: return Font.headline
        }
    }

    private func inline(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

struct LegalDocumentView: View {
    let document: LegalDocument

    var body: some View {
        Group {
            if let text = document.text() {
                if document.isMarkdown {
                    MarkdownDocumentView(markdown: text)
                } else {
                    ScrollView {
                        Text(text)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .textSelection(.enabled)
                    }
                }
            } else {
                Text("This document is missing from the app bundle.")
                    .padding()
            }
        }
        .navigationTitle(document.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Privacy policy, legal notice, license and credits, shown from the About screen.
struct LegalView: View {
    var body: some View {
        List {
            ForEach(LegalDocument.allCases) { document in
                NavigationLink(document.title) {
                    LegalDocumentView(document: document)
                }
            }
        }
        .navigationTitle("Privacy and legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
