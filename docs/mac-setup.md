# mac Setup

This document defines the macOS baseline produced by the `terminal-bootstrap` repository.

## Target State

- Terminal: `WezTerm`
- Default interactive shell: `NuShell`
- Prompt: `Starship`
- Navigation: `zoxide`, `fzf`
- Editor: `Neovim + LazyVim`
- Font: `Monoplex KR Nerd Wide`
- Theme: `Catppuccin Mocha`
- Background style: `window_background_opacity = 0.8` + `macos_window_background_blur = 20`

## Entry Point

```bash
./mac/install.sh --dry-run
```

Primary options:

- `--dry-run`: print the planned actions without modifying the system
- `--sync-mode auto|link|copy`: choose how managed assets are synchronized
- `--skip-packages`: skip Homebrew package installation
- `--skip-configs`: skip asset staging and app configuration deployment

## Install Flow

### 1. Package Manager Readiness

- The primary package manager is `brew`.
- The installer prepares Homebrew first if it is not already available.

### 2. Core Packages

The package baseline is defined in [mac/Brewfile](../mac/Brewfile).

Key packages:

- `wezterm`
- `nushell`
- `neovim`
- `starship`
- `ripgrep`, `fd`, `fzf`, `zoxide`, `git`, `lazygit`
- Other supporting CLIs

### 3. Stage Managed Assets

Managed assets are staged into `~/.config/terminal-bootstrap`.

- `fonts/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

### 4. Wire WezTerm

The following files are linked or copied into their real locations.

- `shared/wezterm/wezterm.lua` -> `~/.wezterm.lua`
- `shared/starship/starship.toml` -> `~/.config/starship.toml`

`WezTerm` launches `nu -l` as the default shell.

### 5. Wire NuShell

NuShell configuration files are placed in the standard NuShell config directory, typically `~/Library/Application Support/nushell`.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload/wezterm-integration.nu`

### 6. Wire Starship, zoxide, and fzf

The installer generates NuShell autoload files, and `config.nu` sources them explicitly.

- `starship init nu` -> `~/Library/Application Support/nushell/autoload/starship.nu`
- `zoxide init nushell` -> `~/Library/Application Support/nushell/autoload/zoxide.nu`

`fzf` is installed as an external CLI and is expected to be directly callable from NuShell.

### 7. Sync LazyVim

`shared/nvim/` is linked or copied into `~/.config/nvim`.

This repository manages configuration only. Caches and external editor tools are regenerated in the target environment.

### 8. Verify

Minimum verification:

- WezTerm opens successfully and starts NuShell
- The Starship prompt renders correctly
- `zoxide`, `fzf`, `rg`, `fd`, `git`, and `nvim` run successfully
- New tabs and splits continue the expected working flow

## Sync Policy

- Default: link
- Fallback: copy

Why links are preferred:

- The repository and staging directory remain the source of truth
- Asset changes show up immediately

Why copy is allowed:

- Some target paths are simpler to manage via copy
- It reduces the need to care about environment-specific permission differences

## Notes

- Fonts are loaded through WezTerm `font_dirs`, not installed system-wide
- The macOS baseline is also defined around `NuShell`; other shell profile files are out of scope
- Homebrew remains the installer and package source, not the daily interactive shell baseline
- On macOS, WezTerm checks the common Homebrew `NuShell` install paths first and falls back to `nu` by name
