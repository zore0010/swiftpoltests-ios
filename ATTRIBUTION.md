# Attribution and credits

## NeoValues

- **Original work:** NeoValues by **neomediavalist**. https://github.com/neomediavalist/neovalues
- **Bundled from:** the fork https://github.com/zore0010/neovalues at commit `b8dce4ef53d507763baddd7bcb634bcccd31eb88`.
- **License:** Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0).
  Legal code: https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode
- The upstream project was MIT licensed before version 1.0. Copies made before that change remain under MIT.
- Icons carry their own licenses and credits, listed with their sources in the NeoValues data.

## NeoValues, native version

- The native NeoValues screens port the matching rules in the fork's `results.html` and the question flow in its `quiz.js`.
  The questions, descriptions and values come from the same pinned fork. `scripts/golden-neovalues.js` runs the original
  scoring and quiz code to produce the reference results the Swift tests use.

## 12Axes

- **Original work:** the 12Axes quiz in the politicaltests project, copyright (c) 2020 8values (SapplyValues).
  https://github.com/politicaltests/politicaltests.github.io
- **Bundled from:** the `12axes` folder at commit `5a508de557cc88eb7e9a44d89f45501dbe912d61`.
- **License:** MIT. The full license text is bundled with the quiz at `tests/axes/LICENSE-MIT.txt`.

## What this app adds

- The native menu, the WebView screens, the `app://` scheme handler, and the storage of progress and results.
- `App/OverlayScript.swift`, which saves and restores each quiz. It wraps the quizzes' own functions and does not
  edit their files.
- The tests, scripts, and documentation in this repository.
