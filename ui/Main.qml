import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import "panels"

ApplicationWindow {
    id: window
    width: 1120
    height: 720
    minimumWidth: 820
    minimumHeight: 600
    visible: true
    title: "Phoeramus"

    property color appBackground: "#0C0D10"
    property color surface: "#15171C"
    property color surfaceHover: "#1C1F25"
    property color surfaceStrong: "#22252D"
    property color accent: "#A9C7FF"
    property color accentHover: "#BDD5FF"
    property color accentPressed: "#91B5F7"
    property color textPrimary: "#F5F7FA"
    property color textSecondary: "#A8AFBA"
    property color textMuted: "#707784"
    property color outline: "#30343D"
    color: appBackground

    Component.onCompleted: {
        mediaSelector.audioSelected = (backend.settings.startup_mode || "audio") !== "video"
    }

    Connections {
        target: backend
        function onMediaInfoChanged() { Qt.callLater(window.applyDefaultAudioFormat) }
        function onSettingsChanged() {
            mediaSelector.audioSelected = (backend.settings.startup_mode || "audio") !== "video"
            Qt.callLater(window.applyDefaultAudioFormat)
        }
    }

    function hasMedia() { return !!(backend.mediaInfo && backend.mediaInfo.title) }
    function currentOptions() {
        if (!hasMedia()) return []
        return mediaSelector.audioSelected ? (backend.mediaInfo.audio_options || []) : (backend.mediaInfo.video_options || [])
    }
    function applyDefaultAudioFormat() {
        if (!mediaSelector.audioSelected || !hasMedia()) return
        var wanted = backend.settings.default_audio_format || "original"
        var items = backend.mediaInfo.audio_options || []
        for (var i = 0; i < items.length; ++i) {
            if ((items[i].mode || "") === wanted) {
                formatBox.currentIndex = i
                return
            }
        }
        formatBox.currentIndex = 0
    }
    function formatBytes(value) {
        if (!value || value <= 0) return "—"
        var units = ["B", "KiB", "MiB", "GiB"]
        var size = value, index = 0
        while (size >= 1024 && index < units.length - 1) { size /= 1024; index++ }
        return size.toFixed(index >= 2 ? 1 : 0) + " " + units[index]
    }
    function formatEta(seconds) {
        if (!seconds || seconds <= 0) return "—"
        var h = Math.floor(seconds / 3600)
        var m = Math.floor((seconds % 3600) / 60)
        var s = Math.floor(seconds % 60)
        if (h > 0) return h + ":" + (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
        return m + ":" + (s < 10 ? "0" : "") + s
    }
    function inspectorSummary() {
        var i = backend.downloadResult.inspection || {}, parts = []
        if (i.video) {
            var v = i.video, vt = (v.codec || "Video").toUpperCase()
            if (v.width && v.height) vt += " • " + v.width + "×" + v.height
            if (v.fps) vt += " • " + Math.round(v.fps) + " FPS"
            parts.push(vt)
        }
        if (i.audio) {
            var a = i.audio, at = (a.codec || "Audio").toUpperCase()
            if (a.bit_rate) at += " • " + Math.round(a.bit_rate / 1000) + " kbps"
            if (a.sample_rate) at += " • " + (a.sample_rate / 1000).toFixed(a.sample_rate % 1000 ? 1 : 0) + " kHz"
            if (a.channel_layout) at += " • " + a.channel_layout.charAt(0).toUpperCase() + a.channel_layout.slice(1)
            parts.push(at)
        }
        return parts.join("   |   ")
    }
    function inspectorSizeDuration() {
        var i = backend.downloadResult.inspection || {}, parts = []
        if (i.duration) parts.push(formatEta(i.duration))
        if (i.size) parts.push(formatBytes(i.size))
        return parts.join(" • ")
    }


    Rectangle {
        id: historyButton
        width: 38
        height: 38
        radius: 12
        anchors.top: parent.top
        anchors.topMargin: 35
        anchors.right: parent.right
        anchors.rightMargin: 86
        color: historyMouse.containsMouse ? surfaceHover : "transparent"
        z: 20
        Text {
            anchors.centerIn: parent
            text: "↺"
            color: textSecondary
            font.pixelSize: 21
        }
        MouseArea {
            id: historyMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: historyPanel.open()
        }
        ToolTip.visible: historyMouse.containsMouse
        ToolTip.text: (backend.settings.language || "en") === "ru" ? "История" : "History"
    }

    Rectangle {
        anchors.fill: parent
        color: window.appBackground
        Rectangle {
            width: Math.max(parent.width * 0.62, 560); height: width
            x: parent.width - width * 0.48; y: -height * 0.68
            radius: width / 2; color: "#101B2B"; opacity: 0.38
        }
    }

    ScrollView {
        id: pageScroll
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: mainLayout.implicitHeight + 42
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: ScrollBar.AlwaysOff
        Component.onCompleted: contentItem.boundsBehavior = Flickable.StopAtBounds

        ColumnLayout {
            id: mainLayout
            property real pageMargin: Math.max(24, Math.min(46, window.width * 0.04))
            x: pageMargin; y: 22
            width: Math.max(0, pageScroll.width - pageMargin * 2)
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 1
                    Label { text: "PHOERAMUS"; color: window.textPrimary; font.pixelSize: 19; font.bold: true; font.letterSpacing: 2.2 }
                    Label { text: (backend.settings.language || "en") === "ru" ? "Загрузчик медиа" : "Media downloader"; color: window.textMuted; font.pixelSize: 11 }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 36; height: 36; radius: 12
                    color: settingsMouse.containsMouse ? window.surfaceHover : "transparent"
                    Text { anchors.centerIn: parent; text: "⚙"; color: window.textSecondary; font.pixelSize: 17 }
                    MouseArea { id: settingsMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: settingsPanel.open() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: workContent.implicitHeight + 32
                radius: 24; color: "#CC15171C"; border.width: 1; border.color: "#292D35"

                ColumnLayout {
                    id: workContent
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.margins: 16
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true; spacing: 10
                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredHeight: 50; radius: 15
                            color: urlInput.activeFocus ? "#20232A" : window.surfaceStrong
                            border.width: urlInput.activeFocus ? 2 : 1
                            border.color: urlInput.activeFocus ? window.accent : window.outline
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 6; spacing: 8
                                Text { text: "↗"; color: window.textMuted; font.pixelSize: 16 }
                                TextField {
                                    id: urlInput; Layout.fillWidth: true; Layout.fillHeight: true
                                    placeholderText: (backend.settings.language || "en") === "ru" ? "Вставьте ссылку YouTube или медиа..." : "Paste a YouTube or media link..."; placeholderTextColor: window.textMuted
                                    color: window.textPrimary; font.pixelSize: 13; selectByMouse: true; background: Item {}
                                    onAccepted: if (!backend.analyzing && !backend.downloading) backend.analyze(text)
                                }
                                Rectangle {
                                    width: 38; height: 38; radius: 12
                                    color: pasteMouse.pressed ? "#34445E" : pasteMouse.containsMouse ? "#29364A" : "#252A33"
                                    Text { anchors.centerIn: parent; text: "▣"; color: window.accent; font.pixelSize: 17 }
                                    MouseArea {
                                        id: pasteMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: { urlInput.forceActiveFocus(); urlInput.selectAll(); urlInput.paste() }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 132; Layout.preferredHeight: 50; radius: 15
                            color: analyzeMouse.pressed ? window.accentPressed : analyzeMouse.containsMouse ? window.accentHover : window.accent
                            Row { anchors.centerIn: parent; spacing: 7
                                Text { text: backend.analyzing ? "…" : "↳"; color: "#101319"; font.pixelSize: 16; font.bold: true }
                                Text { text: backend.analyzing ? "Analyzing" : "Analyze"; color: "#101319"; font.pixelSize: 13; font.weight: Font.DemiBold }
                            }
                            MouseArea {
                                id: analyzeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                enabled: !backend.analyzing && !backend.downloading
                                onClicked: backend.analyze(urlInput.text)
                            }
                        }
                    }

                    Rectangle {
                        id: mediaSelector
                        property bool audioSelected: true
                        Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: 330; Layout.preferredHeight: 44
                        radius: 15; color: "#20232A"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 4; spacing: 4
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                                color: mediaSelector.audioSelected ? window.accent : "transparent"
                                Row { anchors.centerIn: parent; spacing: 7
                                    Text { text: "♪"; color: mediaSelector.audioSelected ? "#101319" : window.textSecondary; font.pixelSize: 14 }
                                    Text { text: "Audio"; color: mediaSelector.audioSelected ? "#101319" : window.textSecondary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mediaSelector.audioSelected = true; formatBox.currentIndex = 0 } }
                            }
                            Rectangle {
                                Layout.fillWidth: true; Layout.fillHeight: true; radius: 12
                                color: !mediaSelector.audioSelected ? window.accent : "transparent"
                                Row { anchors.centerIn: parent; spacing: 7
                                    Text { text: "▶"; color: !mediaSelector.audioSelected ? "#101319" : window.textSecondary; font.pixelSize: 11 }
                                    Text { text: "Video"; color: !mediaSelector.audioSelected ? "#101319" : window.textSecondary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { mediaSelector.audioSelected = false; formatBox.currentIndex = 0 } }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: hasMedia()
                        spacing: 14

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            Layout.preferredHeight: 224; radius: 18
                            color: "#111318"; border.width: 1; border.color: "#292D35"
                            RowLayout {
                                anchors.fill: parent; anchors.margins: 12; spacing: 14
                                Rectangle {
                                    Layout.preferredWidth: 220; Layout.fillHeight: true; radius: 13; color: "#20232A"; clip: true
                                    Image { anchors.fill: parent; source: hasMedia() ? backend.mediaInfo.thumbnail : ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
                                }
                                ColumnLayout {
                                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 5
                                    Item { Layout.fillHeight: true }
                                    Label { Layout.fillWidth: true; text: hasMedia() ? backend.mediaInfo.title : ""; color: window.textPrimary; font.pixelSize: 16; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; maximumLineCount: 3; elide: Text.ElideRight }
                                    Label { Layout.fillWidth: true; text: hasMedia() ? backend.mediaInfo.uploader : ""; color: window.textSecondary; font.pixelSize: 12; elide: Text.ElideRight }
                                    Label { text: hasMedia() ? backend.mediaInfo.duration_text : ""; color: window.textMuted; font.pixelSize: 11 }
                                    Item { Layout.fillHeight: true }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; Layout.preferredWidth: 1
                            Layout.preferredHeight: 224; radius: 18
                            color: "#111318"; border.width: 1; border.color: "#292D35"
                            ColumnLayout {
                                anchors.fill: parent; anchors.margins: 14; spacing: 7
                                Label { text: mediaSelector.audioSelected ? "Audio format" : "Video quality"; color: window.textSecondary; font.pixelSize: 11; font.weight: Font.Medium }
                                ComboBox {
                                    id: formatBox; Layout.fillWidth: true; Layout.preferredHeight: 44
                                    model: currentOptions(); textRole: "name"; font.pixelSize: 12
                                    contentItem: Text { leftPadding: 13; text: formatBox.displayText; color: window.textPrimary; verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight }
                                    background: Rectangle { radius: 13; color: formatBox.hovered ? "#252932" : "#20232A"; border.width: 1; border.color: formatBox.activeFocus ? window.accent : window.outline }
                                }
                                Label {
                                    Layout.fillWidth: true; color: window.textMuted; font.pixelSize: 10; elide: Text.ElideRight
                                    text: { var items = currentOptions(); if (items.length === 0 || formatBox.currentIndex < 0 || formatBox.currentIndex >= items.length) return ""; return items[formatBox.currentIndex].detail || "" }
                                }
                                Label { text: (backend.settings.language || "en") === "ru" ? "Сохранить в" : "Save to"; color: window.textSecondary; font.pixelSize: 11; font.weight: Font.Medium }
                                Rectangle {
                                    Layout.fillWidth: true; Layout.preferredHeight: 44; radius: 13; color: "#20232A"; border.width: 1; border.color: window.outline
                                    RowLayout {
                                        anchors.fill: parent; anchors.leftMargin: 13; anchors.rightMargin: 5; spacing: 6
                                        Label { Layout.fillWidth: true; text: backend.downloadPath; color: window.textSecondary; font.pixelSize: 11; elide: Text.ElideMiddle }
                                        Rectangle {
                                            width: 34; height: 34; radius: 10; color: folderMouse.containsMouse ? "#29364A" : "#252A33"
                                            Text { anchors.centerIn: parent; text: "▣"; color: window.accent; font.pixelSize: 14 }
                                            MouseArea { id: folderMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.chooseDownloadFolder() }
                                        }
                                    }
                                }
                                Item { Layout.fillHeight: true }
                                Rectangle {
                                    Layout.alignment: Qt.AlignRight; Layout.preferredWidth: 172; Layout.preferredHeight: 44; radius: 14
                                    color: downloadMouse.pressed ? window.accentPressed : downloadMouse.containsMouse ? window.accentHover : window.accent
                                    Row { anchors.centerIn: parent; spacing: 7
                                        Text { text: "↓"; color: "#101319"; font.pixelSize: 16; font.bold: true }
                                        Text { text: backend.downloading ? "Downloading..." : "Download"; color: "#101319"; font.pixelSize: 13; font.weight: Font.DemiBold }
                                    }
                                    MouseArea {
                                        id: downloadMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; enabled: !backend.downloading
                                        onClicked: { var items = currentOptions(); if (formatBox.currentIndex < 0 || formatBox.currentIndex >= items.length) return; backend.startDownload(backend.mediaInfo.webpage_url || urlInput.text, mediaSelector.audioSelected, items[formatBox.currentIndex]) }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: backend.downloading || !!backend.downloadResult.file_name ? (backend.downloading ? 100 : 92) : 0
                        visible: backend.downloading || !!backend.downloadResult.file_name
                        radius: 16; color: "#111318"; border.width: 1; border.color: "#292D35"
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 13; spacing: 14
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 5
                                Label { Layout.fillWidth: true; text: backend.downloading ? (backend.downloadProgress.stage || "Downloading...") : "✓ Download complete"; color: window.textPrimary; font.pixelSize: 13; font.weight: Font.DemiBold }
                                ProgressBar { Layout.fillWidth: true; from: 0; to: 100; value: backend.downloadProgress.percent || 0; visible: backend.downloading }
                                Label {
                                    Layout.fillWidth: true; visible: backend.downloading; color: window.textMuted; font.pixelSize: 10
                                    text: { var p = backend.downloadProgress; var sizeText = formatBytes(p.downloaded); if (p.total > 0) sizeText += " / " + formatBytes(p.total); var speedText = p.speed > 0 ? formatBytes(p.speed) + "/s" : "—"; return Math.round(p.percent || 0) + "%  •  " + sizeText + "  •  " + speedText + "  •  ETA " + formatEta(p.eta) }
                                }
                                Label { Layout.fillWidth: true; visible: !backend.downloading && !!backend.downloadResult.file_name; text: backend.downloadResult.file_name || ""; color: window.textSecondary; font.pixelSize: 11; elide: Text.ElideMiddle }
                                Label { Layout.fillWidth: true; visible: !backend.downloading && inspectorSummary().length > 0; text: inspectorSummary() + (inspectorSizeDuration().length > 0 ? "   •   " + inspectorSizeDuration() : ""); color: window.textMuted; font.pixelSize: 10; elide: Text.ElideRight }
                            }
                            RowLayout {
                                spacing: 7
                                Button { visible: backend.downloading; text: (backend.settings.language || "en") === "ru" ? "Отмена" : "Cancel"; onClicked: backend.cancelDownload() }
                                Button { visible: !backend.downloading && !!backend.downloadResult.file_name; text: (backend.settings.language || "en") === "ru" ? "Открыть файл" : "Open file"; onClicked: backend.openDownloadedFile() }
                                Button { visible: !backend.downloading && !!backend.downloadResult.file_name; text: (backend.settings.language || "en") === "ru" ? "Открыть папку" : "Open folder"; onClicked: backend.openDownloadFolder() }
                            }
                        }
                    }

                    Rectangle {
                        id: logPanel
                        Layout.fillWidth: true; Layout.preferredHeight: logExpanded ? 88 : 38
                        radius: 13; color: "#111318"; border.width: 1; border.color: "#262A31"
                        property bool logExpanded: false
                        Connections { target: backend; function onErrorChanged() { if (backend.error.length > 0) logPanel.logExpanded = true } }
                        Column {
                            anchors.fill: parent; anchors.leftMargin: 13; anchors.rightMargin: 13; spacing: 1
                            Item {
                                width: parent.width; height: 36
                                Row { anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Text { text: "●"; color: backend.error.length > 0 ? "#FF7B7B" : backend.analyzing ? "#FFD479" : "#72D69B"; font.pixelSize: 8 }
                                    Text { text: backend.downloading ? (backend.downloadProgress.stage || "Downloading...") : backend.analyzing ? "Analyzing media..." : backend.error.length > 0 ? "Error" : hasMedia() ? "Media ready" : "Ready"; color: window.textSecondary; font.pixelSize: 11 }
                                }
                                Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: logPanel.logExpanded ? "⌃" : "⌄"; color: window.textMuted; font.pixelSize: 15 }
                                MouseArea { anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: logPanel.logExpanded = !logPanel.logExpanded }
                            }
                            Text {
                                visible: logPanel.logExpanded; width: parent.width; color: window.textMuted; font.family: "Consolas"; font.pixelSize: 10; wrapMode: Text.Wrap
                                text: backend.error.length > 0 ? backend.error : backend.analyzing ? "Reading media information with yt-dlp..." : hasMedia() ? backend.mediaInfo.title + "\n" + backend.mediaInfo.uploader + "  •  " + backend.mediaInfo.duration_text : "Phoeramus is ready."
                            }
                        }
                    }
                }
            }

            Label { Layout.alignment: Qt.AlignRight; text: "yt-dlp engine"; color: window.textMuted; font.pixelSize: 9 }
        }
    }

    HistoryPanel {
        id: historyPanel
    }

    SettingsPanel {
        id: settingsPanel
    }
}
