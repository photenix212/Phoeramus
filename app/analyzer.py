import yt_dlp
from app.youtube_access import run_with_cookie_fallback
from PySide6.QtCore import QObject, Signal, Slot


class AnalyzeWorker(QObject):
    finished = Signal(dict)
    error = Signal(str)

    def __init__(self, url, language="en", preferred_browser=""):
        super().__init__()
        self.url = url
        self.language = language
        self.preferred_browser = preferred_browser

    @Slot()
    def run(self):
        try:
            options = {
                "quiet": True,
                "no_warnings": True,
                "skip_download": True,
                "noplaylist": True,
            }
            info, _browser_used = run_with_cookie_fallback(
                self.url,
                options,
                lambda ydl: ydl.extract_info(self.url, download=False),
                self.language,
                self.preferred_browser,
            )
            if not info:
                raise RuntimeError("No media information received.")

            duration = int(info.get("duration") or 0)
            result = {
                "title": info.get("title") or "Unknown title",
                "uploader": info.get("uploader") or info.get("channel") or "Unknown channel",
                "thumbnail": info.get("thumbnail") or "",
                "duration": duration,
                "duration_text": self.format_duration(duration),
                "webpage_url": info.get("webpage_url") or self.url,
                "metadata": self.build_metadata(info),
                "audio_options": self.build_audio_options(info),
                "video_options": self.build_video_options(info),
            }
            self.finished.emit(result)
        except Exception as exc:
            self.error.emit(str(exc))

    @staticmethod
    def build_metadata(info):
        raw_title = (info.get("title") or "").strip()
        track = (info.get("track") or "").strip()
        artist = (info.get("artist") or info.get("creator") or "").strip()
        album = (info.get("album") or "").strip()
        year = str(info.get("release_year") or info.get("release_date") or info.get("upload_date") or "")[:4]

        # Music uploads often use "Artist - Title" even when YouTube does not expose music fields.
        if not track and " - " in raw_title:
            left, right = raw_title.split(" - ", 1)
            if left.strip() and right.strip():
                artist = artist or left.strip()
                track = right.strip()

        return {
            "title": track or raw_title or "Unknown title",
            "artist": artist,
            "album": album,
            "year": year,
            "thumbnail": info.get("thumbnail") or "",
        }

    @staticmethod
    def format_duration(seconds):
        hours = seconds // 3600
        minutes = (seconds % 3600) // 60
        seconds %= 60
        if hours:
            return f"{hours}:{minutes:02d}:{seconds:02d}"
        return f"{minutes}:{seconds:02d}"

    @staticmethod
    def build_audio_options(info):
        audio_streams = []
        for fmt in info.get("formats", []):
            acodec = fmt.get("acodec") or "none"
            vcodec = fmt.get("vcodec") or "none"
            if acodec == "none" or vcodec != "none":
                continue
            audio_streams.append({
                "format_id": str(fmt.get("format_id")),
                "ext": fmt.get("ext") or "",
                "codec": acodec,
                "abr": fmt.get("abr") or 0,
            })

        best = max(audio_streams, key=lambda item: item["abr"] or 0) if audio_streams else None
        result = []
        if best:
            detail = best["codec"]
            if best["abr"]:
                detail += f" • ~{round(best['abr'])} kbps"
            result.append({
                "name": "Original • Best available",
                "detail": detail,
                "mode": "original",
                "format_id": best["format_id"],
                "ext": best["ext"],
                "codec": best["codec"],
            })
        else:
            result.append({
                "name": "Original • Best available",
                "detail": "Best audio stream",
                "mode": "original",
                "format_id": "bestaudio",
                "ext": "",
            })

        result.extend([
            {
                "name": "MP3",
                "detail": "Convert using FFmpeg • 320 kbps",
                "mode": "mp3",
                "format_id": "bestaudio/best",
                "ext": "mp3",
            },
            {
                "name": "M4A",
                "detail": "AAC / M4A • convert only when needed",
                "mode": "m4a",
                "format_id": "bestaudio[ext=m4a]/bestaudio/best",
                "ext": "m4a",
            },
        ])
        return result

    @staticmethod
    def build_video_options(info):
        heights = {}
        for fmt in info.get("formats", []):
            if (fmt.get("vcodec") or "none") == "none":
                continue
            height = int(fmt.get("height") or 0)
            if height <= 0:
                continue
            fps = int(fmt.get("fps") or 0)
            current = heights.get(height)
            if current is None or fps > current["fps"]:
                heights[height] = {"height": height, "fps": fps}

        result = [{
            "name": "Best available",
            "detail": "Highest available quality",
            "height": 0,
            "mode": "best",
        }]
        for height in sorted(heights, reverse=True):
            fps = heights[height]["fps"]
            result.append({
                "name": f"{height}p",
                "detail": f"Up to {fps} FPS" if fps else "Video",
                "height": height,
                "mode": "height",
            })
        return result
