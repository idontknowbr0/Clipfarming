#!/bin/bash

# --- Auto-update section ---
echo "Checking for updates (yt-dlp & ffmpeg)..."
brew upgrade yt-dlp &> /dev/null
brew upgrade ffmpeg &> /dev/null
echo "✅ Update check complete."
# --- End of Auto-update section ---


# --- NEW: Argument parsing ---
# Check if we got exactly 5 arguments
if [ "$#" -ne 5 ]; then
    echo "❌ Error: Incorrect number of arguments."
    echo ""
    echo "Usage: $0 \"<url_or_shortcut>\" \"<output_filename>\" \"<time_sections>\" \"<codec>\" \"<use_cookies_yes/no>\""
    echo ""
    echo "URL Shortcuts:"
    echo "  'cutscene': https://www.youtube.com/watch?v=phMgrmAeYYA"
    echo "  'gameplay': https://www.youtube.com/watch?v=pkCrPpNlbpY"
    echo ""
    echo "Codec: 'h264', 'prores_hq', 'prores_std', 'prores_lt', 'prores_proxy'"
    echo "Use Cookies: 'yes' (for age-restricted) or 'no'"
    echo ""
    echo "Example (Shortcut):"
    echo "$0 \"cutscene\" \"my_clip_proxy\" \"*00:01:00-00:02:30\" \"prores_proxy\" \"yes\""
    echo ""
    echo "Example (Full URL):"
    echo "$0 \"https://...\" \"my_compilation\" \"*00:05:00-00:06:15\" \"h264\" \"no\""
    echo ""
    exit 1
fi

# Assign arguments to variables
url_input=$(echo "$1" | tr '[:upper:]' '[:lower:]') # Convert URL or shortcut to lowercase
filename="$2"
download_sections="$3"
codec=$(echo "$4" | tr '[:upper:]' '[:lower:]') # Convert codec to lowercase
age_restricted=$(echo "$5" | tr '[:upper:]' '[:lower:]') # Convert cookie option to lowercase
# --- End of new section ---

echo "⬇️  Starting download for: $url"
echo "📼 Sections: ${download_sections}"
echo "💾 Filename: ${filename}"
echo "🎞️ Codec: ${codec}"

# --- MODIFIED: Use a generic temp download name ---
temp_download_file="downloaded_temp.%(ext)s"

# --- NEW: Build yt-dlp command in an array ---
# This allows us to conditionally add the cookie flag
yt_dlp_cmd=(
  "yt-dlp"
  "-f" "bestvideo[height=2160][fps=60]+bestaudio/bestvideo[height=2160]+bestaudio/best"
)

# Conditionally add cookies
if [ "$age_restricted" = "yes" ] || [ "$age_restricted" = "y" ]; then
    echo "🍪 Using cookies for age-restricted video."
    yt_dlp_cmd+=("--cookies-from-browser" "chrome:Default")
else
    echo "Standard download (no cookies)."
fi

# Add the rest of the arguments
yt_dlp_cmd+=(
  "--download-sections" "${download_sections}"
  "-o" "${temp_download_file}"
  "$url"
)

# Run the command
echo "Running: ${yt_dlp_cmd[@]}"
"${yt_dlp_cmd[@]}"
# --- End of new yt-dlp logic ---


# Find downloaded file
# --- FIX: Corrected typo from 'headn 1' to 'head -n 1' ---
downloaded_file=$(ls downloaded_temp.* 2>/dev/null | head -n 1)

if [ ! -f "$downloaded_file" ]; then
  echo "❌ Download failed!"
  exit 1
fi

echo "🎯 Downloaded: $downloaded_file"

# --- NEW: Conditional codec logic ---

if [ "$codec" = "h264" ]; then
    echo "🎞️ Re-encoding to 4K H.264 + AAC (Sync Fixed)..."
    final_output="${filename}.mp4"
    temp_output="${filename}.temp.mp4"

    # --- ADDED -vsync cfr AND -async 1 TO FORCE CONSTANT FRAME RATE & AUDIO SYNC ---
    ffmpeg -y -i "$downloaded_file" \
      -vf "format=yuv420p" \
      -c:v libx264 -preset veryfast -crf 20 \
      -c:a aac -b:a 320k \
      -vsync cfr \
      -async 1 \
      "$temp_output"

# --- MODIFIED: Expanded ProRes Options ---
elif [[ "$codec" == "prores"* ]]; then
    
    local_profile=3 # Default: prores_hq
    local_codec_name="ProRes 422 HQ"

    if [ "$codec" = "prores_std" ]; then
        local_profile=2
        local_codec_name="ProRes 422"
    elif [ "$codec" = "prores_lt" ]; then
        local_profile=1
        local_codec_name="ProRes 422 LT (Good for Editing)"
    elif [ "$codec" = "prores_proxy" ]; then
        local_profile=0
        local_codec_name="ProRes 422 Proxy (Fastest)"
    fi

    echo "🎞️ Re-encoding to 4K ${local_codec_name} (Sync Fixed)..."
    final_output="${filename}.mov"
    temp_output="${filename}.temp.mov"

    ffmpeg -y -i "$downloaded_file" \
      -c:v prores_ks \
      -profile:v $local_profile \
      -c:a pcm_s16le \
      -vsync cfr \
      "$temp_output"
else
    echo "❌ Error: Invalid codec '$4'. Must be 'h264', 'prores_hq', 'prores_std', 'prores_lt', 'prores_proxy'."
    rm "$downloaded_file" # Clean up downloaded file
    exit 1
fi
# --- End of new logic ---


# Check if ffmpeg succeeded
if [ $? -eq 0 ]; then
    # ffmpeg success, remove original and rename temp
    rm "$downloaded_file"
    mv "$temp_output" "$final_output"
    echo "✅ Done! Output: $final_output"
else
    # ffmpeg failed, remove temp file and report error
    rm -f "$temp_output"
    rm -f "$downloaded_file"
    echo "❌ FFmpeg re-encoding failed!"
fi
