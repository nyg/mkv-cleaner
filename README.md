# mkv-cleaner

An AI agent for cleaning MKV files using [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli).

The agent uses `ffprobe` to analyze each file, then constructs and runs an `mkvmerge` (or `ffmpeg`) command to strip unwanted streams — no re-encoding, just a fast lossless remux.

## What it does

- **Audio**: keeps only English tracks by default (configurable per-run); picks the highest quality one (TrueHD Atmos > DTS-HD MA > EAC3 > AC3 > AAC …). Commentary tracks are excluded unless keeping one is required to avoid having zero audio tracks in the selected language.
- **Subtitles**: keeps only English tracks (all variants: regular, forced, SDH)
- **Video**: untouched, never re-encoded
- **Chapters**: always preserved
- **Attachments**: removed (fonts, cover art, thumbnails)
- **Metadata**: statistics tags and encoding tool junk stripped
- **Input formats**: `.mkv` and `.m4v` — both are remuxed into MKV
- **Output naming**:
  - Movies: `Title.Year.mkv` in a `cleaned/` subfolder
  - Series episodes: `Series.Name.SxxExx.Episode.Name.mkv` (no year) in a `cleaned/` subfolder
- **Reports**: per-file markdown report with stream analysis and command details

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
./mkv-clean.sh /path/to/your/movies
```

**Or launch Copilot CLI directly from the repo root:**

```bash
cd /path/to/mkv-cleaner
copilot "clean all MKVs in /path/to/your/movies"
```

**Example prompts:**

```bash
copilot "clean Movie.mkv"
copilot "clean all MKVs and M4Vs in ~/Movies recursively"
copilot "clean all MKVs in ~/Movies/Series/Season1 recursively"
copilot "clean all MKVs here but keep French audio too"
```

## Output examples

| Input | Output |
|-------|--------|
| `Eden.2024.2160p.DV.HDR.HEVC.EAC3-NewTeam.mkv` | `cleaned/Eden.2024.mkv` |
| `Dexter S01E02 Crocodile 1080p BluRay x264-GROUP.mkv` | `cleaned/Dexter.S01E02.Crocodile.mkv` |
| `Breaking.Bad.S05E16.Felina.2160p.WEB-DL.mkv` | `cleaned/Breaking.Bad.S05E16.Felina.mkv` |
| `Movie.2019.m4v` | `cleaned/Movie.2019.mkv` |

## Repo structure

```
mkv-cleaner/
├── README.md
├── AGENTS.md              # Agent instructions — edit this to change behaviour
└── mkv-clean.sh           # Convenience launcher with scoped tool permissions
```

## Editing the prompt

Edit `AGENTS.md` directly — it is the single source of truth.
