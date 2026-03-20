#!/usr/bin/env bash
set -euo pipefail

SYNC_MODE="auto"
DRY_RUN=0
SKIP_PACKAGES=0
SKIP_CONFIGS=0
SKIP_SHELL=0

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
    --skip-shell)
      SKIP_SHELL=1
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./install.sh [--dry-run] [--sync-mode auto|link|copy] [--skip-packages] [--skip-configs] [--skip-shell]
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
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

log_section() {
  printf '\n== %s ==\n' "$1"
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

ensure_managed_block() {
  local file="$1"
  local begin="$2"
  local end="$3"
  local block="$4"
  local tmp

  ensure_dir "$(dirname "$file")"
  [[ -f "$file" ]] || : > "$file"

  tmp="$(mktemp)"
  awk -v begin="$begin" -v end="$end" '
    $0 == begin { skip = 1; next }
    $0 == end { skip = 0; next }
    !skip { print }
  ' "$file" > "$tmp"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Update managed block in %s\n' "$file"
    rm -f "$tmp"
    return 0
  fi

  mv "$tmp" "$file"
  {
    printf '\n%s\n' "$begin"
    printf '%s\n' "$block"
    printf '%s\n' "$end"
  } >> "$file"
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

install_packages() {
  log_section "Packages"
  ensure_homebrew
  run_cmd "brew bundle --file $BOOTSTRAP_ROOT/mac/Brewfile" brew bundle --file "$BOOTSTRAP_ROOT/mac/Brewfile"
}

stage_assets() {
  log_section "Stage Managed Assets"

  sync_target "$SOURCE_ROOT/fonts" "$INSTALL_ROOT/fonts"
  sync_target "$SOURCE_ROOT/shell" "$INSTALL_ROOT/shell"
  sync_target "$SOURCE_ROOT/starship" "$INSTALL_ROOT/starship"
  sync_target "$SOURCE_ROOT/tmux" "$INSTALL_ROOT/tmux"
  sync_target "$SOURCE_ROOT/wezterm" "$INSTALL_ROOT/wezterm"
  sync_target "$SOURCE_ROOT/nvim" "$INSTALL_ROOT/nvim"
}

sync_app_configs() {
  log_section "Application Config Targets"

  ensure_dir "$CONFIG_ROOT/wezterm"

  sync_target "$INSTALL_ROOT/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
  sync_target "$INSTALL_ROOT/wezterm/wezterm-shell-integration.sh" "$CONFIG_ROOT/wezterm/wezterm-shell-integration.sh"
  sync_target "$INSTALL_ROOT/starship/starship.toml" "$CONFIG_ROOT/starship.toml"
  sync_target "$INSTALL_ROOT/tmux/.tmux.conf" "$HOME/.tmux.conf"
  sync_target "$INSTALL_ROOT/nvim" "$CONFIG_ROOT/nvim"
}

update_shell_profiles() {
  log_section "Shell Profiles"

  ensure_managed_block \
    "$HOME/.zshrc" \
    '# >>> terminal-bootstrap >>>' \
    '# <<< terminal-bootstrap <<<' \
    'if [ -f "$HOME/.config/terminal-bootstrap/shell/aliases.sh" ]; then
  . "$HOME/.config/terminal-bootstrap/shell/aliases.sh"
fi'
}

printf 'terminal-bootstrap mac installer\n'
printf 'Mode: %s\n' "$SYNC_MODE"
printf 'DryRun: %s\n' "$DRY_RUN"

if [[ $SKIP_PACKAGES -eq 0 ]]; then
  install_packages
fi

if [[ $SKIP_CONFIGS -eq 0 ]]; then
  stage_assets
  sync_app_configs
fi

if [[ $SKIP_SHELL -eq 0 ]]; then
  update_shell_profiles
fi

printf '\nmac bootstrap plan complete.\n'
