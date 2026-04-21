#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cp "$REPO_ROOT/shared/nushell/autoload/claude-integration.nu" /tmp/claude-integration-generated.nu
nu -n "$REPO_ROOT/tests/nushell/claude-generated-options.nu"
