CLI Instructions — mkvmerge and ffmpeg

Purpose: explicit, copy-paste commands and a recommended workflow so simpler/less-capable agents will not omit track-selection arguments.

1) Inspect the file (ffprobe):

  ffprobe -v quiet -print_format json -show_streams -show_chapters -show_format "input.mkv" > input.ffprobe.json

Use this JSON to choose which ffprobe stream indexes to keep.

2) Map mkvtrack IDs (mkvmerge):

  mkvmerge -i "input.mkv"

Example output lines to read:
  Track ID 0: video (V_MPEGH/ISO/HEVC)
  Track ID 1: audio (A_AC3)
  Track ID 2: subtitles (S_TEXT/ASS)

Note: mkvmerge Track IDs are local to the file and usually start at 0 in the order tracks appear. Do not assume ffprobe's numeric "index" equals mkvmerge Track ID. Always run mkvmerge -i to get the correct IDs.

3) Remux with explicit track selection (mkvmerge — preferred):

  # Keep mkv Track IDs 0 (video), 1 (best English audio), 3 (English subtitles)
  mkvmerge -o "cleaned/output.mkv" \
    --no-track-tags --no-global-tags --no-attachments --disable-track-statistics-tags \
    --tracks "input.mkv:0,1,3" \
    "input.mkv"

Or use the per-type selectors if you already know mkv IDs per type:
  mkvmerge -o "cleaned/output.mkv" --video-tracks 0 --audio-tracks 1 --subtitle-tracks 3 \
    --no-track-tags --no-global-tags --no-attachments --disable-track-statistics-tags "input.mkv"

4) Fallback: ffmpeg (maps by stream index as shown by ffprobe):

  ffmpeg -hide_banner -loglevel error -i "input.mkv" \
    -map 0:v:0 -map 0:a:1 -map 0:s:0 \
    -c copy -map_chapters 0 -map_metadata -1 "cleaned/output.mkv"

5) Verify output matches planned selection:

  ffprobe -v quiet -print_format json -show_streams "cleaned/output.mkv" > output.ffprobe.json

Compare the output JSON with the planned track list. If they differ, do NOT assume success — log the mismatch and retry using ffmpeg mapping or warn the user.

6) Minimal checklist for scripts/agents to follow (copy/paste safe):
  - Run ffprobe to decide which ffprobe stream indexes to keep.
  - Run mkvmerge -i to map mkv Track IDs (do not assume ffprobe index == mkv Track ID).
  - Build mkvmerge command using --tracks "<file>:<id,id,...>" or per-type --video-tracks/--audio-tracks/--subtitle-tracks.
  - If mkvmerge fails or refuses to drop tracks, fall back to ffmpeg using explicit -map 0:<type>:<n> arguments.
  - After remux, run ffprobe on the output and assert the output contains only the intended tracks.

7) Example verification snippet (bash):

  # planned_ffprobe_indexes is an array of ffprobe stream indexes chosen earlier
  jq -r '.streams[] | "\(.index) \(.codec_type) \(.tags.language // "und") \(.codec_name)"' output.ffprobe.json > out-streams.txt
  # then grep/compare with planned list; if mismatch, fail and log


Add this file to the repository and link it from README.md so agents and humans find it. The goal: eliminate brittle assumptions and force explicit, unambiguous commands in automation.
