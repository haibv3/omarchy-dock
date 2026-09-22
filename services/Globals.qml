pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property bool settingsOpen: false

    function openSettings() {
        settingsOpen = true;
    }
    function closeSettings() {
        settingsOpen = false;
    }

    IpcHandler {
        target: "dock"
        function toggleSettings() {
            root.settingsOpen = !root.settingsOpen;
        }
    }
}
