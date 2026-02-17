#!/usr/bin/env bash
# start-docs.sh - Start the Just Enough Nix documentation server

PORT="${DOCS_PORT:-8080}"
DOCS_DIR="${DOCS_DIR:-$(dirname $(dirname $0))/docs}"

echo "Starting Just Enough Nix documentation server..."
echo "  Port: $PORT"
echo "  Directory: $DOCS_DIR"
echo ""
echo "Access via:"
echo "  Local:   http://localhost:$PORT"
echo "  Tailscale: http://$(hostname -s | tr '[:upper:]' '[:lower:]'):$PORT"
echo ""
echo "Press Ctrl+C to stop"
echo "---"

cd "$DOCS_DIR" || exit 1
python3 -m http.server "$PORT"
