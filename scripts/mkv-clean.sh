#!/usr/bin/env bash
# scripts/mkv-clean.sh
# Convenience wrapper to launch the MKV cleaner agent.
# Usage: bash /path/to/scripts/mkv-clean.sh [target-folder]

set -euo pipefail

TARGET="${1:-$(pwd)}"
PROMPT="Clean all MKV files in: $TARGET"

if ! command -v copilot &>/dev/null; then
  echo "ERROR: GitHub Copilot CLI not found." >&2
  echo "" >&2
  echo "Install it:" >&2
  echo "  curl -fsSL https://gh.io/copilot-install | bash" >&2
  echo "  # or: brew install copilot-cli" >&2
  exit 1
fi

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
