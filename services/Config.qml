import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy-dock/config.json"

    // ---- settings (persisted) ----
    property string position: "bottom"      // top | bottom | left | right
    property int iconSize: 48
    property int spacing: 6
    property int margin: 8
    property string autohide: "intellihide" // never | timer | intellihide
    property int hideDelay: 400             // ms
    property string monitor: "all"          // "all" | connector name e.g. "eDP-1"
    property var pinned: []                 // desktop entry ids, ordered

    property bool _loaded: false
    property bool _applying: false

    function _apply(o) {
        _applying = true;
        if (o.position !== undefined) position = o.position;
        if (o.iconSize !== undefined) iconSize = o.iconSize;
        if (o.spacing !== undefined) spacing = o.spacing;
        if (o.margin !== undefined) margin = o.margin;
        if (o.autohide !== undefined) autohide = o.autohide;
        if (o.hideDelay !== undefined) hideDelay = o.hideDelay;
        if (o.monitor !== undefined) monitor = o.monitor;
        if (o.pinned !== undefined) pinned = o.pinned;
        _applying = false;
    }

    function save() {
        if (!_loaded || _applying)
            return;
        fileView.setText(JSON.stringify({
            position: position,
            iconSize: iconSize,
            spacing: spacing,
            margin: margin,
            autohide: autohide,
            hideDelay: hideDelay,
            monitor: monitor,
            pinned: pinned
        }, null, 2) + "\n");
    }

    onPositionChanged: save()
    onIconSizeChanged: save()
    onSpacingChanged: save()
    onMarginChanged: save()
    onAutohideChanged: save()
    onHideDelayChanged: save()
    onMonitorChanged: save()
    onPinnedChanged: save()

    function isPinned(desktopId) {
        return pinned.indexOf(desktopId) !== -1;
    }

    function pin(desktopId) {
        if (isPinned(desktopId))
            return;
        pinned = pinned.concat([desktopId]);
    }

    function unpin(desktopId) {
        pinned = pinned.filter(id => id !== desktopId);
    }

    function setPinnedOrder(ids) {
        pinned = ids;
    }

    // ensure ~/.config/omarchy-dock exists before first write
    property Process _mkdir: Process {
        command: ["mkdir", "-p", Quickshell.env("HOME") + "/.config/omarchy-dock"]
        running: true
    }

    property FileView fileView: FileView {
        id: fileView
        path: root.configPath
        watchChanges: true
        atomicWrites: true
        onLoaded: {
            const t = fileView.text();
            if (t.trim().length === 0) {
                root._loaded = true;
                root.save(); // write defaults
                return;
            }
            try {
                root._apply(JSON.parse(t));
            } catch (e) {
                console.warn("omarchy-dock: bad config.json, keeping defaults:", e);
            }
            root._loaded = true;
        }
        onFileChanged: fileView.reload()
        onLoadFailed: {
            // missing file → write defaults
            root._loaded = true;
            root.save();
        }
        onSaveFailed: console.warn("omarchy-dock: failed to write config.json")
    }
}
