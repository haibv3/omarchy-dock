# omarchy-dock

A Quickshell app dock for Omarchy OS (Hyprland/Wayland), with an optional pinned-app menubar widget.

## Features

- Pin favorite apps; running pinned apps show an indicator dot
- Running-but-unpinned apps appear at the end of the dock
- Presentation: dock or Omarchy menubar widget
- Dock position: top / bottom / left / right
- Optional transparent dock background
- Icon size, spacing, margin
- Auto-hide: never / after delay / intellihide (hides when a window touches the dock edge)
- Per-monitor or all-monitors for the dock
- Drag to reorder pinned apps
- Right-click menu: focus windows, pin/unpin, close, settings
- Follows the active Omarchy theme (`colors.toml`)

## Requirements

- Omarchy OS / Hyprland
- `quickshell` (already installed on Omarchy ≥4.0)

## Run

```bash
quickshell -p ~/Workspace/omarchy-dock
```

## Autostart

Add to `~/.config/hypr/autostart.lua`:

```lua
-- omarchy-dock
os.execute("quickshell -p ~/Workspace/omarchy-dock &")
```

(or the equivalent `exec-once` form your Hyprland config uses)

## App menu entry

```bash
./install.sh
```

Installs `omarchy-dock` into `~/.local/bin`, a `.desktop` entry into
`~/.local/share/applications`, and the SVG icon into the hicolor theme.
"Omarchy Dock" then appears in your app launcher — clicking it opens the
dock settings window (or starts the dock if it isn't running).

## Omarchy shell plugin

```bash
./install.sh --plugin
```

Copies the dock panel plugin into `~/.config/omarchy/plugins/haibv3.omarchy-dock` and its companion bar widget into `~/.config/omarchy/plugins/haibv3.omarchy-dock-menubar`, then enables both. Select **Menubar** in dock settings to show pinned icons in the bar instead of a separate dock. Move the widget with `omarchy bar move haibv3.omarchy-dock-menubar --section <left|center|right>`.

- Dock mode summon/hide: `omarchy-shell shell summon haibv3.omarchy-dock` / `omarchy-shell shell hide haibv3.omarchy-dock` (summon pins the dock visible; hide resumes autohide).
- Settings: right-click an app icon or run `omarchy-shell dock toggleSettings`.
- **Caveat:** `keepLoaded` dock-plugin changes are not replaced on hot-reload — run `omarchy restart shell`.

## Config

`~/.config/omarchy-dock/config.json` — created on first run, hot-reloaded:

```json
{
  "position": "bottom",
  "displayMode": "dock",
  "transparentBackground": false,
  "iconSize": 24,
  "spacing": 4,
  "margin": 1,
  "autohide": "intellihide",
  "hideDelay": 400,
  "monitor": "all",
  "pinned": []
}
```

All options are also editable in the GUI: right-click an app icon → *Dock settings…* / *Menubar settings…*.

## Notes

- Tested against Quickshell 0.3.1 (Omarchy 4.0.4).
- Intellihide polls `hyprctl clients -j` debounced off the Hyprland event socket.
- Menubar presentation requires the Omarchy shell plugin; standalone mode remains a dock.
