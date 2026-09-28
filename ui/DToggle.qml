import QtQuick

// Omarchy-style switch: pill track + sliding knob, accent when on.
Rectangle {
    id: root

    required property var theme
    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 44
    implicitHeight: 24
    radius: height / 2   // pill track
    color: root.checked ? theme.accent : theme.trackFill

    Behavior on color { ColorAnimation { duration: 120 } }

    Rectangle {
        id: knob
        y: 3
        width: 18
        height: 18
        radius: width / 2    // round knob
        color: root.checked ? theme.darkerBackground : theme.foreground
        x: root.checked ? root.width - width - 3 : 3
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
