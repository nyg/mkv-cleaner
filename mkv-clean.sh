#!/usr/bin/env sh
# mkv-clean.sh
# Convenience wrapper to launch the MKV cleaner agent.
# Usage: ./mkv-clean.sh [target-folder]

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
TARGET="${1:-$(pwd)}"

case "$TARGET" in /*) ;; *) TARGET="$(pwd)/$TARGET" ;; esac

if [ ! -d "$TARGET" ]; then
  echo "ERROR: not a folder: $TARGET" >&2
  exit 1
fi

for tool in mkvmerge ffprobe jq; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "ERROR: $tool not found." >&2
    echo "" >&2
    echo "Install it:" >&2
    echo "  brew install mkvtoolnix ffmpeg jq          # macOS" >&2
    echo "  sudo apt install mkvtoolnix ffmpeg jq      # Debian / Ubuntu" >&2
    exit 1
  fi
done

if ! command -v copilot >/dev/null 2>&1; then
  echo "ERROR: GitHub Copilot CLI not found." >&2
  echo "" >&2
  echo "Install it:" >&2
  echo "  curl -fsSL https://gh.io/copilot-install | bash" >&2
  echo "  # or: brew install copilot-cli" >&2
  exit 1
fi

cd "$SCRIPT_DIR"

PROMPT="Clean all MKV and M4V files in: $TARGET"

copilot \
  --prompt "$PROMPT" \
  --add-dir "$TARGET" \
  --allow-all
