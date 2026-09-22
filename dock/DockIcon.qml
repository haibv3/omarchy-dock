import QtQuick
import Quickshell
import "../services"

Item {
    id: root

    // ListModel roles injected by the ListView delegate context
    required property string desktopId
    required property string appId
    required property string name
    required property string icon
    required property bool running
    required property bool urgent
    required property bool pinned
    required property int index
    property int iconSize: Config.iconSize
    property bool vertical: false     // dock on left/right edge
    property bool dragging: false
    property bool _dragged: false
    signal clicked()
    signal rightClicked(point pos)
    signal dragMoved(real pos)        // cursor position along dock axis
    signal dragEnded()

    width: vertical ? parent.width : iconSize + Config.spacing
    height: vertical ? iconSize + Config.spacing : parent.height

    readonly property string iconSource: {
        const icon = root.icon;
        if (icon === "")
            return "";
        const p = Quickshell.iconPath(icon);
        if (p === "")
            return "";
        return p.indexOf("://") !== -1 ? p : "file://" + p;
    }

    Rectangle {
        id: tile
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        radius: 10
        color: mouse.containsMouse ? Theme.lighterBackground : "transparent"
        border.width: root.urgent ? 2 : 0
        border.color: Theme.red

        Image {
            id: img
            anchors.centerIn: parent
            width: root.iconSize - 8
            height: root.iconSize - 8
            source: root.iconSource
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: root.running || root.pinned ? 1.0 : 0.85
        }

        // fallback glyph when no themed icon
        Text {
            anchors.centerIn: parent
            visible: img.status === Image.Error || img.status === Image.Null
            text: root.name.length ? root.name[0].toUpperCase() : "?"
            color: Theme.foreground
            font.pixelSize: root.iconSize * 0.4
            font.bold: true
        }

        // running indicator
        Rectangle {
            visible: root.running
            width: 5
            height: 5
            radius: 2.5
            color: root.urgent ? Theme.red : Theme.accent
            anchors {
                horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
                verticalCenter: root.vertical ? parent.verticalCenter : undefined
                bottom: root.vertical ? undefined : parent.bottom
                right: root.vertical ? parent.right : undefined
                bottomMargin: 1
                rightMargin: 1
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: btn => {
            if (root._dragged) {
                root._dragged = false;
                return;
            }
            if (btn.button === Qt.RightButton)
                root.rightClicked(Qt.point(mouse.mouseX, mouse.mouseY));
            else
                root.clicked();
        }
        onPositionChanged: {
            if (pressed && root.pinned) {
                root.dragging = true;
                root.dragMoved(root.vertical ? mouse.mouseY : mouse.mouseX);
            }
        }
        onReleased: {
            if (root.dragging) {
                root.dragging = false;
                root._dragged = true;
                root.dragEnded();
            }
        }
    }
}
