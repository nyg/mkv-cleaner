#!/usr/bin/env bash
# scripts/mkv-clean.sh
# Convenience wrapper to launch the MKV cleaner agent.
# Usage: bash /path/to/scripts/mkv-clean.sh [target-folder]
#
# The script auto-detects which CLI tool is available (claude or gh copilot).

set -euo pipefail

TARGET="${1:-$(pwd)}"
PROMPT="Clean all MKV files in: $TARGET
- Remove any audio track that is not English
- If multiple English audio tracks exist, keep only the highest quality one
- Keep only English subtitles
- Preserve all chapter information
- Keep font and cover art attachments, remove others
- Never re-encode, copy streams only
- Output cleaned files as <name>.clean.mkv alongside originals"

if command -v claude &>/dev/null; then
  echo "Using Claude Code..."
  claude "$PROMPT"
elif command -v gh &>/dev/null && gh extension list 2>/dev/null | grep -q copilot; then
  echo "Using GitHub Copilot CLI..."
  gh copilot suggest -t shell "$PROMPT"
else
  echo "ERROR: No supported AI CLI found." >&2
  echo "" >&2
  echo "Install one of:" >&2
  echo "  Claude Code:        npm install -g @anthropic-ai/claude-code" >&2
  echo "  GitHub Copilot CLI: gh extension install github/gh-copilot" >&2
  exit 1
fi
