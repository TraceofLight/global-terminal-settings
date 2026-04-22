# Linux and WSL Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single `linux/install.sh` and supporting assets that reproduce the shared terminal baseline on native Ubuntu and inside WSL Ubuntu, with WSL deferring the WezTerm UI to the Windows-side installer.

**Architecture:** `linux/install.sh` follows the same eight-stage structure as `mac/install.sh`, auto-detects WSL via `$WSL_DISTRO_NAME` and `/proc/version`, uses apt only to bootstrap Linuxbrew, installs baseline tools from `linux/Brewfile`, and stages managed assets into `~/.config/terminal-bootstrap`. On WSL the installer skips font staging and the `~/.wezterm.lua` wiring because the Windows-side WezTerm (updated via the existing Windows installer) handles the UI and the WSL domain entry point.

**Tech Stack:** Bash, NuShell, Lua, Linuxbrew, apt, WezTerm, Markdown

---

### Task 1: Add Linux branch to `shared/nushell/env.nu`

**Files:**
- Modify: `shared/nushell/env.nu`

- [ ] **Step 1: Append Linux branch after the Windows branch**

After the existing `if (($nu.os-info.name | str downcase) == "windows") { ... }` block, append:

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

The new block must sit between the closing `}` of the Windows branch and the `$env.EDITOR = "nvim"` line. Preserve the blank line above `$env.EDITOR`.

- [ ] **Step 2: Verify file integrity**

Run: `grep -c "os-info.name" shared/nushell/env.nu`
Expected: `3` (macos, windows, linux branches each reference it once).

- [ ] **Step 3: Commit**

```bash
git add shared/nushell/env.nu
git commit -m "feat: add Linux PATH bootstrap branch to shared NuShell env"
```

---

### Task 2: Add WSL entry point to `shared/wezterm/wezterm.lua`

**Files:**
- Modify: `shared/wezterm/wezterm.lua`

- [ ] **Step 1: Add WSL domain, launch menu, and keybinding inside the Windows branch**

Inside the existing `if wezterm.target_triple:find("windows") then ... end` block, after the `if not config.default_prog then config.default_prog = { "nu.exe", "-l" } end` sub-block, append:

```lua
  config.wsl_domains = {
    {
      name = "WSL:Ubuntu",
      distribution = "Ubuntu",
      default_cwd = "~",
      default_prog = { "/home/linuxbrew/.linuxbrew/bin/nu", "-l" },
    },
  }
  config.launch_menu = {
    { label = "WSL Ubuntu (nu)", domain = { DomainName = "WSL:Ubuntu" } },
  }
```

No new keybinding is added. WezTerm's default `Ctrl+Shift+Space` opens the launch menu, which is where the new "WSL Ubuntu (nu)" entry surfaces. WezTerm defaults such as `Ctrl+Shift+W` (close-tab) stay intact.

- [ ] **Step 2: Verify Lua syntax**

Run: `wezterm --config-file shared/wezterm/wezterm.lua ls-fonts --list-system 2>&1 | head -n 3` on a machine with WezTerm available. If `wezterm` is not available, skip — the config is loaded live when WezTerm starts.

Alternatively, if `luac` is available: `luac -p shared/wezterm/wezterm.lua`
Expected: no output.

- [ ] **Step 3: Commit**

```bash
git add shared/wezterm/wezterm.lua
git commit -m "feat: add WSL Ubuntu domain and launch menu entry to WezTerm"
```

---

### Task 3: Create `linux/Brewfile`

**Files:**
- Create: `linux/Brewfile`

- [ ] **Step 1: Create the Brewfile**

Write exactly:

```ruby
tap "wezterm/wezterm"
brew "wezterm"

brew "bat"
brew "btop"
brew "carapace"
brew "delta"
brew "dust"
brew "duf"
brew "fastfetch"
brew "fd"
brew "fzf"
brew "git"
brew "lazygit"
brew "lsd"
brew "mise"
brew "navi"
brew "neovim"
brew "nushell"
brew "ripgrep"
brew "starship"
brew "zoxide"
```

Note: Linuxbrew's default `homebrew-core` does not ship a `wezterm` formula; WezTerm publishes the formula through its own tap at `wezterm/wezterm`. The explicit `tap` directive ensures `brew bundle` adds the tap before attempting the install. Homebrew distributes `wezterm` as a cask on macOS instead, which is why `mac/Brewfile` does not require the tap. The installer filters both the tap and the `brew "wezterm"` line out in WSL mode.

- [ ] **Step 2: Commit**

```bash
git add linux/Brewfile
git commit -m "feat: add Linuxbrew manifest mirroring macOS Brewfile"
```

---

### Task 4: Create `linux/install.sh` with full eight-stage flow

**Files:**
- Create: `linux/install.sh`

- [ ] **Step 1: Write the installer script**

Create `linux/install.sh` with exactly this content:

```bash
#!/usr/bin/env bash
set -euo pipefail

SYNC_MODE="copy"
DRY_RUN=0
SKIP_PACKAGES=0
SKIP_CONFIGS=0
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --sync-mode)
      SYNC_MODE="${2:?missing value for --sync-mode}"
      shift
      ;;
    --skip-packages)
      SKIP_PACKAGES=1
      ;;
    --skip-configs)
      SKIP_CONFIGS=1
      ;;
    --target)
      TARGET="${2:?missing value for --target}"
      shift
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./install.sh [--dry-run] [--sync-mode auto|link|copy] [--skip-packages] [--skip-configs] [--target linux|wsl]
EOF
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
  shift
done

case "$SYNC_MODE" in
  auto|link|copy)
    ;;
  *)
    printf 'Invalid --sync-mode: %s\n' "$SYNC_MODE" >&2
    exit 1
    ;;
esac

is_wsl() {
  [[ -n "${WSL_DISTRO_NAME:-}" ]] && return 0
  [[ -r /proc/version ]] && grep -qiE 'microsoft|wsl' /proc/version && return 0
  return 1
}

if [[ -z "$TARGET" ]]; then
  if is_wsl; then
    TARGET="wsl"
  else
    TARGET="linux"
  fi
fi

case "$TARGET" in
  linux|wsl)
    ;;
  *)
    printf 'Invalid --target: %s\n' "$TARGET" >&2
    exit 1
    ;;
esac

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$BOOTSTRAP_ROOT/shared"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
INSTALL_ROOT="$CONFIG_ROOT/terminal-bootstrap"
DEFAULT_NUSHELL_ROOT="$CONFIG_ROOT/nushell"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

log_stage() {
  printf '\n== %s. %s ==\n' "$1" "$2"
}

run_cmd() {
  local description="$1"
  shift
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] %s\n' "$description"
    return 0
  fi

  printf '>> %s\n' "$description"
  "$@"
}

ensure_dir() {
  local dir="$1"
  [[ -d "$dir" ]] && return 0
  run_cmd "Create directory $dir" mkdir -p "$dir"
}

backup_target() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  run_cmd "Backup $target" mv "$target" "$target.pre-terminal-bootstrap-$TIMESTAMP"
}

sync_target() {
  local source="$1"
  local target="$2"
  local mode="$SYNC_MODE"

  ensure_dir "$(dirname "$target")"

  if [[ "$mode" != "copy" && -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      printf 'skip  %s already points to managed source\n' "$target"
      return 0
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  if [[ "$mode" == "auto" || "$mode" == "link" ]]; then
    if run_cmd "Link $target -> $source" ln -s "$source" "$target"; then
      return 0
    fi
    if [[ "$mode" == "link" ]]; then
      return 1
    fi
  fi

  run_cmd "Copy $source -> $target" cp -R "$source" "$target"
}

copy_managed_file() {
  local source="$1"
  local target="$2"

  ensure_dir "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    backup_target "$target"
  elif [[ -f "$target" ]]; then
    if cmp -s "$source" "$target"; then
      printf 'skip  %s already matches managed source\n' "$target"
      return 0
    fi
    backup_target "$target"
  elif [[ -e "$target" ]]; then
    backup_target "$target"
  fi

  run_cmd "Copy managed file $source -> $target" cp "$source" "$target"
}

ensure_apt_dependencies() {
  if ! command -v apt-get >/dev/null 2>&1; then
    printf 'warn  apt-get not found; skipping apt dependency preparation\n' >&2
    return 0
  fi

  local apt_packages=(build-essential curl file git procps)
  local missing=()
  for pkg in "${apt_packages[@]}"; do
    if ! dpkg -s "$pkg" >/dev/null 2>&1; then
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    printf 'skip  apt dependencies already installed\n'
    return 0
  fi

  run_cmd "apt-get update" sudo apt-get update
  run_cmd "apt-get install ${missing[*]}" sudo apt-get install -y "${missing[@]}"
}

ensure_linuxbrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Install Linuxbrew\n'
    return 0
  fi

  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

install_packages() {
  log_stage 2 "Core Packages"
  ensure_linuxbrew

  local brewfile="$BOOTSTRAP_ROOT/linux/Brewfile"

  if [[ "$TARGET" == "wsl" ]]; then
    local filtered
    filtered="$(mktemp)"
    trap 'rm -f "$filtered"' RETURN
    grep -vE '^(brew "wezterm"|tap "wezterm/wezterm")$' "$brewfile" > "$filtered"
    run_cmd "brew bundle --file $filtered (wezterm filtered)" brew bundle --file "$filtered"
  else
    run_cmd "brew bundle --file $brewfile" brew bundle --file "$brewfile"
  fi
}

stage_assets() {
  log_stage 3 "Stage Managed Assets"

  if [[ "$TARGET" == "linux" ]]; then
    sync_target "$SOURCE_ROOT/fonts" "$INSTALL_ROOT/fonts"
    sync_target "$SOURCE_ROOT/wezterm" "$INSTALL_ROOT/wezterm"
  fi
  sync_target "$SOURCE_ROOT/nushell" "$INSTALL_ROOT/nushell"
  sync_target "$SOURCE_ROOT/starship" "$INSTALL_ROOT/starship"
  sync_target "$SOURCE_ROOT/nvim" "$INSTALL_ROOT/nvim"
}

sync_app_configs() {
  log_stage 4 "Wire WezTerm"
  local nushell_root="$DEFAULT_NUSHELL_ROOT"

  ensure_dir "$nushell_root/autoload"

  if [[ "$TARGET" == "linux" ]]; then
    ensure_dir "$CONFIG_ROOT/wezterm"
    sync_target "$INSTALL_ROOT/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
  else
    printf 'skip  WezTerm wiring (WSL target; Windows-side installer manages wezterm.lua)\n'
  fi
  sync_target "$INSTALL_ROOT/starship/starship.toml" "$CONFIG_ROOT/starship.toml"

  log_stage 5 "Wire NuShell"
  copy_managed_file "$INSTALL_ROOT/nushell/config.nu" "$nushell_root/config.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/env.nu" "$nushell_root/env.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/login.nu" "$nushell_root/login.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/autoload/wezterm-integration.nu" "$nushell_root/autoload/wezterm-integration.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/autoload/openclaude-integration.nu" "$nushell_root/autoload/openclaude-integration.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/autoload/claude-integration.nu" "$nushell_root/autoload/claude-integration.nu"

  NVIM_TARGET="$CONFIG_ROOT/nvim"
}

initialize_nushell_autoload() {
  log_stage 6 "Starship, zoxide, fzf, carapace, claude, openclaude"
  local nushell_root="$DEFAULT_NUSHELL_ROOT"
  local autoload_root="$nushell_root/autoload"
  ensure_dir "$autoload_root"
  local carapace_target="$autoload_root/carapace.nu"
  local no_op_script="# managed by terminal-bootstrap"

  if command -v carapace >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Generate NuShell Carapace autoload\n'
    else
      carapace _carapace nushell > "$carapace_target"
    fi
  else
    printf 'warn  carapace command not found; writing no-op NuShell Carapace autoload\n' >&2
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Write NuShell Carapace autoload placeholder\n'
    else
      printf '%s\n' "$no_op_script" > "$carapace_target"
    fi
  fi

  if command -v starship >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Generate NuShell Starship autoload\n'
    else
      starship init nu > "$autoload_root/starship.nu"
    fi
  else
    printf 'warn  starship command not found; writing no-op NuShell Starship autoload\n' >&2
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Write NuShell Starship autoload placeholder\n'
    else
      printf '%s\n' "$no_op_script" > "$autoload_root/starship.nu"
    fi
  fi

  if command -v zoxide >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Generate NuShell zoxide autoload\n'
    else
      zoxide init nushell > "$autoload_root/zoxide.nu"
    fi
  else
    printf 'warn  zoxide command not found; writing no-op NuShell zoxide autoload\n' >&2
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Write NuShell zoxide autoload placeholder\n'
    else
      printf '%s\n' "$no_op_script" > "$autoload_root/zoxide.nu"
    fi
  fi

  if command -v openclaude >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Write NuShell OpenClaude autoload marker\n'
    else
      printf '%s\n%s\n' '# managed by terminal-bootstrap' '# openclaude detected' > "$autoload_root/openclaude.nu"
    fi
  else
    printf 'warn  openclaude command not found; writing no-op NuShell OpenClaude autoload\n' >&2
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Write NuShell OpenClaude autoload placeholder\n'
    else
      printf '%s\n' "$no_op_script" > "$autoload_root/openclaude.nu"
    fi
  fi

  if command -v claude >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Write NuShell Claude autoload marker\n'
    else
      printf '%s\n%s\n' '# managed by terminal-bootstrap' '# claude detected' > "$autoload_root/claude.nu"
    fi
  else
    printf 'warn  claude command not found; writing no-op NuShell Claude autoload\n' >&2
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '[dry-run] Write NuShell Claude autoload placeholder\n'
    else
      printf '%s\n' "$no_op_script" > "$autoload_root/claude.nu"
    fi
  fi
}

sync_nvim_config() {
  log_stage 7 "Sync LazyVim"

  sync_target "$INSTALL_ROOT/nvim" "$NVIM_TARGET"
}

printf 'terminal-bootstrap linux installer\n'
if [[ "$TARGET" == "wsl" ]]; then
  printf 'Mode: wsl\n'
else
  printf 'Mode: native-linux\n'
fi
printf 'Sync: %s\n' "$SYNC_MODE"
printf 'DryRun: %s\n' "$DRY_RUN"

log_stage 1 "Package Manager Readiness"
ensure_apt_dependencies
ensure_linuxbrew

if [[ $SKIP_PACKAGES -eq 0 ]]; then
  install_packages
fi

if [[ $SKIP_CONFIGS -eq 0 ]]; then
  stage_assets
  sync_app_configs
  initialize_nushell_autoload
  sync_nvim_config
fi

log_stage 8 "Verify"
if [[ "$TARGET" == "wsl" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'Run bash ./linux/install.sh to apply the WSL baseline. Then on the Windows host, run the Windows installer so wezterm.lua registers the WSL Ubuntu domain, and pick "WSL Ubuntu (nu)" from the WezTerm launch menu (Ctrl+Shift+Space) to enter the WSL nu tab.\n'
  else
    printf 'On the Windows host, run the Windows installer to register the WSL Ubuntu domain in wezterm.lua, then pick "WSL Ubuntu (nu)" from the WezTerm launch menu (Ctrl+Shift+Space) to enter the WSL nu tab.\n'
  fi
else
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'Run bash ./linux/install.sh to apply the baseline, then launch WezTerm to verify the NuShell entrypoint.\n'
  else
    printf 'Launch WezTerm to verify the NuShell entrypoint.\n'
  fi
fi
```

- [ ] **Step 2: Make executable**

```bash
chmod +x linux/install.sh
```

- [ ] **Step 3: Syntax check**

```bash
bash -n linux/install.sh
```
Expected: no output.

- [ ] **Step 4: Dry-run native Linux path**

```bash
bash ./linux/install.sh --dry-run --target linux
```
Expected output includes:
- `Mode: native-linux`
- `== 1. Package Manager Readiness ==`
- `== 2. Core Packages ==` with `[dry-run] brew bundle --file .../linux/Brewfile`
- `== 3. Stage Managed Assets ==` with both `fonts` and `wezterm` lines
- `== 4. Wire WezTerm ==` with `.wezterm.lua` line
- `== 5. Wire NuShell ==` through `== 8. Verify ==`
- Final message: "Run bash ./linux/install.sh to apply the baseline, then launch WezTerm..."

- [ ] **Step 5: Dry-run WSL path**

```bash
bash ./linux/install.sh --dry-run --target wsl
```
Expected differences from the native run:
- `Mode: wsl`
- Stage 2 line includes `(wezterm filtered)`
- Stage 3 omits the `fonts` and `wezterm` sync lines
- Stage 4 prints `skip  WezTerm wiring (WSL target; ...)` and no `.wezterm.lua` sync
- Final verify message mentions Windows installer and the WezTerm launch menu entry

- [ ] **Step 6: Commit**

```bash
git add linux/install.sh
git commit -m "feat: add Linux installer with WSL auto-detection"
```

---

### Task 5: Create `docs/linux-setup.md`

**Files:**
- Create: `docs/linux-setup.md`

- [ ] **Step 1: Write the setup guide**

Create `docs/linux-setup.md` with this content:

````markdown
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

The installer first installs the minimum apt dependencies that Linuxbrew requires (`build-essential`, `curl`, `file`, `git`, `procps`) and then bootstraps Linuxbrew at `/home/linuxbrew/.linuxbrew`. Daily-use binaries are resolved through Linuxbrew's `bin` directories, which the shared `env.nu` adds to `$env.PATH` for NuShell sessions.

### 2. Core Packages

The package baseline is defined in [linux/Brewfile](../linux/Brewfile).

Key packages:

- `WezTerm` (native Linux only; filtered out in WSL mode)
- `NuShell`
- `Neovim`
- `Starship`
- `carapace`
- `ripgrep`, `fd`, `fzf`, `zoxide`, `git`, `lazygit`
- Other supporting CLIs

### 3. Stage Managed Assets

Managed assets are staged into `~/.config/terminal-bootstrap`.

Native Linux stages:

- `fonts/`
- `nushell/`
- `starship/`
- `wezterm/`
- `nvim/`

WSL stages:

- `nushell/`
- `starship/`
- `nvim/`

### 4. Wire WezTerm

Native Linux: `shared/wezterm/wezterm.lua` is copied to `~/.wezterm.lua` and `shared/starship/starship.toml` is copied to `~/.config/starship.toml`.

WSL: only `shared/starship/starship.toml` is copied. The Windows-side installer manages `wezterm.lua` and registers the WSL Ubuntu domain. See the WSL Notes section below.

### 5. Wire NuShell

NuShell configuration files are placed in `~/.config/nushell`. The managed NuShell files are copied into that directory as standalone files.

- `config.nu`
- `env.nu`
- `login.nu`
- `autoload/wezterm-integration.nu`
- `autoload/claude-integration.nu`
- `autoload/openclaude-integration.nu`

### 6. Wire Starship, zoxide, fzf, carapace, and optional claude / openclaude integration

The installer generates `carapace.nu`, `starship.nu`, and `zoxide.nu` into `~/.config/nushell/autoload/`, and `config.nu` sources them when they are present. `config.nu` also optionally sources `autoload/user-overrides.nu` when present.

`fzf` is installed as an external CLI and is directly callable from NuShell.

Neither `claude` nor `openclaude` is installed by this repository. The managed NuShell layer stages `autoload/claude-integration.nu` and `autoload/openclaude-integration.nu`, and writes `autoload/claude.nu` / `autoload/openclaude.nu` markers during install when the matching CLI is present. If either CLI is absent, the corresponding integration stays inactive and the shell still starts cleanly.

### 7. Sync LazyVim

`shared/nvim/` is copied (or linked, with `--sync-mode link`/`auto`) into `~/.config/nvim`.

This repository manages configuration only. Caches and external editor tools are regenerated in the target environment.

### 8. Verify

Native Linux minimum verification:

- WezTerm opens successfully and starts NuShell
- The Starship prompt renders correctly
- `carapace`, `zoxide`, `fzf`, `rg`, `fd`, `git`, `nvim` run successfully
- If `claude` or `openclaude` is installed, the matching NuShell extern layer loads without startup errors

WSL minimum verification:

- On the Windows host, the WezTerm launch menu (`Ctrl+Shift+Space`) exposes a "WSL Ubuntu (nu)" entry that opens a new tab running `wsl nu -l`
- Inside the WSL tab, the Starship prompt renders and the baseline CLIs run
- If `claude` or `openclaude` is installed inside WSL, the matching NuShell extern layer loads

## WSL Notes

WSL is an intentionally reduced install. The Windows host runs WezTerm and owns font rendering, window chrome, and the `wsl_domains` entry. The WSL installer therefore skips `shared/fonts/` and `shared/wezterm/wezterm.lua` and defers the WezTerm wiring.

To complete the WSL setup end to end:

1. Inside WSL, run `bash ./linux/install.sh`. The installer detects WSL automatically; pass `--target wsl` to force it.
2. On the Windows host, run the Windows installer so the updated `shared/wezterm/wezterm.lua` is deployed to `%USERPROFILE%\.wezterm.lua`. The updated config registers a `wsl_domains` entry named `WSL:Ubuntu` and adds a launch menu item "WSL Ubuntu (nu)" pointing at that domain.
3. Restart WezTerm on the Windows host. Open the launch menu with `Ctrl+Shift+Space` and pick "WSL Ubuntu (nu)" to enter the WSL nu session.

The WSL domain distribution name is hard-coded to `Ubuntu`. If your distribution is named differently (for example `Ubuntu-22.04`), edit the `distribution` field in `shared/wezterm/wezterm.lua` before running the Windows installer, or override it locally.

## Sync Policy

- Default: `copy`
- `copy`: always copy managed assets
- `auto`: try links first and fall back to copy if link creation fails
- `link`: require links and stop if link creation fails
- Existing managed targets are moved to `<target>.pre-terminal-bootstrap-<timestamp>` before replacement

## Notes

- Fonts are loaded through WezTerm `font_dirs` in the native Linux install, not installed system-wide
- On WSL, fonts live on the Windows side and are not deployed to the WSL filesystem
- Linuxbrew is used only as the installer-time source for baseline tools; once installed, each binary runs independently of `brew`
- `mise` is available as a baseline tool but language runtimes themselves are out of scope for this repository
````

- [ ] **Step 2: Commit**

```bash
git add docs/linux-setup.md
git commit -m "docs: add Linux and WSL setup guide"
```

---

### Task 6: Update `README.md`

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Update the Repository Layout block**

Replace the existing layout code block:

```text
global-terminal-settings/
├─ docs/
│  ├─ plans/
│  ├─ mac-setup.md
│  ├─ ux-contract.md
│  └─ windows-setup.md
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

With:

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

- [ ] **Step 2: Update the Entry Points section**

Replace:

```markdown
- Windows setup guide: [docs/windows-setup.md](docs/windows-setup.md)
- macOS setup guide: [docs/mac-setup.md](docs/mac-setup.md)
- Shared UX contract: [docs/ux-contract.md](docs/ux-contract.md)
- Design document: [docs/plans/wezterm-nushell-bootstrap-design.md](docs/plans/wezterm-nushell-bootstrap-design.md)
- Implementation plan: [docs/plans/wezterm-nushell-bootstrap.md](docs/plans/wezterm-nushell-bootstrap.md)
```

With:

```markdown
- Windows setup guide: [docs/windows-setup.md](docs/windows-setup.md)
- macOS setup guide: [docs/mac-setup.md](docs/mac-setup.md)
- Linux and WSL setup guide: [docs/linux-setup.md](docs/linux-setup.md)
- Shared UX contract: [docs/ux-contract.md](docs/ux-contract.md)
- Design document: [docs/plans/wezterm-nushell-bootstrap-design.md](docs/plans/wezterm-nushell-bootstrap-design.md)
- Linux and WSL design document: [docs/plans/linux-wsl-support-design.md](docs/plans/linux-wsl-support-design.md)
- Implementation plan: [docs/plans/wezterm-nushell-bootstrap.md](docs/plans/wezterm-nushell-bootstrap.md)
- Linux and WSL implementation plan: [docs/plans/linux-wsl-support.md](docs/plans/linux-wsl-support.md)
```

- [ ] **Step 3: Update the Goals section**

Replace the line:

```markdown
- Keep Windows and macOS installation guides aligned to the same stage structure
```

With:

```markdown
- Keep Windows, macOS, and Linux installation guides aligned to the same stage structure
```

- [ ] **Step 4: Update the Scope section**

In the `Excluded:` list, remove the line:

```markdown
- WSL-based workflows
```

Leave the remaining excluded items intact.

- [ ] **Step 5: Update the Shared Installation Stages section**

Replace:

```markdown
Windows and macOS use the same eight installation stages.
```

With:

```markdown
Windows, macOS, and Linux (native and WSL) use the same eight installation stages.
```

Replace:

```markdown
Only the concrete commands and package sources differ.

- Windows: `winget` first, `choco` only when already installed and the package allows fallback
- macOS: `brew`
- `claude` and `openclaude` themselves remain external prerequisites; this repo only wires shell integration when the command is already available
```

With:

```markdown
Only the concrete commands and package sources differ.

- Windows: `winget` first, `choco` only when already installed and the package allows fallback
- macOS: `brew`
- Linux (native and WSL Ubuntu): `apt` for Linuxbrew bootstrap dependencies, then `brew` for the baseline
- WSL defers font and WezTerm deployment to the Windows host; the Windows installer registers a `wsl_domains` entry so WezTerm can enter the WSL `nu` session directly
- `claude` and `openclaude` themselves remain external prerequisites; this repo only wires shell integration when the command is already available
```

- [ ] **Step 6: Commit**

```bash
git add README.md
git commit -m "docs: document Linux and WSL support in README"
```

---

### Task 7: Extend the base design document's Platform Model

**Files:**
- Modify: `docs/plans/wezterm-nushell-bootstrap-design.md`

- [ ] **Step 1: Extend the Platform Model section**

In the existing `### 1. Platform Model` section, replace the line:

```markdown
The shared baseline stack is fixed as follows.
```

With:

```markdown
The shared baseline stack is fixed as follows and applies to Windows, macOS, native Ubuntu Linux, and WSL Ubuntu. WSL is a reduced install that defers the WezTerm UI layer to the Windows host; see `linux-wsl-support-design.md` for the target-specific differences.
```

- [ ] **Step 2: Commit**

```bash
git add docs/plans/wezterm-nushell-bootstrap-design.md
git commit -m "docs: cross-link Linux and WSL support from base design"
```

---

### Task 8: End-to-end dry-run verification

**Files:** none modified

- [ ] **Step 1: Re-run the native Linux dry-run**

```bash
bash ./linux/install.sh --dry-run --target linux
```

Verify the full eight-stage output structure matches Stage 4 of Task 4.

- [ ] **Step 2: Re-run the WSL dry-run**

```bash
bash ./linux/install.sh --dry-run --target wsl
```

Verify the WSL-specific differences match Step 5 of Task 4.

- [ ] **Step 3: Grep sanity check**

```bash
grep -R "WSL-based workflows" README.md docs/ || echo "clean"
```
Expected: `clean`.

```bash
grep -c "os-info.name" shared/nushell/env.nu
```
Expected: `3`.

```bash
grep -c "WSL:Ubuntu" shared/wezterm/wezterm.lua
```
Expected: `2` (once in the `wsl_domains` `name` field, once in the `launch_menu` entry's `DomainName`).

No commit is required for this task; it is a pre-flight check before live testing.

---

## Manual Live Verification (outside this plan)

After all automated steps pass, exercise the installer on a live Ubuntu or WSL environment:

1. `bash ./linux/install.sh --dry-run` — review the planned actions
2. `bash ./linux/install.sh` — apply the baseline
3. Native Linux: launch WezTerm; confirm NuShell starts and Starship renders
4. WSL: after running the Windows installer on the host to deploy the updated `wezterm.lua`, open the WezTerm launch menu (`Ctrl+Shift+Space`), pick "WSL Ubuntu (nu)", and confirm the WSL nu tab opens with Starship rendering
5. In either environment: `carapace`, `zoxide`, `fzf`, `rg`, `fd`, `git`, `nvim` must run without errors
