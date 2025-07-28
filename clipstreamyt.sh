#!/bin/bash

read -p "Enter YouTube livestream URL: " url
read -p "Enter START time (format HH:MM:SS): " start
read -p "Enter END time (format HH:MM:SS): " end

# Clean filenames
filename="clip-${start//:/-}-${end//:/-}"
final_output="${filename}-final.mp4"

# Download livestream clip using yt-dlp (force best 1080p60 only)
yt-dlp \
  -f "bestvideo[height=1080][fps=60]+bestaudio" \
  --download-sections "*${start}-${end}" \
  -o "${filename}.%(ext)s" \
  "$url"

# Find actual downloaded file
downloaded_file=$(ls "${filename}".* 2>/dev/null | head -n 1)

# Check if download succeeded
if [ ! -f "$downloaded_file" ]; then
  echo "❌ Download failed!"
  exit 1
fi

echo "🎯 Downloaded file: $downloaded_file"

# Fully re-encode to Premiere Pro–friendly format (H.264 + AAC)
echo "🎞️ Converting to Premiere-safe MP4 (H.264 + AAC)..."
ffmpeg -y -i "$downloaded_file" \
  -vf "format=yuv420p" \
  -c:v libx264 -preset veryfast -crf 18 \
  -c:a aac -b:a 320k \
  "$final_output"

# Optional: delete original file to save space
rm "$downloaded_file"

echo "✅ Done! Your fully Premiere-compatible file is: $final_output"
