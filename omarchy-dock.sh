#!/usr/bin/env bash
# omarchy-dock launcher: opens dock settings if running, else starts the dock.
set -u

DOCK_PATH="${OMARCHY_DOCK_PATH:-$HOME/Workspace/omarchy-dock}"

# If a dock instance for this config is running, toggle its settings window.
if quickshell ipc -p "$DOCK_PATH" call dock toggleSettings 2>/dev/null; then
    exit 0
fi

# Not running → start it.
exec quickshell -p "$DOCK_PATH"
