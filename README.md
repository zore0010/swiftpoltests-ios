# Political Tests (SwiftPolTest)

An iOS app with two political-values quizzes behind one menu, built in SwiftUI:

- **NeoValues**, rebuilt natively in SwiftUI from the fork of neomediavalist's project. The questions, descriptions and matching rules are the original ones.
- **NeoValues (web)**, the original NeoValues web pages, in a WebKit screen.
- **12 Axes**, the MIT-licensed quiz from the politicaltests project, in a WebKit screen.

Each quiz saves every answer as you go. An unfinished quiz can be resumed after a misclick or a restart, and each
finished result is saved as a readable Markdown file in Files > Political Tests.

License: CC BY-NC-SA 4.0 for this project. Credits and the MIT notices are in `ATTRIBUTION.md` and in the app's
About screen. Privacy policy, legal notice and license are `PRIVACY.md`, `LEGAL_NOTICE.md` and `LICENSE`; the app
shows the same text.

## How the quizzes are built

`scripts/fetch-sources.sh` clones each source at a pinned commit. It then:

- copies the quiz folders into `Web/` for the WebKit screens, and removes the excluded ideologies with
  `scripts/filter-neovalues.js` (the list is in `scripts/neovalues-exclusions.json`);
- exports the native NeoValues data into `Generated/neovalues/` with `scripts/export-neovalues.js`;
- writes `Tests/neovalues-golden.json` with `scripts/golden-neovalues.js`, which runs NeoValues' own scoring
  (`results.html`) and quiz logic (`quiz.js`) in Node, so the Swift tests compare against the original code;
- copies the legal documents into `Generated/legal/`.

The pins are at the top of the script. The bundled quizzes are not edited.

`App/OverlayScript.swift` is the one piece of JavaScript written for this app. It is added to each web quiz page
and wraps the quiz's own functions to save and restore state.

`App/NeoValues/` is the native NeoValues: `NeoValuesData` loads the exported data, `NeoValuesQuiz` walks the
question tree like `quiz.js`, `NeoValuesMatcher` ports the matching in `results.html`, and the views show the
questions and results.

## Build

CI (push to `main`, or run the iOS workflow by hand) runs the tests and produces an unsigned `SwiftPolTest-unsigned-ipa`
artifact. If a step fails, the errors are listed on the run's summary page.

Locally (macOS only, Node needed for the fetch step):

```bash
bash scripts/fetch-sources.sh Web
brew install xcodegen
xcodegen generate
open SwiftPolTest.xcodeproj
```

## Layout

| Path | Purpose |
| --- | --- |
| `App/` | SwiftUI menu, WebView screen, scheme handler, progress and result storage, About and legal screens |
| `App/NeoValues/` | Native NeoValues: data, quiz engine, matcher, views |
| `App/OverlayScript.swift` | The overlay that saves and restores each web quiz |
| `App/AxesSpec.swift` | The 12 Axes names, poles, and score bands |
| `Tests/` | Routing, storage, legal text, and NeoValues tests (matching and quiz checked against the original code) |
| `scripts/fetch-sources.sh` | Builds `Web/`, `Generated/` and the golden reference from the pinned sources |
| `scripts/export-neovalues.js` | Exports the NeoValues data as JSON |
| `scripts/golden-neovalues.js` | Writes the reference results from the original NeoValues code |
| `project.yml` | XcodeGen project (the `.xcodeproj` is generated, not committed) |
| `.github/workflows/ios.yml` | CI: fetch, test, archive, IPA artifact |
