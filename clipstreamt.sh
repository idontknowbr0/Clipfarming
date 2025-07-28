#!/bin/bash

read -p "Enter Twitch VOD URL: " url
read -p "Enter START time (format HH:MM:SS): " start
read -p "Enter END time (format HH:MM:SS): " end

# Clean filename
filename="clip-${start//:/-}-${end//:/-}"
final_output="${filename}-final.mp4"

# Try downloading 1080p60 (if available) and fallback to best combined format
yt-dlp \
  -f "best[height=1080][fps=60]/best[height=1080]/best" \
  --download-sections "*${start}-${end}" \
  -o "${filename}.%(ext)s" \
  "$url"

# Find downloaded file
downloaded_file=$(ls "${filename}".* 2>/dev/null | head -n 1)

if [ ! -f "$downloaded_file" ]; then
  echo "❌ Download failed!"
  exit 1
fi

echo "🎯 Downloaded file: $downloaded_file"

# Re-encode to safe H.264 + AAC (if needed) and save to .mp4
echo "🎞️ Converting to Premiere-safe MP4 (H.264 + AAC)..."
ffmpeg -y -i "$downloaded_file" \
  -vf "format=yuv420p" \
  -c:v libx264 -preset veryfast -crf 18 \
  -c:a aac -b:a 320k \
  "$final_output"

# Clean up original (optional)
rm "$downloaded_file"

echo "✅ Done! Your Premiere-compatible clip is: $final_output"
