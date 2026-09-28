import QtQuick
import Quickshell
import Quickshell.Io

// Two palette sources:
//   "signal"  — Signal Dark tokens, read from signal-dark.tokens.json (W3C
//               token format) next to this file; ships with the plugin.
//   "omarchy" — the host theme's colors.toml (~/.local/state/omarchy/current/
//               theme is a symlink retargeted on theme-set, so we watch
//               theme.name and re-resolve the path).
// Property defaults already encode Signal Dark, so a missing token file
// degrades to the same palette.
QtObject {
    id: root

    readonly property string stateDir: Quickshell.env("HOME") + "/.local/state/omarchy/current"
    readonly property string colorsPath: stateDir + "/theme/colors.toml"

    property string mode: "dark"
    property color accent: "#4ade80"
    property color background: "#0c0e12"
    property color darkerBackground: "#14171d"
    property color lighterBackground: "#191d26"
    property color foreground: "#e6e9ef"
    property color darkForeground: "#8b93a1"
    property color selection: "#22472f"
    property color muted: "#6b7280"
    // Readable secondary text (5.8:1+); `muted` stays reserved for non-text
    // chrome (separators, carets) since it only reaches 4.0:1 on bg.
    property color mutedText: "#8b93a1"
    property color red: "#f87171"
    property color yellow: "#fbbf24"
    property color green: "#4ade80"
    property color brightRed: "#f87171"

    // State fills — the shell composites foreground at low alpha rather
    // than trusting lighter_background (some themes, e.g. solitude, set
    // lighter_background == background which makes hover invisible).
    readonly property color normalFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.04)
    readonly property color hoverFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.08)
    readonly property color trackFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.14)
    readonly property color borderFill: Qt.rgba(foreground.r, foreground.g, foreground.b, 0.16)

    // Shape + type roles — Signal Dark tokens; "omarchy" keeps these values
    // too since the token set is the design system, not a host override.
    property int radiusControl: 4
    property int radiusWindow: 8
    property int radiusDock: 12
    property string fontMono: "JetBrains Mono"

    // Palette source. "signal" maps the Signal Dark token palette onto the
    // same roles (dark console, single electric accent); "omarchy" follows
    // the host theme's colors.toml. Roles keep their names — only values swap.
    property string palette: "signal"
    onPaletteChanged: {
        if (palette === "signal")
            tokensFile.reload();   // onLoaded applies the token values
        else
            colorsFile.reload();   // re-parse colors.toml into the roles
    }
    property var _signalTokens: null

    // Map W3C token paths onto the existing role names; missing keys keep
    // the Signal Dark defaults declared above.
    function _applySignal() {
        if (!_signalTokens)
            return;
        const t = _signalTokens.color || {};
        const v = k => (t[k] && t[k].$value) ? t[k].$value : undefined;
        mode = "dark";
        if (v("accent")) accent = v("accent");
        if (v("bg")) background = v("bg");
        if (v("surface")) darkerBackground = v("surface");
        if (v("surface-raised")) lighterBackground = v("surface-raised");
        if (v("fg")) foreground = v("fg");
        if (v("muted-text")) darkForeground = v("muted-text");
        if (v("accent-dim")) selection = v("accent-dim");
        if (v("muted")) muted = v("muted");
        if (v("muted-text")) mutedText = v("muted-text");
        if (v("danger")) red = v("danger");
        if (v("warning")) yellow = v("warning");
        if (v("accent")) green = v("accent");
        if (v("danger")) brightRed = v("danger");
    }

    function _applySignalShape() {
        if (!_signalTokens)
            return;
        const r = _signalTokens.radius || {};
        const px = k => r[k] && r[k].$value ? parseInt(r[k].$value) : 0;
        if (px("control")) radiusControl = px("control");
        if (px("window")) radiusWindow = px("window");
        if (px("dock")) radiusDock = px("dock");
        const ty = _signalTokens.typography || {};
        if (ty["font-mono"] && ty["font-mono"].$value)
            fontMono = ty["font-mono"].$value.split(",")[0].trim();
    }
    function _parse(toml) {
        if (root.palette === "signal")
            return;   // fixed palette — colors.toml must not overwrite it
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
        if (c("bright_red")) brightRed = map["bright_red"];
        // colors.toml has no muted-text key — secondary text follows the
        // theme's own dim foreground.
        mutedText = darkForeground;
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

    // W3C token file shipped in services/ — resolved relative to this QML so
    // it works standalone and inside the plugin dir.
    readonly property string tokensPath:
        Qt.resolvedUrl("signal-dark.tokens.json").toString().replace("file://", "")

    property FileView tokensFile: FileView {
        id: tokensFile
        path: root.tokensPath
        watchChanges: true
        onLoaded: {
            try {
                root._signalTokens = JSON.parse(tokensFile.text());
            } catch (e) {
                console.warn("omarchy-dock: bad signal-dark.tokens.json, keeping defaults:", e);
            }
            if (root.palette === "signal") {
                root._applySignal();
                root._applySignalShape();
            }
        }
        onLoadFailed: console.warn("omarchy-dock: signal-dark.tokens.json not found, using defaults")
        onFileChanged: tokensFile.reload()
    }
}
