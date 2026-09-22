import QtQuick
import Quickshell
import "../services"

// One dock per selected screen. Layer-shell panel anchored to the configured
// edge; a 4px strip keeps a small exclusiveZone while hidden so maximized
// windows can never cover the hover target.
PanelWindow {
    id: win

    required property ShellScreen modelData
    required property var config
    required property var theme
    required property var hyprClients
    required property var globals

    readonly property string edge: config.position          // top|bottom|left|right
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property int strip: 4
    readonly property int thickness: config.iconSize + config.margin * 2 + 6

    // ---- visibility state ----
    // plugin summon: pin the dock open regardless of autohide mode
    property bool forceVisible: false
    readonly property bool hovered: stripHover.hovered || surfaceHover.hovered
    readonly property bool edgeBusy: config.autohide === "intellihide"
        && hyprClients.edgeOccupied(modelData.name, edge, thickness + 8)
    readonly property bool wantHide: {
        if (config.autohide === "never" || forceVisible)
            return false;
        if (hovered || menuOpen)
            return false;
        if (config.autohide === "intellihide")
            return edgeBusy;
        return true; // "timer": hide whenever not hovered
    }
    readonly property bool menuOpen: dockView.menuOpen
    property bool hidden: false

    onWantHideChanged: {
        if (wantHide)
            hideTimer.restart();
        else {
            hideTimer.stop();
            hidden = false;
        }
    }

    Timer {
        id: hideTimer
        interval: config.hideDelay
        onTriggered: win.hidden = true
    }

    // ---- layer-shell setup ----
    anchors {
        top: edge === "top"
        bottom: edge === "bottom"
        left: edge === "left"
        right: edge === "right"
    }
    exclusiveZone: hidden ? strip : thickness
    exclusionMode: ExclusionMode.Normal
    aboveWindows: true
    focusable: false
    color: "transparent"

    implicitWidth: vertical ? thickness : screen.width
    implicitHeight: vertical ? screen.height : thickness
    screen: modelData

    // input mask: strip only when hidden, full surface when shown
    mask: Region {
        item: win.hidden ? stripItem : surface
    }

    // hover strip — always rendered, keeps a sliver of exclusive zone
    Item {
        id: stripItem
        anchors {
            top: win.edge === "top" ? parent.top : undefined
            bottom: win.edge === "bottom" ? parent.bottom : undefined
            left: win.edge === "left" ? parent.left : undefined
            right: win.edge === "right" ? parent.right : undefined
        }
        width: win.vertical ? win.strip : parent.width
        height: win.vertical ? parent.height : win.strip

        Rectangle {
            anchors.fill: parent
            color: theme.accent
            opacity: win.hidden && stripHover.hovered ? 0.6 : 0.0
        }

        HoverHandler { id: stripHover }
    }

    // sliding surface
    Item {
        id: surface
        anchors.fill: parent
        HoverHandler { id: surfaceHover }

        Rectangle {
            id: pill
            color: Qt.rgba(theme.background.r, theme.background.g,
                           theme.background.b, 0.85)
            radius: 16
            border.color: Qt.rgba(theme.lighterBackground.r,
                                  theme.lighterBackground.g,
                                  theme.lighterBackground.b, 0.9)
            border.width: 1

            // centered on the free axis, hugging the anchored edge
            anchors {
                horizontalCenter: win.vertical ? undefined : parent.horizontalCenter
                verticalCenter: win.vertical ? parent.verticalCenter : undefined
                top: win.edge === "top" ? parent.top : undefined
                bottom: win.edge === "bottom" ? parent.bottom : undefined
                left: win.edge === "left" ? parent.left : undefined
                right: win.edge === "right" ? parent.right : undefined
                topMargin: win.edge === "top" ? win.strip : 0
                bottomMargin: win.edge === "bottom" ? win.strip : 0
                leftMargin: win.edge === "left" ? win.strip : 0
                rightMargin: win.edge === "right" ? win.strip : 0
            }
            width: win.vertical ? win.thickness - win.strip
                                : dockView.implicitWidth + 8
            height: win.vertical ? dockView.implicitHeight + 8
                                 : win.thickness - win.strip

            DockView {
                id: dockView
                anchors.centerIn: parent
                appModel: AppModel {
                    monitorName: win.modelData.name
                    config: win.config
                }
                vertical: win.vertical
                dockWindow: win
                config: win.config
                theme: win.theme
                globals: win.globals
            }
        }

        // slide off-screen when hidden; strip stays put
        transform: Translate {
            x: win.hidden
               ? (win.edge === "left" ? -(win.thickness)
                  : win.edge === "right" ? win.thickness : 0)
               : 0
            y: win.hidden
               ? (win.edge === "top" ? -(win.thickness)
                  : win.edge === "bottom" ? win.thickness : 0)
               : 0
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }
    }

}
