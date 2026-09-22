#!/usr/bin/env bash
# omarchy-dock launcher: opens dock settings if running, else starts the dock.
set -u

DOCK_PATH="${OMARCHY_DOCK_PATH:-$HOME/Workspace/omarchy-dock}"

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
