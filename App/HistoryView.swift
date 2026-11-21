import SwiftUI

struct HistoryView: View {
    let test: TestDefinition
    @State private var entries: [ProgressStore.HistoryEntry] = []

    var body: some View {
        List {
            if entries.isEmpty {
                Text("No completed results yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(entries) { entry in
                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.headline)
                    Text(ResultSummary.text(for: entry.payload))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .onDelete(perform: delete)
        }
        .navigationTitle(test.title + " results")
        .onAppear(perform: reload)
    }

    private func reload() {
        entries = ProgressStore.history(for: test.id)
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            try? ProgressStore.deleteEntry(entries[index], for: test.id)
        }
        reload()
    }
}

/// A short, readable line for each saved result.
enum ResultSummary {
    static func text(for payload: String) -> String {
        guard let data = payload.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Saved result"
        }

        // NeoValues: category -> chosen value.
        if let results = object["results"] as? [String: Any] {
            return results.keys.sorted().map { key -> String in
                key + ": " + String(describing: results[key] ?? "")
            }.joined(separator: "\n")
        }

        // 12 Axes: the result page's query string holds one score per axis.
        if let query = object["query"] as? String,
           let components = URLComponents(string: "https://localhost/results" + query),
           let items = components.queryItems, !items.isEmpty {
            return items.map { $0.name + ": " + ($0.value ?? "") }.joined(separator: "  ")
        }

        return "Saved result"
    }
}
