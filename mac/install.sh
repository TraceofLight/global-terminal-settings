#!/usr/bin/env bash
set -euo pipefail

SYNC_MODE="copy"
DRY_RUN=0
SKIP_PACKAGES=0
SKIP_CONFIGS=0
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
    --include-root)
      # Kept for backward compatibility — root wiring is on by default.
      INCLUDE_ROOT=1
      ;;
    --skip-root)
      INCLUDE_ROOT=0
      ;;
    --help|-h)
      cat <<'EOF'
Usage: ./install.sh [--dry-run] [--sync-mode auto|link|copy] [--skip-packages] [--skip-configs] [--skip-root]

  --skip-root     Disable the default root wiring. By default install.sh
                  also wires /var/root with the same Homebrew PATH,
                  aqua/mise env, nu shell handoff, and symlinks to the
                  invoking user's ~/.config/{nushell,nvim,aquaproj-aqua,
                  mise,starship.toml} — so `sudo -i` lands in the same
                  managed UX. Pass this flag on shared machines where the
                  invoking user is not (or should not be) a sudoer, or
                  when sudo isn't available.

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

BOOTSTRAP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCE_ROOT="$BOOTSTRAP_ROOT/shared"
CONFIG_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}"
INSTALL_ROOT="$CONFIG_ROOT/terminal-bootstrap"
DEFAULT_NUSHELL_ROOT="${XDG_CONFIG_HOME:-$HOME/.config}/nushell"
MACOS_NUSHELL_FALLBACK="$HOME/Library/Application Support/nushell"

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

link_macos_nushell_fallback() {
  # GUI-launched processes on macOS (JetBrains IDEs, Raycast, etc.) do not
  # inherit the XDG_CONFIG_HOME that the WezTerm entrypoint sets, so nu falls
  # back to ~/Library/Application Support/nushell and reads a stale snapshot.
  # Point that path at the managed nushell root so every GUI-launched nu
  # session resolves the same live config.
  local target="$MACOS_NUSHELL_FALLBACK"
  local source="$DEFAULT_NUSHELL_ROOT"

  ensure_dir "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      printf 'skip  %s already points to %s\n' "$target" "$source"
      return 0
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  run_cmd "Link $target -> $source" ln -s "$source" "$target"
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
  printf '%s\n' "$DEFAULT_NUSHELL_ROOT"
}

install_packages() {
  log_stage 2 "Core Packages"
  ensure_homebrew
  run_cmd "brew bundle --file $BOOTSTRAP_ROOT/mac/Brewfile" brew bundle --file "$BOOTSTRAP_ROOT/mac/Brewfile"
}

stage_assets() {
  log_stage 3 "Stage Managed Assets"

  sync_target "$SOURCE_ROOT/aqua" "$INSTALL_ROOT/aqua"
  sync_target "$SOURCE_ROOT/fonts" "$INSTALL_ROOT/fonts"
  sync_target "$SOURCE_ROOT/mise" "$INSTALL_ROOT/mise"
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

  link_macos_nushell_fallback

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
  $env.PROMPT_COMMAND_RIGHT = {|| "" }
  $env.config = (
    $env.config?
    | default {}
    | merge {
        render_right_prompt_on_last_line: false
      }
  )

  $env.PROMPT_COMMAND = {||
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
      $"--status=($env.LAST_EXIT_CODE)"
      "--terminal-width"
      $terminal_width
      ...$job_args
    ]
  }
}
NU_TAIL
  } > "$target"
}

initialize_nushell_autoload() {
  log_stage 6 "Starship, zoxide, fzf, carapace, claude, openclaude"
  local nushell_root
  nushell_root="$(get_nushell_root)"
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

resolve_brew_prefix() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    printf '/opt/homebrew\n'
  elif [[ -x /usr/local/bin/brew ]]; then
    printf '/usr/local\n'
  fi
}

persist_root_setup() {
  if ! command -v sudo >/dev/null 2>&1; then
    printf 'warn  sudo not available; cannot wire root\n' >&2
    return 0
  fi

  log_stage R "Root environment (wire /var/root)"

  local user_config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
  local user_aqua_bin="$HOME/.local/share/aquaproj-aqua/bin"
  local user_home="$HOME"
  local root_home="/var/root"
  local brew_prefix
  brew_prefix="$(resolve_brew_prefix)"
  if [[ -z "$brew_prefix" ]]; then
    printf 'warn  Homebrew not found; root env block will be inert\n' >&2
  fi

  local env_marker_begin="# BEGIN managed by terminal-bootstrap (root-env)"
  local env_marker_end="# END managed by terminal-bootstrap (root-env)"
  local handoff_marker_begin="# BEGIN managed by terminal-bootstrap (root-handoff)"
  local handoff_marker_end="# END managed by terminal-bootstrap (root-handoff)"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '[dry-run] Build root-side script and execute as root in one shot\n'
    printf '[dry-run]   target: %s/.zprofile (env block), %s/.zshrc (handoff)\n' "$root_home" "$root_home"
    printf '[dry-run]   symlinks: %s/.config/{nushell,nvim,aquaproj-aqua,mise,starship.toml} -> %s\n' "$root_home" "$user_config_dir"
    return 0
  fi

  # Build a single root-side script and execute it via one privileged
  # dispatch. This avoids per-command sudo prompts (and, on macOS, lets
  # us fall back to a single GUI password popup via osascript when no
  # TTY is available — e.g. when install.sh is invoked from CI, IDE
  # "run" buttons, or agent shells where sudo can't read a password).
  local root_script_file
  root_script_file=$(mktemp -t terminal-bootstrap-root)

  # Write the inner script with variables expanded by the outer shell.
  # Quoting model: the heredoc body is UNquoted so $variables here
  # interpolate now; the inner heredocs (EOF_ENV, EOF_HANDOFF) use
  # \$ for variables that must remain literal at root-run time.
  cat > "$root_script_file" <<INNER_SCRIPT
#!/bin/bash
set -e

ROOT_HOME='$root_home'
USER_HOME='$user_home'
USER_CONFIG_DIR='$user_config_dir'
USER_AQUA_BIN='$user_aqua_bin'
BREW_PREFIX='$brew_prefix'
ENV_MARKER_BEGIN='$env_marker_begin'
ENV_MARKER_END='$env_marker_end'
HANDOFF_MARKER_BEGIN='$handoff_marker_begin'
HANDOFF_MARKER_END='$handoff_marker_end'

# env block → /var/root/.zprofile
if grep -qF "\$ENV_MARKER_BEGIN" "\$ROOT_HOME/.zprofile" 2>/dev/null; then
  echo "skip  \$ROOT_HOME/.zprofile already has root-env block"
else
  cat >> "\$ROOT_HOME/.zprofile" <<EOF_ENV

\$ENV_MARKER_BEGIN
# Reuse \$USER_HOME Homebrew/aqua/mise environment. Sourced for all root
# login shells (interactive and non-interactive) so brew/aqua-managed CLIs
# resolve under sudo -i, ssh root@host, etc.
if [ -x "\$BREW_PREFIX/bin/brew" ]; then
  eval "\\\$(\$BREW_PREFIX/bin/brew shellenv)"
fi
if [ -f "\$USER_CONFIG_DIR/aquaproj-aqua/aqua.yaml" ]; then
  export AQUA_GLOBAL_CONFIG="\$USER_CONFIG_DIR/aquaproj-aqua/aqua.yaml"
fi
if [ -d "\$USER_AQUA_BIN" ]; then
  case ":\\\$PATH:" in
    *":\$USER_AQUA_BIN:"*) ;;
    *) export PATH="\$USER_AQUA_BIN:\\\$PATH" ;;
  esac
fi
\$ENV_MARKER_END
EOF_ENV
  echo "ok    Added root-env block to \$ROOT_HOME/.zprofile"
fi

# handoff block → /var/root/.zshrc
if grep -qF "\$HANDOFF_MARKER_BEGIN" "\$ROOT_HOME/.zshrc" 2>/dev/null; then
  echo "skip  \$ROOT_HOME/.zshrc already has root-handoff block"
else
  cat >> "\$ROOT_HOME/.zshrc" <<EOF_HANDOFF

\$HANDOFF_MARKER_BEGIN
# Same env as /var/root/.zprofile, repeated here for non-login interactive
# shells. zsh sources .zprofile only for login shells and .zshrc for
# interactive shells.
if [ -x "\$BREW_PREFIX/bin/brew" ]; then
  eval "\\\$(\$BREW_PREFIX/bin/brew shellenv)"
fi
if [ -f "\$USER_CONFIG_DIR/aquaproj-aqua/aqua.yaml" ]; then
  export AQUA_GLOBAL_CONFIG="\$USER_CONFIG_DIR/aquaproj-aqua/aqua.yaml"
fi
if [ -d "\$USER_AQUA_BIN" ]; then
  case ":\\\$PATH:" in
    *":\$USER_AQUA_BIN:"*) ;;
    *) export PATH="\$USER_AQUA_BIN:\\\$PATH" ;;
  esac
fi

# Hand off interactive root zsh sessions to nu (same UX as the user).
# Emergency escape: TERMINAL_BOOTSTRAP_NO_HANDOFF=1 sudo -i
if [[ -o interactive ]] && [ -z "\\\${TERMINAL_BOOTSTRAP_NO_HANDOFF:-}" ] && [ -z "\\\${TERMINAL_BOOTSTRAP_NU_HANDOFF:-}" ] && command -v nu >/dev/null 2>&1; then
  export TERMINAL_BOOTSTRAP_NU_HANDOFF=1
  exec nu -l
fi
\$HANDOFF_MARKER_END
EOF_HANDOFF
  echo "ok    Added root-handoff block to \$ROOT_HOME/.zshrc"
fi

# /var/root/.config symlinks → invoking user's managed config
mkdir -p "\$ROOT_HOME/.config"
for sub in nushell nvim aquaproj-aqua mise; do
  src="\$USER_CONFIG_DIR/\$sub"
  target="\$ROOT_HOME/.config/\$sub"
  if [ ! -d "\$src" ]; then
    echo "warn  source \$src missing; skipping symlink for \$sub" >&2
    continue
  fi
  if [ -L "\$target" ] || [ -e "\$target" ]; then
    echo "skip  \$target already exists"
  else
    ln -s "\$src" "\$target"
    echo "ok    Symlink \$target -> \$src"
  fi
done

src="\$USER_CONFIG_DIR/starship.toml"
target="\$ROOT_HOME/.config/starship.toml"
if [ ! -f "\$src" ]; then
  echo "warn  source \$src missing; skipping starship symlink" >&2
elif [ -L "\$target" ] || [ -e "\$target" ]; then
  echo "skip  \$target already exists"
else
  ln -s "\$src" "\$target"
  echo "ok    Symlink \$target -> \$src"
fi
INNER_SCRIPT

  chmod +x "$root_script_file"

  # Dispatch — prefer sudo (TTY or cached), fall back to osascript GUI
  # popup on macOS without TTY, otherwise warn and skip.
  if sudo -n true 2>/dev/null; then
    sudo bash "$root_script_file"
  elif [[ -t 0 ]]; then
    sudo bash "$root_script_file"
  elif command -v osascript >/dev/null 2>&1; then
    printf 'info  no TTY available; using macOS GUI password prompt for the root setup\n'
    if ! osascript -e "do shell script \"bash $root_script_file\" with administrator privileges" 2>/dev/null; then
      printf 'warn  GUI authentication failed or cancelled; root wiring skipped\n' >&2
    fi
  else
    printf 'warn  no TTY and no osascript; root wiring skipped\n' >&2
  fi

  rm -f "$root_script_file"
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
  initialize_aqua_packages
  initialize_mise_runtimes
  initialize_nushell_autoload
  sync_nvim_config
fi

# Root wiring is on by default. persist_root_setup builds a single
# root-side script and dispatches it once (sudo if cache/TTY, osascript
# GUI popup if no TTY on macOS), so there's no separate priming step.
if [[ $INCLUDE_ROOT -eq 1 ]]; then
  persist_root_setup
fi

log_stage 8 "Verify"
if [[ $DRY_RUN -eq 1 ]]; then
  printf 'Run bash ./mac/install.sh to apply the baseline, then launch WezTerm to verify the NuShell entrypoint.\n'
else
  printf 'Launch WezTerm to verify the NuShell entrypoint.\n'
fi
