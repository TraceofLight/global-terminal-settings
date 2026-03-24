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
- `-SyncMode Auto|Link|Copy`: choose how managed assets are synchronized; default is `Auto`
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

The following files are linked or copied into their real locations.

- `shared/wezterm/wezterm.lua` -> `%USERPROFILE%\.wezterm.lua`
- `shared/starship/starship.toml` -> `%USERPROFILE%\.config\starship.toml`

`WezTerm` launches `nu -l` as the default shell.

### 5. Wire NuShell

NuShell configuration files are placed in the directory reported by `nu -n -c '$nu.default-config-dir'` when `nu` is already available. If `nu` is not available yet, the installer falls back to `%APPDATA%\nushell`.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload\wezterm-integration.nu`

On Windows, NuShell is used as the WezTerm entrypoint rather than as a separate shell-profile layer.

For the Windows `WezTerm + NuShell` baseline, `shell_integration.osc133` is disabled because the default prompt markers can interfere with redraw behavior.

### 6. Wire Starship, zoxide, and fzf

The installer generates `starship.nu` and `zoxide.nu` into the resolved NuShell config directory under `autoload\`, and `config.nu` sources them explicitly.

`fzf` is installed as an external CLI and is expected to be directly callable from NuShell.

### 7. Sync LazyVim

`shared/nvim/` is linked or copied into `%LOCALAPPDATA%\nvim`.

This repository manages configuration only. Caches and external editor tools are regenerated in the target environment.

### 8. Verify

Minimum verification:

- WezTerm opens successfully and starts NuShell
- The Starship prompt renders correctly
- `zoxide`, `fzf`, `rg`, `fd`, `git`, and `nvim` run successfully
- New tabs and splits continue the expected working flow

## Sync Policy

- Default: `Auto`
- `Auto`: try links first and fall back to copy if link creation fails
- `Link`: require links and stop if link creation fails
- `Copy`: always copy managed assets
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap-<timestamp>` before replacement

Why links are preferred:

- The repository and staging directory remain the source of truth
- Asset changes show up immediately

Why copy is allowed:

- Non-admin Windows environments may block symlink creation
- Some target paths are simpler to manage via copy

## Notes

- Fonts are loaded through WezTerm `font_dirs`, not installed system-wide
- The Windows baseline is defined around `NuShell`; other shell profile files are out of scope
- `pwsh` remains only the installer runner, not the daily interactive shell baseline
- On Windows, WezTerm checks the common `NuShell` install path first and falls back to `nu.exe` by name
- If `nu` is not visible in the current shell immediately after package installation, start a fresh terminal session
