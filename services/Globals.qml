import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property bool settingsOpen: false

    function openSettings() {
        settingsOpen = true;
    }
    function closeSettings() {
        settingsOpen = false;
    }

    property IpcHandler _ipc: IpcHandler {
        target: "dock"
        function toggleSettings() {
            root.settingsOpen = !root.settingsOpen;
        }
    }
}
