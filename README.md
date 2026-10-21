<p align="center">
  <img src="icon.png" width="128" alt="Phoeramus icon">
</p>

<h1 align="center">Phoeramus</h1>

<p align="center">
  <strong>A lightweight Windows media downloader with a native Qt/QML interface.</strong>
</p>

<p align="center">
  Python · PySide6/QML · yt-dlp · FFmpeg
</p>

<p align="center">
  <a href="https://github.com/photenix212/Phoeramus/releases/latest"><strong>Download for Windows</strong></a>
  ·
  <a href="https://github.com/photenix212/Phoeramus/releases/latest">Latest Release</a>
</p>

<p align="center">
  Windows 10/11 x64 · Portable · No Python installation required
</p>

---

## Download

The easiest way to use Phoeramus is the portable Windows build.

1. Open the [latest release](https://github.com/photenix212/Phoeramus/releases/latest).
2. Download `Phoeramus-v1.0.0-Windows-x64.zip` from **Assets**.
3. Extract the ZIP.
4. Run `Phoeramus.exe`.

No Python or FFmpeg installation is required.

> Windows SmartScreen may show an "unrecognized app" warning because Phoeramus is currently not code-signed.

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
- Portable Windows build

## Run from source

Requirements:

- Windows 10/11
- Python 3.13

Create a virtual environment:

```powershell
py -3.13 -m venv .venv
```

Activate it:

```powershell
.\.venv\Scripts\Activate.ps1
```

Install dependencies:

```powershell
python -m pip install -r requirements.txt
```

Download FFmpeg and ffprobe:

```powershell
.\setup_ffmpeg.ps1
```

Run Phoeramus:

```powershell
python main.py
```

`setup_ffmpeg.ps1` downloads the FFmpeg essentials build and keeps only `ffmpeg.exe` and `ffprobe.exe` in the local `bin` directory.

## Build a portable version

After preparing the environment, run:

```powershell
.\build_portable.ps1
```

The application is created in `dist/Phoeramus/`, along with a portable ZIP in `dist/`.

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

Phoeramus v1 focuses on YouTube and other media URLs supported by yt-dlp.

Possible future experiments include Spotify, Deezer and Apple Music link recognition, source matching, and searching for the best available quality across multiple sources.

## Notes

Phoeramus does not host or provide media. Users are responsible for complying with the terms of the services they use and with applicable copyright law.

## License

Licensed under the GNU General Public License v3.0. See `LICENSE`.