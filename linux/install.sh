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

  if [[ "$TARGET" == "wsl" ]]; then
    persist_bash_handoff_block
  fi

  NVIM_TARGET="$CONFIG_ROOT/nvim"
}

persist_bash_handoff_block() {
  local bashrc="$HOME/.bashrc"
  local begin_marker="# BEGIN managed by terminal-bootstrap"

  if [[ -f "$bashrc" ]] && grep -qF "$begin_marker" "$bashrc"; then
    printf 'skip  %s already has terminal-bootstrap handoff block\n' "$bashrc"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Append terminal-bootstrap handoff block to %s\n' "$bashrc"
    return 0
  fi

  [[ -f "$bashrc" ]] || touch "$bashrc"

  cat >> "$bashrc" <<'BASHRC_EOF'

# BEGIN managed by terminal-bootstrap
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Hand off interactive bash sessions to nu so the managed UX
# (Starship, carapace, vi alias, etc.) takes effect. Skip by setting
# TERMINAL_BOOTSTRAP_NO_HANDOFF=1, or when the shell is non-interactive.
if [[ $- == *i* ]] && [ -z "${TERMINAL_BOOTSTRAP_NO_HANDOFF:-}" ] && [ -z "${TERMINAL_BOOTSTRAP_NU_HANDOFF:-}" ] && command -v nu >/dev/null 2>&1; then
  export TERMINAL_BOOTSTRAP_NU_HANDOFF=1
  exec nu -l
fi
# END managed by terminal-bootstrap
BASHRC_EOF

  printf 'ok    Added terminal-bootstrap handoff block to %s\n' "$bashrc"
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
