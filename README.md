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
- **Input formats**: `.mkv`, `.m4v` and `.m2ts` (Blu-ray streams) — all remuxed into MKV
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

## Update

Installing a plugin pins the copy you got that day; new versions do not arrive on their own. Updating is always two steps: refresh the marketplace catalog, then update the plugin itself. Claude Code and Copilot CLI need a restart of the session afterwards.

### Claude Code

```
/plugin marketplace update mkv-cleaner
```
```
/plugin update mkv-cleaner@mkv-cleaner
```

Same thing from a shell, outside a session:

```bash
claude plugin marketplace update mkv-cleaner && claude plugin update mkv-cleaner@mkv-cleaner
```

`claude plugin list` shows the installed version, and `claude plugin marketplace update` with no name refreshes every marketplace you have added.

### GitHub Copilot CLI

```bash
copilot plugin marketplace update mkv-cleaner && copilot plugin update mkv-cleaner@mkv-cleaner
```

`copilot plugin update --all` updates every installed plugin instead. The slash equivalents work inside an interactive session.

### Codex

Codex mirrors the same pair of subcommands:

```bash
codex plugin marketplace update mkv-cleaner && codex plugin update mkv-cleaner@mkv-cleaner
```

If your Codex build names them differently, `codex plugin --help` lists what it has; re-running `codex plugin add mkv-cleaner@mkv-cleaner` also picks up the newer version.

### Symlink install, checkout, or OpenCode

Nothing to update — those all read the skill out of the checkout, so a `git pull` is the whole update:

```bash
cd /path/to/mkv-cleaner && git pull
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

Every run ends with a summary of what it cost:

```
--- Run summary ---
Harness:  claude
Model:    claude-sonnet-5-20250929
Input:    36 tokens
Output:   1132 tokens
Cache:    22445 written, 144288 read
Cost:     $0.065
Resume:   claude --resume 8d238bd5-ee73-4bf7-880b-d02a91eeec5c
Duration: 18s
```

Claude Code reports the model that actually answered — which is not always the one you asked for, after a fallback — along with token counts and cost. The other harnesses only get a token line if their own output prints one; otherwise the summary says so and shows the model you requested.

The resume command is worth keeping. The launcher runs the agent from the mkv-cleaner checkout so the skill is in scope, so the session is filed under that folder and `/resume` will not list it from your movie folder. Resuming by id works from anywhere.

**Or prompt your agent directly:**

```bash
copilot "clean Movie.mkv"
claude "clean all MKVs, M4Vs and M2TS files in ~/Movies recursively"
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
| `Heat.1995.BluRay.REMUX.m2ts` | `cleaned/Heat.1995.mkv` |
| `00800.m2ts` | skipped — no title in the name, tell the agent what it is |

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

## Releasing a new version of the plugin

The behaviour change is one file; shipping it to installed plugins is the rest of this list.

1. Edit `skills/mkv-cleaner/SKILL.md`, then `./scripts/sync-agents-md.sh`.
2. If the change affects what the plugin claims to do, update the `description` in all five manifests (`.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `.codex-plugin/plugin.json`, `.github/plugin/plugin.json`, `.github/plugin/marketplace.json`) and the `description` in the skill's front matter — that front matter is what makes the agent pick the skill up, so a new input format or flag belongs in it.
3. Bump `version` in the three `plugin.json` files, together. A user's `plugin update` is a no-op if the version has not moved.
4. Validate and push:

```bash
claude plugin validate . && ./scripts/sync-agents-md.sh --check
```

5. Push to `master`. `.agents/plugins/marketplace.json` pins `ref: master`, so that is what installs fetch.
6. Optionally tag the release — `claude plugin tag` checks that `plugin.json` and the marketplace entry agree on the version before tagging:

```bash
claude plugin tag .
```

Then test the update path itself from a real install: `claude plugin marketplace update mkv-cleaner && claude plugin update mkv-cleaner@mkv-cleaner`, restart, and confirm `claude plugin list` shows the new version.
