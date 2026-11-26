# swiftnav.nvim

Xcode-style navigation for Swift in Neovim: Open Quickly, document items, a
breadcrumb jump bar, Related Items, and `gd`/`gr`/`gi` that keep working in
Xcode app targets where sourcekit-lsp has no build index.

## Why

sourcekit-lsp is the same engine Xcode uses, but it only indexes what it can
build. An iOS or macOS app target with no `Package.swift`, `buildServer.json`
or `compile_commands.json` gives it nothing to index, so go-to-definition and
find-references return empty even though the server is attached.

swiftnav keeps a project-wide declaration index as a fallback and uses
sourcekit first wherever it does have build settings. The index is built with
ripgrep, cached to disk, and patched as files change.

## Features

- **Open Quickly** (`:SwiftOpen`) — ranked workspace symbols, files and recent
  edits with a live preview. Ranks types above members, prefers the current
  file, and remembers what you open.
- **Document Items** (`:SwiftJump`) — the current file's declarations in order,
  the way Xcode's Control-6 menu lists them.
- **Jump bar** — `File › Type › member` in the winbar, following the cursor.
- **Related Items** (`:SwiftRelated`) — callers, callees, overrides,
  conformances, supertypes, subtypes and references in one popup.
- **Navigation with fallbacks** — `gd`, `gD`, `gy`, `gi`, `gr`, `grr`, `gri`,
  `grt`, `K`, `gO` and `<C-]>`, all LSP-first and index-backed.
- **Swift-aware ranking** — current file, target folder and enclosing type beat
  a distant match; camel-case initials (`BVC` → `ButtonViewController`) work.
- **Index cache** — ~170ms to build a 70k-symbol repository, ~60ms to load it
  next session, a few milliseconds to patch changed files.

## Requirements

- Neovim 0.11 or newer (developed on 0.12)
- A Swift toolchain with `sourcekit-lsp` on `PATH` (Swiftly, Xcode, or swift.org)
- [ripgrep](https://github.com/BurntSushi/ripgrep) — required for the index
- [fd](https://github.com/sharkdp/fd) — optional, faster file listing in Open Quickly
- The Swift treesitter parser (for enclosing-type resolution)

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  'guitaripod/swiftnav.nvim',
  lazy = false,
  opts = {},
}
```

With `vim.pack` or a manual clone:

```sh
git clone https://github.com/guitaripod/swiftnav.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/swiftnav.nvim
```

```lua
require('swiftnav').setup()
```

sourcekit-lsp itself is your choice of client setup. If you use Neovim's
built-in LSP:

```lua
vim.lsp.config('sourcekit', {
  cmd = { 'sourcekit-lsp' },
  filetypes = { 'swift' },
  root_markers = { 'Package.swift', 'buildServer.json', 'compile_commands.json', '.git' },
})
vim.lsp.enable('sourcekit')
```

The navigation fallbacks work without an LSP client; the LSP-first paths use it
when it is attached.

## Setup

```lua
require('swiftnav').setup({
  keymaps = {
    open = '<leader>so',
    jump = '<leader>sj',
    related = '<leader>sR',
    reveal = '<leader>sS',
  },
  index = {
    preload = true,
  },
})
```

- `keymaps` — leader maps for the four list commands, or `false` to keep your
  own. Swift buffers always get the `gd` family.
- `index.preload` — start building the declaration index shortly after a Swift
  buffer opens. Set to `false` to build only on first use.

## Keys

Swift buffers:

| Key | Action |
| --- | --- |
| `gd`, `gD`, `<C-]>` | Definition, with the project index when sourcekit has no answer |
| `gy` | Type definition |
| `gi`, `gri` | Implementations and overrides |
| `gr`, `grr` | References (sourcekit, or a project-wide search) |
| `grt` | Type definition |
| `K` | Hover, or the declaration line when the server has nothing |
| `gO` | Document items |

Global (configurable):

| Key | Action |
| --- | --- |
| `<leader>so` | Open Quickly |
| `<leader>sj` | Document items |
| `<leader>sR` | Related items |
| `<leader>sS` | Reveal in the project tree (nvim-tree) |

## Commands

| Command | Action |
| --- | --- |
| `:SwiftOpen [query]` | Open Quickly, optionally prefilled |
| `:SwiftJump` | Document items for the current file |
| `:SwiftRelated` | Related items at the cursor |
| `:SwiftReveal` | Reveal the current file in nvim-tree |
| `:SwiftIndex` | Rebuild the declaration index |
| `:SwiftWarm` | Warm sourcekit-lsp's own index for a package |

## How it works

- `swiftnav.indexer` scans the repository (nearest `.git`, `Package.swift` or
  `project.yml`) with four ripgrep passes — types, functions, type-level
  properties and enum cases — and stores the result in
  `stdpath('cache')/swiftnav/<root>.json` with file mtimes. On the next
  session it loads that cache and reconciles added, changed and deleted files in
  the background.
- Lookups rank by current file, Xcode target folder and enclosing type.
  Enclosing types come from treesitter and are cached per file.
- `swiftnav.nav` asks sourcekit first when the file has `Package.swift`,
  `buildServer.json` or `compile_commands.json` above it. Otherwise it goes
  straight to the index, which avoids a round trip that can only return
  nothing. On macOS, `xcodebuild.nvim` writes `buildServer.json`, so app
  targets use the real sourcekit index there.
- Open Quickly, Document Items and Related Items are drawn in floating windows,
  with no picker plugin dependency.

## Performance

Measured on a 2,561-file, 70k-declaration application repository:

| Operation | Time |
| --- | --- |
| First index build | ~170ms (chunked, no main-loop stall) |
| Cache load | ~60ms |
| Incremental patch after a save | < 5ms |
| `gd` warm, index fallback | ~1ms |
| References fallback (`gr`) | ~18ms |

## Troubleshooting

- **sourcekit-lsp asks whether to trust a workspace on macOS** — trust it once.
  Without trust it answers nothing, and swiftnav uses the declaration index.
- **A definition opens the right file at line 1** — sourcekit sometimes answers
  with a file-only location; 0.1.1 and later ignore those and use the index.
- **No symbols at all** — `ripgrep` must be on `PATH`; run `:SwiftIndex` to
  rebuild.

## License

GPL-3.0. See [LICENSE](LICENSE).
