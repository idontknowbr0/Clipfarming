#!/bin/bash

# This script interactively asks for a YouTube URL, start time, and end time,
# then downloads that section as a high-quality MP3 file.

# --- Check for Dependencies ---
# Check if yt-dlp is installed
if ! command -v yt-dlp &> /dev/null
then
    echo "Error: 'yt-dlp' is not installed or not in your PATH."
    echo "Please install it to use this script."
    exit 1
fi

# Check if ffmpeg is installed (required for MP3 conversion)
if ! command -v ffmpeg &> /dev/null
then
    echo "Error: 'ffmpeg' is not installed or not in your PATH."
    echo "yt-dlp requires ffmpeg to convert audio to MP3."
    exit 1
fi

# --- Get User Input ---
read -p "Enter YouTube URL: " url
read -p "Enter START time (HH:MM:SS) (leave empty for start): " start
read -p "Enter END time (HH:MM:SS) (leave empty for end): " end
read -p "Enter output directory (default: current folder): " output_dir

# --- Set Variables ---
# Default to current directory '.' if output_dir is empty
OUTPUT_DIR="${output_dir:-.}"

# --- Create Directory ---
# Create the output directory if it doesn't exist
# The '-p' flag creates parent directories if needed and doesn't error if it already exists.
mkdir -p "$OUTPUT_DIR"
if [ $? -ne 0 ]; then
    echo "Error: Could not create directory '$OUTPUT_DIR'."
    exit 1
fi

# --- Build Command ---
echo "Preparing download..."

# We use a bash array to safely build the command with optional arguments
declare -a YT_ARGS

# Add the arguments from your snippet
YT_ARGS=(
    --cookies-from-browser 'chrome'
    --extractor-args 'youtube:client=web'
    --format 'bestaudio/best'
    -x --audio-format mp3
    --audio-quality 0
)

# --- Handle Trimming Logic ---
if [ -z "$start" ] && [ -z "$end" ]; then
    # --- NO TRIMMING ---
    echo "No start/end time given, downloading full audio."
    # Set standard output template
    OUTPUT_TEMPLATE="$OUTPUT_DIR/%(title)s.%(ext)s"
else
    # --- TRIMMING ---
    echo "Trimming audio from '${start}' to '${end}'"
    # Add the download-sections argument
    YT_ARGS+=(--download-sections "*${start}-${end}")
    
    # Create a filename friendly for trimming
    start_file=${start:-start}
    end_file=${end:-end}
    OUTPUT_TEMPLATE="$OUTPUT_DIR/%(title)s [${start_file//:/-}-${end_file//:/-}].%(ext)s"
fi

# Add the final output template and URL to the arguments
YT_ARGS+=(-o "$OUTPUT_TEMPLATE")
YT_ARGS+=("$url")

echo "Attempting to download, trim, and convert..."

# --- Run yt-dlp ---
# We use "${YT_ARGS[@]}" to expand the array safely,
# handling spaces in paths or arguments.
yt-dlp "${YT_ARGS[@]}"

# Check the exit status of yt-dlp
if [ $? -eq 0 ]; then
    echo -e "\n✅ Download complete!"
    echo "File saved in: $OUTPUT_DIR"
else
    echo -e "\n❌ Download failed! Please check the URL and timestamps."
fi
