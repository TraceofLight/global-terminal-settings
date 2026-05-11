# Linux Setup

This document defines the Linux baseline produced by the `terminal-bootstrap` repository. It covers both native Ubuntu and WSL Ubuntu. The WSL-specific differences are listed in the final section.

## Target State

- Terminal: `WezTerm` (native Linux only; WSL defers to the Windows-side WezTerm)
- Default interactive shell: `NuShell`
- Prompt: `Starship`
- Navigation: `zoxide`, `fzf`
- Editor: `Neovim + LazyVim`
- Font: `Monoplex KR Wide Nerd` (native Linux only; WSL uses Windows-side WezTerm fonts)
- Theme: `Catppuccin Mocha`

## Entry Point

Prerequisites:

- Ubuntu 22.04 or newer
- `sudo` access for the initial apt step
- Network access to install Linuxbrew and formulae

Inspect the plan:

```bash
bash ./linux/install.sh --dry-run
```

Apply the baseline:

```bash
bash ./linux/install.sh
```

Primary options:

- `--dry-run`: print the planned actions without modifying the system
- `--sync-mode auto|link|copy`: choose how managed assets are synchronized; default is `copy`
- `--skip-packages`: skip package installation
- `--skip-configs`: skip asset staging and app configuration deployment
- `--target linux|wsl`: override the auto-detected target

The installer auto-detects WSL via `$WSL_DISTRO_NAME` and the `microsoft` marker in `/proc/version`. The detected target is printed as `Mode: native-linux` or `Mode: wsl` at start.

## Install Flow

### 1. Package Manager Readiness

The installer first installs the minimum apt dependencies that Linuxbrew requires (`build-essential`, `curl`, `file`, `git`, `procps`) and then bootstraps Linuxbrew at `/home/linuxbrew/.linuxbrew`. Bootstrap binaries are resolved through Linuxbrew's `bin` directories, which the shared `env.nu` adds to `$env.PATH` for NuShell sessions. Daily cross-platform CLIs are managed by aqua after bootstrap.

### 2. Core Packages

The package baseline is defined in [linux/Brewfile](../linux/Brewfile).

Key packages:

- `WezTerm` (native Linux only; filtered out in WSL mode)
- `NuShell`
- `git`
- `aqua`

Daily cross-platform CLIs are declared in [shared/aqua/aqua.yaml](../shared/aqua/aqua.yaml) and installed by aqua after the bootstrap packages are available.

### 3. Stage Managed Assets

Managed assets are staged into `~/.config/terminal-bootstrap`.

Native Linux stages:

- `fonts/`
- `aqua/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

WSL stages:

- `nushell/`
- `aqua/`
- `starship/`
- `nvim/`

### 4. Wire WezTerm

Native Linux: `shared/wezterm/wezterm.lua` is copied to `~/.wezterm.lua`, `shared/starship/starship.toml` is copied to `~/.config/starship.toml`, and `shared/aqua/aqua.yaml` is copied to `~/.config/aquaproj-aqua/aqua.yaml`.

WSL: `shared/starship/starship.toml` and `shared/aqua/aqua.yaml` are copied. The Windows-side installer manages `wezterm.lua` and registers the WSL Ubuntu domain. See the WSL Notes section below.

### 5. Wire NuShell

NuShell configuration files are placed in `~/.config/nushell`. The managed NuShell files are copied into that directory as standalone files.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload/wezterm-integration.nu`
- `autoload/claude-integration.nu`
- `autoload/openclaude-integration.nu`

### 6. Wire Starship, zoxide, fzf, carapace, and optional claude / openclaude integration

After the aqua config is copied, the installer runs `aqua install -a` when `aqua` is available. If that command fails, the installer warns and continues because aqua lazy install can retry in a later shell session.

The installer generates `carapace.nu`, `starship.nu`, and `zoxide.nu` into `~/.config/nushell/autoload/`, and `config.nu` sources them when they are present. These binaries are provided by aqua. `env.nu` sets `AQUA_GLOBAL_CONFIG` when the managed aqua config exists and prepends aqua's root `bin` directory when present. `config.nu` also optionally sources `autoload/user-overrides.nu` when present; this file is reserved for user-managed aliases, Java/runtime setup, and scripts and is not overwritten by reinstall.

`fzf` and the other daily CLIs are expected to resolve through aqua.

Neither `claude` nor `openclaude` is installed by this repository. The managed NuShell layer stages `autoload/claude-integration.nu` and `autoload/openclaude-integration.nu`, and writes `autoload/claude.nu` / `autoload/openclaude.nu` markers during install when the matching CLI is present. If either CLI is absent, the corresponding integration stays inactive and the shell still starts cleanly.

### 7. Sync LazyVim

`shared/nvim/` is copied (or linked, with `--sync-mode link`/`auto`) into `~/.config/nvim`. The `nvim` binary itself is aqua-managed.

This repository manages configuration only. Caches and external editor tools are regenerated in the target environment.

### 8. Verify

Native Linux minimum verification:

- WezTerm opens successfully and starts NuShell
- The Starship prompt renders correctly
- `aqua`, `git`, and the aqua-managed `btm`, `carapace`, `zoxide`, `fzf`, `rg`, `fd`, and `nvim` run successfully
- If `claude` or `openclaude` is installed, the matching NuShell extern layer loads without startup errors

WSL minimum verification:

- On the Windows host, the WezTerm launch menu (`Ctrl+Shift+Space`) exposes a "WSL Ubuntu (nu)" entry that opens a new tab running `wsl nu -l`
- Inside the WSL tab, the Starship prompt renders and aqua-managed baseline CLIs run
- If `claude` or `openclaude` is installed inside WSL, the matching NuShell extern layer loads

## WSL Notes

WSL is an intentionally reduced install. The Windows host runs WezTerm and owns font rendering, window chrome, and the `wsl_domains` entry. The WSL installer therefore skips `shared/fonts/` and `shared/wezterm/wezterm.lua` and defers the WezTerm wiring.

To complete the WSL setup end to end:

1. Inside WSL, run `bash ./linux/install.sh`. The installer detects WSL automatically; pass `--target wsl` to force it.
2. On the Windows host, run `pwsh -NoProfile -File .\windows\install.ps1` from the repository root so the updated `shared/wezterm/wezterm.lua` is deployed to `%USERPROFILE%\.wezterm.lua`. The updated config registers a `wsl_domains` entry named `WSL:Ubuntu` and adds a launch menu item "WSL Ubuntu (nu)" pointing at that domain.
3. Restart WezTerm on the Windows host. Open the launch menu with `Ctrl+Shift+Space` and pick "WSL Ubuntu (nu)" to enter the WSL nu session.

The WSL domain distribution name is hard-coded to `Ubuntu`. If your distribution is named differently (for example `Ubuntu-22.04`), edit the `distribution` field in `shared/wezterm/wezterm.lua` before running the Windows installer, or override it locally.

The WSL domain also invokes `nu` by the absolute path `/home/linuxbrew/.linuxbrew/bin/nu` rather than by name. `wsl.exe -- <cmd>` runs the command directly without a login shell, so the shell initialization files are not sourced and Linuxbrew's `bin` directory is not on `$PATH`. Using the absolute path sidesteps that, at the cost of assuming a standard Linuxbrew install location. If nu lives elsewhere in your WSL filesystem, edit `default_prog` in the `wsl_domains` entry accordingly.

### Default WSL distribution

When Docker Desktop is installed, it registers its own WSL2 distribution (`docker-desktop`) and often marks it as the default. A bare `wsl` invocation from Windows then lands in that Alpine-based distro instead of the Ubuntu one managed by this installer, which is why the prompt may appear as a root `#` shell under `/mnt/host/c/...`.

Set Ubuntu as the default so `wsl` with no arguments enters the managed environment:

```powershell
wsl --set-default Ubuntu
```

This is fully reversible — `wsl --set-default docker-desktop` restores the previous default. Docker Desktop continues to work either way because it targets its own distro by name internally.

### Interactive bash handoff to nu

`wsl` (no command) enters the distribution's default login shell, which on Ubuntu is bash. Without shell setup, bash has no knowledge of Linuxbrew, so `nvim`, `nu`, `starship`, and similar commands resolve to "not found". The WSL stage of `linux/install.sh` therefore appends an idempotent managed block to `~/.bashrc`:

- `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` so `/home/linuxbrew/.linuxbrew/bin` joins `$PATH`
- `exec nu -l` when the shell is interactive, the user has not opted out with `TERMINAL_BOOTSTRAP_NO_HANDOFF=1`, the recursion guard `TERMINAL_BOOTSTRAP_NU_HANDOFF` is unset, and `nu` is available

The combined effect: `wsl` from Windows opens bash briefly, which then re-execs into a login nu session. The handoff runs only for interactive shells, so non-interactive invocations (scripts, `wsl -- <cmd>`, VS Code Remote WSL server commands) are unaffected. To disable the handoff for a session, export `TERMINAL_BOOTSTRAP_NO_HANDOFF=1` before launching wsl.

The block is bounded by `# BEGIN managed by terminal-bootstrap` / `# END managed by terminal-bootstrap` markers. The installer's idempotency check looks for the BEGIN marker and skips re-append if present. To remove the handoff permanently, delete the managed block from `~/.bashrc`.

## Sync Policy

- Default: `copy`
- `copy`: always copy managed assets
- `auto`: try links first and fall back to copy if link creation fails
- `link`: require links and stop if link creation fails
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap` before replacement; each run overwrites the previous backup, so at most one backup per target is retained

Why copy is preferred:

- Installed apps keep working even if the repository checkout or worktree is removed
- Runtime configuration does not depend on staged assets remaining linked to the source checkout
- Symlink behavior across mixed filesystems (notably WSL accessing NTFS-mounted paths) is inconsistent, so copy is the safer default

Why link modes still exist:

- Some maintenance workflows prefer the repository and staging directory to remain the source of truth
- Asset changes can show up immediately when link-based deployment is intentional

## Notes

- Fonts are loaded through WezTerm `font_dirs` in the native Linux install, not installed system-wide
- On WSL, fonts live on the Windows side and are not deployed to the WSL filesystem
- Linuxbrew is used only as the installer-time source for bootstrap tools; daily cross-platform CLIs are managed by aqua
- Language runtimes, including Java, remain out of scope for this repository's baseline and should live in `autoload/user-overrides.nu`, a user aqua config, or project-local configuration
- On native Linux, WezTerm launches `nu` by name from the user's PATH; Linuxbrew's `/home/linuxbrew/.linuxbrew/bin` entry added by `brew shellenv` (typically sourced from `~/.profile` or `~/.bashrc`) is what makes that resolution work. If WezTerm cannot find `nu`, verify that `command -v nu` succeeds in a login shell before launching WezTerm.
- The current `shared/wezterm/wezterm.lua` probes `/opt/homebrew/bin/nu` and `/usr/local/bin/nu` before falling back to `nu` by name. Those macOS-style paths are harmless on Linux; they simply never match and the PATH lookup wins.
- Unlike the macOS branch, the Linux path does not inject `XDG_CONFIG_HOME` from WezTerm because Linux already treats `~/.config` as the default XDG config root, so NuShell resolves its managed config directly.
