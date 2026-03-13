#!/usr/bin/env bash
# scripts/mkv-clean.sh
# Convenience wrapper to launch the MKV cleaner agent.
# Usage: bash /path/to/scripts/mkv-clean.sh [target-folder]
#
# The script auto-detects which CLI tool is available (claude or gh copilot).

set -euo pipefail

TARGET="${1:-$(pwd)}"
PROMPT="Clean all MKV files in: $TARGET"

if command -v claude &>/dev/null; then
  echo "Using Claude Code..."
  claude "$PROMPT"
elif command -v copilot &>/dev/null; then
  echo "Using GitHub Copilot CLI..."
#   copilot -p "$PROMPT" --allow-all-tools --add-dir "$TARGET"
  copilot -p "$PROMPT" --add-dir "$TARGET"
else
  echo "ERROR: No supported AI CLI found." >&2
  echo "" >&2
  echo "Install one of:" >&2
  echo "  Claude Code:        npm install -g @anthropic-ai/claude-code" >&2
  echo "  GitHub Copilot CLI: gh extension install github/gh-copilot" >&2
  exit 1
fi
