import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QC

// Omarchy-style dropdown: bordered pill + overlay Popup (escapes
// Flickable clipping and window-edge overflow).
Rectangle {
    id: root

    required property var theme
    property var model: []            // [{label, value}]
    property var currentValue
    property string placeholder: "Select…"
    signal selected(var value)

    implicitHeight: 34
    radius: 9
    color: theme.darkerBackground
    border.color: popup.opened ? theme.accent : theme.borderFill
    border.width: 1

    readonly property string currentLabel: {
        for (const o of model)
            if (o.value === currentValue)
                return o.label;
        return placeholder;
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        Text {
            Layout.fillWidth: true
            text: root.currentLabel
            color: theme.foreground
            font.pixelSize: 13
            elide: Text.ElideRight
        }
        Text {
            text: popup.opened ? "▴" : "▾"
            color: theme.darkForeground
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: popup.opened ? popup.close() : popup.open()
    }

    QC.Popup {
        id: popup
        y: root.height + 4
        width: root.width
        height: Math.min(list.contentHeight, 220) + 8
        padding: 4

        background: Rectangle {
            radius: 9
            color: root.theme.darkerBackground
            border.color: root.theme.borderFill
            border.width: 1
        }

        contentItem: ListView {
            id: list
            model: root.model
            clip: true
            delegate: Rectangle {
                required property var modelData
                width: list.width
                height: 30
                radius: 6
                color: itemMa.containsMouse ? root.theme.hoverFill
                                            : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    width: parent.width - 20
                    text: modelData.label
                    color: modelData.value === root.currentValue
                        ? root.theme.accent : root.theme.foreground
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.selected(modelData.value);
                        popup.close();
                    }
                }
            }
        }
    }
}
