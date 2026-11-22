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
                Text("Shared under CC BY-NC-SA 4.0. Credit the authors listed here, and share any changes under the same license.")
                Text("Your answers are saved on this device after every question. An unfinished test can be resumed, and finished results are kept under Saved results.")
            }

            Section("Legal") {
                NavigationLink("Privacy policy and legal notice") {
                    LegalView()
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
