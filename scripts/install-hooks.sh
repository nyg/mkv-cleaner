#!/usr/bin/env bash
# scripts/install-hooks.sh
# Run once after cloning to install the pre-commit hook.
# Usage: bash scripts/install-hooks.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/.git/hooks"
HOOK_SOURCE="$REPO_ROOT/scripts/pre-commit.hook"
HOOK_DEST="$HOOKS_DIR/pre-commit"

if [[ ! -d "$HOOKS_DIR" ]]; then
  echo "ERROR: .git/hooks not found. Are you in a git repo?" >&2
  exit 1
fi

cp "$HOOK_SOURCE" "$HOOK_DEST"
chmod +x "$HOOK_DEST"
echo "✓ pre-commit hook installed at $HOOK_DEST"
echo ""
echo "The hook will auto-sync CLAUDE.md and AGENTS.md"
echo "whenever you commit changes to prompts/mkv-cleaner.md."
