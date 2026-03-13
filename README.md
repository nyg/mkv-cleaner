# mkv-cleaner

An AI agent configuration for cleaning MKV files using Claude Code or GitHub Copilot CLI.

The agent uses `ffprobe` to analyze each file, then constructs and runs an `mkvmerge` (or `ffmpeg`) command to strip unwanted streams — no re-encoding, just a fast lossless remux.

## What it does

- **Audio**: keeps only English tracks; if multiple English tracks exist, keeps the highest quality one (TrueHD > DTS-HD MA > DTS > EAC3 > AC3 > AAC …)
- **Subtitles**: keeps only English tracks (all variants: regular, forced, SDH)
- **Chapters**: always preserved
- **Attachments**: keeps fonts and cover art; removes others
- **Video**: untouched, never re-encoded

## Requirements

```bash
# macOS
brew install mkvtoolnix ffmpeg

# Ubuntu / Debian
sudo apt install mkvtoolnix ffmpeg

# Windows (WSL recommended, or use winget)
winget install MKVToolNix ffmpeg
```

You also need one of:

| Tool | Install |
|------|---------|
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` |
| **GitHub Copilot CLI** | `gh extension install github/gh-copilot` |

## Setup

```bash
git clone https://github.com/you/mkv-cleaner
cd mkv-cleaner
bash scripts/install-hooks.sh   # installs the pre-commit hook (one-time)
```

## Usage

**Navigate to your MKV folder and launch the agent:**

```bash
# With Claude Code — auto-loads CLAUDE.md as context
cd /path/to/your/movies
claude "clean all MKVs in this folder"

# With GitHub Copilot CLI
cd /path/to/your/movies
gh copilot suggest -t shell "clean all MKVs in this folder"

# Or use the convenience wrapper (auto-detects which tool is available)
bash /path/to/mkv-cleaner/scripts/mkv-clean.sh /path/to/your/movies
```

**Example prompts:**

```bash
claude "clean Movie.mkv"
claude "clean all MKVs in ~/Movies/Series/Season1 recursively"
claude "clean all MKVs here but keep French audio too"
```

## Repo structure

```
mkv-cleaner/
├── README.md
├── CLAUDE.md                          # Auto-generated — Claude Code reads this
├── AGENTS.md                          # Auto-generated — Copilot reads this
├── prompts/
│   └── mkv-cleaner.md                 # ← EDIT THIS to change agent behaviour
└── scripts/
    ├── sync-prompts.sh                # Manually sync prompt to derived files
    ├── install-hooks.sh               # Install the pre-commit hook (run once)
    ├── pre-commit.hook                # Hook source, tracked by git
    └── mkv-clean.sh                   # Convenience launcher
```

## Editing the prompt

**Only edit `prompts/mkv-cleaner.md`** — `CLAUDE.md` and `.AGENTS.md` are auto-generated and will be overwritten.

The pre-commit hook syncs them automatically when you commit:

```bash
vim prompts/mkv-cleaner.md
git add prompts/mkv-cleaner.md
git commit -m "tweak audio quality ranking"
# Hook fires → CLAUDE.md and AGENTS.md are updated and added to the commit
```

Or sync manually without committing:

```bash
bash scripts/sync-prompts.sh
```
