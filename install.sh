#!/usr/bin/env bash
# Install omarchy-dock: icon, .desktop entry, launcher script.
# Usage:
#   ./install.sh           standalone mode (quickshell -p)
#   ./install.sh --plugin  also install as an Omarchy shell plugin
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ID="haibv3.omarchy-dock"

mkdir -p "$HOME/.config/omarchy-dock"
install -Dm755 "$SRC/omarchy-dock.sh" "$HOME/.local/bin/omarchy-dock"
install -Dm644 "$SRC/omarchy-dock.desktop" "$HOME/.local/share/applications/omarchy-dock.desktop"
install -Dm644 "$SRC/assets/omarchy-dock.svg" "$HOME/.local/share/icons/hicolor/scalable/apps/omarchy-dock.svg"

# Point the launcher at this checkout.
sed -i "s|^DOCK_PATH=.*|DOCK_PATH=\"\${OMARCHY_DOCK_PATH:-$SRC}\"|" "$HOME/.local/bin/omarchy-dock"

# Refresh caches (best-effort).
command -v update-desktop-database >/dev/null && update-desktop-database "$HOME/.local/share/applications" || true
command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true

if [[ "${1:-}" == "--plugin" ]]; then
    dest="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
    mkdir -p "$dest"
    cp -r "$SRC"/{manifest.json,PluginEntry.qml,dock,services,settings} "$dest/"
    omarchy-shell shell rescanPlugins || true
    omarchy plugin enable "$PLUGIN_ID" || true
    echo "Plugin installed to $dest and enabled."
    echo "NOTE: keepLoaded plugins only reload on shell restart — run"
    echo "      'omarchy restart shell' (or reboot) to pick up code changes."
fi

echo "Installed. 'Omarchy Dock' should now appear in your app launcher."
echo "Click it to open dock settings (or start the dock if not running)."
