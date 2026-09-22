import QtQuick
import QtQuick.Layouts

// Omarchy-style spinbox: − value + in a bordered pill.
Rectangle {
    id: root

    required property var theme
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property int value: 0
    property string suffix: ""
    signal valueModified(int value)

    implicitWidth: 130
    implicitHeight: 34
    radius: 9
    color: theme.darkerBackground
    border.color: theme.lighterBackground
    border.width: 1

    function setValue(v) {
        const nv = Math.max(from, Math.min(to, v));
        if (nv !== value)
            root.valueModified(nv);
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 3
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            radius: 6
            color: minusMa.containsMouse ? theme.lighterBackground : "transparent"
            Text {
                anchors.centerIn: parent
                text: "−"
                color: theme.foreground
                font.pixelSize: 14
            }
            MouseArea {
                id: minusMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setValue(root.value - root.stepSize)
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: root.value + root.suffix
            color: theme.foreground
            font.pixelSize: 13
        }

        Rectangle {
            Layout.preferredWidth: 30
            Layout.fillHeight: true
            radius: 6
            color: plusMa.containsMouse ? theme.lighterBackground : "transparent"
            Text {
                anchors.centerIn: parent
                text: "+"
                color: theme.foreground
                font.pixelSize: 14
            }
            MouseArea {
                id: plusMa
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.setValue(root.value + root.stepSize)
            }
        }
    }
}
