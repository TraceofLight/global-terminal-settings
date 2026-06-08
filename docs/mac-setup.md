# mac Setup

This document defines the macOS baseline produced by the `terminal-bootstrap` repository.

## Target State

- Terminal: `WezTerm` (nightly channel — the stable cask has not been refreshed in a long time, so macOS pins the `wezterm@nightly` Homebrew cask)
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
- `--skip-root`: disable the default root wiring (see "Root environment" section below). Use on shared Macs where the invoking user is not a sudoer, or when sudo isn't available
- `--include-root`: kept for backward compatibility; root wiring is on by default, so this flag is a no-op

## Install Flow

### 1. Package Manager Readiness

- The primary package manager is `brew`.
- The installer prepares Homebrew first if it is not already available.

### 2. Core Packages

The package baseline is defined in [mac/Brewfile](../mac/Brewfile).

Key packages:

- `wezterm@nightly`
- `nushell`
- `git`
- `aqua`
- `mise`
- `font-symbols-only-nerd-font`

Daily cross-platform CLIs are declared in [shared/aqua/aqua.yaml](../shared/aqua/aqua.yaml) and installed by aqua after the bootstrap packages are available. Cross-platform language runtimes (Java, Python) are declared in [shared/mise/config.toml](../shared/mise/config.toml) and installed by mise after the aqua step.

### 3. Stage Managed Assets

Managed assets are staged into `~/.config/terminal-bootstrap` by default. If `XDG_CONFIG_HOME` is set, the installer uses `$XDG_CONFIG_HOME/terminal-bootstrap`.

- `fonts/`
- `aqua/`
- `mise/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

### 4. Wire WezTerm

The following files are copied into their real locations by default. `--sync-mode link` or `--sync-mode auto` can opt back into link-based deployment when needed.

- `shared/wezterm/wezterm.lua` -> `~/.wezterm.lua`
- `shared/starship/starship.toml` -> `~/.config/starship.toml` by default
- If `XDG_CONFIG_HOME` is set, `shared/starship/starship.toml` -> `$XDG_CONFIG_HOME/starship.toml`
- `shared/aqua/aqua.yaml` -> `~/.config/aquaproj-aqua/aqua.yaml` by default, or `$XDG_CONFIG_HOME/aquaproj-aqua/aqua.yaml` when `XDG_CONFIG_HOME` is set
- `shared/mise/config.toml` -> `~/.config/mise/config.toml` by default, or `$XDG_CONFIG_HOME/mise/config.toml` when `XDG_CONFIG_HOME` is set

`WezTerm` launches `nu -l` as the default shell and sets `XDG_CONFIG_HOME=~/.config` on macOS so NuShell resolves its active config from `~/.config/nushell`.

### 5. Wire NuShell

NuShell configuration files are placed in `~/.config/nushell` by default. If `XDG_CONFIG_HOME` is set, the installer uses `$XDG_CONFIG_HOME/nushell`. The managed NuShell files are copied into that directory as standalone files rather than linked, so the active shell configuration does not depend on `terminal-bootstrap/` or the repository checkout.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload/wezterm-integration.nu`
- `autoload/claude-integration.nu`
- `autoload/openclaude-integration.nu`
- `autoload/zz-prompt-overrides.nu`

GUI-launched processes on macOS (JetBrains IDEs, Raycast, and other applications launched outside WezTerm) do not inherit the `XDG_CONFIG_HOME=~/.config` that the WezTerm entrypoint sets, so NuShell falls back to `~/Library/Application Support/nushell` and reads a separate snapshot. To keep every GUI-launched NuShell session aligned with the managed configuration, the installer links `~/Library/Application Support/nushell` to the resolved NuShell config directory. An existing directory at the fallback path is moved to `<target>.pre-terminal-bootstrap` before the link is created, consistent with the rest of the sync policy.

### 6. Wire Starship, zoxide, fzf, carapace, mise, and optional claude / openclaude integration

After the aqua config is copied, the installer runs `aqua install -a` when `aqua` is available. If that command fails, the installer warns and continues because aqua lazy install can retry in a later shell session.

After the mise config is copied, the installer runs `mise install -y` when `mise` is available so the runtimes pinned in `shared/mise/config.toml` (Java, Python) are present after bootstrap. If the mise binary is missing or the command fails, the installer warns and continues; the runtimes can be installed later with `mise install`.

The installer generates `carapace.nu`, `starship.nu`, and `zoxide.nu` into the resolved NuShell config directory under `autoload/`, and `config.nu` sources them when they are present. These binaries are provided by aqua. The generated `starship.nu` resolves the real Starship executable with `aqua which starship` when possible, disables the NuShell right-prompt hook, skips Starship rendering immediately after POSIX and Windows interrupt exit statuses, and catches Starship prompt-render failures so an interrupted foreground command cannot surface as a prompt hook error. `autoload/zz-prompt-overrides.nu` is staged as a managed late-load guard; the `zz-` prefix intentionally keeps it after normal generated autoload files in alphabetical load order. Managed and generated autoload files may be temporarily absent during bootstrap or repair without blocking shell startup. `env.nu` sets `AQUA_GLOBAL_CONFIG` to the managed config only when the variable is not already set, and prepends aqua's root `bin` directory when present. `config.nu` also optionally sources `autoload/user-overrides.nu` when present; this file is reserved for user-managed aliases, Java/runtime setup, and scripts and is not overwritten by reinstall.

`fzf` and the other daily CLIs are expected to resolve through aqua.

Neither `claude` nor `openclaude` is installed by this repository. Instead, the managed NuShell layer stages `autoload/claude-integration.nu` and `autoload/openclaude-integration.nu`, and writes `autoload/claude.nu` / `autoload/openclaude.nu` markers during install. Startup does not depend on any of those files. If the `claude` or `openclaude` CLI is absent, the corresponding integration remains inactive and the shell still starts normally.

### 7. Sync LazyVim

`shared/nvim/` is linked or copied into `~/.config/nvim` by default. If `XDG_CONFIG_HOME` is set, the installer uses `$XDG_CONFIG_HOME/nvim`. The `nvim` binary itself is aqua-managed.

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

## Root environment

The installer wires `/var/root` alongside the invoking user by default. When `sudo -i` / `sudo su -` lands you in the root account, you otherwise get a bare zsh that knows nothing about the managed Homebrew PATH, aqua-managed CLIs, or NuShell aliases — so habits like `vi` (aliased to `nvim` inside NuShell) silently break under root because: (a) the alias is defined in `~user/.config/nushell/config.nu`, not in root's shell; (b) `nvim` lives at `~user/.local/share/aquaproj-aqua/bin/nvim`, which is not on root's `$PATH`; (c) aqua's stub launcher needs `AQUA_GLOBAL_CONFIG`, which root doesn't have. All three layers miss, and the editor stops working.

The default behavior plugs all three:

- Sets `/Users/root`'s `UserShell` to `/bin/zsh` via `dscl . -create /Users/root UserShell /bin/zsh`. macOS ships root with `/bin/sh`, which never sources `.zshrc` and therefore never reaches the nu handoff — so `sudo su` (non-login interactive) would otherwise drop you into `sh`, not nu. zsh is kept as the login shell (rather than setting root's shell directly to nu) because it acts as a one-line trampoline that immediately exec's nu, while leaving a working fallback if nu is ever missing or broken so the root account is never unbootable.
- `/var/root/.zprofile` env block (idempotent, marker `# BEGIN managed by terminal-bootstrap (root-env)`): exports `XDG_CONFIG_HOME=/var/root/.config` (so nu and starship read the managed config instead of falling back to `/var/root/Library/Application Support/nushell` on macOS), sources Homebrew `shellenv` (auto-detected at `/opt/homebrew` or `/usr/local`), exports `AQUA_GLOBAL_CONFIG` to the invoking user's aqua config, and prepends aqua's bin directory to `$PATH`. Sourced for all root login shells, interactive or not.
- `/var/root/.zshrc` handoff block (idempotent, marker `# BEGIN managed by terminal-bootstrap (root-handoff)`): repeats the env setup including `XDG_CONFIG_HOME` (for non-login interactive shells like `sudo su`) and re-execs into `nu -l` when the shell is interactive. Same escape hatches as the regular user handoff (`TERMINAL_BOOTSTRAP_NO_HANDOFF=1`, `TERMINAL_BOOTSTRAP_NU_HANDOFF` guard).
- `/var/root/.config/{nushell,nvim,aquaproj-aqua,mise}` and `/var/root/.config/starship.toml` symlinks → corresponding paths under the invoking user's `~/.config`. Root reads the same nu config, the same LazyVim setup, the same aqua/mise pins, and the same starship prompt. Single source of truth: edits in the user's home apply to both.
- `/var/root/Library/Application Support/nushell` symlink → `/var/root/.config/nushell` (the same managed config). Mirrors the user-side macOS fallback link so that any root nu session — even one that somehow drops `XDG_CONFIG_HOME` — still resolves the managed config instead of creating a fresh empty one. Existing directories at this path are backed up to `.pre-terminal-bootstrap.<unix-ts>` before the link is created.

With this in place, `sudo -i`, `sudo su -`, and `sudo su` all land in nu with the full managed UX (root's shell is zsh, `.zshrc` runs the handoff for interactive sessions, `.zprofile` covers login). `sudo nvim /etc/foo` works because aqua's stub now resolves with `AQUA_GLOBAL_CONFIG` set. The `vi` alias works because root is in nu, where the alias is defined.

The installer builds the root-side script once and dispatches it through a single privileged invocation, so authentication happens once and there are no per-command re-prompts. The dispatch chain is:

1. `sudo` with a valid credential cache (`sudo -n true` succeeds) — runs silently.
2. Interactive TTY present — normal `sudo bash …` terminal password prompt.
3. No TTY but macOS available — `osascript … with administrator privileges` pops the system GUI password dialog, then runs the script as root. This lets `install.sh` succeed in non-TTY contexts (CI, IDE "Run script" buttons, agent shells) where ordinary sudo can't read a password.

If all three fail or sudo isn't installed, the step is skipped with a warn and the rest of the install proceeds normally — so non-sudoer accounts still get a working user-level setup. Pass `--skip-root` to disable explicitly.

**Security model**: root reuses the *invoking user*'s binaries and config. If the user account is compromised, the attacker can plant a malicious binary in `~/.local/share/aquaproj-aqua/bin/` and the next `sudo -i` will execute it as root. This is harmless on a personal Mac where the user is already a sudoer (the attacker can do the same with `sudo bash`), but on shared Macs where the invoking user is NOT a sudoer this leaks a privilege-escalation path — pass `--skip-root` to disable.

To remove after the fact: delete the two managed blocks from `/var/root/.zprofile` and `/var/root/.zshrc`, `sudo rm /var/root/.config/{nushell,nvim,aquaproj-aqua,mise,starship.toml}` and `sudo rm "/var/root/Library/Application Support/nushell"` (these are symlinks; removing them does not touch the source files), and revert root's shell with `sudo dscl . -create /Users/root UserShell /bin/sh` if you want the macOS default back.

## Sync Policy

- Default: `copy`
- `copy`: always copy managed assets
- `auto`: try links first and fall back to copy if link creation fails
- `link`: require links and stop if link creation fails
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap` before replacement; each run overwrites the previous backup, so at most one backup per target is retained

Why copy is preferred:

- Installed apps keep working even if the repository checkout or worktree is removed
- Runtime configuration does not depend on staged assets remaining linked to the source checkout
- It avoids environment-specific link permission differences

Why link modes still exist:

- Some maintenance workflows prefer the repository and staging directory to remain the source of truth
- Asset changes can show up immediately when link-based deployment is intentional

## Notes

- Fonts are loaded through WezTerm `font_dirs`, not installed system-wide
- `Symbols Nerd Font Mono` is installed system-wide via the `font-symbols-only-nerd-font` Homebrew cask so GUI terminals that rely on the system font pool (JetBrains IDEs, etc.) can resolve the full Nerd Font symbol range. WezTerm uses it as a fallback after `Monoplex KR Wide Nerd` to cover codepoints that the primary font does not ship, such as the `[os]` indicator glyphs from `starship.toml`
- The macOS baseline is also defined around `NuShell`; other shell profile files are out of scope
- Homebrew remains the installer and package source, not the daily interactive shell baseline
- On macOS, WezTerm checks the common Homebrew `NuShell` install paths first and falls back to `nu` by name
- The managed `env.nu` prepends the common Homebrew bin directories so GUI-launched WezTerm sessions can still find bootstrap CLIs, and prepends aqua's root `bin` when present so aqua-managed daily CLIs win

## JetBrains Terminal Configuration

JetBrains IDE terminals on macOS do not share WezTerm's font fallback chain. To render the full Nerd Font symbol range (including the Material Design OS indicator glyphs that `Monoplex KR Wide Nerd` does not ship), configure the IDE terminal explicitly:

- `Settings` -> `Tools` -> `Terminal`
- Font: `MonoplexKR Wide Nerd`
- Fallback: `Symbols Nerd Font Mono`

This matches the WezTerm fallback chain declared in `shared/wezterm/wezterm.lua` and produces consistent glyph coverage across the two environments.
