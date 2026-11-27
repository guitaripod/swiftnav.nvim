# Changelog

## Unreleased

- Open Quickly lists indexed declarations when sourcekit-lsp returns no workspace symbols.
- Fix line numbers in files edited after the first index when they contain blank lines.
- `:SwiftNavDebug` includes the receiver type.
- Add headless test suite (`tests/run.lua`).
- Add `nav.pick_margin`, `nav.weights` and `:SwiftNavDebug` to tune and explain ranking.
- Resolve `Type.member` and `value.member` against the receiver's type.
- Add Nerd Font kind icons (`icons`), per-kind colors, match highlighting and a selection bar.
- Add `:checkhealth swiftnav`.

## 0.1.3

- Rank monorepo siblings by shared path and show their folder.
