#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

AUTOLOAD_ROOT="$TEST_ROOT/nushell/autoload"
mkdir -p "$AUTOLOAD_ROOT"

backup_target() {
  local target="$1"
  [[ -e "$target" ]] || return 0
  mv "$target" "$target.pre-terminal-bootstrap-test"
}

remove_legacy_nu_autoload_artifacts() {
  local autoload_root="$1"
  local legacy_target="$autoload_root/openclaude-completions.nu"
  [[ -e "$legacy_target" ]] || return 0
  backup_target "$legacy_target"
}

legacy_file="$AUTOLOAD_ROOT/openclaude-completions.nu"
printf '%s\n' '# legacy placeholder' > "$legacy_file"

remove_legacy_nu_autoload_artifacts "$AUTOLOAD_ROOT"

[[ ! -e "$legacy_file" ]]
[[ -f "$legacy_file.pre-terminal-bootstrap-test" ]]
