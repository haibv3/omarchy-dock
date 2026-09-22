import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Geometry source for intellihide. HyprlandToplevel lacks x/y/w/h, so we poll
// `hyprctl clients -j` debounced off the Hyprland event stream.
QtObject {
    id: root

    // address -> {x, y, w, h, monitor, workspace, fullscreen, hidden}
    property var clients: ({})
    property bool _pending: false

    function refresh() {
        if (proc.running) {
            _pending = true;
            return;
        }
        proc.running = true;
    }

    function _parse(json) {
        let map = {};
        try {
            for (const c of JSON.parse(json)) {
                map[c.address] = {
                    x: c.at[0],
                    y: c.at[1],
                    w: c.size[0],
                    h: c.size[1],
                    monitor: c.monitor,
                    workspace: c.workspace ? c.workspace.id : -1,
                    fullscreen: c.fullscreen !== 0,
                    hidden: c.hidden === true || c.mapped === false
                };
            }
        } catch (e) {
            console.warn("omarchy-dock: hyprctl clients parse failed:", e);
        }
        clients = map;
    }

    // Is any visible window on `monitorName` overlapping the dock edge band?
    function edgeOccupied(monitorName, edge, band) {
        const mons = Hyprland.monitors.values;
        let mon = null;
        for (const m of mons) {
            if (m.name === monitorName) {
                mon = m;
                break;
            }
        }
        if (!mon)
            return false;
        const ws = mon.activeWorkspace ? mon.activeWorkspace.id : -1;
        for (const addr in clients) {
            const c = clients[addr];
            if (c.monitor !== mon.id || c.hidden)
                continue;
            if (!c.fullscreen && c.workspace !== ws)
                continue;
            const right = c.x + c.w;
            const bottom = c.y + c.h;
            const monRight = mon.x + mon.width;
            const monBottom = mon.y + mon.height;
            if (edge === "bottom" && bottom >= monBottom - band)
                return true;
            if (edge === "top" && c.y <= mon.y + band)
                return true;
            if (edge === "left" && c.x <= mon.x + band)
                return true;
            if (edge === "right" && right >= monRight - band)
                return true;
        }
        return false;
    }

    property Process proc: Process {
        id: proc
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root._parse(this.text)
        }
        onExited: {
            if (root._pending) {
                root._pending = false;
                root.refresh();
            }
        }
    }

    property Timer debounce: Timer {
        id: debounce
        interval: 120
        onTriggered: root.refresh()
    }

    property Connections _conn: Connections {
        target: Hyprland
        function onRawEvent(event) {
            debounce.restart();
        }
    }

    Component.onCompleted: refresh()
}
