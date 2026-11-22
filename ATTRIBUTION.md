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

## politicaltests: 12Axes, AuthValues, InfValues

- **Original work:** the politicaltests project, copyright (c) 2020 8values (SapplyValues).
  https://github.com/politicaltests/politicaltests.github.io
- **Bundled from:** the `12axes`, `auth` and `inf` folders at commit `5a508de557cc88eb7e9a44d89f45501dbe912d61`.
- **License:** MIT. The full license text is bundled with each quiz at `LICENSE-MIT.txt`.

## RightValues

- **Original work:** https://github.com/rightvaluestest/rightvaluestest.github.io, at commit `e655d615423757c9d207c4542274e35603b28873`.
- **License:** MIT. The license text is bundled with the quiz at `LICENSE.txt`.

## 10Groups

- **Original work:** https://github.com/10Groups/10groups.github.io, at commit `f984ba4b9240daceaf1b335bb9b69ab8afa81c10`, from the original 8values.
- **License:** MIT. The license text is bundled with the quiz at `LICENSE.txt`.

## 8Dreams

- **Original work:** copyright (c) 2017 8values. https://github.com/8Dreams/8dreams.github.io, at commit `80ca1ca25482e215e5b2e42c4734200ff2a9d873`.
- **License:** MIT. The repository has no LICENSE file; the license text from its license page is bundled at `LICENSE.txt`.

## TheoValues, ReligioQuest, MyTests

- **Original work:** neomediavalist. https://github.com/neomediavalist/theovalues (commit `bae011807dd280c538d2a4cf2ef9688660a0cf45`), https://github.com/neomediavalist/ReligioQuest (commit `46b945cd122cb6e6e41647cb4b67047b5634b1a6`), https://github.com/neomediavalist/mytests (commit `8be6c831495aed1fc52f5fc1343d4cac3fd8a045`).
- **License:** CC BY-NC-SA 4.0. The license text is bundled with each quiz at `LICENSE.txt`.

## Libraries and fonts bundled with the quizzes

- **jQuery** 3.5.1 and 1.10.2: MIT. https://jquery.com
- **list.js** 2.3.1: MIT. https://listjs.com
- **html2canvas** 1.0.0-rc.5 and 0.4.1: MIT. https://html2canvas.hertzen.com
- **Font Awesome Free** 5.15.4: icons CC BY 4.0, fonts SIL OFL 1.1, code MIT. https://fontawesome.com
- **Google Fonts** (Montserrat, Roboto, Quicksand): SIL Open Font License 1.1. https://fonts.google.com

## What this app adds

- The native menu, the WebView screens, the `app://` scheme handler, and the storage of progress and results.
- `App/OverlayScript.swift`, which saves and restores each quiz. It wraps the quizzes' own functions and does not
  edit their files.
- The native NeoValues screens in `App/NeoValues/`.
- For the imported quizzes: analytics and advertising code was removed, and every script, stylesheet and font they load
  is bundled instead of being loaded from the network. The ideologies named Fascism, Italian Fascism, National Socialism,
  Nazism and Neo-Fascism were removed from their data. This is done by `scripts/import-tests.js`.
- The tests, scripts, and documentation in this repository.
