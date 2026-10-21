import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: panel
    modal: true
    focus: true
    padding: 0
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    anchors.centerIn: Overlay.overlay
    width: Math.min(560, Overlay.overlay ? Overlay.overlay.width - 40 : 560)
    height: Math.min(680, Overlay.overlay ? Overlay.overlay.height - 32 : 680)

    property bool ru: (backend.settings.language || "en") === "ru"
    property color surface: "#15171C"
    property color surfaceStrong: "#20232A"
    property color hover: "#252932"
    property color accent: "#A9C7FF"
    property color textPrimary: "#F5F7FA"
    property color textSecondary: "#A8AFBA"
    property color textMuted: "#707784"
    property color outline: "#30343D"

    Overlay.modal: Rectangle { color: "#99080A0D" }
    background: Rectangle {
        radius: 22
        color: panel.surface
        border.width: 1
        border.color: "#30343D"
    }

    function audioFormatIndex() {
        var value = backend.settings.default_audio_format || "original"
        if (value === "mp3") return 1
        if (value === "m4a") return 2
        return 0
    }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 1
                Label { text: panel.ru ? "Настройки" : "Settings"; color: panel.textPrimary; font.pixelSize: 20; font.bold: true }
                Label { text: panel.ru ? "Настройки Phoeramus" : "Phoeramus preferences"; color: panel.textMuted; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 34; height: 34; radius: 11
                color: closeMouse.containsMouse ? panel.hover : "transparent"
                Text { anchors.centerIn: parent; text: "×"; color: panel.textSecondary; font.pixelSize: 22 }
                MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.close() }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 1; color: panel.outline
        }

        Label { text: panel.ru ? "ЗАГРУЗКА" : "DOWNLOAD"; color: panel.textMuted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.2 }

        ColumnLayout {
            Layout.fillWidth: true; spacing: 7
            Label { text: panel.ru ? "Папка загрузки по умолчанию" : "Default download folder"; color: panel.textSecondary; font.pixelSize: 11 }
            Rectangle {
                Layout.fillWidth: true; Layout.preferredHeight: 46; radius: 13
                color: panel.surfaceStrong; border.width: 1; border.color: panel.outline
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 13; anchors.rightMargin: 6; spacing: 8
                    Label { Layout.fillWidth: true; text: backend.downloadPath; color: panel.textSecondary; font.pixelSize: 11; elide: Text.ElideMiddle }
                    Rectangle {
                        width: 84; height: 34; radius: 10
                        color: folderMouse.containsMouse ? "#29364A" : "#252A33"
                        Text { anchors.centerIn: parent; text: panel.ru ? "Выбрать" : "Browse"; color: panel.accent; font.pixelSize: 11; font.weight: Font.DemiBold }
                        MouseArea { id: folderMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.chooseSettingsDownloadFolder() }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 12
            ColumnLayout {
                Layout.fillWidth: true; spacing: 7
                Label { text: panel.ru ? "Режим при запуске" : "Startup mode"; color: panel.textSecondary; font.pixelSize: 11 }
                ComboBox {
                    id: startupMode
                    Layout.fillWidth: true; Layout.preferredHeight: 44
                    model: panel.ru ? ["Аудио", "Видео"] : ["Audio", "Video"]
                    currentIndex: (backend.settings.startup_mode || "audio") === "video" ? 1 : 0
                    onActivated: backend.setSetting("startup_mode", currentIndex === 1 ? "video" : "audio")
                    contentItem: Text { leftPadding: 13; text: startupMode.displayText; color: panel.textPrimary; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 13; color: startupMode.hovered ? panel.hover : panel.surfaceStrong; border.width: 1; border.color: panel.outline }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 7
                Label { text: panel.ru ? "Аудиоформат по умолчанию" : "Default audio format"; color: panel.textSecondary; font.pixelSize: 11 }
                ComboBox {
                    id: audioFormat
                    Layout.fillWidth: true; Layout.preferredHeight: 44
                    model: ["Original", "MP3 320", "M4A"]
                    Component.onCompleted: currentIndex = panel.audioFormatIndex()
                    onActivated: {
                        var values = ["original", "mp3", "m4a"]
                        backend.setSetting("default_audio_format", values[currentIndex])
                    }
                    contentItem: Text { leftPadding: 13; text: audioFormat.displayText; color: panel.textPrimary; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 13; color: audioFormat.hovered ? panel.hover : panel.surfaceStrong; border.width: 1; border.color: panel.outline }
                }
            }
        }


        ColumnLayout {
            Layout.fillWidth: true; spacing: 7
            Label { text: panel.ru ? "Язык интерфейса" : "Interface language"; color: panel.textSecondary; font.pixelSize: 11 }
            ComboBox {
                id: languageBox
                Layout.fillWidth: true; Layout.preferredHeight: 44
                model: ["English", "Русский"]
                currentIndex: (backend.settings.language || "en") === "ru" ? 1 : 0
                onActivated: backend.setSetting("language", currentIndex === 1 ? "ru" : "en")
                contentItem: Text { leftPadding: 13; text: languageBox.displayText; color: panel.textPrimary; verticalAlignment: Text.AlignVCenter }
                background: Rectangle { radius: 13; color: languageBox.hovered ? panel.hover : panel.surfaceStrong; border.width: 1; border.color: panel.outline }
            }
        }

        Label { text: panel.ru ? "МЕТАДАННЫЕ И ОБЛОЖКА" : "METADATA & ARTWORK"; color: panel.textMuted; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.2 }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 58; radius: 14
            color: "#111318"; border.width: 1; border.color: "#292D35"
            RowLayout {
                anchors.fill: parent; anchors.margins: 13
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Label { text: panel.ru ? "Встраивать метаданные" : "Embed metadata"; color: panel.textPrimary; font.pixelSize: 12; font.weight: Font.Medium }
                    Label { text: panel.ru ? "Название, исполнитель, альбом и год, если доступны" : "Title, artist, album and year when available"; color: panel.textMuted; font.pixelSize: 10 }
                }
                Rectangle {
                    id: metadataSwitch
                    width: 48; height: 26; radius: 13
                    property bool checked: backend.settings.embed_metadata === undefined ? true : backend.settings.embed_metadata
                    color: checked ? panel.accent : "#3A3D43"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        y: 3
                        x: metadataSwitch.checked ? 25 : 3
                        color: metadataSwitch.checked ? "#101318" : "#F5F7FA"
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.setSetting("embed_metadata", !metadataSwitch.checked)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 58; radius: 14
            color: "#111318"; border.width: 1; border.color: "#292D35"
            RowLayout {
                anchors.fill: parent; anchors.margins: 13
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 2
                    Label { text: panel.ru ? "Встраивать обложку" : "Embed cover artwork"; color: panel.textPrimary; font.pixelSize: 12; font.weight: Font.Medium }
                    Label { text: panel.ru ? "Встраивать исходную обложку YouTube в аудиофайл" : "Use the original YouTube thumbnail inside audio files"; color: panel.textMuted; font.pixelSize: 10 }
                }
                Rectangle {
                    id: artworkSwitch
                    width: 48; height: 26; radius: 13
                    property bool checked: backend.settings.embed_artwork === undefined ? true : backend.settings.embed_artwork
                    color: checked ? panel.accent : "#3A3D43"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Rectangle {
                        width: 20; height: 20; radius: 10
                        y: 3
                        x: artworkSwitch.checked ? 25 : 3
                        color: artworkSwitch.checked ? "#101318" : "#F5F7FA"
                        Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.setSetting("embed_artwork", !artworkSwitch.checked)
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true; Layout.preferredHeight: 68; radius: 14
            color: "#111318"; border.width: 1; border.color: "#292D35"
            RowLayout {
                anchors.fill: parent; anchors.margins: 13
                ColumnLayout {
                    spacing: 2
                    Label { text: "Phoeramus"; color: panel.textPrimary; font.pixelSize: 12; font.bold: true }
                    Label { text: panel.ru ? "Загрузчик медиа для Windows" : "Desktop media downloader"; color: panel.textMuted; font.pixelSize: 10 }
                    Label { text: "yt-dlp + FFmpeg"; color: panel.textMuted; font.pixelSize: 10 }
                }
                Item { Layout.fillWidth: true }
                Label { text: panel.ru ? "Настройки сохраняются автоматически" : "Settings are saved automatically"; color: panel.textMuted; font.pixelSize: 10 }
            }
        }
    }
}
