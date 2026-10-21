import json
from datetime import datetime
from pathlib import Path


class HistoryStore:
    def __init__(self, base_dir, limit=100):
        self.data_dir = Path(base_dir) / "data"
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.file = self.data_dir / "history.json"
        self.limit = limit

    def load(self):
        if not self.file.exists():
            return []
        try:
            data = json.loads(self.file.read_text(encoding="utf-8"))
            return data if isinstance(data, list) else []
        except Exception:
            return []

    def add(self, item):
        items = self.load()
        entry = dict(item or {})
        entry["downloaded_at"] = datetime.now().isoformat(timespec="seconds")
        path = str(entry.get("file_path") or "")
        items = [x for x in items if str(x.get("file_path") or "") != path]
        items.insert(0, entry)
        self.file.write_text(json.dumps(items[:self.limit], ensure_ascii=False, indent=2), encoding="utf-8")

    def clear(self):
        self.file.write_text("[]", encoding="utf-8")
