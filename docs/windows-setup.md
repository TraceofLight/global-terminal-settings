# Windows Setup

This document defines the Windows baseline produced by the `terminal-bootstrap` repository.

## Target State

- Terminal: `WezTerm`
- Default interactive shell: `NuShell`
- Prompt: `Starship`
- Navigation: `zoxide`, `fzf`
- Editor: `Neovim + LazyVim`
- Font: `Monoplex KR Wide Nerd`
- Theme: `Catppuccin Mocha`
- Background style: `window_background_opacity = 0.8` + `win32_system_backdrop = "Acrylic"`

## Entry Point

Prerequisites:

- `pwsh` must already be available
- Install PowerShell 7 first if `pwsh` is missing
- `winget` must already be available

Inspect the plan:

```powershell
pwsh -NoProfile -File .\windows\install.ps1 -DryRun
```

Apply the baseline:

```powershell
pwsh -NoProfile -File .\windows\install.ps1
```

Primary options:

- `-DryRun`: print the planned actions without modifying the system
- `-SyncMode Auto|Link|Copy`: choose how managed assets are synchronized; default is `Copy`
- `-SkipPackages`: skip package installation
- `-SkipConfigs`: skip asset staging and app configuration deployment

## Install Flow

### 1. Package Manager Readiness

- The primary package manager is `winget`.
- `choco` is only used when a package defines a Chocolatey fallback and `choco` is already installed.
- If `choco` is unavailable, optional fallback packages are skipped and required fallback packages fail.
- A package must not be owned by both managers at the same time.

### 2. Core Packages

The package baseline is defined in [windows/packages.psd1](../windows/packages.psd1).

Key packages:

- `WezTerm`
- `NuShell`
- `Neovim`
- `Starship`
- `carapace`
- `ripgrep`, `fd`, `fzf`, `zoxide`, `git`, `lazygit`
- Other supporting CLIs

### 3. Stage Managed Assets

Managed assets are staged into `%USERPROFILE%\.config\terminal-bootstrap`.

- `fonts/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

### 4. Wire WezTerm

The following files are copied into their real locations by default. `-SyncMode Link` or `-SyncMode Auto` can opt back into link-based deployment when needed.

- `shared/wezterm/wezterm.lua` -> `%USERPROFILE%\.wezterm.lua`
- `shared/starship/starship.toml` -> `%USERPROFILE%\.config\starship.toml`

`WezTerm` launches `nu -l` as the default shell. On Windows it sets `XDG_CONFIG_HOME=%USERPROFILE%\.config`, checks standard install locations derived from the environment first, and then falls back to `nu.exe` on `PATH`.

### 5. Wire NuShell

NuShell configuration files are placed in `%USERPROFILE%\.config\nushell` on Windows. The managed NuShell files are copied into that directory as standalone files rather than linked, so the active shell configuration does not depend on `.config\terminal-bootstrap` or the repository checkout. The installer also sets the user `XDG_CONFIG_HOME` environment variable to `%USERPROFILE%\.config` and creates a compatibility junction at `%APPDATA%\nushell` that points to `%USERPROFILE%\.config\nushell`, so standalone `nu`, `exec nu`, and WezTerm-launched sessions resolve the same live config root. When rerun for repair, the installer backs up obsolete legacy autoload artifacts such as `openclaude-completions.nu` out of the active `autoload\` directory and backs up any pre-existing legacy `%APPDATA%\nushell` tree before recreating the compatibility junction.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload\wezterm-integration.nu`
- `autoload\claude-integration.nu`
- `autoload\openclaude-integration.nu`

On Windows, NuShell is used as the WezTerm entrypoint rather than as a separate shell-profile layer.

For the Windows `WezTerm + NuShell` baseline, `shell_integration.osc133` is disabled because the default prompt markers can interfere with redraw behavior.

### 6. Wire Starship, zoxide, fzf, carapace, and optional claude / openclaude integration

The installer generates `carapace.nu`, `starship.nu`, and `zoxide.nu` into the resolved NuShell config directory under `autoload\`, and `config.nu` sources them when they are present. Those managed and generated autoload files may be temporarily absent during bootstrap or repair without blocking shell startup. `config.nu` also optionally sources `autoload\user-overrides.nu` when present; this file is reserved for user-managed aliases and scripts and is not overwritten by reinstall.

`fzf` is installed as an external CLI and is expected to be directly callable from NuShell.

Neither `claude` nor `openclaude` is installed by this repository. Instead, the managed NuShell layer stages `autoload\claude-integration.nu` and `autoload\openclaude-integration.nu`, and writes `autoload\claude.nu` / `autoload\openclaude.nu` markers during install. Startup does not depend on any of those files. On Windows, the installer also adds `%APPDATA%\npm` and `%USERPROFILE%\.local\bin` to the user `PATH` when those directories exist so locally installed `openclaude` and `claude.exe` remain discoverable in fresh shell sessions. If the `claude` or `openclaude` CLI is absent, the corresponding integration remains inactive and the shell still starts normally.

### 7. Sync LazyVim

`shared/nvim/` is linked or copied into `%USERPROFILE%\.config\nvim`. This matches the `XDG_CONFIG_HOME` that the installer sets, so Neovim resolves its config from the same location the installer writes to. A pre-existing `%LOCALAPPDATA%\nvim` tree from earlier installs is backed up to `%LOCALAPPDATA%\nvim.pre-terminal-bootstrap` on the first run after this change so it cannot be picked up as a stale fallback when `XDG_CONFIG_HOME` is unset in a given session.

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

- Default: `Copy`
- `Copy`: always copy managed assets
- `Auto`: try links first and fall back to copy if link creation fails
- `Link`: require links and stop if link creation fails
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap` before replacement; each run overwrites the previous backup, so at most one backup per target is retained

Why copy is preferred:

- Installed apps keep working even if the repository checkout or worktree is removed
- Runtime configuration does not depend on staged assets remaining linked to the source checkout
- It avoids admin- and environment-specific link permission differences

Why link modes still exist:

- Some maintenance workflows prefer the repository and staging directory to remain the source of truth
- Asset changes can show up immediately when link-based deployment is intentional

## Notes

- Fonts are loaded through WezTerm `font_dirs`, not installed system-wide
- The Windows baseline is defined around `NuShell`; other shell profile files are out of scope
- `pwsh` remains only the installer runner, not the daily interactive shell baseline
- On Windows, WezTerm sets `XDG_CONFIG_HOME=%USERPROFILE%\.config`, checks standard `NuShell` install locations from the environment, and falls back to `nu.exe` by name
- If `nu` is not visible in the current shell immediately after package installation, start a fresh terminal session
