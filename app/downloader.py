from pathlib import Path
import threading
import yt_dlp
from app.youtube_access import run_with_cookie_fallback
from PySide6.QtCore import QObject, Signal, Slot
from app.media_probe import probe_media, write_music_tags


class DownloadCancelled(Exception):
    pass


class DownloadWorker(QObject):
    progress = Signal(dict)
    finished = Signal(dict)
    error = Signal(str)
    cancelled = Signal()

    def __init__(self, url, download_path, option, audio_mode, ffmpeg_dir, metadata=None, embed_metadata=True, embed_artwork=True, language="en", preferred_browser=""):
        super().__init__()
        self.url = url
        self.download_path = Path(download_path)
        self.option = dict(option or {})
        self.audio_mode = bool(audio_mode)
        self.ffmpeg_dir = Path(ffmpeg_dir)
        self.metadata = dict(metadata or {})
        self.embed_metadata = bool(embed_metadata)
        self.embed_artwork = bool(embed_artwork)
        self.language = language
        self.preferred_browser = preferred_browser
        self._cancel_event = threading.Event()

    def cancel(self):
        self._cancel_event.set()

    def _check_cancel(self):
        if self._cancel_event.is_set():
            raise DownloadCancelled()

    def _progress_hook(self, data):
        self._check_cancel()
        status = data.get("status")
        if status == "downloading":
            downloaded = int(data.get("downloaded_bytes") or 0)
            total = int(data.get("total_bytes") or data.get("total_bytes_estimate") or 0)
            percent = (downloaded / total * 100.0) if total else 0.0
            self.progress.emit({
                "stage": "Downloading...",
                "percent": max(0.0, min(percent, 100.0)),
                "downloaded": downloaded,
                "total": total,
                "speed": float(data.get("speed") or 0),
                "eta": int(data.get("eta") or 0),
            })
        elif status == "finished":
            self.progress.emit({
                "stage": "Processing...",
                "percent": 100.0,
                "downloaded": int(data.get("downloaded_bytes") or 0),
                "total": int(data.get("total_bytes") or data.get("total_bytes_estimate") or 0),
                "speed": 0.0,
                "eta": 0,
            })

    def _postprocessor_hook(self, data):
        self._check_cancel()
        if data.get("status") == "started":
            pp = data.get("postprocessor") or "FFmpeg"
            stage = "Processing with FFmpeg..."
            if "ExtractAudio" in pp:
                stage = "Converting audio..."
            elif "Merger" in pp:
                stage = "Merging video and audio..."
            self.progress.emit({"stage": stage, "percent": 100.0, "downloaded": 0, "total": 0, "speed": 0.0, "eta": 0})

    def _format_selector(self):
        if self.audio_mode:
            return self.option.get("format_id") or "bestaudio/best"
        height = int(self.option.get("height") or 0)
        if height > 0:
            return f"bestvideo[height<={height}]+bestaudio/best[height<={height}]"
        return "bestvideo+bestaudio/best"

    @Slot()
    def run(self):
        try:
            self._check_cancel()
            self.download_path.mkdir(parents=True, exist_ok=True)
            before = {p.resolve() for p in self.download_path.iterdir() if p.is_file()}

            opts = {
                "quiet": True,
                "no_warnings": True,
                "noplaylist": True,
                "format": self._format_selector(),
                "outtmpl": str(self.download_path / "%(title)s.%(ext)s"),
                "ffmpeg_location": str(self.ffmpeg_dir),
                "progress_hooks": [self._progress_hook],
                "postprocessor_hooks": [self._postprocessor_hook],
                "windowsfilenames": True,
                "overwrites": False,
                "writethumbnail": self.audio_mode and self.embed_artwork,
            }

            mode = self.option.get("mode")
            postprocessors = []
            if self.audio_mode and mode == "mp3":
                postprocessors.append({
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": "mp3",
                    "preferredquality": "320",
                })
            elif self.audio_mode and mode == "m4a":
                postprocessors.append({
                    "key": "FFmpegExtractAudio",
                    "preferredcodec": "m4a",
                    "preferredquality": "0",
                })
            elif self.audio_mode and mode == "original":
                # Best YouTube audio is commonly Opus inside a WebM container.
                # EmbedThumbnail cannot embed artwork into WebM. Extracting to
                # .opus here keeps the existing Opus stream (no lossy re-encode)
                # and gives EmbedThumbnail a supported target container.
                source_ext = str(self.option.get("ext") or "").lower()
                source_codec = str(self.option.get("codec") or "").lower()
                if source_ext == "webm" and "opus" in source_codec:
                    postprocessors.append({
                        "key": "FFmpegExtractAudio",
                        "preferredcodec": "opus",
                        "preferredquality": "0",
                    })
            elif not self.audio_mode:
                opts["merge_output_format"] = "mkv"

            # Optional metadata/artwork settings. Neither setting intentionally
            # re-encodes an already-compatible original audio stream.
            if self.embed_metadata:
                postprocessors.append({"key": "FFmpegMetadata", "add_metadata": True})
            if self.audio_mode and self.embed_artwork:
                postprocessors.append({"key": "EmbedThumbnail", "already_have_thumbnail": False})
            opts["postprocessors"] = postprocessors

            run_with_cookie_fallback(
                self.url,
                opts,
                lambda ydl: ydl.download([self.url]),
                self.language,
                self.preferred_browser,
            )

            self._check_cancel()
            candidates = []
            for p in self.download_path.iterdir():
                if not p.is_file() or p.suffix.lower() in {".part", ".ytdl", ".jpg", ".jpeg", ".png", ".webp"}:
                    continue
                if p.resolve() not in before:
                    candidates.append(p)
            if not candidates:
                candidates = [
                    p for p in self.download_path.iterdir()
                    if p.is_file() and p.suffix.lower() not in {".part", ".ytdl", ".jpg", ".jpeg", ".png", ".webp"}
                ]
            final_file = max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None
            if final_file and self.audio_mode and self.embed_metadata:
                write_music_tags(final_file, self.metadata)
            inspection = probe_media(final_file, self.ffmpeg_dir / "ffprobe.exe") if final_file else {}
            self.finished.emit({
                "file_path": str(final_file) if final_file else "",
                "file_name": final_file.name if final_file else "Download complete",
                "size": final_file.stat().st_size if final_file and final_file.exists() else 0,
                "inspection": inspection,
            })
        except DownloadCancelled:
            self.cancelled.emit()
        except yt_dlp.utils.DownloadError as exc:
            if self._cancel_event.is_set():
                self.cancelled.emit()
            else:
                self.error.emit(str(exc))
        except Exception as exc:
            if self._cancel_event.is_set():
                self.cancelled.emit()
            else:
                self.error.emit(str(exc))
