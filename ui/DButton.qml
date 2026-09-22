import QtQuick

// Omarchy-style button: transparent idle, hoverFill on hover,
// accent fill when selected/pressed.
Rectangle {
    id: root

    required property var theme
    property string text: ""
    property bool selected: false
    property bool danger: false
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 32
    radius: 8

    color: {
        if (ma.pressed)
            return theme.selection;
        if (root.selected)
            return theme.accent;
        if (ma.containsMouse)
            return theme.hoverFill;
        return "transparent";
    }
    border.width: root.selected ? 0 : 1
    border.color: theme.borderFill

    Text {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.selected ? theme.darkerBackground
             : root.danger ? theme.brightRed
             : theme.foreground
        font.pixelSize: 13
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
