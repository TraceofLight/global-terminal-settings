#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$REPO_ROOT/shared/nushell/generate_externs.py" --command claude --output /tmp/claude-integration-from-generator.nu
nu -n "$REPO_ROOT/tests/nushell/claude-generated-types.nu"
