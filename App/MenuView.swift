import SwiftUI

struct MenuView: View {
    @ObservedObject private var results = ResultStore.shared
    @State private var pendingTest: TestDefinition?
    @State private var openTest: TestDefinition?

    var body: some View {
        NavigationStack {
            List {
                Section("Tests") {
                    ForEach(TestCatalog.all) { test in
                        Button {
                            choose(test)
                        } label: {
                            TestRow(test: test, unfinished: results.unfinished.contains(test.id))
                        }
                    }
                }

                Section("Saved results") {
                    ForEach(TestCatalog.all) { test in
                        NavigationLink {
                            HistoryView(test: test)
                        } label: {
                            Label("\(test.title) (\(results.counts[test.id] ?? 0))", systemImage: "clock")
                        }
                    }
                }

                Section {
                    NavigationLink("About and credits") {
                        AboutView()
                    }
                }
            }
            .navigationTitle("Political Tests")
            .onAppear {
                results.reload()
            }
            .onChange(of: openTest?.id) { _ in
                results.reload()
            }
            .confirmationDialog(
                pendingTest.map { "\($0.title): unfinished answers" } ?? "Unfinished answers",
                isPresented: Binding(
                    get: { pendingTest != nil },
                    set: { if !$0 { pendingTest = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Resume") {
                    openTest = pendingTest
                    pendingTest = nil
                }
                Button("Start over", role: .destructive) {
                    if let test = pendingTest {
                        ProgressStore.clear(test.id)
                    }
                    openTest = pendingTest
                    pendingTest = nil
                }
                Button("Cancel", role: .cancel) {
                    pendingTest = nil
                }
            } message: {
                Text("Resume where you left off, or start the test again from the beginning.")
            }
            .fullScreenCover(item: $openTest) { test in
                TestScreen(test: test)
            }
        }
    }

    /// Tests with an unfinished session ask first, so a misclick never throws progress away.
    private func choose(_ test: TestDefinition) {
        if ProgressStore.load(test.id) != nil {
            pendingTest = test
        } else {
            openTest = test
        }
    }
}

struct TestRow: View {
    let test: TestDefinition
    let unfinished: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(test.title)
                    .font(.headline)
                if unfinished {
                    Spacer()
                    Text("In progress")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            Text(test.subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct TestScreen: View {
    let test: TestDefinition
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TestWebView(test: test, webRoot: AppPaths.webRoot)
                .navigationTitle(test.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Menu") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
