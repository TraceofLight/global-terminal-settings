# UX Contract

This document defines what must stay consistent between Windows and macOS, and what is allowed to vary by platform.

## Must Match

- The terminal application is `WezTerm`
- The default interactive shell is `NuShell`
- The default prompt is `Starship`
- The color direction is `Catppuccin Mocha`
- The baseline background style uses `window_background_opacity = 0.8`
- Windows uses `Acrylic`; macOS uses blur `20`
- The default font is `Monoplex KR Nerd Wide`
- `vi` and `vim` resolve to `nvim`
- `EDITOR` and `VISUAL` are both `nvim`
- Shared navigation tools are `rg`, `fd`, `fzf`, and `zoxide`
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
- Editor launch: `nvim`
- Short edit aliases: `vi`, `vim`

## Prompt Policy

- The shared prompt baseline is `Starship`
- The prompt should prioritize current context, Git state, and timing over decorative noise
- A fresh NuShell session should drop directly into the normal working flow
- The WezTerm baseline uses a single left prompt
- NuShell's built-in `vi` indicators and right-prompt path are disabled
- On Windows, the WezTerm baseline disables `shell_integration.osc133`

## Font Policy

- Fonts are not downloaded externally during installation
- Files under `shared/fonts/` are treated as the installation source
- Fonts are staged into `~/.config/terminal-bootstrap/fonts/`
- WezTerm loads them directly through `font_dirs`

## Editor Policy

- The source-of-truth asset is `shared/nvim`
- `nvim-data` is not a managed shared asset
- Caches and package-managed binaries are regenerated per OS
