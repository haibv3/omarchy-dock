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
        width: root.iconSize + 2
        height: root.iconSize + 2
        radius: theme.radiusControl
        color: mouse.containsMouse ? theme.hoverFill : "transparent"
        border.width: root.urgent ? 2 : 0
        border.color: theme.brightRed
        Image {
            id: img
            anchors.centerIn: parent
            width: root.iconSize - 4
            height: root.iconSize - 4
            source: root.iconSource
            // Decode at physical pixels like the bar's Tray.qml does:
            // logical×2 both upsamples at fractional scales (e.g. 1.6x needs
            // only 1.6×12=19px) and wastes decode budget at 1x.
            sourceSize.width: Math.max(1, Math.round(width * Screen.devicePixelRatio))
            sourceSize.height: Math.max(1, Math.round(height * Screen.devicePixelRatio))
            // mipmap + smooth: themed PNGs are 48-256px sources downscaled to
            // ~12px; without mipmapping the sampler aliases and reads blurry.
            mipmap: true
            fillMode: Image.PreserveAspectFit
            smooth: true
            // pinned-but-idle reads dimmer — running/pinned running rows keep
            // full saturation so the strip scans as: bright = alive, dim = launcher
            opacity: root.pinned && !root.running ? 0.55 : 1.0
        }

        // fallback glyph when no themed icon
        Text {
            anchors.centerIn: parent
            visible: img.status === Image.Error || img.status === Image.Null
            text: root.name.length ? root.name[0].toUpperCase() : "?"
            color: theme.foreground
            font.pixelSize: root.iconSize * 0.4
            font.bold: true
            opacity: root.pinned && !root.running ? 0.55 : 1.0
        }
    }
    // hairline between the pinned block and running-only rows — makes the
    // reorder boundary visible (running rows are not draggable)
    Rectangle {
        visible: {
            if (root.pinned || root.index === 0)
                return false;
            const v = root.ListView.view;
            return v && v.model.get(root.index - 1).pinned;
        }
        color: theme.borderFill
        width: root.vertical ? Math.round(root.iconSize * 0.6) : 1
        height: root.vertical ? 1 : Math.round(root.iconSize * 0.6)
        anchors {
            left: root.vertical ? undefined : root.left
            top: root.vertical ? root.top : undefined
            horizontalCenter: root.vertical ? root.horizontalCenter : undefined
            verticalCenter: root.vertical ? undefined : root.verticalCenter
        }
    }

    // running indicator — sits outside the tile, on the free-axis edge
    Rectangle {
        visible: root.running
        width: 3
        height: 3
        radius: 1.5
        color: root.urgent ? theme.brightRed : theme.accent
        anchors {
            horizontalCenter: root.vertical ? undefined : root.horizontalCenter
            verticalCenter: root.vertical ? root.verticalCenter : undefined
            bottom: root.vertical ? undefined : root.bottom
            right: root.vertical ? root.right : undefined
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
