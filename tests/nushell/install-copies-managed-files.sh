#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

NUSHELL_ROOT="$TEST_ROOT/nushell"
AUTOLOAD_ROOT="$NUSHELL_ROOT/autoload"
INSTALL_ROOT="$TEST_ROOT/.config/terminal-bootstrap"
mkdir -p "$AUTOLOAD_ROOT" "$INSTALL_ROOT/nushell/autoload"

cp "$REPO_ROOT/shared/nushell/config.nu" "$INSTALL_ROOT/nushell/config.nu"
cp "$REPO_ROOT/shared/nushell/env.nu" "$INSTALL_ROOT/nushell/env.nu"
cp "$REPO_ROOT/shared/nushell/login.nu" "$INSTALL_ROOT/nushell/login.nu"
cp "$REPO_ROOT/shared/nushell/autoload/wezterm-integration.nu" "$INSTALL_ROOT/nushell/autoload/wezterm-integration.nu"
cp "$REPO_ROOT/shared/nushell/autoload/openclaude-integration.nu" "$INSTALL_ROOT/nushell/autoload/openclaude-integration.nu"

copy_managed_file() {
  local source="$1"
  local target="$2"

  mkdir -p "$(dirname "$target")"

  if [[ -L "$target" || -e "$target" ]]; then
    rm -rf "$target"
  fi

  cp "$source" "$target"
}

copy_managed_file "$INSTALL_ROOT/nushell/config.nu" "$NUSHELL_ROOT/config.nu"
copy_managed_file "$INSTALL_ROOT/nushell/env.nu" "$NUSHELL_ROOT/env.nu"
copy_managed_file "$INSTALL_ROOT/nushell/login.nu" "$NUSHELL_ROOT/login.nu"
copy_managed_file "$INSTALL_ROOT/nushell/autoload/wezterm-integration.nu" "$AUTOLOAD_ROOT/wezterm-integration.nu"
copy_managed_file "$INSTALL_ROOT/nushell/autoload/openclaude-integration.nu" "$AUTOLOAD_ROOT/openclaude-integration.nu"

for path in \
  "$NUSHELL_ROOT/config.nu" \
  "$NUSHELL_ROOT/env.nu" \
  "$NUSHELL_ROOT/login.nu" \
  "$AUTOLOAD_ROOT/wezterm-integration.nu" \
  "$AUTOLOAD_ROOT/openclaude-integration.nu"
do
  [[ -f "$path" ]]
  [[ ! -L "$path" ]]
done

cmp "$INSTALL_ROOT/nushell/config.nu" "$NUSHELL_ROOT/config.nu"
cmp "$INSTALL_ROOT/nushell/env.nu" "$NUSHELL_ROOT/env.nu"
cmp "$INSTALL_ROOT/nushell/login.nu" "$NUSHELL_ROOT/login.nu"
cmp "$INSTALL_ROOT/nushell/autoload/wezterm-integration.nu" "$AUTOLOAD_ROOT/wezterm-integration.nu"
cmp "$INSTALL_ROOT/nushell/autoload/openclaude-integration.nu" "$AUTOLOAD_ROOT/openclaude-integration.nu"
