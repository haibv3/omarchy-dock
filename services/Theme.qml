import QtQuick
import Quickshell
import Quickshell.Io

// Reads the active Omarchy theme's colors.toml.
// ~/.local/state/omarchy/current/theme is a symlink that gets retargeted on
// theme-set, so we watch theme.name (a regular file) and re-resolve the path.
QtObject {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/current"
    readonly property string colorsPath: stateDir + "/theme/colors.toml"

    property string mode: "dark"
    property color accent: "#89b4fa"
    property color background: "#1e1e2e"
    property color darkerBackground: "#101019"
    property color lighterBackground: "#313244"
    property color foreground: "#cdd6f4"
    property color darkForeground: "#6c7086"
    property color selection: "#45475a"
    property color muted: "#585b70"
    property color red: "#f38ba8"
    property color yellow: "#f9e2af"
    property color green: "#a6e3a1"

    function _parse(toml) {
        const map = {};
        for (const line of toml.split("\n")) {
            const m = line.match(/^\s*([A-Za-z_]+)\s*=\s*"([^"]*)"/);
            if (m)
                map[m[1]] = m[2];
        }
        const c = k => map[k] !== undefined ? map[k] : undefined;
        if (c("mode")) mode = map["mode"];
        if (c("accent")) accent = map["accent"];
        if (c("background")) background = map["background"];
        if (c("darker_background")) darkerBackground = map["darker_background"];
        if (c("lighter_background")) lighterBackground = map["lighter_background"];
        if (c("foreground")) foreground = map["foreground"];
        if (c("dark_foreground")) darkForeground = map["dark_foreground"];
        if (c("selection")) selection = map["selection"];
        if (c("muted")) muted = map["muted"];
        if (c("red")) red = map["red"];
        if (c("yellow")) yellow = map["yellow"];
        if (c("green")) green = map["green"];
    }

    // theme.name changes on every theme-set → force colors.toml reload by
    // retoggling the path (the symlink target may have changed inode).
    property FileView nameFile: FileView {
        id: nameFile
        path: root.stateDir + "/theme.name"
        watchChanges: true
        onLoaded: {
            colorsFile.path = "";
            colorsFile.path = root.colorsPath;
        }
        onLoadFailed: console.warn("omarchy-dock: theme.name not found, using fallback colors")
        onFileChanged: nameFile.reload()
    }

    property FileView colorsFile: FileView {
        id: colorsFile
        path: root.colorsPath
        watchChanges: true
        onLoaded: root._parse(colorsFile.text())
        onLoadFailed: console.warn("omarchy-dock: colors.toml not found at", path)
        onFileChanged: colorsFile.reload()
    }
}
