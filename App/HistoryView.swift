import SwiftUI

struct HistoryView: View {
    let test: TestDefinition
    @ObservedObject private var results = ResultStore.shared
    @State private var files: [URL] = []

    var body: some View {
        List {
            if files.isEmpty {
                Text("No finished results yet.")
                    .foregroundStyle(.secondary)
            }

            ForEach(files, id: \.self) { url in
                NavigationLink {
                    ResultDetailView(url: url)
                } label: {
                    Text(ResultStore.date(for: url).map { ResultFormat.displayDate($0) } ?? url.lastPathComponent)
                }
            }
            .onDelete { offsets in
                for index in offsets {
                    results.delete(files[index])
                }
                files = ResultStore.files(for: test.resultsFolder)
            }
        }
        .navigationTitle(test.title)
        .onAppear {
            files = ResultStore.files(for: test.resultsFolder)
        }
        .onChange(of: results.counts[test.id]) { _ in
            files = ResultStore.files(for: test.resultsFolder)
        }
    }
}

/// Shows one saved result as the text stored in its file, with a share button.
struct ResultDetailView: View {
    let url: URL

    var body: some View {
        ScrollView {
            Text(text)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .textSelection(.enabled)
        }
        .navigationTitle("Result")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: url)
            }
        }
    }

    private var text: String {
        (try? String(contentsOf: url, encoding: .utf8)) ?? "This result could not be read."
    }
}
