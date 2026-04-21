#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

NUSHELL_ROOT="$TEST_ROOT/nushell"
AUTOLOAD_ROOT="$NUSHELL_ROOT/autoload"
mkdir -p "$AUTOLOAD_ROOT"

cp "$REPO_ROOT/shared/nushell/config.nu" "$NUSHELL_ROOT/config.nu"
cp "$REPO_ROOT/shared/nushell/autoload/wezterm-integration.nu" "$AUTOLOAD_ROOT/wezterm-integration.nu"
printf '%s\n' '# test placeholder' > "$AUTOLOAD_ROOT/starship.nu"
printf '%s\n' '# test placeholder' > "$AUTOLOAD_ROOT/zoxide.nu"

XDG_CONFIG_HOME="$TEST_ROOT" nu -n "$REPO_ROOT/tests/nushell/config-missing-autoloads.nu"

[[ ! -e "$AUTOLOAD_ROOT/user-overrides.nu" ]]
