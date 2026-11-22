import SwiftUI

struct AboutView: View {
    var body: some View {
        List {
            Section("Tests") {
                ForEach(TestCatalog.primary) { test in
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
                Text("The code and documentation of this app are shared under CC BY-NC-SA 4.0. NeoValues is CC BY-NC-SA 4.0 by its author, and 12Axes is under the MIT License. Credit the authors listed here, and share changes under the same license where it requires that.")
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
