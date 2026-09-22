#!/usr/bin/env bash
# omarchy-dock launcher: opens dock settings if running, else starts the dock.
set -u

DOCK_PATH="${OMARCHY_DOCK_PATH:-$HOME/Workspace/omarchy-dock}"

# Find a running dock instance (launched with -p DOCK_PATH) and toggle settings.
for pid in $(pgrep -f "quickshell -p ${DOCK_PATH}" 2>/dev/null); do
    if quickshell ipc --pid "$pid" call dock toggleSettings 2>/dev/null; then
        exit 0
    fi
done

# Not running → start it.
exec quickshell -p "$DOCK_PATH"
