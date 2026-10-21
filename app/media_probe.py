import json
import subprocess
from pathlib import Path


def _rate(value):
    if not value or value == "0/0":
        return 0.0
    try:
        a, b = value.split("/", 1)
        return float(a) / float(b) if float(b) else 0.0
    except Exception:
        try:
            return float(value)
        except Exception:
            return 0.0


def _codec_label(stream):
    codec = (stream.get("codec_name") or "").upper()
    profile = stream.get("profile") or ""
    if codec == "AAC" and profile and profile.lower() != "unknown":
        return f"AAC {profile}"
    return codec or "Unknown"


def probe_media(file_path, ffprobe_path):
    path = Path(file_path)
    exe = Path(ffprobe_path)
    if not path.exists() or not exe.exists():
        return {}

    cmd = [str(exe), "-v", "error", "-show_streams", "-show_format", "-of", "json", str(path)]
    creationflags = getattr(subprocess, "CREATE_NO_WINDOW", 0)
    completed = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8", errors="replace", creationflags=creationflags)
    if completed.returncode != 0:
        return {}

    data = json.loads(completed.stdout or "{}")
    streams = data.get("streams") or []
    fmt = data.get("format") or {}
    audio = next((s for s in streams if s.get("codec_type") == "audio"), {})
    video = next((s for s in streams if s.get("codec_type") == "video" and not (s.get("disposition") or {}).get("attached_pic")), {})

    duration = float(fmt.get("duration") or audio.get("duration") or video.get("duration") or 0)
    size = int(fmt.get("size") or path.stat().st_size)
    result = {"duration": duration, "size": size, "format_name": fmt.get("format_name") or ""}

    if audio:
        channels = int(audio.get("channels") or 0)
        layout = audio.get("channel_layout") or ("stereo" if channels == 2 else ("mono" if channels == 1 else ""))
        result["audio"] = {
            "codec": _codec_label(audio),
            "codec_name": audio.get("codec_name") or "",
            "bit_rate": int(audio.get("bit_rate") or 0),
            "sample_rate": int(audio.get("sample_rate") or 0),
            "channels": channels,
            "channel_layout": layout,
        }

    if video:
        result["video"] = {
            "codec": _codec_label(video),
            "codec_name": video.get("codec_name") or "",
            "width": int(video.get("width") or 0),
            "height": int(video.get("height") or 0),
            "fps": _rate(video.get("avg_frame_rate") or video.get("r_frame_rate")),
            "bit_rate": int(video.get("bit_rate") or 0),
        }

    tags = fmt.get("tags") or {}
    result["tags"] = {
        "title": tags.get("title") or "",
        "artist": tags.get("artist") or tags.get("ARTIST") or "",
        "album": tags.get("album") or "",
        "date": tags.get("date") or tags.get("year") or "",
    }
    result["artwork_embedded"] = any((s.get("disposition") or {}).get("attached_pic") for s in streams)
    return result


def write_music_tags(file_path, metadata):
    """Write friendly title/artist/album/year tags when the container is supported."""
    if not metadata or not file_path:
        return
    path = Path(file_path)
    try:
        suffix = path.suffix.lower()
        if suffix == ".mp3":
            from mutagen.easyid3 import EasyID3
            from mutagen.id3 import ID3, ID3NoHeaderError
            try:
                tags = EasyID3(str(path))
            except ID3NoHeaderError:
                ID3().save(str(path))
                tags = EasyID3(str(path))
            if metadata.get("title"): tags["title"] = [metadata["title"]]
            if metadata.get("artist"): tags["artist"] = [metadata["artist"]]
            if metadata.get("album"): tags["album"] = [metadata["album"]]
            if metadata.get("year"): tags["date"] = [metadata["year"]]
            tags.save()
        elif suffix in {".m4a", ".mp4"}:
            from mutagen.mp4 import MP4
            media = MP4(str(path))
            if metadata.get("title"): media["\xa9nam"] = [metadata["title"]]
            if metadata.get("artist"): media["\xa9ART"] = [metadata["artist"]]
            if metadata.get("album"): media["\xa9alb"] = [metadata["album"]]
            if metadata.get("year"): media["\xa9day"] = [metadata["year"]]
            media.save()
    except Exception:
        # Tagging is optional and must never turn a successful download into a failure.
        pass
