#!/usr/bin/env bash
# onboard.sh - Interactive onboarding for ubuntu-nix-config
# Uses Python TUI if available, otherwise falls back to bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Try Python TUI first (better experience)
if command -v python3 &>/dev/null && [ -f "$SCRIPT_DIR/onboard-tui.py" ]; then
    exec python3 "$SCRIPT_DIR/onboard-tui.py" "$@"
fi

# Fall back to bash version
exec "$SCRIPT_DIR/onboard-simple.sh" "$@"
