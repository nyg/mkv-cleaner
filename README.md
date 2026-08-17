# mkv-cleaner

An AI agent for cleaning MKV files. It runs in Claude Code, Codex, GitHub Copilot CLI and OpenCode from the same instruction file.

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
brew install mkvtoolnix ffmpeg jq

# Ubuntu / Debian
sudo apt install mkvtoolnix ffmpeg jq
```

Plus one agent CLI: [Claude Code](https://claude.ai/code), [Codex](https://developers.openai.com/codex), [GitHub Copilot CLI](https://docs.github.com/copilot/how-tos/copilot-cli) or [OpenCode](https://opencode.ai).

## Install

### Any harness, from any folder

```bash
git clone https://github.com/nyg/mkv-cleaner && ./mkv-cleaner/install.sh
```

Symlinks the skill into `~/.agents/skills/` (Codex, Copilot CLI, OpenCode) and `~/.claude/skills/` (Claude Code, OpenCode). Undo with `./install.sh --uninstall`.

### Claude Code

Two separate prompts, in the CLI or the Desktop app's Code tab:

```
/plugin marketplace add nyg/mkv-cleaner
```
```
/plugin install mkv-cleaner@mkv-cleaner
```

Then `/mkv-cleaner:mkv-cleaner clean all MKVs in ~/Movies`.

### Codex

```bash
codex plugin marketplace add nyg/mkv-cleaner
codex plugin add mkv-cleaner@mkv-cleaner
```

### GitHub Copilot CLI

```bash
copilot plugin marketplace add nyg/mkv-cleaner
copilot plugin install mkv-cleaner@mkv-cleaner
```

The slash equivalents (`/plugin marketplace add …`, `/plugin install …`) work inside an interactive session.

### OpenCode

OpenCode has no plugin needed — `install.sh` above puts the skill where it already looks. Then:

```bash
opencode run --dir ~/Movies --auto "clean all MKVs here"
```

### No install at all

Every harness in the list also reads skills straight out of a checkout:

```bash
git clone https://github.com/nyg/mkv-cleaner && cd mkv-cleaner
copilot   # or claude, codex, opencode
```

## Usage

**Use the convenience script:**

```bash
./mkv-clean.sh /path/to/your/movies
```

It picks the first agent CLI it finds on your PATH; force one with `--harness claude|codex|copilot|opencode`.

Pick a model with `--model <model>`. Claude Code defaults to `claude-sonnet-5` at high reasoning effort; the other harnesses use their own default model unless you pass `--model`.

```bash
./mkv-clean.sh --harness claude --model claude-opus-5 /path/to/your/movies
```

Keep another language than English with `--lang <code>`, comma-separated for several. It replaces English as the target language for both audio and subtitles; two- and three-letter codes both work.

```bash
./mkv-clean.sh --lang fr /path/to/your/movies
./mkv-clean.sh --lang jpn,eng /path/to/your/movies
```

Audio and subtitles can target different languages: `--audio-lang <code>` and `--sub-lang <code>` (alias `--subtitle-lang`) set them independently, and either one overrides `--lang` for its own stream type. Anything you leave unset stays English.

```bash
./mkv-clean.sh --audio-lang jpn --sub-lang eng /path/to/your/movies
./mkv-clean.sh --lang fr --sub-lang fre,eng /path/to/your/movies
```

**Or prompt your agent directly:**

```bash
copilot "clean Movie.mkv"
claude "clean all MKVs and M4Vs in ~/Movies recursively"
codex "clean all MKVs in ~/Movies/Series/Season1 recursively"
opencode run --auto "clean all MKVs here but keep French audio too"
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
├── skills/mkv-cleaner/SKILL.md   # The agent. Everything else is packaging.
├── AGENTS.md                     # Generated copy, always-on for agents in a checkout
├── CLAUDE.md                     # Imports AGENTS.md for Claude Code
├── mkv-clean.sh                  # Launcher (checks tools, picks a harness)
├── install.sh                    # Symlinks the skill into your harnesses
└── scripts/sync-agents-md.sh     # Regenerates AGENTS.md from the skill
```

## Adapters

The behaviour lives in `skills/mkv-cleaner/SKILL.md`, in the [Agent Skills](https://agentskills.io) format. Everything below is a thin adapter pointing back at it.

| Harness | Files | Notes |
|---------|-------|-------|
| Claude Code | `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.claude/skills/` | Plugin install, or the `.claude/skills/` symlink in a checkout. Claude Code reads `CLAUDE.md`, never `AGENTS.md`, so `CLAUDE.md` imports it. |
| Codex | `.codex-plugin/plugin.json`, `.agents/plugins/marketplace.json`, `.agents/skills/` | Plugin install, or the `.agents/skills/` symlink in a checkout. Also reads `AGENTS.md` at the repo root. |
| GitHub Copilot CLI | `.github/plugin/plugin.json`, `.github/plugin/marketplace.json`, `.claude/skills/`, `.agents/skills/` | Plugin install, or either symlink in a checkout. Also reads `AGENTS.md` at the repo root. |
| OpenCode | `.claude/skills/`, `.agents/skills/` | No adapter needed; OpenCode scans both paths in a project and `~/.claude/skills`, `~/.agents/skills` globally. |

## Editing the prompt

Edit `skills/mkv-cleaner/SKILL.md` — it is the single source of truth — then run `./scripts/sync-agents-md.sh` to regenerate `AGENTS.md`. CI fails if the two drift apart.
