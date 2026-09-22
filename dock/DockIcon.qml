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
    required property var config
    required property var theme
    property int iconSize: config.iconSize
    property bool vertical: false     // dock on left/right edge
    property bool dragging: false     // bound by parent for visual state
    property bool _dragging: false    // internal press-drag state
    property bool _dragged: false
    property point _pressPos: Qt.point(0, 0)
    signal clicked()
    signal rightClicked(point pos)
    signal dragMoved(real pos)        // cursor position along dock axis
    signal dragEnded()

    width: vertical ? (parent ? parent.width : iconSize + config.spacing)
                    : iconSize + config.spacing
    height: vertical ? iconSize + config.spacing
                     : (parent ? parent.height : iconSize + config.spacing)

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
        width: root.iconSize + 8
        height: root.iconSize + 8
        radius: 12
        color: mouse.containsMouse ? theme.lighterBackground : "transparent"
        border.width: root.urgent ? 2 : 0
        border.color: theme.red

        Image {
            id: img
            anchors.centerIn: parent
            width: root.iconSize - 10
            height: root.iconSize - 10
            source: root.iconSource
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        // fallback glyph when no themed icon
        Text {
            anchors.centerIn: parent
            visible: img.status === Image.Error || img.status === Image.Null
            text: root.name.length ? root.name[0].toUpperCase() : "?"
            color: theme.foreground
            font.pixelSize: root.iconSize * 0.4
            font.bold: true
        }
    }

    // running indicator — sits outside the tile, on the free-axis edge
    Rectangle {
        visible: root.running
        width: 5
        height: 5
        radius: 2.5
        color: root.urgent ? theme.red : theme.accent
        anchors {
            horizontalCenter: root.vertical ? undefined : root.horizontalCenter
            verticalCenter: root.vertical ? root.verticalCenter : undefined
            bottom: root.vertical ? undefined : root.bottom
            right: root.vertical ? root.right : undefined
            bottomMargin: 1
            rightMargin: 1
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onPressed: {
            root._pressPos = Qt.point(mouseX, mouseY);
            root._dragged = false;
        }
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
            if (!pressed || !root.pinned)
                return;
            const axis = root.vertical ? mouseY - root._pressPos.y
                                       : mouseX - root._pressPos.x;
            if (!root._dragging && Math.abs(axis) < 8)
                return; // drag threshold
            root._dragging = true;
            root.dragMoved(root.vertical ? mouse.mouseY : mouse.mouseX);
        }
        onReleased: {
            if (root._dragging) {
                root._dragging = false;
                root._dragged = true;
                root.dragEnded();
            }
        }
    }
}
