# Terminal Bootstrap

This repository bootstraps a shared `WezTerm + NuShell + Starship + zoxide + fzf + carapace + Neovim/LazyVim` environment across Windows, macOS, native Ubuntu Linux, and WSL Ubuntu.

## Goals

- Provide a shared terminal UX built on `WezTerm`
- Use `NuShell` as the default interactive shell
- Keep a consistent visual baseline with `Catppuccin Mocha` and `Monoplex KR Wide Nerd`
- Preserve the current workflow around `Starship`, `zoxide`, `fzf`, `carapace`, `rg`, `fd`, `git`, and `lazygit`
- Treat the current local `LazyVim` setup as a managed asset
- Keep Windows, macOS, and Linux installation guides aligned to the same stage structure

## Repository Layout

```text
global-terminal-settings/
├─ docs/
│  ├─ plans/
│  ├─ linux-setup.md
│  ├─ mac-setup.md
│  ├─ ux-contract.md
│  └─ windows-setup.md
├─ linux/
│  ├─ Brewfile
│  └─ install.sh
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
  - NuShell integration layer for WezTerm and optional `claude` / `openclaude` extern wiring
- `shared/nvim/`
  - Current `LazyVim` configuration snapshot
- `shared/starship/starship.toml`
  - Shared prompt configuration
- `shared/wezterm/wezterm.lua`
  - Shared WezTerm configuration

## Installation Model

The installers first stage managed assets into a per-user install root and then copy them into the application-specific locations by default. `--sync-mode auto` and `--sync-mode link` are available for workflows that still want link-based deployment. NuShell managed files are always copied into the resolved NuShell config directory as standalone files so the live shell config does not depend on the staging root or the repository checkout.

- Windows install root: `%USERPROFILE%\.config\terminal-bootstrap\`
- macOS install root: `~/.config/terminal-bootstrap/` by default
- If `XDG_CONFIG_HOME` is set on macOS, the installer uses `$XDG_CONFIG_HOME/terminal-bootstrap/`
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap` before replacement; subsequent runs overwrite that file, so at most one backup per target is retained

- `~/.wezterm.lua`
- Windows: `%USERPROFILE%\.config\starship.toml`
- macOS: `~/.config/starship.toml` by default
- If `XDG_CONFIG_HOME` is set on macOS, the installer uses `$XDG_CONFIG_HOME/starship.toml`
- Windows NuShell config dir: `%USERPROFILE%\.config\nushell\`
- macOS NuShell config dir: `~/.config/nushell/` by default
- If `XDG_CONFIG_HOME` is set on macOS, the installer uses `$XDG_CONFIG_HOME/nushell/`
- Windows: `%USERPROFILE%\.config\nvim` (aligned with the user `XDG_CONFIG_HOME` the installer sets; pre-existing `%LOCALAPPDATA%\nvim` is backed up once and skipped thereafter)
- macOS: `~/.config/nvim` by default
- If `XDG_CONFIG_HOME` is set on macOS, the installer uses `$XDG_CONFIG_HOME/nvim`
- Linux (native and WSL): `$XDG_CONFIG_HOME/nvim` when set, otherwise `~/.config/nvim`

The NuShell `carapace`, `Starship`, and `zoxide` init files are generated into the real NuShell `autoload/` directory, and `config.nu` sources them when those files are present. Managed and generated autoload files may be temporarily absent during bootstrap or repair without blocking shell startup. The managed NuShell layer also stages `claude-integration.nu` and `openclaude-integration.nu`, and writes `claude.nu` / `openclaude.nu` markers during install, but startup does not depend on any of those files. If the `claude` or `openclaude` CLI is not installed, the corresponding integration stays inactive and the shell still starts cleanly. `config.nu` also optionally sources `autoload/user-overrides.nu` when present; this file is user-managed and is not overwritten by reinstall, so OS-specific aliases and custom scripts can live there. On Windows, rerunning the installer repairs the live NuShell files in `~/.config/nushell`, sets user `XDG_CONFIG_HOME=~/.config`, recreates `%APPDATA%\nushell` as a compatibility junction to the same live root so standalone `nu` and `exec nu` see the same config, backs up obsolete legacy autoload artifacts such as `openclaude-completions.nu`, and backs up an existing legacy `%APPDATA%\nushell` tree before rebuilding the junction. On macOS, the managed WezTerm entrypoint sets `XDG_CONFIG_HOME=~/.config` so the live NuShell runtime resolves from `~/.config/nushell` instead of `~/Library/Application Support/nushell`.

On Windows, the `WezTerm + NuShell` baseline disables `shell_integration.osc133` for redraw stability. The prompt model uses a single left `Starship` prompt and disables NuShell's built-in `vi` indicators and right-prompt path.

## Shared Installation Stages

Windows, macOS, and Linux (native and WSL) use the same eight installation stages.

1. Package manager readiness
2. Core packages
3. Stage managed assets
4. Wire WezTerm
5. Wire NuShell
6. Wire Starship, zoxide, fzf, carapace, and optional claude / openclaude integration
7. Sync LazyVim
8. Verify

Only the concrete commands and package sources differ.

- Windows: `winget` first, `choco` only when already installed and the package allows fallback
- macOS: `brew`
- Linux (native and WSL Ubuntu): `apt` for Linuxbrew bootstrap dependencies, then `brew` for the baseline
- WSL defers font and WezTerm deployment to the Windows host; the Windows installer registers a `wsl_domains` entry so WezTerm can enter the WSL `nu` session directly
- `claude` and `openclaude` themselves remain external prerequisites; this repo only wires shell integration when the command is already available

## Entry Points

- Windows setup guide: [docs/windows-setup.md](docs/windows-setup.md)
- macOS setup guide: [docs/mac-setup.md](docs/mac-setup.md)
- Linux and WSL setup guide: [docs/linux-setup.md](docs/linux-setup.md)
- Shared UX contract: [docs/ux-contract.md](docs/ux-contract.md)
- Historical design and implementation plans: [docs/plans/archive/](docs/plans/archive/)

## Scope

Included:

- Terminal configuration
- Shell UX
- Prompt behavior
- Navigation and search tools
- Command completion and optional `claude` / `openclaude` extern wiring
- Fonts
- Neovim configuration deployment

Excluded:

- Compilers and build toolchains
- Per-language development environment automation
- Parallel documentation for superseded shell designs
