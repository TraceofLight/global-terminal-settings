#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cp "$REPO_ROOT/shared/nushell/autoload/openclaude-integration.nu" /tmp/openclaude-integration-generated.nu
nu -n "$REPO_ROOT/tests/nushell/openclaude-generated-options.nu"
