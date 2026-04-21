#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

NUSHELL_ROOT="$TEST_ROOT/nushell"
AUTOLOAD_ROOT="$NUSHELL_ROOT/autoload"
mkdir -p "$AUTOLOAD_ROOT"

cp "$REPO_ROOT/shared/nushell/autoload/claude-integration.nu" "$AUTOLOAD_ROOT/claude-integration.nu"
XDG_CONFIG_HOME="$TEST_ROOT" PATH="/opt/homebrew/bin:$PATH" nu -n "$REPO_ROOT/tests/nushell/claude-extern-registration.nu"
