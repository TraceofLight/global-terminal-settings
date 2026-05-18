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

The installer first installs the minimum apt dependencies that Linuxbrew and the WezTerm APT repository require (`build-essential`, `ca-certificates`, `curl`, `file`, `git`, `gpg`, `procps`) and then bootstraps Linuxbrew at `/home/linuxbrew/.linuxbrew`. Bootstrap binaries are resolved through Linuxbrew's `bin` directories, which the shared `env.nu` adds to `$env.PATH` for NuShell sessions. Daily cross-platform CLIs are managed by aqua after bootstrap.

### 2. Core Packages

The package baseline is defined in [linux/Brewfile](../linux/Brewfile).

Linuxbrew bootstrap packages:

- `NuShell`
- `git`
- `aqua`
- `mise`

Daily cross-platform CLIs are declared in [shared/aqua/aqua.yaml](../shared/aqua/aqua.yaml) and installed by aqua after the bootstrap packages are available. Cross-platform language runtimes (Java, Python) are declared in [shared/mise/config.toml](../shared/mise/config.toml) and installed by mise after the aqua step. Native Ubuntu Linux installs WezTerm separately from WezTerm's official APT repository rather than Linuxbrew, because the Linuxbrew tap can install an x86-64 WezTerm binary on ARM64 hosts. WSL skips WezTerm because the Windows host owns the terminal UI.

### 3. Stage Managed Assets

Managed assets are staged into `~/.config/terminal-bootstrap`.

Native Linux stages:

- `fonts/`
- `aqua/`
- `mise/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

WSL stages:

- `nushell/`
- `aqua/`
- `mise/`
- `starship/`
- `nvim/`

### 4. Wire WezTerm

Native Linux: `shared/wezterm/wezterm.lua` is copied to `~/.wezterm.lua`, `shared/starship/starship.toml` is copied to `~/.config/starship.toml`, `shared/aqua/aqua.yaml` is copied to `~/.config/aquaproj-aqua/aqua.yaml`, and `shared/mise/config.toml` is copied to `~/.config/mise/config.toml`.

WSL: `shared/starship/starship.toml`, `shared/aqua/aqua.yaml`, and `shared/mise/config.toml` are copied. The Windows-side installer manages `wezterm.lua` and registers the WSL Ubuntu domain. See the WSL Notes section below.

### 5. Wire NuShell

NuShell configuration files are placed in `~/.config/nushell`. The managed NuShell files are copied into that directory as standalone files.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload/wezterm-integration.nu`
- `autoload/claude-integration.nu`
- `autoload/openclaude-integration.nu`
- `autoload/zz-prompt-overrides.nu`

### 6. Wire Starship, zoxide, fzf, carapace, mise, and optional claude / openclaude integration

After the aqua config is copied, the installer runs `aqua install -a` when `aqua` is available. If that command fails, the installer warns and continues because aqua lazy install can retry in a later shell session.

After the mise config is copied, the installer runs `mise install -y` when `mise` is available so the runtimes pinned in `shared/mise/config.toml` (Java, Python) are present after bootstrap. If the mise binary is missing or the command fails, the installer warns and continues; the runtimes can be installed later with `mise install`.

The installer generates `carapace.nu`, `starship.nu`, and `zoxide.nu` into `~/.config/nushell/autoload/`, and `config.nu` sources them when they are present. These binaries are provided by aqua. The generated `starship.nu` resolves the real Starship executable with `aqua which starship` when possible, disables the NuShell right-prompt path, and catches Starship prompt-render failures so an interrupted foreground command cannot surface as a prompt hook error. `autoload/zz-prompt-overrides.nu` is staged as a managed late-load guard; the `zz-` prefix intentionally keeps it after normal generated autoload files in alphabetical load order. `env.nu` sets `AQUA_GLOBAL_CONFIG` to the managed config only when the variable is not already set, and prepends aqua's root `bin` directory when present. `config.nu` also optionally sources `autoload/user-overrides.nu` when present; this file is reserved for user-managed aliases, Java/runtime setup, and scripts and is not overwritten by reinstall.

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

## Interactive bash / zsh handoff to nu

This applies to both native Linux and WSL. Interactive SSH sessions and `wsl` with no command enter the distribution's default login shell, which on Ubuntu is usually bash but may be zsh on existing machines. Without shell setup, the login shell has no knowledge of Linuxbrew, so `nvim`, `nu`, `starship`, and similar commands resolve to "not found". The Linux installer therefore appends idempotent managed blocks in two places: an **env block** in `~/.profile` (and `~/.zprofile` when zsh is the login shell) that sets up the Linuxbrew PATH, and a **handoff block** in `~/.bashrc` (and `~/.zshrc` when applicable) that re-execs interactive shells into nu.

- env block — `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"` so `/home/linuxbrew/.linuxbrew/bin` joins `$PATH`. Marker: `# BEGIN managed by terminal-bootstrap (env)`
- handoff block — `exec nu -l` when bash or zsh is interactive, the user has not opted out with `TERMINAL_BOOTSTRAP_NO_HANDOFF=1`, the recursion guard `TERMINAL_BOOTSTRAP_NU_HANDOFF` is unset, and `nu` is available. Marker: `# BEGIN managed by terminal-bootstrap`. The handoff block also re-runs `brew shellenv` for the non-login interactive case where only `~/.bashrc` / `~/.zshrc` get sourced; `brew shellenv` is idempotent so this is harmless.

Why the env block is separate from the handoff block: Ubuntu's default `~/.bashrc` opens with `case $- in *i*) ;; *) return;; esac`, which early-returns for non-interactive shells. Any later code in `~/.bashrc` — including `eval "$(brew shellenv)"` — is then skipped for non-interactive bash login shells (for example `ssh host -- bash -lc "command"` invocations used by Ansible, CI agents, and scripts). Putting the env block in `~/.profile` instead bypasses that guard and makes the managed CLIs resolve in those non-interactive login shells too.

The combined effect: SSH and `wsl` from Windows open bash briefly, which then re-execs into a login nu session. The handoff runs only for interactive shells, so non-interactive invocations (`ssh host command`, `wsl -- <cmd>`, VS Code Remote WSL server commands) skip the nu hop. They still get the Linuxbrew PATH from `~/.profile` when invoked as login shells (e.g. `ssh host "bash -lc 'nu --version'"`); non-login non-interactive shells (a bare `ssh host "nu --version"`) do not source either file and remain unaffected — that is a bash invocation rule, not a managed behavior. To disable the handoff for a session, export `TERMINAL_BOOTSTRAP_NO_HANDOFF=1` before launching the interactive shell.

The env block is bounded by `# BEGIN managed by terminal-bootstrap (env)` / `# END managed by terminal-bootstrap (env)` markers, and the handoff block by `# BEGIN managed by terminal-bootstrap` / `# END managed by terminal-bootstrap`. Each block's idempotency check looks for its own BEGIN marker and skips re-append if present. To remove either permanently, delete the matching managed block from `~/.profile` / `~/.zprofile` (env) and `~/.bashrc` / `~/.zshrc` (handoff).

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
- Linuxbrew is used only as the installer-time source for bootstrap tools; daily cross-platform CLIs are managed by aqua, and cross-platform language runtimes are managed by mise
- The shared language runtime baseline (Java, Python) lives in `shared/mise/config.toml` and is staged into `~/.config/mise/config.toml`; extend it by adding entries there, then rerun the installer or `mise install`
- On native Linux, WezTerm launches `nu` by name from the user's PATH; Linuxbrew's `/home/linuxbrew/.linuxbrew/bin` entry added by `brew shellenv` (typically sourced from `~/.profile` or `~/.bashrc`) is what makes that resolution work. If WezTerm cannot find `nu`, verify that `command -v nu` succeeds in a login shell before launching WezTerm.
- The current `shared/wezterm/wezterm.lua` probes `/opt/homebrew/bin/nu` and `/usr/local/bin/nu` before falling back to `nu` by name. Those macOS-style paths are harmless on Linux; they simply never match and the PATH lookup wins.
- Unlike the macOS branch, the Linux path does not inject `XDG_CONFIG_HOME` from WezTerm because Linux already treats `~/.config` as the default XDG config root, so NuShell resolves its managed config directly.
- Headless servers (no GUI, e.g. cloud VMs) can pass `--target wsl` to skip the WezTerm APT install and font/wezterm asset staging while keeping the rest of the baseline (NuShell, aqua, mise, Starship, LazyVim). The post-install verification line still mentions "On the Windows host …" because the WSL branch is shared with the WSL flow; ignore it on a headless server.
- `nu which <cmd>` for any cross-platform CLI such as `starship`, `nvim`, or `rg` lists `~/.config/nushell/autoload/claude-integration.nu` as the resolver instead of the actual aqua-managed binary path. This is a display artifact of how nu enumerates the large generated `extern "claude"` declaration; the external binaries still execute normally (use `^<cmd>` to force-resolve as external if you want to verify).
