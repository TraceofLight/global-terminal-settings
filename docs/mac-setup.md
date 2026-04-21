# mac Setup

This document defines the macOS baseline produced by the `terminal-bootstrap` repository.

## Target State

- Terminal: `WezTerm`
- Default interactive shell: `NuShell`
- Prompt: `Starship`
- Navigation: `zoxide`, `fzf`
- Editor: `Neovim + LazyVim`
- Font: `Monoplex KR Wide Nerd`
- Theme: `Catppuccin Mocha`
- Background style: `window_background_opacity = 0.8` + `macos_window_background_blur = 20`

## Entry Point

Inspect the plan:

```bash
bash ./mac/install.sh --dry-run
```

Apply the baseline:

```bash
bash ./mac/install.sh
```

Primary options:

- `--dry-run`: print the planned actions without modifying the system
- `--sync-mode auto|link|copy`: choose how managed assets are synchronized; default is `copy`
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
- `carapace`
- `ripgrep`, `fd`, `fzf`, `zoxide`, `git`, `lazygit`
- Other supporting CLIs

### 3. Stage Managed Assets

Managed assets are staged into `~/.config/terminal-bootstrap` by default. If `XDG_CONFIG_HOME` is set, the installer uses `$XDG_CONFIG_HOME/terminal-bootstrap`.

- `fonts/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

### 4. Wire WezTerm

The following files are copied into their real locations by default. `--sync-mode link` or `--sync-mode auto` can opt back into link-based deployment when needed.

- `shared/wezterm/wezterm.lua` -> `~/.wezterm.lua`
- `shared/starship/starship.toml` -> `~/.config/starship.toml` by default
- If `XDG_CONFIG_HOME` is set, `shared/starship/starship.toml` -> `$XDG_CONFIG_HOME/starship.toml`

`WezTerm` launches `nu -l` as the default shell and sets `XDG_CONFIG_HOME=~/.config` on macOS so NuShell resolves its active config from `~/.config/nushell`.

### 5. Wire NuShell

NuShell configuration files are placed in `~/.config/nushell` by default. If `XDG_CONFIG_HOME` is set, the installer uses `$XDG_CONFIG_HOME/nushell`. The managed NuShell files are copied into that directory as standalone files rather than linked, so the active shell configuration does not depend on `terminal-bootstrap/` or the repository checkout.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload/wezterm-integration.nu`

### 6. Wire Starship, zoxide, fzf, carapace, and optional claude / openclaude integration

The installer generates `carapace.nu`, `starship.nu`, and `zoxide.nu` into the resolved NuShell config directory under `autoload/`, and `config.nu` sources them when they are present. Those managed and generated autoload files may be temporarily absent during bootstrap or repair without blocking shell startup. `config.nu` also optionally sources `autoload/user-overrides.nu` when present; this file is reserved for user-managed aliases and scripts and is not overwritten by reinstall.

`fzf` is installed as an external CLI and is expected to be directly callable from NuShell.

Neither `claude` nor `openclaude` is installed by this repository. Instead, the managed NuShell layer stages `autoload/claude-integration.nu` and `autoload/openclaude-integration.nu`, and writes `autoload/claude.nu` / `autoload/openclaude.nu` markers during install. Startup does not depend on any of those files. If the `claude` or `openclaude` CLI is absent, the corresponding integration remains inactive and the shell still starts normally.

### 7. Sync LazyVim

`shared/nvim/` is linked or copied into `~/.config/nvim` by default. If `XDG_CONFIG_HOME` is set, the installer uses `$XDG_CONFIG_HOME/nvim`.

This repository manages configuration only. Caches and external editor tools are regenerated in the target environment.

### 8. Verify

Minimum verification:

- WezTerm opens successfully and starts NuShell
- The Starship prompt renders correctly
- `carapace`, `zoxide`, `fzf`, `rg`, `fd`, `git`, and `nvim` run successfully
- If `claude` or `openclaude` is installed, the matching NuShell extern layer loads without startup errors
- If neither is installed, the shell still starts normally with both integrations inactive
- New tabs and splits continue the expected working flow

## Sync Policy

- Default: `copy`
- `copy`: always copy managed assets
- `auto`: try links first and fall back to copy if link creation fails
- `link`: require links and stop if link creation fails
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap-<timestamp>` before replacement

Why copy is preferred:

- Installed apps keep working even if the repository checkout or worktree is removed
- Runtime configuration does not depend on staged assets remaining linked to the source checkout
- It avoids environment-specific link permission differences

Why link modes still exist:

- Some maintenance workflows prefer the repository and staging directory to remain the source of truth
- Asset changes can show up immediately when link-based deployment is intentional

## Notes

- Fonts are loaded through WezTerm `font_dirs`, not installed system-wide
- The macOS baseline is also defined around `NuShell`; other shell profile files are out of scope
- Homebrew remains the installer and package source, not the daily interactive shell baseline
- On macOS, WezTerm checks the common Homebrew `NuShell` install paths first and falls back to `nu` by name
- The managed `env.nu` prepends the common Homebrew bin directories so GUI-launched WezTerm sessions can still find brew-installed CLIs
