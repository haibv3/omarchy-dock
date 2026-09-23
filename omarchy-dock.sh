#!/usr/bin/env bash
# omarchy-dock launcher: opens dock settings if running, else starts the dock.
#   omarchy-dock              toggle settings / start dock
#   omarchy-dock --autostart  login hook: start only when appropriate
set -u

DOCK_PATH="${OMARCHY_DOCK_PATH:-$HOME/Workspace/omarchy-dock}"
CONFIG="$HOME/.config/omarchy-dock/config.json"
SHELL_JSON="$HOME/.config/omarchy/shell.json"
PLUGIN_ID="haibv3.omarchy-dock"

plugin_active() {
    # Dock is provided by omarchy-shell when the plugin is enabled AND the
    # shell is actually running.
    grep -q "\"$PLUGIN_ID\"" "$SHELL_JSON" 2>/dev/null \
        && pgrep -f 'quickshell.*omarchy/shell' >/dev/null 2>&1
}

if [[ "${1:-}" == "--quit" ]]; then
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
    # Plugin mode owns the dock — don't double-launch.
    plugin_active && exit 0
    # Already running.
    pgrep -f "quickshell -p $DOCK_PATH" >/dev/null && exit 0
    exec quickshell -p "$DOCK_PATH"
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
