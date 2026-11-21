import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section("Tests") {
                ForEach(TestCatalog.all) { test in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(test.title)
                            .font(.headline)
                        Text(test.credits)
                            .font(.footnote)
                        Text("License: " + test.license)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            Section("This app") {
                Text("Personal, non-commercial use only. Not for distribution.")
                Text("Your answers are saved on this device after every question. An unfinished test can be resumed, and finished results are kept under Saved results.")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
