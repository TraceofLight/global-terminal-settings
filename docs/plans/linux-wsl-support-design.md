# Linux and WSL Support Design

**Date:** 2026-04-22

## Goal

Extend the terminal-bootstrap baseline so the same `WezTerm + NuShell + Starship + zoxide + fzf + carapace + Neovim/LazyVim` environment can be reproduced on native Ubuntu Linux and inside WSL Ubuntu, using the same stage structure already defined for Windows and macOS.

## Constraints

- The shared scope remains terminal, shell, and editor only
- Stage numbers and meanings must stay aligned with the existing 1-8 structure on Windows and macOS
- Native Linux must reach the same user experience as Windows and macOS
- WSL defers the UI layer to the Windows-side WezTerm and is therefore a reduced install
- One installer script covers both native Linux and WSL; the distinction is documented in the setup guide
- Existing Windows and macOS installers, Brewfile, NuShell configuration, and LazyVim snapshot are preserved
- Native Linux must not require different NuShell content from Windows or macOS; OS-specific behavior lives behind `$nu.os-info.name` branches

## Decisions

### 1. Platform Model

Linux and WSL are added as additional targets on top of Windows and macOS. The shared baseline stack is unchanged.

- Terminal: `WezTerm`
- Default interactive shell: `NuShell`
- Prompt: `Starship`
- Navigation: `fzf`, `zoxide`
- Command completion: `carapace`
- Optional CLI extern layers: `claude`, `openclaude`
- Editor: `Neovim + LazyVim`

The WSL model treats Windows-side WezTerm as the terminal host. The WSL installer does not deploy a WezTerm configuration inside the WSL filesystem. The Windows installer registers a `wsl_domains` entry, a `launch_menu` item, and a keybinding in the shared `wezterm.lua` so the WSL Ubuntu session can be opened directly with `nu -l`.

### 2. Package Strategy

Ubuntu native and WSL Ubuntu both use two package layers.

- `apt` for the minimum host dependencies that Linuxbrew itself requires (`build-essential`, `curl`, `file`, `git`, `procps`)
- Linuxbrew (`/home/linuxbrew/.linuxbrew`) for every other baseline tool

Linuxbrew is chosen because it mirrors the macOS Brewfile almost verbatim and provides current releases of `nushell`, `starship`, `carapace`, `zoxide`, `lazygit`, and friends that are missing from or outdated in the Ubuntu repositories. The Linuxbrew dependency is install-time only. Once installed, the individual binaries run independently of the `brew` command at daily-use time.

The Linux Brewfile contains all formulae from the macOS Brewfile with `cask "wezterm"` replaced by `brew "wezterm"`. In WSL mode, the `wezterm` line is filtered out before `brew bundle` is invoked.

### 3. Installer Model

A single `linux/install.sh` serves both native Linux and WSL.

- WSL is detected automatically via `$WSL_DISTRO_NAME` and `/proc/version`
- `--target=linux|wsl` overrides the detected target
- The installer reuses the eight-stage structure from the Windows and macOS installers
- Differences between the two targets are limited to Stage 2 (Brewfile filtering), Stage 3 (fonts/wezterm staging), Stage 4 (WezTerm wiring), and Stage 8 (verification messaging)

The installer emits `Mode: native-linux` or `Mode: wsl` at start so the detected target is visible.

### 4. Stage Differences

| Stage | Native Linux | WSL |
|---|---|---|
| 1. Package Manager Readiness | apt minimum deps + Linuxbrew bootstrap | Same |
| 2. Core Packages | `brew bundle` with full Brewfile | `brew bundle` with `wezterm` line filtered out |
| 3. Stage Managed Assets | fonts, nushell, starship, wezterm, nvim | nushell, starship, nvim; fonts and wezterm skipped |
| 4. Wire WezTerm | `~/.wezterm.lua` and `~/.config/starship.toml` | Only `~/.config/starship.toml`; no WezTerm wiring |
| 5. Wire NuShell | Same as macOS | Same as macOS |
| 6. Starship/zoxide/fzf/carapace/claude/openclaude autoload | Same as macOS | Same as macOS |
| 7. Sync LazyVim | Same as macOS | Same as macOS |
| 8. Verify | Includes WezTerm launch check | Omits WezTerm launch check |

### 5. Shell Model

The existing `shared/nushell/config.nu`, `env.nu`, `login.nu`, and autoload files are shared across all four targets. Linux-specific behavior is added only to `env.nu`.

```nu
if (($nu.os-info.name | str downcase) == "linux") {
  let linux_bootstrap_paths = [
    "/home/linuxbrew/.linuxbrew/bin"
    "/home/linuxbrew/.linuxbrew/sbin"
    ($env.HOME? | path join ".local" | path join "bin")
  ] | where {|it| ($it != null) and ($it | path exists) }

  $env.PATH = (($linux_bootstrap_paths | append ($env.PATH? | default [])) | uniq)
}
```

WSL and native Linux both report `$nu.os-info.name == "linux"`, so a single branch covers them. `config.nu`'s Windows-only `btop4win` alias is unaffected. `wezterm-integration.nu`'s OSC 7 emitter already handles non-Windows paths correctly.

### 6. WezTerm WSL Integration (Windows-side)

The Windows branch of `shared/wezterm/wezterm.lua` gains a WSL entry. It is deployed to Windows users through the existing Windows installer. The WSL installer never writes a WezTerm file on the WSL side.

```lua
-- Inside the existing Windows branch, after default_prog is resolved:
config.wsl_domains = {
  {
    name = "WSL:Ubuntu",
    distribution = "Ubuntu",
    default_cwd = "~",
    -- wsl.exe -- cmd runs cmd directly without a login shell, so PATH
    -- does not include Linuxbrew's bin. Invoke nu by absolute path.
    default_prog = { "/home/linuxbrew/.linuxbrew/bin/nu", "-l" },
  },
}
config.launch_menu = {
  { label = "WSL Ubuntu (nu)", domain = { DomainName = "WSL:Ubuntu" } },
}
```

- New WezTerm windows still default to Windows-native `nu`
- `Ctrl+Shift+Space` opens the launch menu, which exposes the WSL entry
- No new keybinding is added; WezTerm's defaults (including `Ctrl+Shift+W` for close-tab) remain unchanged

The WSL distribution name is hard-coded to `Ubuntu` to match the supported target. Users with differently named distributions must adjust the entry manually; this is documented in `docs/linux-setup.md`.

### 7. File Layout

Repository additions:

```text
linux/
├── install.sh
└── Brewfile
docs/
└── linux-setup.md
```

Repository modifications:

- `README.md` — remove the `WSL-based workflows` exclusion, add Linux and WSL entry points, list `linux/` in the repository layout
- `shared/nushell/env.nu` — add the Linux branch shown in Decision 5
- `shared/wezterm/wezterm.lua` — add the WSL domain, launch menu item, and keybinding shown in Decision 6
- `docs/plans/wezterm-nushell-bootstrap-design.md` — extend the Platform Model section to acknowledge Linux and WSL as additional targets

### 8. Documentation Model

One setup guide covers both native Linux and WSL.

- `docs/linux-setup.md` follows the same stage layout as `docs/mac-setup.md` and `docs/windows-setup.md`
- A dedicated `## WSL Notes` subsection documents the target-detection behavior, the omitted stages, and the Windows-side WezTerm entry point
- Users running the installer from WSL are pointed to the Windows setup guide for the WezTerm piece

### 9. Verification Model

Native Linux verification:

- WezTerm launches and starts NuShell
- Starship prompt renders
- `carapace`, `zoxide`, `fzf`, `rg`, `fd`, `git`, `nvim` run successfully
- `claude` and `openclaude` extern layers activate when the CLIs are present

WSL verification:

- The WSL Ubuntu entry is visible in the Windows-side WezTerm launch menu (`Ctrl+Shift+Space`, the WezTerm default)
- Selecting the entry opens a new tab that enters `wsl nu -l` directly
- Inside that tab, Starship renders and the baseline CLIs run
- `claude` and `openclaude` extern layers activate when the CLIs are present inside WSL

## Deliverables

- `linux/install.sh` with WSL auto-detection
- `linux/Brewfile`
- `docs/linux-setup.md`
- Updated `shared/nushell/env.nu`
- Updated `shared/wezterm/wezterm.lua`
- Updated `README.md`
- Updated `docs/plans/wezterm-nushell-bootstrap-design.md`

## Non-Goals

- Installing WezTerm inside WSL
- Deploying fonts inside WSL
- Supporting non-Ubuntu Linux distributions
- Managing language runtimes or build toolchains beyond the apt dependencies that Linuxbrew needs
- Renaming the WSL distribution; users with non-`Ubuntu` distribution names are expected to adapt the WezTerm entry locally
