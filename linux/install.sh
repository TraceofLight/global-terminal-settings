#!/usr/bin/env bash
set -euo pipefail

SYNC_MODE="copy"
DRY_RUN=0
SKIP_PACKAGES=0
SKIP_CONFIGS=0
TARGET=""
HEADLESS=0
INCLUDE_ROOT=1  # default on; install.sh prompts for sudo up front so a single
                # `bash install.sh` invocation wires both user and root in one
                # pass. Use --skip-root to disable on machines where the
                # invoking user is not (or should not be) a sudoer.

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
    --headless)
      HEADLESS=1
      ;;
    --include-root)
      # Kept for backward compatibility — root wiring is on by default.
      INCLUDE_ROOT=1
      ;;
    --skip-root)
      INCLUDE_ROOT=0
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./install.sh [--dry-run] [--sync-mode auto|link|copy] [--skip-packages] [--skip-configs] [--target linux|wsl] [--headless] [--skip-root]

  --headless      Server/SSH install mode for native Linux. Installs the
                  terminal CLI baseline and shell handoff, but skips WezTerm
                  package install, WezTerm config wiring, and font staging.

  --skip-root     Disable the default root wiring. By default install.sh
                  also wires ~root with the same Linuxbrew PATH, aqua/mise
                  env, nu shell handoff, and symlinks to the invoking
                  user's ~/.config/{nushell,nvim,aquaproj-aqua,mise,
                  starship.toml} — so `sudo -i` lands in the same managed
                  UX. Pass this flag on machines where the invoking user
                  is not (or should not be) a sudoer, or when sudo isn't
                  available.

  --include-root  Kept for backward compatibility; root wiring is now on
                  by default, so this flag is a no-op.
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

run_as_root() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    printf 'error sudo not available; cannot run privileged command: %s\n' "$*" >&2
    return 1
  fi
}

install_gui_assets() {
  [[ "$TARGET" == "linux" && $HEADLESS -eq 0 ]]
}

run_as_linuxbrew_user() {
  if command -v runuser >/dev/null 2>&1; then
    runuser -u linuxbrew -- "$@"
  else
    local quoted=""
    local arg
    for arg in "$@"; do
      quoted+=" $(printf '%q' "$arg")"
    done
    su -s /bin/bash linuxbrew -c "${quoted# }"
  fi
}

run_brew() {
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    run_as_linuxbrew_user bash -lc 'cd /tmp && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew "$@"' bash "$@"
  else
    brew "$@"
  fi
}

ensure_dir() {
  local dir="$1"
  [[ -d "$dir" ]] && return 0
  run_cmd "Create directory $dir" mkdir -p "$dir"
}

backup_target() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  local backup="$target.pre-terminal-bootstrap"
  if [[ -e "$backup" || -L "$backup" ]]; then
    run_cmd "Remove stale $backup" rm -rf "$backup"
  fi
  run_cmd "Backup $target" mv "$target" "$backup"
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

  local apt_packages=(build-essential ca-certificates curl file git gpg procps)
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

  run_cmd "apt-get update" run_as_root apt-get update
  run_cmd "apt-get install ${missing[*]}" run_as_root apt-get install -y "${missing[@]}"
}

ensure_linuxbrew() {
  if command -v brew >/dev/null 2>&1; then
    return 0
  fi

  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
      run_as_root chmod 755 /home/linuxbrew
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Install Linuxbrew\n'
    return 0
  fi

  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    if ! getent passwd linuxbrew >/dev/null 2>&1; then
      run_as_root useradd -m -s /bin/bash linuxbrew
    fi
    run_as_root mkdir -p /home/linuxbrew
    run_as_root chown -R linuxbrew:linuxbrew /home/linuxbrew
    run_as_root chmod 755 /home/linuxbrew
    run_as_linuxbrew_user bash -lc 'NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
  else
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
      run_as_root chmod 755 /home/linuxbrew
    fi
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
}

install_packages() {
  log_stage 2 "Core Packages"
  ensure_linuxbrew

  local brewfile="$BOOTSTRAP_ROOT/linux/Brewfile"

  if install_gui_assets; then
    install_wezterm_from_apt
  elif [[ "$TARGET" == "linux" && $HEADLESS -eq 1 ]]; then
    printf 'skip  WezTerm package install (headless Linux target)\n'
  fi

  local brewfile_for_run="$brewfile"
  if [[ ${EUID:-$(id -u)} -eq 0 && $DRY_RUN -eq 0 ]]; then
    brewfile_for_run="$(mktemp /tmp/terminal-bootstrap-brewfile.XXXXXX)"
    cp "$brewfile" "$brewfile_for_run"
    chmod 644 "$brewfile_for_run"
  fi

  run_cmd "brew bundle --file $brewfile" run_brew bundle --file "$brewfile_for_run"

  if [[ "$brewfile_for_run" != "$brewfile" ]]; then
    rm -f "$brewfile_for_run"
  fi
}

remove_linuxbrew_wezterm() {
  command -v brew >/dev/null 2>&1 || return 0

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Check for and remove legacy Linuxbrew WezTerm formulae\n'
    return 0
  fi

  local formulas=(
    "wezterm/wezterm-linuxbrew/wezterm"
    "wezterm"
  )
  for formula in "${formulas[@]}"; do
    if run_brew list --formula "$formula" >/dev/null 2>&1; then
      run_cmd "Remove Linuxbrew WezTerm formula $formula" run_brew uninstall --formula "$formula"
    fi
  done
}

install_wezterm_from_apt() {
  if ! command -v apt-get >/dev/null 2>&1; then
    printf 'warn  apt-get not found; skipping native Linux WezTerm install\n' >&2
    return 0
  fi

  remove_linuxbrew_wezterm

  if dpkg -s wezterm-nightly >/dev/null 2>&1; then
    printf 'skip  WezTerm nightly already installed\n'
    return 0
  fi

  local keyring="/usr/share/keyrings/wezterm-fury.gpg"
  local source_list="/etc/apt/sources.list.d/wezterm.list"
  local source_line="deb [signed-by=$keyring] https://apt.fury.io/wez/ * *"

  install_wezterm_key() {
    curl -fsSL https://apt.fury.io/wez/gpg.key | run_as_root gpg --yes --dearmor -o "$keyring"
  }

  configure_wezterm_source() {
    printf '%s\n' "$source_line" | run_as_root tee "$source_list" >/dev/null
    run_as_root chmod 644 "$keyring" "$source_list"
  }

  run_cmd "Install WezTerm APT signing key" install_wezterm_key
  run_cmd "Configure WezTerm APT source" configure_wezterm_source
  run_cmd "apt-get update for WezTerm" run_as_root apt-get update
  run_cmd "apt-get install wezterm-nightly" run_as_root apt-get install -y wezterm-nightly
}

stage_assets() {
  log_stage 3 "Stage Managed Assets"

  sync_target "$SOURCE_ROOT/aqua" "$INSTALL_ROOT/aqua"
  if install_gui_assets; then
    sync_target "$SOURCE_ROOT/fonts" "$INSTALL_ROOT/fonts"
    sync_target "$SOURCE_ROOT/wezterm" "$INSTALL_ROOT/wezterm"
  elif [[ "$TARGET" == "linux" && $HEADLESS -eq 1 ]]; then
    printf 'skip  font and WezTerm asset staging (headless Linux target)\n'
  fi
  sync_target "$SOURCE_ROOT/mise" "$INSTALL_ROOT/mise"
  sync_target "$SOURCE_ROOT/nushell" "$INSTALL_ROOT/nushell"
  sync_target "$SOURCE_ROOT/starship" "$INSTALL_ROOT/starship"
  sync_target "$SOURCE_ROOT/nvim" "$INSTALL_ROOT/nvim"
}

sync_app_configs() {
  log_stage 4 "Wire WezTerm"
  local nushell_root="$DEFAULT_NUSHELL_ROOT"

  ensure_dir "$nushell_root/autoload"

  if install_gui_assets; then
    ensure_dir "$CONFIG_ROOT/wezterm"
    sync_target "$INSTALL_ROOT/wezterm/wezterm.lua" "$HOME/.wezterm.lua"
  elif [[ "$TARGET" == "linux" && $HEADLESS -eq 1 ]]; then
    printf 'skip  WezTerm wiring (headless Linux target)\n'
  else
    printf 'skip  WezTerm wiring (WSL target; Windows-side installer manages wezterm.lua)\n'
  fi
  sync_target "$INSTALL_ROOT/starship/starship.toml" "$CONFIG_ROOT/starship.toml"
  copy_managed_file "$INSTALL_ROOT/aqua/aqua.yaml" "$CONFIG_ROOT/aquaproj-aqua/aqua.yaml"
  copy_managed_file "$INSTALL_ROOT/mise/config.toml" "$CONFIG_ROOT/mise/config.toml"

  log_stage 5 "Wire NuShell"
  copy_managed_file "$INSTALL_ROOT/nushell/config.nu" "$nushell_root/config.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/env.nu" "$nushell_root/env.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/login.nu" "$nushell_root/login.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/autoload/wezterm-integration.nu" "$nushell_root/autoload/wezterm-integration.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/autoload/openclaude-integration.nu" "$nushell_root/autoload/openclaude-integration.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/autoload/claude-integration.nu" "$nushell_root/autoload/claude-integration.nu"
  copy_managed_file "$INSTALL_ROOT/nushell/autoload/zz-prompt-overrides.nu" "$nushell_root/autoload/zz-prompt-overrides.nu"

  persist_shell_handoff_blocks

  NVIM_TARGET="$CONFIG_ROOT/nvim"
}

prepend_aqua_bin_to_path() {
  command -v aqua >/dev/null 2>&1 || return 0

  local aqua_root
  aqua_root="$(aqua root-dir 2>/dev/null || true)"
  [[ -n "$aqua_root" ]] || return 0

  local aqua_bin="$aqua_root/bin"
  [[ -d "$aqua_bin" ]] || return 0

  case ":$PATH:" in
    *":$aqua_bin:"*)
      ;;
    *)
      export PATH="$aqua_bin:$PATH"
      ;;
  esac
}

initialize_aqua_packages() {
  local aqua_config="$CONFIG_ROOT/aquaproj-aqua/aqua.yaml"
  if [[ -f "$aqua_config" ]]; then
    export AQUA_GLOBAL_CONFIG="$aqua_config"
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Install Aqua packages from %s\n' "$aqua_config"
    return 0
  fi

  if ! command -v aqua >/dev/null 2>&1; then
    printf 'warn  aqua command not found; skipping Aqua package install\n' >&2
    return 0
  fi

  if ! aqua install -a; then
    printf 'warn  aqua install -a failed; continuing because lazy install can retry later\n' >&2
  fi

  prepend_aqua_bin_to_path
}

initialize_mise_runtimes() {
  local mise_config="$CONFIG_ROOT/mise/config.toml"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Install mise runtimes from %s\n' "$mise_config"
    return 0
  fi

  if ! command -v mise >/dev/null 2>&1; then
    printf 'warn  mise command not found; skipping language runtime install\n' >&2
    return 0
  fi

  if ! mise install -y; then
    printf 'warn  mise install failed; rerun manually after resolving the error\n' >&2
  fi
}

persist_profile_env_block() {
  local profile="$HOME/.profile"
  local begin_marker="# BEGIN managed by terminal-bootstrap (env)"

  if [[ -f "$profile" ]] && grep -qF "$begin_marker" "$profile"; then
    printf 'skip  %s already has terminal-bootstrap env block\n' "$profile"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Append terminal-bootstrap env block to %s\n' "$profile"
    return 0
  fi

  [[ -f "$profile" ]] || touch "$profile"

  cat >> "$profile" <<'PROFILE_EOF'

# BEGIN managed by terminal-bootstrap (env)
# Linuxbrew shellenv. Sourced for all bash login shells, including the
# non-interactive case (e.g. `ssh host -- bash -lc "..."`), so managed CLIs
# (nu, aqua, mise, ...) resolve there too. ~/.bashrc has its own copy guarded
# by the bash early-return-for-non-interactive idiom, which is why login
# non-interactive shells must source the env from here instead.
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
# END managed by terminal-bootstrap (env)
PROFILE_EOF

  printf 'ok    Added terminal-bootstrap env block to %s\n' "$profile"
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

uses_zsh_shell() {
  local login_shell=""
  if command -v getent >/dev/null 2>&1; then
    login_shell="$(getent passwd "$(id -un)" | cut -d: -f7 || true)"
  fi

  local shell_path
  for shell_path in "${SHELL:-}" "$login_shell"; do
    [[ -n "$shell_path" ]] || continue
    if [[ "$(basename "$shell_path")" == "zsh" ]]; then
      return 0
    fi
  done

  return 1
}

persist_zprofile_env_block() {
  local zprofile="$HOME/.zprofile"
  local begin_marker="# BEGIN managed by terminal-bootstrap (env)"

  if [[ -f "$zprofile" ]] && grep -qF "$begin_marker" "$zprofile"; then
    printf 'skip  %s already has terminal-bootstrap env block\n' "$zprofile"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Append terminal-bootstrap env block to %s\n' "$zprofile"
    return 0
  fi

  [[ -f "$zprofile" ]] || touch "$zprofile"

  cat >> "$zprofile" <<'ZPROFILE_EOF'

# BEGIN managed by terminal-bootstrap (env)
# Linuxbrew shellenv for zsh login shells, including the non-interactive
# case (e.g. `ssh host -- zsh -lc "..."`). ~/.zshrc holds the interactive
# handoff to nu separately.
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
# END managed by terminal-bootstrap (env)
ZPROFILE_EOF

  printf 'ok    Added terminal-bootstrap env block to %s\n' "$zprofile"
}

persist_zsh_handoff_block() {
  local zshrc="$HOME/.zshrc"
  local begin_marker="# BEGIN managed by terminal-bootstrap"

  if [[ -f "$zshrc" ]] && grep -qF "$begin_marker" "$zshrc"; then
    printf 'skip  %s already has terminal-bootstrap handoff block\n' "$zshrc"
    return 0
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Append terminal-bootstrap handoff block to %s\n' "$zshrc"
    return 0
  fi

  [[ -f "$zshrc" ]] || touch "$zshrc"

  cat >> "$zshrc" <<'ZSHRC_EOF'

# BEGIN managed by terminal-bootstrap
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# Hand off interactive zsh sessions to nu so the managed UX
# (Starship, carapace, vi alias, etc.) takes effect. Skip by setting
# TERMINAL_BOOTSTRAP_NO_HANDOFF=1, or when the shell is non-interactive.
if [[ -o interactive ]] && [ -z "${TERMINAL_BOOTSTRAP_NO_HANDOFF:-}" ] && [ -z "${TERMINAL_BOOTSTRAP_NU_HANDOFF:-}" ] && command -v nu >/dev/null 2>&1; then
  export TERMINAL_BOOTSTRAP_NU_HANDOFF=1
  exec nu -l
fi
# END managed by terminal-bootstrap
ZSHRC_EOF

  printf 'ok    Added terminal-bootstrap handoff block to %s\n' "$zshrc"
}

persist_shell_handoff_blocks() {
  persist_profile_env_block
  persist_bash_handoff_block

  if uses_zsh_shell; then
    persist_zprofile_env_block
    persist_zsh_handoff_block
  fi
}

write_root_managed_block() {
  local target="$1"
  local begin_marker="$2"
  local end_marker="$3"
  local description="$4"
  local block
  block="$(cat)"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Replace %s in %s\n' "$description" "$target"
    return 0
  fi

  local tmp
  tmp="$(mktemp)"

  if run_as_root test -f "$target"; then
    run_as_root awk -v begin="$begin_marker" -v end="$end_marker" '
      $0 == begin { skip = 1; next }
      $0 == end { skip = 0; next }
      !skip { print }
    ' "$target" > "$tmp"
  fi

  printf '\n%s\n' "$block" >> "$tmp"
  run_as_root install -m 0644 "$tmp" "$target"
  rm -f "$tmp"
  printf 'ok    Replaced %s in %s\n' "$description" "$target"
}

persist_root_setup() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]] && ! command -v sudo >/dev/null 2>&1; then
    printf 'warn  sudo not available; cannot wire root (--include-root skipped)\n' >&2
    return 0
  fi

  log_stage R "Root environment (wire ~root)"

  local user_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
  local user_aqua_bin="$HOME/.local/share/aquaproj-aqua/bin"
  local user_mise_data="$HOME/.local/share/mise"
  local user_mise_shims="$user_mise_data/shims"
  local user_home="$HOME"

  local env_marker_begin="# BEGIN managed by terminal-bootstrap (root-env)"
  local env_marker_end="# END managed by terminal-bootstrap (root-env)"
  local handoff_marker_begin="# BEGIN managed by terminal-bootstrap (root-handoff)"
  local handoff_marker_end="# END managed by terminal-bootstrap (root-handoff)"

  write_root_managed_block /root/.profile "$env_marker_begin" "$env_marker_end" "root-env block" <<EOF
$env_marker_begin
# Reuse $user_home Linuxbrew/aqua/mise environment. Sourced for all root
# login shells (interactive and non-interactive) so brew/aqua-managed CLIs
# resolve under sudo -i, ssh root@host, etc.
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
if [ -f "$user_config_dir/aquaproj-aqua/aqua.yaml" ]; then
  export AQUA_GLOBAL_CONFIG="$user_config_dir/aquaproj-aqua/aqua.yaml"
fi
if [ -d "$user_mise_data" ]; then
  export MISE_DATA_DIR="$user_mise_data"
fi
if [ -d "$user_aqua_bin" ]; then
  case ":\$PATH:" in
    *":$user_aqua_bin:"*) ;;
    *) export PATH="$user_aqua_bin:\$PATH" ;;
  esac
fi
if [ -d "$user_mise_shims" ]; then
  case ":\$PATH:" in
    *":$user_mise_shims:"*) ;;
    *) export PATH="$user_mise_shims:\$PATH" ;;
  esac
fi
$env_marker_end
EOF

  write_root_managed_block /root/.bashrc "$handoff_marker_begin" "$handoff_marker_end" "root-handoff block" <<EOF
$handoff_marker_begin
# Same env as /root/.profile, repeated here for non-login interactive shells
# (ubuntu .bashrc early-returns for non-interactive, so this also won't run
# in non-interactive non-login — by bash invocation rules).
if [ -d /home/linuxbrew/.linuxbrew ]; then
  eval "\$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
if [ -f "$user_config_dir/aquaproj-aqua/aqua.yaml" ]; then
  export AQUA_GLOBAL_CONFIG="$user_config_dir/aquaproj-aqua/aqua.yaml"
fi
if [ -d "$user_mise_data" ]; then
  export MISE_DATA_DIR="$user_mise_data"
fi
if [ -d "$user_aqua_bin" ]; then
  case ":\$PATH:" in
    *":$user_aqua_bin:"*) ;;
    *) export PATH="$user_aqua_bin:\$PATH" ;;
  esac
fi
if [ -d "$user_mise_shims" ]; then
  case ":\$PATH:" in
    *":$user_mise_shims:"*) ;;
    *) export PATH="$user_mise_shims:\$PATH" ;;
  esac
fi

# Hand off interactive root bash sessions to nu (same UX as the user).
# Emergency escape: TERMINAL_BOOTSTRAP_NO_HANDOFF=1 ssh root@host
if [[ \$- == *i* ]] && [ -z "\${TERMINAL_BOOTSTRAP_NO_HANDOFF:-}" ] && [ -z "\${TERMINAL_BOOTSTRAP_NU_HANDOFF:-}" ] && command -v nu >/dev/null 2>&1; then
  export TERMINAL_BOOTSTRAP_NU_HANDOFF=1
  exec nu -l
fi
$handoff_marker_end
EOF

  # /root/.config symlinks → invoking user's managed config (single source of truth)
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Create /root/.config and symlink to %s\n' "$user_config_dir"
  else
    run_as_root mkdir -p /root/.config

    local sub src target
    for sub in nushell nvim aquaproj-aqua mise; do
      src="$user_config_dir/$sub"
      target="/root/.config/$sub"
      if [ ! -d "$src" ]; then
        printf 'warn  source %s missing; skipping symlink for %s\n' "$src" "$sub" >&2
        continue
      fi
      if run_as_root test -L "$target" || run_as_root test -e "$target"; then
        printf 'skip  %s already exists\n' "$target"
      else
        run_as_root ln -s "$src" "$target"
        printf 'ok    Symlink %s -> %s\n' "$target" "$src"
      fi
    done

    # starship.toml lives at $user_config_dir/starship.toml (file, not dir)
    src="$user_config_dir/starship.toml"
    target="/root/.config/starship.toml"
    if [ ! -f "$src" ]; then
      printf 'warn  source %s missing; skipping starship symlink\n' "$src" >&2
    elif run_as_root test -L "$target" || run_as_root test -e "$target"; then
      printf 'skip  %s already exists\n' "$target"
    else
      run_as_root ln -s "$src" "$target"
      printf 'ok    Symlink %s -> %s\n' "$target" "$src"
    fi
  fi

  local mise_cmd
  mise_cmd="$(command -v mise 2>/dev/null || true)"
  local mise_config="$user_config_dir/mise/config.toml"
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Trust mise config for root with MISE_DATA_DIR=%s\n' "$user_mise_data"
  elif [[ -n "$mise_cmd" && -f "$mise_config" && -d "$user_mise_data" ]]; then
    if run_as_root env MISE_DATA_DIR="$user_mise_data" "$mise_cmd" trust "$mise_config"; then
      printf 'ok    Trusted mise config for root with MISE_DATA_DIR=%s\n' "$user_mise_data"
    else
      printf 'warn  mise trust for root failed; root runtimes may prompt on first use\n' >&2
    fi
  fi
}

nu_string_literal() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

resolve_starship_command() {
  if command -v aqua >/dev/null 2>&1; then
    local candidate
    candidate="$(aqua which starship 2>/dev/null | head -n 1 || true)"
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  command -v starship
}

write_starship_autoload() {
  local target="$1"
  local starship_command="$2"
  local starship_literal
  starship_literal="$(nu_string_literal "$starship_command")"

  {
    cat <<'NU_HEAD'
# managed by terminal-bootstrap
# terminal-bootstrap safe starship prompt
export-env {
NU_HEAD
    printf '  let starship_command = %s\n' "$starship_literal"
    cat <<'NU_TAIL'

  let run_starship_prompt = {|args|
    let result = try {
      run-external $starship_command "prompt" ...$args | complete
    } catch {
      { stdout: "", stderr: "", exit_code: 1 }
    }

    if $result.exit_code == 0 {
      $result.stdout
    } else {
      ""
    }
  }

  $env.STARSHIP_SHELL = "nu"
  $env.STARSHIP_SESSION_KEY = (random chars -l 16)
  $env.PROMPT_MULTILINE_INDICATOR = ""
  $env.PROMPT_INDICATOR = ""
  $env.PROMPT_INDICATOR_VI_INSERT = ""
  $env.PROMPT_INDICATOR_VI_NORMAL = ""
  $env.PROMPT_COMMAND_RIGHT = ""
  $env.config = (
    $env.config?
    | default {}
    | merge {
        render_right_prompt_on_last_line: false
      }
  )

  $env.PROMPT_COMMAND = {||
    let last_exit_code = try { ($env.LAST_EXIT_CODE? | default 0 | into int) } catch { 0 }
    if $last_exit_code in [130, 3221225786, -1073741510] {
      ""
    } else {
      let cmd_duration = ($env.CMD_DURATION_MS? | default 0 | into int)
      let terminal_width = try { (term size).columns } catch { 80 }
      let job_args = if (which "job list" | where type == built-in | is-not-empty) {
        ["--jobs", (job list | length)]
      } else {
        []
      }

      do $run_starship_prompt [
        "--cmd-duration"
        $cmd_duration
        $"--status=($last_exit_code)"
        "--terminal-width"
        $terminal_width
        ...$job_args
      ]
    }
  }
}
NU_TAIL
  } > "$target"
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
      write_starship_autoload "$autoload_root/starship.nu" "$(resolve_starship_command)"
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
elif [[ $HEADLESS -eq 1 ]]; then
  printf 'Mode: headless-linux\n'
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
  initialize_aqua_packages
  initialize_mise_runtimes
  initialize_nushell_autoload
  sync_nvim_config
fi

# Root wiring is on by default and independent of SKIP_CONFIGS. Three
# auth paths in order, mirroring the mac installer's dispatch model:
#   1. `sudo -n true` succeeds — cached or NOPASSWD, no prompt needed.
#   2. Interactive TTY present — `sudo -v` prompts for the password and
#      caches it so the many sudos inside persist_root_setup don't each
#      re-prompt.
#   3. Neither — warn and skip the whole step rather than fail the
#      install, so non-sudoer / non-TTY contexts still get a working
#      user-level setup. (Use --skip-root for explicit opt-out.)
if [[ $INCLUDE_ROOT -eq 1 ]]; then
  if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    printf 'skip  root wiring (installer is already running as root)\n'
    INCLUDE_ROOT=0
  elif ! command -v sudo >/dev/null 2>&1; then
    printf 'warn  sudo not available; skipping root wiring\n' >&2
    INCLUDE_ROOT=0
  elif [[ $DRY_RUN -eq 0 ]]; then
    if sudo -n true 2>/dev/null; then
      :  # NOPASSWD or cache already valid
    elif [[ -t 0 ]]; then
      if ! sudo -v; then
        printf 'warn  sudo authentication failed; skipping root wiring\n' >&2
        INCLUDE_ROOT=0
      fi
    else
      printf 'warn  no TTY and sudo requires a password; skipping root wiring\n' >&2
      INCLUDE_ROOT=0
    fi
  fi
fi

if [[ $INCLUDE_ROOT -eq 1 ]]; then
  persist_root_setup
fi

log_stage 8 "Verify"
if [[ "$TARGET" == "wsl" ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'Run bash ./linux/install.sh to apply the WSL baseline. Then on the Windows host, run the Windows installer so wezterm.lua registers the WSL Ubuntu domain, and pick "WSL Ubuntu (nu)" from the WezTerm launch menu (Ctrl+Shift+Space) to enter the WSL nu tab.\n'
  else
    printf 'On the Windows host, run the Windows installer to register the WSL Ubuntu domain in wezterm.lua, then pick "WSL Ubuntu (nu)" from the WezTerm launch menu (Ctrl+Shift+Space) to enter the WSL nu tab.\n'
  fi
elif [[ $HEADLESS -eq 1 ]]; then
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'Run bash ./linux/install.sh --headless to apply the SSH/server baseline, then open a new SSH session to verify the NuShell entrypoint.\n'
  else
    printf 'Open a new SSH session to verify the NuShell entrypoint.\n'
  fi
else
  if [[ $DRY_RUN -eq 1 ]]; then
    printf 'Run bash ./linux/install.sh to apply the baseline, then launch WezTerm to verify the NuShell entrypoint.\n'
  else
    printf 'Launch WezTerm to verify the NuShell entrypoint.\n'
  fi
fi
