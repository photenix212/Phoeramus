import sys
import os
from pathlib import Path

from PySide6.QtCore import (
    QObject,
    Property,
    Signal,
    Slot,
)
from PySide6.QtGui import QIcon
from PySide6.QtQml import (
    QQmlApplicationEngine,
)
from PySide6.QtWidgets import QApplication

from app.backend import Backend


BASE_DIR = Path(__file__).resolve().parent

# Use a non-native Qt Quick Controls style because Phoeramus customizes controls.
os.environ.setdefault("QT_QUICK_CONTROLS_STYLE", "Basic")


class AppBridge(QObject):
    clipboardTextChanged = Signal()

    def __init__(self):
        super().__init__()

        self._clipboard = (
            QApplication.clipboard()
        )

        self._clipboard.dataChanged.connect(
            self.clipboardTextChanged
        )

    @Property(
        str,
        notify=clipboardTextChanged,
    )
    def clipboardText(self):
        return (
            self._clipboard
            .text()
            .strip()
        )

    @Slot(result=str)
    def pasteClipboard(self):
        return (
            self._clipboard
            .text()
            .strip()
        )


def main():
    app = QApplication(sys.argv)

    app.setApplicationName(
        "Phoeramus"
    )

    app.setOrganizationName(
        "Phoeramus"
    )

    icon_path = (
        BASE_DIR / "icon.png"
    )

    if icon_path.exists():
        app.setWindowIcon(
            QIcon(str(icon_path))
        )

    engine = QQmlApplicationEngine()

    bridge = AppBridge()

    backend = Backend(
        BASE_DIR
    )

    engine.rootContext().setContextProperty(
        "appBridge",
        bridge,
    )

    engine.rootContext().setContextProperty(
        "backend",
        backend,
    )

    qml_file = (
        BASE_DIR
        / "ui"
        / "Main.qml"
    )

    engine.load(qml_file)

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(
        app.exec()
    )


if __name__ == "__main__":
    main()