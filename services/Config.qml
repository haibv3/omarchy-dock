import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string configPath: Quickshell.env("HOME") + "/.config/omarchy-dock/config.json"

    // ---- settings (persisted) ----
    property string position: "bottom"      // top | bottom | left | right
    property string displayMode: "dock"  // dock | menubar
    property bool enabled: true             // master on/off: dock/widget shown at all
    property bool transparentBackground: false
    // Defaults sized so dock thickness (iconSize + margin*2) equals the
    // 26px omarchy bar while keeping the icon as large as possible.
    property int iconSize: 24
    property int spacing: 4
    property int margin: 1
    property string autohide: "intellihide" // never | timer | intellihide
    property int hideDelay: 400             // ms
    property string monitor: "all"          // "all" | connector name e.g. "eDP-1"
    property var pinned: []                 // desktop entry ids, ordered
    property bool autostart: true           // launch standalone dock on login

    // Standalone host only. In plugin mode the shell owns the login state
    // (plugin enabled/disabled), so the hypr autostart hook must not be
    // touched from there.
    property bool standalone: false

    property bool _loaded: false
    property bool _applying: false

    function _apply(o) {
        _applying = true;
        if (o.position !== undefined) position = o.position;
        if (o.displayMode !== undefined) displayMode = o.displayMode;
        if (o.enabled !== undefined) enabled = o.enabled;
        if (o.transparentBackground !== undefined)
            transparentBackground = o.transparentBackground;
        if (o.iconSize !== undefined) iconSize = o.iconSize;
        if (o.spacing !== undefined) spacing = o.spacing;
        if (o.margin !== undefined) margin = o.margin;
        if (o.autohide !== undefined) autohide = o.autohide;
        if (o.hideDelay !== undefined) hideDelay = o.hideDelay;
        if (o.monitor !== undefined) monitor = o.monitor;
        if (o.pinned !== undefined) pinned = o.pinned;
        if (o.autostart !== undefined) autostart = o.autostart;
        _applying = false;
    }

    function save() {
        if (!_loaded || _applying)
            return;
        fileView.setText(JSON.stringify({
            position: position,
            displayMode: displayMode,
            enabled: enabled,
            transparentBackground: transparentBackground,
            iconSize: iconSize,
            spacing: spacing,
            margin: margin,
            autohide: autohide,
            hideDelay: hideDelay,
            monitor: monitor,
            pinned: pinned,
            autostart: autostart,
        }, null, 2) + "\n");
    }

    onPositionChanged: save()
    onDisplayModeChanged: save()
    onEnabledChanged: save()
    onTransparentBackgroundChanged: save()
    onIconSizeChanged: save()
    onSpacingChanged: save()
    onMarginChanged: save()
    onAutohideChanged: save()
    onHideDelayChanged: save()
    onMonitorChanged: save()
    onPinnedChanged: save()
    onAutostartChanged: {
        save();
        // install.sh adds the hook once; without this the toggle would be a
        // no-op whenever the hook is missing, and would leave a stale hook
        // behind after the user turns autostart off.
        if (standalone && !_applying)
            _syncAutostartHook();
    }

    // Keep ~/.config/hypr/autostart.lua in sync with the toggle. Only the
    // line install.sh writes is touched; a missing file is left alone.
    function _syncAutostartHook() {
        const script = [
            'f="$HOME/.config/hypr/autostart.lua"',
            '[ -f "$f" ] || exit 0',
            'line=\'o.launch_on_start("omarchy-dock --autostart")\'',
            'if [ "$1" = on ]; then',
            '    grep -qF "$line" "$f" || printf \'\\n%s\\n\' "$line" >> "$f"',
            'else',
            '    sed -i "/omarchy-dock --autostart/d" "$f"',
            'fi',
        ].join("\n");
        hookProc.command = ["bash", "-c", script, "omarchy-dock", autostart ? "on" : "off"];
        hookProc.running = true;
    }

    property Process hookProc: Process {
        id: hookProc
        onExited: function (exitCode) {
            if (exitCode !== 0)
                console.warn("omarchy-dock: autostart hook sync failed (exit " + exitCode + ")");
        }
    }

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
