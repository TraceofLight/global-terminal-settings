# UX Contract

This document defines what must stay consistent between Windows and macOS, and what is allowed to vary by platform.

## Must Match

- The terminal application is `WezTerm`
- The default interactive shell is `NuShell`
- The default prompt is `Starship`
- The color direction is `Catppuccin Mocha`
- The baseline background style uses `window_background_opacity = 0.8`
- Windows uses `Acrylic`; macOS uses blur `20`
- The default font is `Monoplex KR Wide Nerd`
- `vi` and `vim` resolve to `nvim`
- `EDITOR` and `VISUAL` are both `nvim`
- Shared navigation tools are `rg`, `fd`, `fzf`, and `zoxide`
- Shared command completion baseline includes `carapace`
- The Git TUI is `lazygit`
- The Neovim UX follows the current `LazyVim` snapshot
- The installation guides use the same stage numbers and meanings

## May Differ

- Package manager choice
- External tool installation method
- Actual binary paths on each OS
- Clipboard implementation details
- The physical standard location of NuShell config files

## Command Policy

- Default list view: `ls` -> `lsd`
- Detailed list view: `ll`, `la`
- Tree view: `lt`
- Everyday file discovery: `fd`
- Everyday text search: `rg`
- Directory jumping: `zoxide`
- Command completion: `carapace`
- Editor launch: `nvim`
- Short edit aliases: `vi`, `vim`
- If `claude` or `openclaude` is installed, NuShell should expose the matching managed extern layer without breaking startup when the command is absent

## Prompt Policy

- The shared prompt baseline is `Starship`
- The leftmost prompt segment is the current OS symbol (`Macos`, `Ubuntu`, `Debian`, `Linux`, or `Windows`)
- The prompt should prioritize current context, Git state, and timing over decorative noise
- A fresh NuShell session should drop directly into the normal working flow
- The WezTerm baseline uses a single left prompt
- NuShell's built-in `vi` indicators and right-prompt path are disabled
- `autoload/zz-prompt-overrides.nu` is the managed late-load guard that reasserts the single left-prompt policy after generated autoload files
- The shared WezTerm + NuShell baseline disables `shell_integration.osc133` across all platforms

## Prompt Segments

Shared left-prompt layout lives in `shared/starship/starship.toml`. Segments, in order:

| # | Segment | Background | Purpose |
| --- | --- | --- | --- |
| 1 | `$os` | peach | OS indicator |
| 2 | `$directory` | mauve | Current path, 3-component truncation, prefix `…/` |
| 3 | `$git_branch` + `$git_status` | blue | Branch icon, branch name, Git status flags |
| 4 | `$cmd_duration` | surface overlay | Shown when the previous command ran over 2s |
| 5 | `$character` | — | `❯` on success, red on failure, `<` in Vi command mode |

### Glyph codepoint policy

OS and branch glyphs use Nerd Font Material Design (`md-*`) codepoints in the **supplementary PUA** (U+F0000–U+FFFFF, 4-byte UTF-8). Legacy BMP PUA codepoints (U+E000–U+F8FF — for example U+F179 Apple, U+F31B Ubuntu, U+E0A0 Powerline branch) are intentionally avoided: the current WezTerm + `Monoplex KR Wide Nerd` combination reports cmap coverage for those codepoints but renders blank cells in practice. The supplementary-PUA range falls back reliably to the built-in `Symbols Nerd Font Mono`, so any cell that does not match a bundled glyph still renders.

| Slot | Glyph | Codepoint | Nerd Font name |
| --- | --- | --- | --- |
| `os.symbols.Macos` | `󰀵` | U+F0035 | `md-apple` |
| `os.symbols.Ubuntu` | `󰕈` | U+F0548 | `md-ubuntu` |
| `os.symbols.Debian` | `󰣚` | U+F08DA | `md-debian` |
| `os.symbols.Linux` | `󰌽` | U+F033D | `md-linux` |
| `os.symbols.Windows` | `󰍲` | U+F0372 | `md-microsoft-windows` |
| `git_branch.symbol` | `󰘬` | U+F062C | `md-source-branch` |

### Padding

Segment format strings use single-space left/right padding by default. Two exceptions:

- `$os` uses an extra trailing space so the peach-colored block reads as a label, not a stray icon.
- `$git_branch.symbol` includes two trailing spaces so the branch icon does not collide with the branch name.

## Font Policy

- Fonts are not downloaded externally during installation
- Files under `shared/fonts/` are treated as the installation source
- Fonts are staged into the per-user install root under `fonts/`
- WezTerm loads them directly through `font_dirs`

## Editor Policy

- The source-of-truth asset is `shared/nvim`
- `nvim-data` is not a managed shared asset
- Caches and package-managed binaries are regenerated per OS
