#!/bin/bash

read -p "Enter YouTube video/livestream URL: " url
read -p "Enter START time (format HH:MM:SS): " start
read -p "Enter END time (format HH:MM:SS): " end

filename="clip4k-${start//:/-}-${end//:/-}"

# Try 4K60 > 4K > best available
yt-dlp \
  -f "bestvideo[height=2160][fps=60]+bestaudio/bestvideo[height=2160]+bestaudio/best" \
  --download-sections "*${start}-${end}" \
  -o "${filename}.%(ext)s" \
  "$url"

# Find downloaded file
downloaded_file=$(ls ${filename}.* 2>/dev/null | head -n 1)

if [ ! -f "$downloaded_file" ]; then
  echo "❌ Download failed!"
  exit 1
fi

echo "🎯 Downloaded: $downloaded_file"

# Re-encode to Premiere-safe H.264 + AAC
echo "🎞️ Re-encoding to 4K H.264 + AAC for editing..."
ffmpeg -y -i "$downloaded_file" \
  -vf "format=yuv420p" \
  -c:v libx264 -preset veryfast -crf 20 \
  -c:a aac -b:a 320k \
  "${filename}.mp4"

rm "$downloaded_file"

echo "✅ Done! Output: ${filename}.mp4"
