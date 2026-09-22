import QtQuick

// Omarchy-style slider: thin track, accent fill, round knob.
Item {
    id: root

    required property var theme
    property real from: 0
    property real to: 100
    property real stepSize: 1
    property real value: 0
    signal moved(real value)

    implicitWidth: 200
    implicitHeight: 28

    readonly property real range: Math.max(0.0001, to - from)
    readonly property real progress: Math.max(0, Math.min(1, (value - from) / range))

    function snap(v) {
        const stepped = Math.round((v - from) / stepSize) * stepSize + from;
        return Math.max(from, Math.min(to, stepped));
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        height: 4
        radius: 2
        color: theme.trackFill

        Rectangle {
            width: root.progress * parent.width
            height: parent.height
            radius: 2
            color: theme.accent
        }
    }

    Rectangle {
        id: knob
        x: root.progress * (root.width - width)
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: theme.foreground
        border.color: theme.accent
        border.width: ma.containsMouse || ma.pressed ? 2 : 0
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        onPressed: root.moved(root.snap(root.from + (mouseX / width) * root.range))
        onPositionChanged: {
            if (pressed)
                root.moved(root.snap(root.from + (mouseX / width) * root.range));
        }
    }
}
