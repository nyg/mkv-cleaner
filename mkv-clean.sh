#!/usr/bin/env sh
# mkv-clean.sh
# Convenience wrapper to launch the MKV cleaner agent.
# Usage: ./mkv-clean.sh [--harness copilot|claude|codex|opencode] [--model <model>] [target-folder]

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
HARNESS=""
MODEL=""
CLAUDE_DEFAULT_MODEL="claude-sonnet-5"
CLAUDE_DEFAULT_EFFORT="high"

while [ $# -gt 0 ]; do
  case "$1" in
    --harness)
      [ $# -ge 2 ] || { echo "ERROR: --harness needs a value." >&2; exit 1; }
      HARNESS="$2"
      shift 2
      ;;
    --harness=*)
      HARNESS="${1#--harness=}"
      shift
      ;;
    --model)
      [ $# -ge 2 ] || { echo "ERROR: --model needs a value." >&2; exit 1; }
      MODEL="$2"
      shift 2
      ;;
    --model=*)
      MODEL="${1#--model=}"
      shift
      ;;
    *)
      break
      ;;
  esac
done

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

if [ -n "$HARNESS" ]; then
  case "$HARNESS" in
    copilot|claude|codex|opencode) ;;
    *)
      echo "ERROR: unknown harness: $HARNESS" >&2
      echo "Pick one of: copilot, claude, codex, opencode" >&2
      exit 1
      ;;
  esac
  if ! command -v "$HARNESS" >/dev/null 2>&1; then
    echo "ERROR: $HARNESS not found on PATH." >&2
    exit 1
  fi
else
  for candidate in copilot claude codex opencode; do
    if command -v "$candidate" >/dev/null 2>&1; then
      HARNESS="$candidate"
      break
    fi
  done
fi

if [ -z "$HARNESS" ]; then
  echo "ERROR: no supported agent CLI found." >&2
  echo "" >&2
  echo "Install one of:" >&2
  echo "  Claude Code       https://claude.ai/code" >&2
  echo "  Codex             https://developers.openai.com/codex" >&2
  echo "  Copilot CLI       curl -fsSL https://gh.io/copilot-install | bash" >&2
  echo "  OpenCode          https://opencode.ai" >&2
  exit 1
fi

cd "$SCRIPT_DIR"

PROMPT="Use the mkv-cleaner skill. Clean all MKV and M4V files in: $TARGET"

if [ -z "$MODEL" ] && [ "$HARNESS" = claude ]; then
  MODEL="$CLAUDE_DEFAULT_MODEL"
fi

echo "Harness: $HARNESS"
echo "Model:   ${MODEL:-<harness default>}"
echo "Target:  $TARGET"

case "$HARNESS" in
  copilot)
    if [ -n "$MODEL" ]; then
      copilot --prompt "$PROMPT" --add-dir "$TARGET" --allow-all --model "$MODEL"
    else
      copilot --prompt "$PROMPT" --add-dir "$TARGET" --allow-all
    fi
    ;;
  claude)
    claude --print "$PROMPT" --add-dir "$TARGET" --dangerously-skip-permissions \
      --model "$MODEL" --effort "$CLAUDE_DEFAULT_EFFORT"
    ;;
  codex)
    if [ -n "$MODEL" ]; then
      codex exec --cd "$TARGET" --sandbox workspace-write --skip-git-repo-check --model "$MODEL" "$PROMPT"
    else
      codex exec --cd "$TARGET" --sandbox workspace-write --skip-git-repo-check "$PROMPT"
    fi
    ;;
  opencode)
    if [ -n "$MODEL" ]; then
      opencode run --dir "$TARGET" --auto --model "$MODEL" "$PROMPT"
    else
      opencode run --dir "$TARGET" --auto "$PROMPT"
    fi
    ;;
esac
