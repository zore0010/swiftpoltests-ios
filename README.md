# Political Tests

An iOS app with two political-values quizzes behind one menu:

- **NeoValues**, bundled from the fork of neomediavalist's project.
- **12 Axes**, the MIT-licensed quiz from the politicaltests project.

Both save every answer as you go. An unfinished quiz can be resumed after a misclick or a restart, and each
finished result is kept under Saved results.

License: CC BY-NC-SA 4.0 for this project. Credits and the MIT notices are in `ATTRIBUTION.md` and in the app's About screen.

## How the quizzes are built

`scripts/fetch-sources.sh` clones each source at a pinned commit and copies only the quiz folder into `Web/`.
The pins are at the top of that script. The bundled quizzes are not edited.

`App/OverlayScript.swift` is the one piece of JavaScript written for this app. It is added to each quiz page
and wraps the quiz's own functions to save and restore state.

## Build

CI (push to `main`, or run the iOS workflow by hand) produces an unsigned `WKWVTests-unsigned-ipa` artifact.
If a step fails, the errors are listed on the run's summary page.

Locally (macOS only):

```bash
bash scripts/fetch-sources.sh Web
brew install xcodegen
xcodegen generate
open WKWVTests.xcodeproj
```

## Layout

| Path | Purpose |
| --- | --- |
| `App/` | SwiftUI menu, WebView screen, scheme handler, progress and history storage, About screen |
| `App/OverlayScript.swift` | The overlay that saves and restores each quiz |
| `Tests/` | Routing and storage tests |
| `scripts/fetch-sources.sh` | Builds `Web/` from the pinned sources |
| `project.yml` | XcodeGen project (the `.xcodeproj` is generated, not committed) |
| `.github/workflows/ios.yml` | CI: fetch, test, archive, IPA artifact |

## Not done yet

- Native UI for the quizzes (for now the menu opens the web versions).
- A viewer for the history beyond the simple list.
- Automatic updates for NeoValues (the bundled commit is fixed).
