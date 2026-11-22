import SwiftUI

extension Color {
    /// Reads "#RRGGBB" or "#RRGGBBAA", the formats the NeoValues data uses for ideology colors.
    init(neoHex hex: String?) {
        let digits = (hex ?? "").trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard digits.count == 6 || digits.count == 8, let value = UInt64(digits, radix: 16) else {
            self = Color.gray
            return
        }
        let hasAlpha = digits.count == 8
        let red = Double((value >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let green = Double((value >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let blue = Double((value >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let alpha = hasAlpha ? Double(value & 0xFF) / 255 : 1
        self = Color(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}

/// The native NeoValues test: loads the data, then shows the questions and the results.
struct NeoValuesFlow: View {
    let test: TestDefinition

    var body: some View {
        switch NeoValuesData.bundled {
        case .success(let data):
            NeoValuesPlayView(test: test, data: data)
        case .failure(let error):
            Text(error.localizedDescription)
                .padding()
        }
    }
}

struct NeoValuesPlayView: View {
    let test: TestDefinition
    let data: NeoValuesData

    @StateObject private var quiz: NeoValuesQuiz
    @State private var match: NeoValuesMatch?
    @State private var saveFailed = false

    init(test: TestDefinition, data: NeoValuesData) {
        self.test = test
        self.data = data
        let saved = ProgressStore.load(test.id).flatMap { NeoValuesQuiz.Snapshot.decode(from: $0.state) }
        _quiz = StateObject(wrappedValue: NeoValuesQuiz(data: data, snapshot: saved))
    }

    var body: some View {
        Group {
            if let match {
                NeoValuesResultsView(
                    data: data,
                    answers: quiz.results,
                    match: match,
                    saveFailed: saveFailed,
                    onRetake: retake
                )
            } else {
                NeoValuesQuestionView(quiz: quiz, onChoose: choose, onBack: goBack)
            }
        }
    }

    private func choose(_ option: NeoValuesOption) {
        quiz.choose(option)
        if quiz.isFinished {
            finish()
        } else {
            saveProgress()
        }
    }

    private func goBack() {
        guard quiz.back() else { return }
        saveProgress()
    }

    /// Keeps the unfinished quiz after every answer, so it can be resumed.
    private func saveProgress() {
        if quiz.history.isEmpty {
            ProgressStore.clear(test.id)
        } else if let text = quiz.snapshot.encoded() {
            try? ProgressStore.save(state: text, for: test.id)
        }
    }

    private func finish() {
        let result = NeoValuesMatcher(data: data).match(quiz.results)
        match = result
        let lines = NeoValuesSummary.lines(data: data, answers: quiz.results, match: result)
        do {
            try ResultStore.shared.completeNative(lines: lines, for: test)
            saveFailed = false
        } catch {
            saveFailed = true
        }
    }

    private func retake() {
        ProgressStore.clear(test.id)
        quiz.reset()
        match = nil
    }
}

struct NeoValuesQuestionView: View {
    @ObservedObject var quiz: NeoValuesQuiz
    let onChoose: (NeoValuesOption) -> Void
    let onBack: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                if let node = quiz.currentNode {
                    Text(node.text ?? "")
                        .font(.title3.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(Array((node.options ?? []).enumerated()), id: \.offset) { _, option in
                        Button {
                            onChoose(option)
                        } label: {
                            Text(option.text)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 6)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button("Previous question") {
                    onBack()
                }
                .disabled(quiz.history.isEmpty)
                .padding(.top, 8)
            }
            .padding()
        }
        .id(String(quiz.categoryIndex) + "/" + quiz.nodeId)
    }

    private var header: some View {
        let total = max(quiz.data.categories.count, 1)
        let title = quiz.currentCategory.map { quiz.data.categoryTitle($0) } ?? ""
        return VStack(alignment: .leading, spacing: 6) {
            ProgressView(value: Double(min(quiz.categoryIndex, total)), total: Double(total))
            Text("Category " + String(min(quiz.categoryIndex + 1, total)) + " of " + String(total) + ": " + title)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}

struct NeoValuesResultsView: View {
    let data: NeoValuesData
    let answers: [String: String]
    let match: NeoValuesMatch
    let saveFailed: Bool
    let onRetake: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section("Closest ideology") {
                if let exact = match.exact {
                    ideologyRow(exact)
                } else {
                    Text("No exact match")
                }
                if let next = match.nextClosest, let ideology = findIdeology(named: next.name) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Next closest match")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ideologyRow(ideology)
                        Text(String(next.identicalCount) + " of " + String(next.totalRequired) + " values match")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Your values") {
                ForEach(data.categories, id: \.self) { category in
                    if let valueID = answers[category] {
                        NavigationLink {
                            NeoValuesValueView(
                                categoryTitle: data.categoryTitle(category),
                                name: data.valueName(category, valueID),
                                description: data.value(category, valueID)?.description
                            )
                        } label: {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(data.categoryTitle(category))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(data.valueName(category, valueID))
                            }
                        }
                    }
                }
            }

            Section {
                if saveFailed {
                    Text("This result could not be saved to Files.")
                        .foregroundStyle(.red)
                } else {
                    Text("Saved to Files, in Political Tests.")
                        .foregroundStyle(.secondary)
                }
                Button("Take the test again") {
                    onRetake()
                }
                Button("Done") {
                    dismiss()
                }
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func findIdeology(named name: String) -> NeoValuesIdeology? {
        data.ideologies.first { $0.name == name }
    }

    private func ideologyRow(_ ideology: NeoValuesIdeology) -> some View {
        NavigationLink {
            NeoValuesIdeologyView(data: data, ideology: ideology, answers: answers)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(Color(neoHex: ideology.color))
                    .frame(width: 14, height: 14)
                Text(ideology.name)
                    .font(.headline)
            }
        }
    }
}

struct NeoValuesIdeologyView: View {
    let data: NeoValuesData
    let ideology: NeoValuesIdeology
    let answers: [String: String]

    var body: some View {
        List {
            Section {
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color(neoHex: ideology.color))
                        .frame(width: 14, height: 14)
                    Text(ideology.group ?? "Ideology")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text(ideology.description ?? "No description available.")
                    .textSelection(.enabled)
            }

            Section("Required values") {
                ForEach(ideology.requirements) { requirement in
                    let matches = answers[requirement.category].map { requirement.allowed.contains($0) } ?? false
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: matches ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(matches ? Color.green : Color.secondary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(data.categoryTitle(requirement.category))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(requirement.allowed.map { data.valueName(requirement.category, $0) }.joined(separator: ", "))
                        }
                    }
                }
            }
        }
        .navigationTitle(ideology.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NeoValuesValueView: View {
    let categoryTitle: String
    let name: String
    let description: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(categoryTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(name)
                    .font(.title2.weight(.semibold))
                Text(description ?? "No description available.")
                    .textSelection(.enabled)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .navigationTitle(name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
