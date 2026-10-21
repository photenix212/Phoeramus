from pathlib import Path
import os

from PySide6.QtCore import QObject, Property, Signal, Slot, QThread
from PySide6.QtWidgets import QFileDialog

from app.analyzer import AnalyzeWorker
from app.downloader import DownloadWorker
from app.settings_store import SettingsStore
from app.history_store import HistoryStore


class Backend(QObject):
    analyzingChanged = Signal()
    mediaInfoChanged = Signal()
    errorChanged = Signal()
    downloadPathChanged = Signal()
    downloadingChanged = Signal()
    downloadProgressChanged = Signal()
    downloadResultChanged = Signal()
    settingsChanged = Signal()
    historyChanged = Signal()

    def __init__(self, base_dir):
        super().__init__()
        self._base_dir = Path(base_dir)
        self._settings = SettingsStore(self._base_dir)
        self._history_store = HistoryStore(self._base_dir)
        self._history = self._history_store.load()
        self._settings_data = self._settings.load()
        self._download_path = self._settings_data["download_path"]
        self._analyzing = False
        self._media_info = {}
        self._error = ""
        self._downloading = False
        self._download_progress = self._empty_progress("Ready")
        self._download_result = {}
        self._analysis_thread = None
        self._analysis_worker = None
        self._download_thread = None
        self._download_worker = None

    @staticmethod
    def _empty_progress(stage):
        return {"stage": stage, "percent": 0.0, "downloaded": 0, "total": 0, "speed": 0.0, "eta": 0}

    @Property(bool, notify=analyzingChanged)
    def analyzing(self): return self._analyzing

    @Property("QVariantMap", notify=mediaInfoChanged)
    def mediaInfo(self): return self._media_info

    @Property(str, notify=errorChanged)
    def error(self): return self._error

    @Property(str, notify=downloadPathChanged)
    def downloadPath(self): return self._download_path

    @Property(bool, notify=downloadingChanged)
    def downloading(self): return self._downloading

    @Property("QVariantMap", notify=downloadProgressChanged)
    def downloadProgress(self): return self._download_progress

    @Property("QVariantMap", notify=downloadResultChanged)
    def downloadResult(self): return self._download_result

    @Property("QVariantMap", notify=settingsChanged)
    def settings(self): return self._settings_data

    @Property("QVariantList", notify=historyChanged)
    def history(self): return self._history

    @Slot()
    def clearHistory(self):
        self._history_store.clear()
        self._history = []
        self.historyChanged.emit()

    @Slot(str)
    def openHistoryFile(self, path):
        if path and Path(path).exists():
            os.startfile(path)

    @Slot(str)
    def openHistoryFolder(self, path):
        if path:
            folder = Path(path).parent
            if folder.exists():
                os.startfile(str(folder))

    @Slot(str, "QVariant")
    def setSetting(self, key, value):
        if key not in SettingsStore.DEFAULTS or key == "download_path":
            return
        self._settings_data[key] = value
        self._settings.set_value(key, value)
        self.settingsChanged.emit()

    @Slot()
    def chooseSettingsDownloadFolder(self):
        if self._downloading:
            return
        folder = QFileDialog.getExistingDirectory(None, "Choose default download folder", self._download_path)
        if folder:
            self._download_path = folder
            self._settings_data["download_path"] = folder
            self._settings_data["download_path"] = folder
            self._settings.save_download_path(folder)
            self.downloadPathChanged.emit()
            self.settingsChanged.emit()
            self.settingsChanged.emit()

    @Slot()
    def chooseDownloadFolder(self):
        if self._downloading:
            return
        folder = QFileDialog.getExistingDirectory(None, "Choose download folder", self._download_path)
        if folder:
            self._download_path = folder
            self._settings.save_download_path(folder)
            self.downloadPathChanged.emit()

    @Slot(str)
    def analyze(self, url):
        url = url.strip()
        if not url:
            self._set_error("Paste a media link first.")
            return
        if self._analyzing or self._downloading:
            return
        self._set_error("")
        self._media_info = {}
        self.mediaInfoChanged.emit()
        self._download_result = {}
        self.downloadResultChanged.emit()
        self._analyzing = True
        self.analyzingChanged.emit()

        self._analysis_thread = QThread()
        self._analysis_worker = AnalyzeWorker(url, self._settings_data.get("language", "en"))
        self._analysis_worker.moveToThread(self._analysis_thread)
        self._analysis_thread.started.connect(self._analysis_worker.run)
        self._analysis_worker.finished.connect(self._analysis_finished)
        self._analysis_worker.error.connect(self._analysis_error)
        self._analysis_worker.finished.connect(self._analysis_thread.quit)
        self._analysis_worker.error.connect(self._analysis_thread.quit)
        self._analysis_thread.finished.connect(self._analysis_worker.deleteLater)
        self._analysis_thread.finished.connect(self._analysis_thread.deleteLater)
        self._analysis_thread.finished.connect(self._analysis_cleanup)
        self._analysis_thread.start()

    @Slot(dict)
    def _analysis_finished(self, info):
        self._media_info = info
        self.mediaInfoChanged.emit()
        self._analyzing = False
        self.analyzingChanged.emit()

    @Slot(str)
    def _analysis_error(self, message):
        self._set_error(message)
        self._analyzing = False
        self.analyzingChanged.emit()

    @Slot()
    def _analysis_cleanup(self):
        self._analysis_worker = None
        self._analysis_thread = None

    @Slot(str, bool, "QVariantMap")
    def startDownload(self, url, audio_mode, option):
        if self._downloading or self._analyzing:
            return
        url = (url or "").strip()
        if not url:
            self._set_error("No media URL available.")
            return
        ffmpeg_dir = self._base_dir / "bin"
        if not (ffmpeg_dir / "ffmpeg.exe").exists() or not (ffmpeg_dir / "ffprobe.exe").exists():
            self._set_error("FFmpeg not found. Expected bin\\ffmpeg.exe and bin\\ffprobe.exe")
            return

        self._set_error("")
        self._download_result = {}
        self.downloadResultChanged.emit()
        self._download_progress = self._empty_progress("Starting download...")
        self.downloadProgressChanged.emit()
        self._downloading = True
        self.downloadingChanged.emit()

        self._download_thread = QThread()
        self._download_worker = DownloadWorker(
            url,
            self._download_path,
            option,
            audio_mode,
            ffmpeg_dir,
            self._media_info.get("metadata", {}),
            self._settings_data.get("embed_metadata", True),
            self._settings_data.get("embed_artwork", True),
            self._settings_data.get("language", "en"),
        )
        self._download_worker.moveToThread(self._download_thread)
        self._download_thread.started.connect(self._download_worker.run)
        self._download_worker.progress.connect(self._on_download_progress)
        self._download_worker.finished.connect(self._download_finished)
        self._download_worker.error.connect(self._download_error)
        self._download_worker.cancelled.connect(self._download_cancelled)
        self._download_worker.finished.connect(self._download_thread.quit)
        self._download_worker.error.connect(self._download_thread.quit)
        self._download_worker.cancelled.connect(self._download_thread.quit)
        self._download_thread.finished.connect(self._download_worker.deleteLater)
        self._download_thread.finished.connect(self._download_thread.deleteLater)
        self._download_thread.finished.connect(self._download_cleanup)
        self._download_thread.start()

    @Slot()
    def cancelDownload(self):
        if self._download_worker and self._downloading:
            self._download_progress = {**self._download_progress, "stage": "Cancelling..."}
            self.downloadProgressChanged.emit()
            self._download_worker.cancel()

    @Slot(dict)
    def _on_download_progress(self, progress):
        self._download_progress = progress
        self.downloadProgressChanged.emit()

    @Slot(dict)
    def _download_finished(self, result):
        self._downloading = False
        self.downloadingChanged.emit()
        self._download_progress = {**self._download_progress, "stage": "Done", "percent": 100.0, "speed": 0.0, "eta": 0}
        self.downloadProgressChanged.emit()
        self._download_result = result
        self.downloadResultChanged.emit()
        history_item = dict(result)
        history_item["title"] = self._media_info.get("title", result.get("file_name", ""))
        history_item["uploader"] = self._media_info.get("uploader", "")
        history_item["thumbnail"] = self._media_info.get("thumbnail", "")
        history_item["mode"] = "audio" if getattr(self._download_worker, "audio_mode", True) else "video"
        self._history_store.add(history_item)
        self._history = self._history_store.load()
        self.historyChanged.emit()

    @Slot(str)
    def _download_error(self, message):
        self._downloading = False
        self.downloadingChanged.emit()
        self._set_error(message)
        self._download_progress = {**self._download_progress, "stage": "Download failed"}
        self.downloadProgressChanged.emit()

    @Slot()
    def _download_cancelled(self):
        self._downloading = False
        self.downloadingChanged.emit()
        self._download_progress = self._empty_progress("Cancelled")
        self.downloadProgressChanged.emit()

    @Slot()
    def _download_cleanup(self):
        self._download_worker = None
        self._download_thread = None

    @Slot()
    def openDownloadedFile(self):
        path = self._download_result.get("file_path", "")
        if path and Path(path).exists():
            os.startfile(path)

    @Slot()
    def openDownloadFolder(self):
        path = self._download_result.get("file_path", "")
        folder = Path(path).parent if path else Path(self._download_path)
        if folder.exists():
            os.startfile(str(folder))

    def _set_error(self, message):
        self._error = message
        self.errorChanged.emit()
