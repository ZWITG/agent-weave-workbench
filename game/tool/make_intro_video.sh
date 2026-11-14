#!/usr/bin/env bash
# Builds the shareable intro videos (square 1080x1080 and vertical
# 1080x1920) from the frames tool/render_intro_test.dart renders.
set -euo pipefail
cd "$(dirname "$0")/.."
FRAMES="${1:-build/intro_frames}"
OUT="${2:-media}"
mkdir -p "$OUT"
flutter test tool/render_intro_test.dart --dart-define=OUT="$FRAMES"
for name in square vertical; do
  # 60 fps frames, hold the logo 1.2 s, fade to black over the last 0.5 s,
  # with a silent audio track so social apps accept it.
  ffmpeg -y -loglevel error -framerate 60 -i "$FRAMES/$name/f%04d.png" \
    -f lavfi -i anullsrc=channel_layout=stereo:sample_rate=48000 \
    -vf "tpad=stop_mode=clone:stop_duration=1.2,fade=t=out:st=3.8:d=0.5,format=yuv420p" \
    -c:v libx264 -preset slow -crf 16 -movflags +faststart \
    -c:a aac -b:a 128k -shortest \
    "$OUT/relivable-intro-$name.mp4"
done
ls -la "$OUT"
