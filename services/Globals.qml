import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root
    property bool settingsOpen: false
    // Standalone only — in plugin mode Qt.quit() would kill the shell.
    property bool canQuit: false

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
        function quit() {
            if (root.canQuit)
                Qt.quit();
        }
    }
}
