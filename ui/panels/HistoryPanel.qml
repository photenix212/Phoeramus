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
    width: Math.min(720, Overlay.overlay ? Overlay.overlay.width - 40 : 720)
    height: Math.min(620, Overlay.overlay ? Overlay.overlay.height - 40 : 620)

    property bool ru: (backend.settings.language || "en") === "ru"
    property color surface: "#15171C"
    property color surface2: "#111318"
    property color hover: "#252932"
    property color accent: "#A9C7FF"
    property color textPrimary: "#F5F7FA"
    property color textSecondary: "#A8AFBA"
    property color textMuted: "#707784"
    property color outline: "#30343D"

    Overlay.modal: Rectangle { color: "#99080A0D" }
    background: Rectangle { radius: 22; color: panel.surface; border.width: 1; border.color: panel.outline }

    contentItem: ColumnLayout {
        anchors.fill: parent
        anchors.margins: 22
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 1
                Label { text: panel.ru ? "История" : "History"; color: panel.textPrimary; font.pixelSize: 20; font.bold: true }
                Label { text: panel.ru ? "Последние загрузки" : "Recent downloads"; color: panel.textMuted; font.pixelSize: 11 }
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 105; height: 34; radius: 10
                visible: backend.history.length > 0
                color: clearMouse.containsMouse ? "#342329" : "#251C21"
                Text { anchors.centerIn: parent; text: panel.ru ? "Очистить" : "Clear"; color: "#FF9BA7"; font.pixelSize: 11 }
                MouseArea { id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.clearHistory() }
            }
            Rectangle {
                width: 34; height: 34; radius: 10; color: closeMouse.containsMouse ? panel.hover : "transparent"
                Text { anchors.centerIn: parent; text: "×"; color: panel.textSecondary; font.pixelSize: 22 }
                MouseArea { id: closeMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: panel.close() }
            }
        }

        Rectangle { Layout.fillWidth: true; Layout.preferredHeight: 1; color: panel.outline }

        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.topMargin: 90
            visible: backend.history.length === 0
            text: panel.ru ? "История пока пустая" : "No downloads yet"
            color: panel.textMuted
            font.pixelSize: 13
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: backend.history.length > 0
            clip: true
            spacing: 8
            model: backend.history

            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width
                height: 82
                radius: 14
                color: itemMouse.containsMouse ? "#181B21" : panel.surface2
                border.width: 1
                border.color: "#292D35"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 12

                    Image {
                        Layout.preferredWidth: 92
                        Layout.preferredHeight: 58
                        source: modelData.thumbnail || ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label {
                            Layout.fillWidth: true
                            text: modelData.title || modelData.file_name || ""
                            color: panel.textPrimary
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            elide: Text.ElideRight
                        }
                        Label {
                            Layout.fillWidth: true
                            text: modelData.uploader || modelData.file_name || ""
                            color: panel.textMuted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                        Label {
                            text: (modelData.probe_summary || "") + (modelData.size_text ? "  •  " + modelData.size_text : "")
                            color: panel.textMuted
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        width: 70; height: 34; radius: 10; color: openMouse.containsMouse ? "#29364A" : "#222730"
                        Text { anchors.centerIn: parent; text: panel.ru ? "Файл" : "Open"; color: panel.accent; font.pixelSize: 10 }
                        MouseArea { id: openMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.openHistoryFile(modelData.file_path || "") }
                    }
                    Rectangle {
                        width: 78; height: 34; radius: 10; color: folderMouse.containsMouse ? "#29364A" : "#222730"
                        Text { anchors.centerIn: parent; text: panel.ru ? "Папка" : "Folder"; color: panel.accent; font.pixelSize: 10 }
                        MouseArea { id: folderMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: backend.openHistoryFolder(modelData.file_path || "") }
                    }
                }
                MouseArea { id: itemMouse; anchors.fill: parent; acceptedButtons: Qt.NoButton; hoverEnabled: true }
            }
        }
    }
}
