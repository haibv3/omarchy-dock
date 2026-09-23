#!/usr/bin/env bash
# omarchy-dock launcher: opens dock settings if running, else starts the dock.
#   omarchy-dock              toggle settings / start dock (re-enables a disabled plugin)
#   omarchy-dock --autostart  login hook: start only when appropriate
#   omarchy-dock --quit       stop the dock (standalone process, or plugin)
set -u

DOCK_PATH="${OMARCHY_DOCK_PATH:-$HOME/Workspace/omarchy-dock}"
CONFIG="$HOME/.config/omarchy-dock/config.json"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
PLUGIN_ID="haibv3.omarchy-dock"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

# The plugin is installed → omarchy-shell owns the dock, whether or not it is
# currently enabled ("Start on login" off disables it).
plugin_installed() { [[ -d "$PLUGIN_DIR" ]]; }
plugin_enabled() {
    grep -q "\"$PLUGIN_ID\"" "$SHELL_JSON" 2>/dev/null
}
plugin_active() {
    plugin_enabled && pgrep -f 'quickshell.*omarchy/shell' >/dev/null 2>&1
}

if [[ "${1:-}" == "--quit" ]]; then
    if plugin_active; then
        # Complete off in plugin mode: the shell stops loading the dock.
        omarchy plugin disable "$PLUGIN_ID" >/dev/null 2>&1 \
            && echo "Dock disabled (re-enable from the app launcher)." \
            || echo "Could not disable the dock plugin." >&2
        exit 0
    fi
    # IPC resolves the instance by config path regardless of how it was
    # launched (absolute path, relative '.', symlink…).
    if quickshell ipc -p "$DOCK_PATH" call dock quit 2>/dev/null; then
        echo "Dock stopped."
        exit 0
    fi
    pkill -f "quickshell -p.*$(basename "$DOCK_PATH")" \
        && echo "Dock stopped." || echo "Dock is not running."
    exit 0
fi

if [[ "${1:-}" == "--autostart" ]]; then
    # Respect the user's "Start on login" toggle.
    grep -q '"autostart"[[:space:]]*:[[:space:]]*false' "$CONFIG" 2>/dev/null \
        && exit 0
    # Plugin installed → the shell owns the dock at login. A disabled plugin
    # means the user turned it off; don't start a second, standalone dock.
    plugin_installed && exit 0
    # Already running.
    pgrep -f "quickshell -p $DOCK_PATH" >/dev/null && exit 0
    exec quickshell -p "$DOCK_PATH"
fi

# Plugin installed but disabled ("Start on login" off): re-enable it, then open
# settings. Without this the launcher would fall through and start a second,
# standalone dock next to the plugin.
if plugin_installed && ! plugin_enabled; then
    omarchy plugin enable "$PLUGIN_ID" >/dev/null 2>&1 || true
    # The panel loads asynchronously; its IPC target appears a moment later.
    for _ in $(seq 1 20); do
        omarchy-shell dock toggleSettings 2>/dev/null && exit 0
        sleep 0.1
    done
    echo "Dock re-enabled." >&2
    exit 0
fi

# Plugin mode: dock lives inside omarchy-shell → toggle via omarchy-shell IPC.
if command -v omarchy-shell >/dev/null 2>&1 \
    && omarchy-shell dock toggleSettings 2>/dev/null; then
    exit 0
fi

# Standalone mode: toggle settings on a running instance, else start it.
if quickshell ipc -p "$DOCK_PATH" call dock toggleSettings 2>/dev/null; then
    exit 0
fi
exec quickshell -p "$DOCK_PATH"
