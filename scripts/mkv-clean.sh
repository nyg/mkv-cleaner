#!/usr/bin/env bash
# scripts/mkv-clean.sh
# Convenience wrapper to launch the MKV cleaner agent.
# Usage: bash /path/to/scripts/mkv-clean.sh [target-folder]

set -euo pipefail

TARGET="${1:-$(pwd)}"
PROMPT="Clean all MKV files in: $TARGET"

if command -v copilot &>/dev/null; then
  echo "Using GitHub Copilot CLI..."
  copilot -p "$PROMPT" \
    --add-dir "$TARGET" \
    --allow-tool='shell(ffprobe:*)' \
    --allow-tool='shell(mkvmerge:*)' \
    --allow-tool='shell(ffmpeg:*)' \
    --allow-tool='shell(command:*)' \
    --allow-tool='shell(ls:*)' \
    --allow-tool='shell(mkdir:*)' \
    --allow-tool='read' \
    --allow-tool='write'
elif command -v claude &>/dev/null; then
  echo "Using Claude Code..."
  claude "$PROMPT"
else
  echo "ERROR: No supported AI CLI found." >&2
  echo "" >&2
  echo "Install one of:" >&2
  echo "  GitHub Copilot CLI: https://docs.github.com/copilot/how-tos/copilot-cli" >&2
  echo "  Claude Code:        npm install -g @anthropic-ai/claude-code" >&2
  exit 1
fi
