# Terminal Bootstrap

This repository bootstraps a shared `WezTerm + NuShell + Starship + zoxide + fzf + Neovim/LazyVim` environment across Windows and macOS.

## Goals

- Provide a shared terminal UX built on `WezTerm`
- Use `NuShell` as the default interactive shell
- Keep a consistent visual baseline with `Catppuccin Mocha` and `Monoplex KR Wide Nerd`
- Preserve the current workflow around `Starship`, `zoxide`, `fzf`, `rg`, `fd`, `git`, and `lazygit`
- Treat the current local `LazyVim` setup as a managed asset
- Keep Windows and macOS installation guides aligned to the same stage structure

## Repository Layout

```text
global-terminal-settings/
├─ docs/
│  ├─ plans/
│  ├─ mac-setup.md
│  ├─ ux-contract.md
│  └─ windows-setup.md
├─ mac/
│  ├─ Brewfile
│  └─ install.sh
├─ shared/
│  ├─ fonts/
│  ├─ nushell/
│  ├─ nvim/
│  ├─ starship/
│  └─ wezterm/
└─ windows/
   ├─ install.ps1
   └─ packages.psd1
```

## Managed Assets

- `shared/fonts/MonoplexKRWideNerd/`
  - Source font assets staged into the per-user install root under `fonts/`
- `shared/nushell/`
  - Shared `config.nu`, `env.nu`, `login.nu`
  - NuShell integration layer for WezTerm
- `shared/nvim/`
  - Current `LazyVim` configuration snapshot
- `shared/starship/starship.toml`
  - Shared prompt configuration
- `shared/wezterm/wezterm.lua`
  - Shared WezTerm configuration

## Installation Model

The installers first stage managed assets into a per-user install root and then link or copy them into the application-specific locations.

- Windows install root: `%USERPROFILE%\.config\terminal-bootstrap\`
- macOS install root: `~/.config/terminal-bootstrap/` by default
- If `XDG_CONFIG_HOME` is set on macOS, the installer uses `$XDG_CONFIG_HOME/terminal-bootstrap/`
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap-<timestamp>` before replacement

- `~/.wezterm.lua`
- Windows: `%USERPROFILE%\.config\starship.toml`
- macOS: `~/.config/starship.toml` by default
- If `XDG_CONFIG_HOME` is set on macOS, the installer uses `$XDG_CONFIG_HOME/starship.toml`
- The NuShell config directory reported by `nu -n -c '$nu.default-config-dir'`
- Windows fallback when `nu` is unavailable: `%APPDATA%\nushell\`
- macOS fallback when `nu` is unavailable: `~/Library/Application Support/nushell/`
- Windows: `%LOCALAPPDATA%\nvim`
- macOS: `~/.config/nvim` by default
- If `XDG_CONFIG_HOME` is set on macOS, the installer uses `$XDG_CONFIG_HOME/nvim`

The NuShell `Starship` and `zoxide` init files are generated into the real NuShell `autoload/` directory, and `config.nu` sources them explicitly.

On Windows, the `WezTerm + NuShell` baseline disables `shell_integration.osc133` for redraw stability. The prompt model uses a single left `Starship` prompt and disables NuShell's built-in `vi` indicators and right-prompt path.

## Shared Installation Stages

Windows and macOS use the same eight installation stages.

1. Package manager readiness
2. Core packages
3. Stage managed assets
4. Wire WezTerm
5. Wire NuShell
6. Wire Starship, zoxide, and fzf
7. Sync LazyVim
8. Verify

Only the concrete commands and package sources differ.

- Windows: `winget` first, `choco` only when already installed and the package allows fallback
- macOS: `brew`

## Entry Points

- Windows setup guide: [docs/windows-setup.md](docs/windows-setup.md)
- macOS setup guide: [docs/mac-setup.md](docs/mac-setup.md)
- Shared UX contract: [docs/ux-contract.md](docs/ux-contract.md)
- Design document: [docs/plans/wezterm-nushell-bootstrap-design.md](docs/plans/wezterm-nushell-bootstrap-design.md)
- Implementation plan: [docs/plans/wezterm-nushell-bootstrap.md](docs/plans/wezterm-nushell-bootstrap.md)

## Scope

Included:

- Terminal configuration
- Shell UX
- Prompt behavior
- Navigation and search tools
- Fonts
- Neovim configuration deployment

Excluded:

- Compilers and build toolchains
- Per-language development environment automation
- WSL-based workflows
- Parallel documentation for superseded shell designs
