# 🎬 Clipfarming

A set of Bash scripts for quickly downloading and converting YouTube and Twitch clips to editor-friendly formats (like Premiere Pro–safe `.mp4`) or high-quality `.mp3` audio.

## 📦 Included Scripts

### `clip4k.sh`
Downloads and trims a 4K YouTube video or livestream clip between two timestamps, then re-encodes to H.264 + AAC `.mp4` for smooth editing.
Usage:
```bash
./clip4k.sh
```

### `clipstreamyt.sh`
Downloads a 1080p60 YouTube **livestream** clip between two timestamps and re-encodes it to a Premiere-safe `.mp4`.
Usage:
```bash
./clipstream.sh
```

### `clipstreamtwitch.sh`
Same as `clipstream.sh`, but for **Twitch VODs**. Downloads at 1080p60 if available, falls back gracefully.
Usage:
```bash
./clipstreamt.sh
```

### `mp3.sh`
Extracts high-quality `.mp3` audio from a YouTube video within a specific time range.
Usage:
```bash
./mp3.sh
```

## 🛠 Requirements

- `yt-dlp`
- `ffmpeg`
- (For `mp3.sh`) `pipx` if you're using a pipx-installed version of yt-dlp

Install on macOS:
```bash
brew install yt-dlp ffmpeg
```

## 📂 Output Format

All output files are named with timestamps to keep things organized, like:
```
clip-00-51-32-01-19-47-final.mp4
audio-00-12-00-00-14-30.mp3
```

## ✅ Features

- Timestamp-based clipping
- Premiere Pro–safe encoding (H.264 + AAC, yuv420p)
- Twitch and YouTube support
- Clean file naming
- Easy to run in terminal

---

Created by [@idontknowbr0](https://github.com/idontknowbr0)
