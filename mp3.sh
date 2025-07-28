#!/bin/bash

read -p "Enter YouTube URL: " url
read -p "Enter START time (HH:MM:SS): " start
read -p "Enter END time (HH:MM:SS): " end

filename="audio-${start//:/-}-${end//:/-}.mp3"

# Use pipx-installed yt-dlp directly
yt_dlp="$HOME/.local/bin/yt-dlp"

# Download best non-HLS audio format and trim it
"$yt_dlp" \
  --format 'bestaudio[ext=m4a]' \
  --download-sections "*${start}-${end}" \
  -x --audio-format mp3 --audio-quality 0 \
  -o "temp_audio.%(ext)s" \
  "$url"

# Find downloaded file
input_file=$(ls temp_audio.* 2>/dev/null | head -n 1)

if [ ! -f "$input_file" ]; then
  echo "❌ Download failed!"
  exit 1
fi

# Convert to MP3
ffmpeg -y \
  -i "$input_file" \
  -vn -c:a libmp3lame -q:a 0 \
  "$filename"

rm "$input_file"

echo "✅ Done! Saved as: $filename"
