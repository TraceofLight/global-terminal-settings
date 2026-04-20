#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
python3 "$REPO_ROOT/shared/nushell/generate_openclaude_integration.py" --output /tmp/openclaude-integration-from-generator.nu
nu -n "$REPO_ROOT/tests/nushell/openclaude-generated-types.nu"
