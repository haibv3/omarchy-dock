import QtQuick
import QtQuick.Layouts

// Omarchy-style dropdown: bordered pill + inline popup list below.
Rectangle {
    id: root

    required property var theme
    property var model: []            // [{label, value}]
    property var currentValue
    property string placeholder: "Select…"
    signal selected(var value)

    property bool open: false

    implicitHeight: 34
    radius: 9
    color: theme.darkerBackground
    border.color: root.open ? theme.accent : theme.lighterBackground
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
            text: root.open ? "▴" : "▾"
            color: theme.darkForeground
            font.pixelSize: 11
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open = !root.open
    }

    // dropdown list — overlays content below, parent must not clip
    Rectangle {
        id: popup
        visible: root.open
        anchors.top: parent.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.min(col.implicitHeight, 200)
        radius: 9
        color: theme.darkerBackground
        border.color: theme.muted
        border.width: 1
        clip: true
        z: 100

        ListView {
            id: col
            anchors.fill: parent
            model: root.model
            delegate: Rectangle {
                required property var modelData
                width: col.width
                height: 30
                color: itemMa.containsMouse ? theme.lighterBackground : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: modelData.label
                    color: modelData.value === root.currentValue
                        ? theme.accent : theme.foreground
                    font.pixelSize: 12
                }
                MouseArea {
                    id: itemMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.selected(modelData.value);
                        root.open = false;
                    }
                }
            }
        }
    }
}
