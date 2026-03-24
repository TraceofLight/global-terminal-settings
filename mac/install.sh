#!/usr/bin/env bash
set -euo pipefail

SYNC_MODE="auto"
DRY_RUN=0
SKIP_PACKAGES=0
SKIP_CONFIGS=0

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
    --help|-h)
      cat <<'EOF'
Usage: ./install.sh [--dry-run] [--sync-mode auto|link|copy] [--skip-packages] [--skip-configs]
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

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$BOOTSTRAP_ROOT/shared"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
INSTALL_ROOT="$CONFIG_ROOT/terminal-bootstrap"
DEFAULT_NUSHELL_ROOT="$HOME/Library/Application Support/nushell"
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

  if [[ -L "$target" ]]; then
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

ensure_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Install Homebrew\n'
    return 0
  fi

  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
}

get_nushell_root() {
  if command -v nu >/dev/null 2>&1; then
    local nu_root
    nu_root="$(nu -n -c '$nu.default-config-dir' 2>/dev/null || true)"
    if [[ -n "$nu_root" ]]; then
      printf '%s\n' "$nu_root"
      return 0
    fi
  fi

  printf '%s\n' "$DEFAULT_NUSHELL_ROOT"
}

install_packages() {
  log_stage 2 "Core Packages"
  ensure_homebrew
  run_cmd "brew bundle --file $BOOTSTRAP_ROOT/mac/Brewfile" brew bundle --file "$BOOTSTRAP_ROOT/mac/Brewfile"
}

stage_assets() {
  log_stage 3 "Stage Managed Assets"

  sync_target "$SOURCE_ROOT/fonts" "$INSTALL_ROOT/fonts"
  sync_target "$SOURCE_ROOT/nushell" "$INSTALL_ROOT/nushell"
  sync_target "$SOURCE_ROOT/starship" "$INSTALL_ROOT/starship"
  sync_target "$SOURCE_ROOT/wezterm" "$INSTALL_ROOT/wezterm"
  sync_target "$SOURCE_ROOT/nvim" "$INSTALL_ROOT/nvim"
}

sync_app_configs() {
  log_stage 4 "Wire WezTerm"
  local nushell_root
  nushell_root="$(get_nushell_root)"

  ensure_dir "$CONFIG_ROOT/wezterm"
  ensure_dir "$nushell_root/autoload"

  sync_target "$INSTALL_ROOT/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
  sync_target "$INSTALL_ROOT/starship/starship.toml" "$CONFIG_ROOT/starship.toml"

  log_stage 5 "Wire NuShell"
  sync_target "$INSTALL_ROOT/nushell/config.nu" "$nushell_root/config.nu"
  sync_target "$INSTALL_ROOT/nushell/env.nu" "$nushell_root/env.nu"
  sync_target "$INSTALL_ROOT/nushell/login.nu" "$nushell_root/login.nu"
  sync_target "$INSTALL_ROOT/nushell/autoload/wezterm-integration.nu" "$nushell_root/autoload/wezterm-integration.nu"

  NVIM_TARGET="$CONFIG_ROOT/nvim"
}

initialize_nushell_autoload() {
  log_stage 6 "Starship, zoxide, fzf"
  local nushell_root
  nushell_root="$(get_nushell_root)"
  local autoload_root="$nushell_root/autoload"
  ensure_dir "$autoload_root"
  local no_op_script="# managed by terminal-bootstrap"

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
}

sync_nvim_config() {
  log_stage 7 "Sync LazyVim"

  sync_target "$INSTALL_ROOT/nvim" "$NVIM_TARGET"
}

printf 'terminal-bootstrap mac installer\n'
printf 'Mode: %s\n' "$SYNC_MODE"
printf 'DryRun: %s\n' "$DRY_RUN"

log_stage 1 "Package Manager Readiness"
ensure_homebrew

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
printf 'Run bash ./mac/install.sh --dry-run to inspect the plan and then launch WezTerm to verify the NuShell entrypoint.\n'
