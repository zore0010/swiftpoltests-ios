# Political Tests (SwiftPolTest)

An iOS app that puts several political-values quizzes behind one menu. It is built in SwiftUI, with the quizzes
themselves shown in WebKit screens, except NeoValues, which is rebuilt natively.

## Quizzes

| Quiz | How it is shown | License |
| --- | --- | --- |
| NeoValues | Native SwiftUI, from the fork of neomediavalist's project | CC BY-NC-SA 4.0 |
| NeoValues (web) | The original web pages, in WebKit | CC BY-NC-SA 4.0 |
| 12 Axes | WebKit | MIT |
| AuthValues | WebKit | MIT |
| InfValues | WebKit | MIT |
| RightValues | WebKit | MIT |
| 10Groups | WebKit | MIT |
| 8Dreams | WebKit | MIT |
| TheoValues | WebKit | CC BY-NC-SA 4.0 |
| ReligioQuest | WebKit | CC BY-NC-SA 4.0 |
| MyTests | WebKit | CC BY-NC-SA 4.0 |

Not every quiz saves yet. Resume and saved results work for NeoValues (native), NeoValues (web) and 12 Axes. The other
quizzes open and can be answered, but their answers are not saved and their results are not written to Files.

Finished results of the NeoValues and 12 Axes quizzes are saved as readable Markdown files in Files > Political Tests.

## Licenses and credits

The code and documentation of this project are under CC BY-NC-SA 4.0. Each quiz keeps its own license, and its license
text is bundled with it. Credits are in `ATTRIBUTION.md` and on the About screen. The privacy policy, legal notice and
license are `PRIVACY.md`, `LEGAL_NOTICE.md` and `LICENSE`. The app shows the same text.

The app makes no network connections. Every script, stylesheet and font the quizzes use is bundled inside the app.
Analytics and advertising code has been removed from the imported quizzes, and the fascist ideologies have been removed
from their data.

## Source of the quizzes

`scripts/fetch-sources.sh` clones every source at a pinned commit and then:

- copies the quiz folders into `Web/tests/`, and removes the excluded NeoValues ideologies with
  `scripts/filter-neovalues.js` (the list is in `scripts/neovalues-exclusions.json`);
- runs `scripts/import-tests.js` on the imported quizzes. It removes analytics and advertising code, downloads every
  script, stylesheet and font into each quiz's `vendor/` folder, removes the fascist ideologies, makes the paths relative,
  and fails the build if an external resource or a missing local file is still referenced;
- exports the native NeoValues data into `Generated/neovalues/` with `scripts/export-neovalues.js`;
- writes `Tests/neovalues-golden.json` with `scripts/golden-neovalues.js`, which runs NeoValues' own scoring
  (`results.html`) and quiz logic (`quiz.js`) in Node, so the Swift tests compare against the original code;
- copies the legal documents into `Generated/legal/`.

The pinned commits are listed in the script. The quizzes are not edited, except for the changes above.

`App/OverlayScript.swift` is the one piece of JavaScript written for this app. It is added to the 12 Axes and NeoValues
(web) pages and wraps their own functions to save and restore state. The other quizzes are not covered yet.

`App/NeoValues/` is the native NeoValues: `NeoValuesData` loads the exported data, `NeoValuesQuiz` walks the question
tree like `quiz.js`, `NeoValuesMatcher` ports the matching in `results.html`, and the views show the questions and results.

## Build

CI runs on pushes to `main` and on pull requests. It fetches the sources, runs the unit tests, and archives an unsigned
`SwiftPolTest-unsigned-ipa` artifact. A failed step is listed on the run's summary page.

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
| `App/OverlayScript.swift` | The overlay that saves and restores the 12 Axes and NeoValues (web) quizzes |
| `App/AxesSpec.swift` | The 12 Axes names, poles, and score bands |
| `App/Assets.xcassets/` | The app icon |
| `Tests/` | Routing, storage, legal text, and NeoValues tests (matching and quiz checked against the original code) |
| `scripts/fetch-sources.sh` | Builds `Web/`, `Generated/` and the golden reference from the pinned sources |
| `scripts/import-tests.js` | Prepares the imported quizzes: analytics removed, everything bundled, paths fixed, checks |
| `scripts/export-neovalues.js` | Exports the NeoValues data as JSON |
| `scripts/golden-neovalues.js` | Writes the reference results from the original NeoValues code |
| `project.yml` | XcodeGen project (the `.xcodeproj` is generated, not committed) |
| `.github/workflows/ios.yml` | CI: fetch, test, archive, IPA artifact |
