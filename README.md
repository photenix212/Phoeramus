<div align="center">
  <img src="icon.png" width="120" alt="Phoeramus icon">

# Phoeramus

**A lightweight Windows media downloader with a native Qt/QML interface.**

Python · PySide6/QML · yt-dlp · FFmpeg
</div>

## About

Phoeramus is a desktop media downloader built as a small personal project around `yt-dlp` and FFmpeg. It focuses on a clean interface, sensible audio defaults, useful metadata, and a portable Windows build.

## Features

- Audio and video downloads through yt-dlp
- Best available original audio without unnecessary re-encoding
- MP3 and M4A output options
- Video quality selection
- Embedded metadata and cover artwork
- Post-download media inspection with ffprobe
- Download history with open-file/open-folder actions
- Persistent settings
- English and Russian interface
- Automatic browser-cookie fallback for YouTube bot/authentication checks
- Bundled FFmpeg/ffprobe in portable builds
- Portable Windows build — no Python installation required for end users

## Run from source

Requirements: Windows and Python 3.13.

```powershell
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
.\setup_ffmpeg.ps1
python main.py
```

`setup_ffmpeg.ps1` downloads the FFmpeg essentials build and keeps only `ffmpeg.exe` and `ffprobe.exe` in the local `bin` directory. These large binaries are intentionally not stored in the Git repository.

## Build a portable version

After creating `.venv`, run:

```powershell
.\build_portable.ps1
```

The resulting application is written to `dist/Phoeramus/`, and a portable ZIP is created in `dist/`.

## Project structure

```text
Phoeramus/
├─ app/                 Python backend, downloader and media tools
├─ ui/                  QML interface and panels
├─ bin/                 Local FFmpeg/ffprobe (ignored by Git)
├─ data/                Local settings/history (ignored by Git)
├─ main.py              Application entry point
├─ icon.png             Application artwork
├─ setup_ffmpeg.ps1     FFmpeg bootstrap script
├─ build_portable.ps1   Windows portable build script
└─ requirements.txt
```

## Roadmap / ideas

Phoeramus v1 focuses on YouTube/media URLs supported by yt-dlp. Possible future experiments include Spotify, Deezer and Apple Music link recognition, source matching, and searching for the best available quality across multiple sources.

## Notes

Phoeramus does not host or provide media. Users are responsible for complying with the terms of the services they use and with applicable copyright law.

## License

Licensed under the GNU General Public License v3.0. See `LICENSE`.
