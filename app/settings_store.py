import json
from pathlib import Path
from PySide6.QtCore import QStandardPaths


class SettingsStore:
    DEFAULTS = {
        "download_path": "",
        "startup_mode": "audio",
        "default_audio_format": "original",
        "embed_metadata": True,
        "embed_artwork": True,
        "language": "en",
    }

    def __init__(self, base_dir):
        self.data_dir = Path(base_dir) / "data"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.file = self.data_dir / "settings.json"

    @staticmethod
    def default_download_path():
        path = QStandardPaths.writableLocation(QStandardPaths.DownloadLocation)
        return path or str(Path.home() / "Downloads")

    def load(self):
        data = dict(self.DEFAULTS)
        data["download_path"] = self.default_download_path()

        if self.file.exists():
            try:
                saved = json.loads(self.file.read_text(encoding="utf-8"))
                if isinstance(saved, dict):
                    data.update(saved)
            except Exception:
                pass

        path = str(data.get("download_path") or "")
        if not path or not Path(path).exists():
            data["download_path"] = self.default_download_path()

        if data.get("startup_mode") not in {"audio", "video"}:
            data["startup_mode"] = "audio"
        if data.get("default_audio_format") not in {"original", "mp3", "m4a"}:
            data["default_audio_format"] = "original"

        data["embed_metadata"] = bool(data.get("embed_metadata", True))
        data["embed_artwork"] = bool(data.get("embed_artwork", True))
        if data.get("language") not in {"en", "ru"}:
            data["language"] = "en"
        return data

    def save(self, data):
        clean = dict(self.DEFAULTS)
        clean.update(dict(data or {}))
        self.file.write_text(
            json.dumps(clean, indent=4, ensure_ascii=False),
            encoding="utf-8",
        )

    def load_download_path(self):
        return self.load()["download_path"]

    def save_download_path(self, path):
        data = self.load()
        data["download_path"] = str(path)
        self.save(data)

    def set_value(self, key, value):
        if key not in self.DEFAULTS:
            return
        data = self.load()
        data[key] = value
        self.save(data)
