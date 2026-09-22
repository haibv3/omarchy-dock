import QtQuick
import QtQuick.Layouts

// Segmented control — Omarchy-style pill group for small option sets.
Rectangle {
    id: root

    required property var theme
    property var options: []          // [{label, value}]
    property var currentValue
    signal selected(var value)

    implicitHeight: 34
    radius: 9
    color: theme.darkerBackground
    border.color: theme.lighterBackground
    border.width: 1
    clip: true

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 3

        Repeater {
            model: root.options
            delegate: Rectangle {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 6
                color: modelData.value === root.currentValue ? theme.accent
                     : segMa.containsMouse ? theme.lighterBackground
                     : "transparent"
                Text {
                    anchors.centerIn: parent
                    text: modelData.label
                    color: modelData.value === root.currentValue
                        ? theme.darkerBackground : theme.foreground
                    font.pixelSize: 12
                    font.bold: modelData.value === root.currentValue
                }
                MouseArea {
                    id: segMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selected(modelData.value)
                }
            }
        }
    }
}
