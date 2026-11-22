import SwiftUI

enum LegalText {
    static let privacy = """
Privacy policy. Last updated: 22 November 2026.

What stays on your device
Your answers, unfinished tests and finished results are stored only on your device. Unfinished tests are kept in the app's private storage. Finished results are saved as text files in Files, in the Political Tests folder. You can read, share or delete them there or in the app. Deleting the app removes its private storage.

What the app does not do
It has no accounts, no sign-in, no advertising, no analytics and no tracking. The developer does not receive your answers, your results or any usage data.

Network connections
The quizzes load their fonts from Google Fonts. Google receives your IP address and the request, under Google's privacy policy. Links to other websites, and the button on the 12 Axes results screen, open in Safari and are governed by those sites' policies.

Backups
iOS may include the app's data and the Files folder in device backups (iCloud or a computer), depending on your settings.

Children
The app is not intended for children under 16.

Contact
[Add a contact email before publishing.]

This is a plain-language summary and not legal advice.
"""

    static let notice = """
Legal notice. Last updated: 22 November 2026.

Purpose
These quizzes are for education and entertainment. Results describe your answers to statements. They are not a scientific measurement, a psychological assessment or advice, and they should not be used to make decisions about anyone.

Content
The quizzes describe many political ideologies, including some that are extremist, violent or illegal in some countries. These descriptions explain what each ideology is. They are not endorsements. The app does not promote violence, hatred or discrimination against anyone. Do not use it to harass, target or threaten anyone.

Your jurisdiction
Laws differ between countries. Some countries restrict displaying, sharing or possessing material connected with certain extremist ideologies, including their symbols. You are responsible for checking what is lawful where you live before you install, use or share this app or its results. If it is not lawful for you, do not use or share it.

Sharing results
Results you export or share are yours to share, and you are responsible for what you share.

Third-party content
Each quiz belongs to its author and is used under its license. Credits and licenses are listed on the About screen. Icons, images and trademarks may have their own licenses or belong to their owners. To report content you believe is wrong or infringing, use the contact details in the privacy policy. Reported content will be reviewed and removed if needed.

No warranty
The app is provided as is, without warranties of any kind. To the extent the law allows, the developer is not liable for losses arising from its use.

This notice is not legal advice. The developer is not a lawyer.
"""
}

/// Privacy policy and legal notice, shown from the About screen.
struct LegalView: View {
    var body: some View {
        List {
            Section {
                Text(LegalText.privacy)
                    .font(.footnote)
                    .textSelection(.enabled)
            }
            Section {
                Text(LegalText.notice)
                    .font(.footnote)
                    .textSelection(.enabled)
            }
        }
        .navigationTitle("Privacy and legal")
        .navigationBarTitleDisplayMode(.inline)
    }
}
