import QtQuick
import Quickshell
import "dock"
import "services"

// Omarchy shell plugin entry point (kind: "panel", keepLoaded).
// The shell mounts this when the plugin is enabled and calls open()/close()
// on summon/hide. For a dock, summon = force-visible; close = resume autohide.
Item {
    id: root

    // Summon contract: the shell reads `opened` for isPluginOpen().
    property bool opened: false

    function open(payload) {
        opened = true;
    }
    function close() {
        opened = false;
    }

    DockRoot {
        forceVisible: root.opened
    }
}
