import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../services"

// Merges pinned desktop entries with running toplevels for one monitor.
// Exposes a ListModel of {desktopId, appId, name, icon, entry, toplevels[],
//                        running, urgent, pinned}.
QtObject {
    id: root

    // ShellScreen name this model serves ("" = all monitors merged).
    property string monitorName: ""

    readonly property ListModel model: ListModel {}

    // ListModel drops QObject/array roles ("handle is null" warnings), so
    // entry + toplevels live here, parallel to model rows.
    property var _rows: []

    function rowAt(i) {
        return _rows[i];
    }

    // appId -> [HyprlandToplevel]
    function runningByApp() {
        const groups = {};
        const mon = monitorName === "" ? null : Hyprland.monitorFor(
            Quickshell.screens.find(s => s.name === monitorName));
        for (const t of Hyprland.toplevels.values) {
            const wl = t.wayland;
            if (!wl || !wl.appId)
                continue;
            if (wl.appId === "org.quickshell")
                continue; // our own settings/menu windows
            if (mon && t.monitor && t.monitor.id !== mon.id)
                continue;
            const key = wl.appId;
            if (!groups[key])
                groups[key] = [];
            groups[key].push(t);
        }
        return groups;
    }

    function entryForAppId(appId, groups) {
        // exact id → lowercase id → startupClass → heuristic
        let e = DesktopEntries.byId(appId);
        if (e)
            return e;
        e = DesktopEntries.byId(appId.toLowerCase());
        if (e)
            return e;
        for (const id in groups) {
            const cand = DesktopEntries.byId(id);
            if (cand && cand.startupClass === appId)
                return cand;
        }
        e = DesktopEntries.heuristicLookup(appId);
        return e; // may be null
    }

    function rebuild() {
        const groups = runningByApp();
        const consumed = {}; // appId already represented by a pinned row
        const next = [];

        for (const desktopId of Config.pinned) {
            const entry = DesktopEntries.byId(desktopId);
            if (!entry)
                continue;
            // find running group matching this entry
            let tls = [];
            for (const appId in groups) {
                const e = entryForAppId(appId, groups);
                if (e && e.id === entry.id) {
                    tls = groups[appId];
                    consumed[appId] = true;
                    break;
                }
            }
            next.push({
                desktopId: entry.id,
                appId: tls.length ? tls[0].wayland.appId : "",
                name: entry.name,
                icon: entry.icon,
                entry: entry,
                toplevels: tls,
                running: tls.length > 0,
                urgent: tls.some(t => t.urgent),
                pinned: true
            });
        }

        // running but not pinned → appended at the end
        for (const appId in groups) {
            if (consumed[appId])
                continue;
            const entry = entryForAppId(appId, groups);
            const tls = groups[appId];
            next.push({
                desktopId: entry ? entry.id : "",
                appId: appId,
                name: entry ? entry.name : appId,
                icon: entry ? entry.icon : "",
                entry: entry,
                toplevels: tls,
                running: true,
                urgent: tls.some(t => t.urgent),
                pinned: false
            });
        }

        _rows = next;
        model.clear();
        for (const row of next) {
            model.append({
                desktopId: row.desktopId,
                appId: row.appId,
                name: row.name,
                icon: row.icon,
                running: row.running,
                urgent: row.urgent,
                pinned: row.pinned
            });
        }
    }

    function activateOrLaunch(index) {
        const row = _rows[index];
        if (!row)
            return;
        if (row.running && row.toplevels.length > 0) {
            const wl = row.toplevels[0].wayland;
            if (wl)
                wl.activate();
        } else if (row.entry) {
            row.entry.execute();
        }
    }


    property Connections _c1: Connections {
        target: Hyprland
        function onRawEvent(event) {
            root.rebuild();
        }
    }
    property Connections _c2: Connections {
        target: Config
        function onPinnedChanged() {
            root.rebuild();
        }
    }
    property Connections _c3: Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.rebuild();
        }
    }
    Component.onCompleted: rebuild()
}
