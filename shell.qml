import QtQuick
import Quickshell
import "dock"
import "settings"
import "services"

ShellRoot {
    id: root

    // screens the dock should appear on
    function dockScreens() {
        if (Config.monitor === "all")
            return Quickshell.screens;
        const s = Quickshell.screens.find(sc => sc.name === Config.monitor);
        return s ? [s] : Quickshell.screens.slice(0, 1);
    }

    Variants {
        model: root.dockScreens()
        delegate: DockWindow {}
    }

    SettingsWindow {}
}
