#!/usr/bin/env sh
# mkv-clean.sh
# Convenience wrapper to launch the MKV cleaner agent.
# Usage: ./mkv-clean.sh [--harness copilot|claude|codex|opencode] [--model <model>]
#          [--lang <code>[,<code>…]] [--audio-lang <code>[,<code>…]] [--sub-lang <code>[,<code>…]] [target-folder]

set -eu

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
HARNESS=""
MODEL=""
TARGET_LANG=""
AUDIO_LANG=""
SUB_LANG=""
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
    --lang)
      [ $# -ge 2 ] || { echo "ERROR: --lang needs a value." >&2; exit 1; }
      TARGET_LANG="$2"
      shift 2
      ;;
    --lang=*)
      TARGET_LANG="${1#--lang=}"
      shift
      ;;
    --audio-lang)
      [ $# -ge 2 ] || { echo "ERROR: --audio-lang needs a value." >&2; exit 1; }
      AUDIO_LANG="$2"
      shift 2
      ;;
    --audio-lang=*)
      AUDIO_LANG="${1#--audio-lang=}"
      shift
      ;;
    --sub-lang|--subtitle-lang)
      [ $# -ge 2 ] || { echo "ERROR: $1 needs a value." >&2; exit 1; }
      SUB_LANG="$2"
      shift 2
      ;;
    --sub-lang=*)
      SUB_LANG="${1#--sub-lang=}"
      shift
      ;;
    --subtitle-lang=*)
      SUB_LANG="${1#--subtitle-lang=}"
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

[ -n "$AUDIO_LANG" ] || AUDIO_LANG="$TARGET_LANG"
[ -n "$SUB_LANG" ] || SUB_LANG="$TARGET_LANG"
[ -n "$AUDIO_LANG" ] || AUDIO_LANG="eng"
[ -n "$SUB_LANG" ] || SUB_LANG="eng"

if [ "$AUDIO_LANG" != eng ] || [ "$SUB_LANG" != eng ]; then
  PROMPT="$PROMPT
The target language for audio is $AUDIO_LANG and the target language for subtitles is $SUB_LANG. These two are set separately and may differ, so never let one decide the other.
For audio, apply the usual audio rules to the $AUDIO_LANG tracks and drop every other language.
For subtitles, keep the $SUB_LANG tracks and drop every other language."
fi

if [ -z "$MODEL" ] && [ "$HARNESS" = claude ]; then
  MODEL="$CLAUDE_DEFAULT_MODEL"
fi

echo "Harness: $HARNESS"
echo "Model:   ${MODEL:-<harness default>}"
echo "Audio:   $AUDIO_LANG"
echo "Subs:    $SUB_LANG"
echo "Target:  $TARGET"

RUN_LOG=$(mktemp "${TMPDIR:-/tmp}/mkv-clean.XXXXXX")
trap 'rm -f "$RUN_LOG"' EXIT INT TERM

STARTED_AT=$(date +%s)

case "$HARNESS" in
  copilot)
    if [ -n "$MODEL" ]; then
      copilot --prompt "$PROMPT" --add-dir "$TARGET" --allow-all --model "$MODEL" | tee "$RUN_LOG"
    else
      copilot --prompt "$PROMPT" --add-dir "$TARGET" --allow-all | tee "$RUN_LOG"
    fi
    ;;
  claude)
    claude --print "$PROMPT" --add-dir "$TARGET" --dangerously-skip-permissions \
      --model "$MODEL" --effort "$CLAUDE_DEFAULT_EFFORT" \
      --output-format stream-json --verbose \
      | tee "$RUN_LOG" \
      | jq -j --unbuffered '
          select(.type == "assistant") | .message.content[]? |
          if .type == "text" then .text + "\n"
          elif .type == "tool_use" then
            "· " + .name +
            (if (.input.command? | type) == "string" then ": " + (.input.command | split("\n")[0]) else "" end) +
            "\n"
          else empty end'
    ;;
  codex)
    if [ -n "$MODEL" ]; then
      codex exec --cd "$TARGET" --sandbox workspace-write --skip-git-repo-check --model "$MODEL" "$PROMPT" | tee "$RUN_LOG"
    else
      codex exec --cd "$TARGET" --sandbox workspace-write --skip-git-repo-check "$PROMPT" | tee "$RUN_LOG"
    fi
    ;;
  opencode)
    if [ -n "$MODEL" ]; then
      opencode run --dir "$TARGET" --auto --model "$MODEL" "$PROMPT" | tee "$RUN_LOG"
    else
      opencode run --dir "$TARGET" --auto "$PROMPT" | tee "$RUN_LOG"
    fi
    ;;
esac

ELAPSED=$(( $(date +%s) - STARTED_AT ))

echo ""
echo "--- Run summary ---"
echo "Harness:  $HARNESS"

CLAUDE_RESULT=""
if [ "$HARNESS" = claude ]; then
  CLAUDE_RESULT=$(jq -c 'select(.type == "result")' "$RUN_LOG" 2>/dev/null | tail -n 1)
fi

if [ -n "$CLAUDE_RESULT" ]; then
  printf '%s' "$CLAUDE_RESULT" | jq -r '
    (.modelUsage // {}) as $usage |
    ([$usage | keys[]] | join(", ")) as $models |
    def total(f): ([$usage[] | f] | add) // 0;
    "Model:    " + (if $models == "" then "unknown" else $models end),
    "Input:    " + (total(.inputTokens) | tostring) + " tokens",
    "Output:   " + (total(.outputTokens) | tostring) + " tokens",
    "Cache:    " + (total(.cacheCreationInputTokens) | tostring) + " written, "
                 + (total(.cacheReadInputTokens) | tostring) + " read",
    "Cost:     $" + ((.total_cost_usd // 0) * 10000 | round / 10000 | tostring),
    (if .session_id then "Resume:   claude --resume " + .session_id else empty end)'
else
  echo "Model:    ${MODEL:-<harness default>} (requested)"
  TOKEN_LINES=$(grep -iE 'tokens? (used|usage)|total tokens|token count' "$RUN_LOG" 2>/dev/null | tail -n 3 || true)
  if [ -n "$TOKEN_LINES" ]; then
    echo "Tokens:"
    printf '%s\n' "$TOKEN_LINES" | sed 's/^/  /'
  elif [ "$HARNESS" = claude ]; then
    echo "Tokens:   unavailable, the run ended without a result event"
  else
    echo "Tokens:   not reported by $HARNESS"
  fi
fi

echo "Duration: ${ELAPSED}s"
