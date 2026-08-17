#!/usr/bin/env sh
# install.sh
# Makes the mkv-cleaner skill available to every agent harness, from any folder.
# Usage: ./install.sh [--uninstall]

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)
SKILL_DIR="$SCRIPT_DIR/skills/mkv-cleaner"

if [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "ERROR: not found: $SKILL_DIR/SKILL.md" >&2
  exit 1
fi

TARGETS="$HOME/.agents/skills $HOME/.claude/skills"

uninstall() {
  for dir in $TARGETS; do
    link="$dir/mkv-cleaner"
    if [ ! -L "$link" ]; then
      if [ -e "$link" ]; then
        echo "skipped  $link (not a symlink)"
      else
        echo "absent   $link"
      fi
      continue
    fi
    if [ "$(CDPATH='' cd -- "$link" 2>/dev/null && pwd -P)" = "$SKILL_DIR" ]; then
      rm "$link"
      echo "removed  $link"
    else
      echo "skipped  $link (points outside this checkout)"
    fi
  done
}

if [ "${1:-}" = "--uninstall" ]; then
  uninstall
  exit 0
fi

for dir in $TARGETS; do
  link="$dir/mkv-cleaner"
  mkdir -p "$dir"
  if [ -e "$link" ] && [ ! -L "$link" ]; then
    echo "ERROR: $link exists and is not a symlink. Move it away and re-run." >&2
    exit 1
  fi
  ln -sfn "$SKILL_DIR" "$link"
  echo "linked   $link -> $SKILL_DIR"
done

echo ""
echo "Installed. Skill discovery per harness:"
echo "  ~/.agents/skills   Codex, GitHub Copilot CLI, OpenCode"
echo "  ~/.claude/skills   Claude Code, OpenCode"
echo ""
echo "Try it:  ./mkv-clean.sh /path/to/your/movies"

for tool in mkvmerge ffprobe jq; do
  command -v "$tool" >/dev/null 2>&1 || {
    echo ""
    echo "WARNING: $tool is not on PATH. Install it before cleaning:"
    echo "  brew install mkvtoolnix ffmpeg jq          # macOS"
    echo "  sudo apt install mkvtoolnix ffmpeg jq      # Debian / Ubuntu"
    break
  }
done
