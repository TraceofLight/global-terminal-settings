#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

LEGACY_ROOT="$TEST_ROOT/AppData/Roaming/nushell"
CANONICAL_ROOT="$TEST_ROOT/.config/nushell"
mkdir -p "$LEGACY_ROOT" "$CANONICAL_ROOT"
printf '%s\n' 'legacy' > "$LEGACY_ROOT/config.nu"

backup_target() {
  local target="$1"
  [[ -e "$target" ]] || return 0
  mv "$target" "$target.pre-terminal-bootstrap-test"
}

backup_legacy_nushell_config_root() {
  local legacy_root="$1"
  local canonical_root="$2"

  [[ -n "$legacy_root" && -n "$canonical_root" ]]
  [[ "$legacy_root" != "$canonical_root" ]]
  [[ -e "$legacy_root" ]] || return 0

  backup_target "$legacy_root"
}

backup_legacy_nushell_config_root "$LEGACY_ROOT" "$CANONICAL_ROOT"

[[ ! -e "$LEGACY_ROOT" ]]
[[ -e "$LEGACY_ROOT.pre-terminal-bootstrap-test" ]]
