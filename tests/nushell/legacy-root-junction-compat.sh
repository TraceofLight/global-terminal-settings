#!/usr/bin/env bash
set -euo pipefail

TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

CANONICAL_ROOT="$TEST_ROOT/.config/nushell"
LEGACY_ROOT="$TEST_ROOT/AppData/Roaming/nushell"
mkdir -p "$CANONICAL_ROOT"

ln -s "$CANONICAL_ROOT" "$LEGACY_ROOT"

[[ -L "$LEGACY_ROOT" ]]
[[ "$(readlink "$LEGACY_ROOT")" = "$CANONICAL_ROOT" ]]
