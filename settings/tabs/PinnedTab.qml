import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../ui"

// Settings → Pinned apps: the ordered pin list plus the app picker.
ColumnLayout {
    id: root

    required property var config
    required property var theme

    function iconSource(entry) {
        if (!entry || !entry.icon)
            return "";
        const p = Quickshell.iconPath(entry.icon);
        if (!p)
            return "";
        return p.indexOf("://") !== -1 ? p : "file://" + p;
    }

    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 14
        spacing: 12

        DSectionLabel {
            theme: root.theme
            label: "PINNED"
            Layout.fillWidth: true
        }

        Text {
            text: root.config.pinned.length
                  + (root.config.pinned.length === 1 ? " app" : " apps")
            color: root.theme.mutedText
            font.pixelSize: 11
            font.family: root.theme.fontMono
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: root.config.pinned

            delegate: Rectangle {
                required property string modelData

                Layout.fillWidth: true
                implicitHeight: 40
                radius: root.theme.radiusControl
                color: rowMa.containsMouse ? root.theme.hoverFill : root.theme.normalFill

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 10

                    Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: root.iconSource(DesktopEntries.byId(modelData))
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            const e = DesktopEntries.byId(modelData);
                            return e ? e.name : modelData;
                        }
                        color: root.theme.foreground
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: root.theme.radiusControl
                        color: unpinMa.containsMouse
                            ? Qt.rgba(root.theme.brightRed.r, root.theme.brightRed.g,
                                      root.theme.brightRed.b, 0.14)
                            : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(0xF0156)
                            color: unpinMa.containsMouse
                                ? root.theme.brightRed : root.theme.mutedText
                            font.pixelSize: 12
                            font.family: root.theme.fontMono
                        }

                        MouseArea {
                            id: unpinMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.config.unpin(modelData)
                        }
                    }
                }

                MouseArea {
                    id: rowMa
                    anchors.fill: parent
                    anchors.rightMargin: 36
                    hoverEnabled: true
                }
            }
        }

        Text {
            visible: root.config.pinned.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 2
            text: "Nothing pinned yet — pick apps below."
            color: root.theme.mutedText
            font.pixelSize: 12
        }
    }

    Text {
        visible: root.config.pinned.length > 1
        Layout.fillWidth: true
        Layout.topMargin: 10
        text: "Drag icons in the dock to reorder them."
        color: root.theme.mutedText
        font.pixelSize: 11
    }

    DSectionLabel {
        theme: root.theme
        label: "ADD APPS"
        Layout.topMargin: 30
        Layout.bottomMargin: 14
    }

    DField {
        id: filter
        theme: root.theme
        Layout.fillWidth: true
        placeholder: "Search applications…"
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 10
        Layout.preferredHeight: 260
        radius: root.theme.radiusControl
        color: root.theme.darkerBackground
        border.color: root.theme.borderFill
        border.width: 1
        clip: true

        ListView {
            id: appList
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2
            model: {
                const q = filter.text.toLowerCase();
                const out = [];
                for (const e of DesktopEntries.applications.values) {
                    if (e.noDisplay)
                        continue;
                    if (q !== "" && e.name.toLowerCase().indexOf(q) === -1)
                        continue;
                    out.push(e);
                }
                out.sort((a, b) => a.name.localeCompare(b.name));
                return out;
            }

            delegate: Rectangle {
                required property var modelData

                width: appList.width
                height: 34
                radius: root.theme.radiusControl
                color: addMa.containsMouse ? root.theme.hoverFill : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 10
                    spacing: 10

                    Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: root.iconSource(modelData)
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: root.config.isPinned(modelData.id)
                            ? root.theme.mutedText : root.theme.foreground
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.config.isPinned(modelData.id)
                        text: "pinned"
                        color: root.theme.accent
                        font.pixelSize: 11
                        font.family: root.theme.fontMono
                    }

                    Text {
                        visible: !root.config.isPinned(modelData.id) && addMa.containsMouse
                        text: String.fromCodePoint(0xF0415)
                        color: root.theme.accent
                        font.pixelSize: 13
                        font.family: root.theme.fontMono
                    }
                }

                MouseArea {
                    id: addMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.config.isPinned(modelData.id)
                    onClicked: root.config.pin(modelData.id)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: appList.count === 0
            text: "No applications match."
            color: root.theme.mutedText
            font.pixelSize: 12
        }
    }
}
