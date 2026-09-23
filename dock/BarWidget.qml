import QtQuick
import Quickshell
import qs.Commons
import "../services"
import "../settings"

// Pinned app icons hosted directly by Omarchy's bar.
Item {
    id: root

    // Omarchy injects these properties when constructing a bar-widget entry.
    property var bar: null
    property string moduleName: "haibv3.omarchy-dock-menubar"
    property var settings: ({})

    readonly property bool active: config.displayMode === "menubar"
    visible: active
    implicitWidth: active ? dockView.implicitWidth : 0
    implicitHeight: active ? dockView.implicitHeight : 0

    Config { id: config }
    Theme { id: theme }

    // Each bar instance owns its settings window state; unlike Globals, this
    // deliberately has no IPC handler, so multi-monitor bars do not duplicate it.
    QtObject {
        id: globals
        property bool settingsOpen: false
        readonly property bool canQuit: false

        function openSettings() { settingsOpen = true; }
        function closeSettings() { settingsOpen = false; }
    }

    AppModel {
        id: appModel
        config: config
        includeUnpinnedRunning: false
    }

    DockView {
        id: dockView
        anchors.fill: parent
        appModel: appModel
        config: config
        theme: theme
        globals: globals
        vertical: root.bar ? root.bar.vertical : false
        // Bar icons follow the bar's raster-icon convention — tray icons are
        // Style.space(12), not the 16px glyph canvas, which nerd-font glyphs
        // only fill to ~11px. DockIcon insets 4px for the hover tile.
        iconSize: root.bar ? Style.space(12) + 4 : config.iconSize
        // Claim the bar's full thickness so the icons land on its optical center.
        thickness: root.bar ? root.bar.barSize : 0
        dockWindow: root.QsWindow ? root.QsWindow.window : null
        canQuit: false
    }

    SettingsWindow {
        config: config
        theme: theme
        globals: globals
    }
}
