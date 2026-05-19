# Windows Setup

This document defines the Windows baseline produced by the `terminal-bootstrap` repository.

## Target State

- Terminal: `WezTerm` (nightly channel — the stable release has not been refreshed in a long time, so Windows pins `wez.wezterm.nightly` via winget)
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

- `WezTerm` (winget `wez.wezterm.nightly`; no Chocolatey fallback because no official nightly package is published there)
- `NuShell`
- `Git`
- `aqua`
- `mise`

Daily cross-platform CLIs are declared in [shared/aqua/aqua.yaml](../shared/aqua/aqua.yaml) and installed by aqua after the bootstrap packages are available. Cross-platform language runtimes (Java, Python) are declared in [shared/mise/config.toml](../shared/mise/config.toml) and installed by mise after the aqua step.

### 3. Stage Managed Assets

Managed assets are staged into `%USERPROFILE%\.config\terminal-bootstrap`.

- `fonts/`
- `aqua/`
- `mise/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

### 4. Wire WezTerm

The following files are copied into their real locations by default. `-SyncMode Link` or `-SyncMode Auto` can opt back into link-based deployment when needed.

- `shared/wezterm/wezterm.lua` -> `%USERPROFILE%\.wezterm.lua`
- `shared/starship/starship.toml` -> `%USERPROFILE%\.config\starship.toml`
- `shared/aqua/aqua.yaml` -> `%USERPROFILE%\.config\aquaproj-aqua\aqua.yaml`
- `shared/mise/config.toml` -> `%USERPROFILE%\.config\mise\config.toml`

`WezTerm` launches `nu -l` as the default shell. On Windows it sets `XDG_CONFIG_HOME=%USERPROFILE%\.config`, checks standard install locations derived from the environment first, and then falls back to `nu.exe` on `PATH`.

### 5. Wire NuShell

NuShell configuration files are placed in `%USERPROFILE%\.config\nushell` on Windows. The managed NuShell files are copied into that directory as standalone files rather than linked, so the active shell configuration does not depend on `.config\terminal-bootstrap` or the repository checkout. The installer also sets the user `XDG_CONFIG_HOME` environment variable to `%USERPROFILE%\.config` and creates a compatibility junction at `%APPDATA%\nushell` that points to `%USERPROFILE%\.config\nushell`, so standalone `nu`, `exec nu`, and WezTerm-launched sessions resolve the same live config root. When rerun for repair, the installer backs up obsolete legacy autoload artifacts such as `openclaude-completions.nu` out of the active `autoload\` directory and backs up any pre-existing legacy `%APPDATA%\nushell` tree before recreating the compatibility junction.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload\wezterm-integration.nu`
- `autoload\claude-integration.nu`
- `autoload\openclaude-integration.nu`
- `autoload\zz-prompt-overrides.nu`

On Windows, NuShell is used as the WezTerm entrypoint rather than as a separate shell-profile layer.

The shared `WezTerm + NuShell` baseline disables `shell_integration.osc133` across all platforms because the default prompt markers can interfere with redraw behavior.

### 6. Wire Starship, zoxide, fzf, carapace, mise, and optional claude / openclaude integration

After the aqua config is copied, the installer sets user `AQUA_GLOBAL_CONFIG` to `%USERPROFILE%\.config\aquaproj-aqua\aqua.yaml` when the user has not already set a custom value, then runs `aqua install -a` when `aqua` is available. If that command fails, the installer warns and continues because aqua lazy install can retry in a later shell session.

After the mise config is copied, the installer runs `mise install -y` when `mise` is available so the runtimes pinned in `shared/mise/config.toml` (Java, Python) are present after bootstrap. If the mise binary is missing or the command fails, the installer warns and continues; the runtimes can be installed later with `mise install`. Resolved mise shim directories (`%LOCALAPPDATA%\mise\shims` and `$MISE_DATA_DIR\shims` when set) are prepended to `$env.PATH` from `env.nu`, so mise-managed runtimes resolve from any NuShell session including GUI-launched ones.

The installer generates `carapace.nu`, `starship.nu`, and `zoxide.nu` into the resolved NuShell config directory under `autoload\`, and `config.nu` sources them when they are present. These binaries are provided by aqua. The generated `starship.nu` resolves the real Starship executable with `aqua which starship` when possible, rather than calling the aqua shim from every prompt render. It also disables the NuShell right-prompt path and catches Starship prompt-render failures so Ctrl-C during an external command cannot surface as a prompt hook error. `autoload\zz-prompt-overrides.nu` is staged as a managed late-load guard; the `zz-` prefix intentionally keeps it after normal generated autoload files in alphabetical load order. Managed and generated autoload files may be temporarily absent during bootstrap or repair without blocking shell startup. The installer adds aqua's root `bin` directory to the user `PATH` after package installation so aqua-managed CLIs can resolve in fresh PowerShell and `cmd` sessions. A machine-wide legacy install that remains earlier in the machine `PATH` can still win there; remove that legacy install or machine `PATH` entry when fully migrating a tool to aqua. `env.nu` sets `XDG_CONFIG_HOME` and `STARSHIP_CONFIG` when they are absent, sets `AQUA_GLOBAL_CONFIG` to `%USERPROFILE%\.config\aquaproj-aqua\aqua.yaml` only when the variable is not already set, and prepends both aqua's root `bin` directory and the Windows aqua executable directory when present, so managed NuShell sessions prefer aqua even when launched from GUI tools such as JetBrains IDEs with stale environment variables. `config.nu` also optionally sources `autoload\user-overrides.nu` when present; this file is reserved for user-managed aliases, Java/runtime setup, and scripts and is not overwritten by reinstall. If a runtime such as Java needs a custom aqua registry or different version policy, point user `AQUA_GLOBAL_CONFIG` or `user-overrides.nu` at a user-owned aqua config that includes the managed package list plus the local runtime package. If that user config uses a non-standard registry, also set user `AQUA_POLICY_CONFIG`; the installer carries the user policy value into the aqua install process.

`fzf` and the other daily CLIs are expected to resolve through aqua.

Neither `claude` nor `openclaude` is installed by this repository. Instead, the managed NuShell layer stages `autoload\claude-integration.nu` and `autoload\openclaude-integration.nu`, and writes `autoload\claude.nu` / `autoload\openclaude.nu` markers during install. Startup does not depend on any of those files. On Windows, the installer also adds `%APPDATA%\npm` and `%USERPROFILE%\.local\bin` to the user `PATH` when those directories exist so locally installed `openclaude` and `claude.exe` remain discoverable in fresh shell sessions. If the `claude` or `openclaude` CLI is absent, the corresponding integration remains inactive and the shell still starts normally.

### 7. Sync LazyVim

`shared/nvim/` is linked or copied into `%USERPROFILE%\.config\nvim`. This matches the `XDG_CONFIG_HOME` that the installer sets, so the aqua-managed `nvim` binary resolves its config from the same location the installer writes to. A pre-existing `%LOCALAPPDATA%\nvim` tree from earlier installs is backed up to `%LOCALAPPDATA%\nvim.pre-terminal-bootstrap` on the first run after this change so it cannot be picked up as a stale fallback when `XDG_CONFIG_HOME` is unset in a given session.

This repository manages configuration only. Caches and external editor tools are regenerated in the target environment.

### 8. Verify

Minimum verification:

- WezTerm opens successfully and starts NuShell
- The Starship prompt renders correctly
- `aqua`, `git`, and the aqua-managed `btm`, `carapace`, `zoxide`, `fzf`, `rg`, `fd`, and `nvim` run successfully
- `mise current` shows the runtimes declared in `shared/mise/config.toml` and `java -version` / `python --version` resolve through the mise shim directory
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
