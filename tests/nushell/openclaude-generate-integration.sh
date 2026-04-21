#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$REPO_ROOT/shared/nushell/generate_externs.py" --command openclaude --output /tmp/openclaude-integration-from-generator.nu
nu -n "$REPO_ROOT/tests/nushell/openclaude-generate-integration.nu"
