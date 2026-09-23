import QtQuick
import Quickshell
import "../services"
import "../settings"

// Shared dock tree: one DockWindow per selected screen + the settings window.
// Used by shell.qml (standalone) and PluginEntry.qml (omarchy plugin).
// Services are plain instances here — Quickshell file singletons don't resolve
// inside plugin directories, so everything below takes them as properties.
Item {
    id: root

    // When true (plugin summoned), dock ignores autohide and stays visible.
    property bool forceVisible: false
    // Standalone only: quitting the process is safe. In plugin mode the
    // dock shares the omarchy-shell process — Qt.quit() would kill it.
    property bool canQuit: false

    property alias config: configSvc
    property alias theme: themeSvc
    property alias hyprClients: hyprSvc
    property alias globals: globalsSvc

    Config { id: configSvc }
    Theme { id: themeSvc }
    HyprClients { id: hyprSvc }
    Globals { id: globalsSvc }

    function dockScreens() {
        if (configSvc.monitor === "all")
            return Quickshell.screens;
        const s = Quickshell.screens.find(sc => sc.name === configSvc.monitor);
        return s ? [s] : Quickshell.screens.slice(0, 1);
    }

    Variants {
        model: root.dockScreens()
        delegate: DockWindow {
            forceVisible: root.forceVisible
            config: configSvc
            theme: themeSvc
            hyprClients: hyprSvc
            globals: globalsSvc
        }
    }

    SettingsWindow {
        config: configSvc
        theme: themeSvc
        globals: globalsSvc
    }
}
