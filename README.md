# mkv-cleaner

An AI agent for cleaning MKV files using [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli) (also compatible with Claude Code).

The agent uses `ffprobe` to analyze each file, then constructs and runs an `mkvmerge` (or `ffmpeg`) command to strip unwanted streams — no re-encoding, just a fast lossless remux.

## What it does

- **Audio**: keeps only English tracks by default (configurable per-run); picks the highest quality one (TrueHD Atmos > DTS-HD MA > EAC3 > AC3 > AAC …)
- **Subtitles**: keeps only English tracks (all variants: regular, forced, SDH)
- **Video**: untouched, never re-encoded
- **Chapters**: always preserved
- **Attachments**: removed (fonts, cover art, thumbnails)
- **Metadata**: statistics tags and encoding tool junk stripped
- **Output naming**: cleaned filenames (`Title.Year.mkv`) in a `cleaned/` subfolder

## Requirements

```bash
# macOS
brew install mkvtoolnix ffmpeg

# Ubuntu / Debian
sudo apt install mkvtoolnix ffmpeg
```

You also need [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli):

```bash
# macOS / Linux
curl -fsSL https://gh.io/copilot-install | bash

# or with Homebrew
brew install copilot-cli
```

## Usage

**Use the convenience script:**

```bash
bash /path/to/mkv-cleaner/scripts/mkv-clean.sh /path/to/your/movies
```

**Or launch Copilot CLI directly from the repo root:**

```bash
cd /path/to/mkv-cleaner
copilot "clean all MKVs in /path/to/your/movies"
```

**Example prompts:**

```bash
copilot "clean Movie.mkv"
copilot "clean all MKVs in ~/Movies/Series/Season1 recursively"
copilot "clean all MKVs here but keep French audio too"
```

## Repo structure

```
mkv-cleaner/
├── README.md
├── AGENTS.md              # Agent instructions — edit this to change behaviour
└── scripts/
    └── mkv-clean.sh       # Convenience launcher with scoped tool permissions
```

## Editing the prompt

Edit `AGENTS.md` directly — it is the single source of truth. Both Copilot CLI and Claude Code read it natively.
