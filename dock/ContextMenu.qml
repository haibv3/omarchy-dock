import QtQuick
import Quickshell
import "../services"

// Popup context menu anchored to a dock icon.
PopupWindow {
    id: root

    property var row: null            // AppModel row
    required property var config
    required property var theme
    required property var globals
    signal menuClosed()

    anchor.rect: Qt.rect(0, 0, 1, 1)
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
    grabFocus: true
    color: "transparent"
    visible: false

    implicitWidth: menuCol.implicitWidth + 8
    implicitHeight: menuCol.implicitHeight + 8

    function openFor(rowData, anchorWindow, x, y) {
        row = rowData;
        anchor.window = anchorWindow;
        anchor.rect = Qt.rect(x, y, 1, 1);
        visible = true;
    }

    onVisibleChanged: {
        if (!visible)
            menuClosed();
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: theme.darkerBackground
        border.color: theme.muted
        border.width: 1

        Column {
            id: menuCol
            anchors.centerIn: parent
            width: 220
            spacing: 0

            Repeater {
                model: root.row ? root.row.toplevels : []
                delegate: Rectangle {
                    required property var modelData
                    required property int index
                    width: menuCol.width
                    height: 28
                    color: winMa.containsMouse ? theme.lighterBackground : "transparent"
                    radius: 4
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        width: parent.width - 20
                        elide: Text.ElideRight
                        text: modelData.title || "(untitled)"
                        color: theme.foreground
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: winMa
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (modelData.wayland)
                                modelData.wayland.activate();
                            root.visible = false;
                        }
                    }
                }
            }

            Rectangle {
                visible: root.row && root.row.toplevels.length > 0
                width: menuCol.width
                height: 1
                color: theme.muted
                opacity: 0.4
            }

            // Pin / Unpin
            Rectangle {
                width: menuCol.width
                height: 30
                color: pinMa.containsMouse ? theme.lighterBackground : "transparent"
                radius: 4
                visible: root.row && root.row.desktopId !== ""
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: root.row && root.row.pinned ? "Unpin from dock" : "Pin to dock"
                    color: theme.foreground
                    font.pixelSize: 12
                }
                MouseArea {
                    id: pinMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (root.row.pinned)
                            config.unpin(root.row.desktopId);
                        else
                            config.pin(root.row.desktopId);
                        root.visible = false;
                    }
                }
            }

            // Close windows
            Rectangle {
                width: menuCol.width
                height: 30
                color: closeMa.containsMouse ? theme.lighterBackground : "transparent"
                radius: 4
                visible: root.row && root.row.running
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: root.row && root.row.toplevels.length > 1 ? "Close all windows" : "Close window"
                    color: theme.red
                    font.pixelSize: 12
                }
                MouseArea {
                    id: closeMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        for (const t of root.row.toplevels) {
                            if (t.wayland)
                                t.wayland.close();
                        }
                        root.visible = false;
                    }
                }
            }

            Rectangle {
                width: menuCol.width
                height: 1
                color: theme.muted
                opacity: 0.4
            }

            // Settings
            Rectangle {
                width: menuCol.width
                height: 30
                color: setMa.containsMouse ? theme.lighterBackground : "transparent"
                radius: 4
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: "Dock settings…"
                    color: theme.foreground
                    font.pixelSize: 12
                }
                MouseArea {
                    id: setMa
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        globals.openSettings();
                        root.visible = false;
                    }
                }
            }
        }
    }
}
