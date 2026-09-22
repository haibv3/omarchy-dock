# omarchy-dock

A macOS/Ubuntu-style dock for Omarchy OS (Hyprland/Wayland), built on Quickshell.

## Features

- Pin favorite apps; running apps merge into pinned icons with an indicator dot
- Running-but-unpinned apps appear at the end of the dock
- Position: top / bottom / left / right
- Icon size, spacing, margin
- Auto-hide: never / after delay / intellihide (hides when a window touches the dock edge)
- Per-monitor or all-monitors
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

## Omarchy shell plugin (phase 2)

```bash
./install.sh --plugin
```

Copies the dock into `~/.config/omarchy/plugins/haibv3.omarchy-dock` and
enables it. The dock then runs inside `omarchy-shell` — no extra process.

- Summon/hide: `omarchy-shell shell summon haibv3.omarchy-dock` /
  `omarchy-shell shell hide haibv3.omarchy-dock` (summon pins the dock
  visible; hide resumes autohide).
- Settings: `omarchy-shell dock toggleSettings` or the app-menu entry.
- **Caveat:** `keepLoaded` plugins are not replaced on hot-reload — code
  changes need `omarchy restart shell`.

## Config

`~/.config/omarchy-dock/config.json` — created on first run, hot-reloaded:

```json
{
  "position": "bottom",
  "iconSize": 48,
  "spacing": 6,
  "margin": 8,
  "autohide": "intellihide",
  "hideDelay": 400,
  "monitor": "all",
  "pinned": []
}
```

All options are also editable in the GUI: right-click the dock → *Dock settings…*.

## Notes

- Tested against Quickshell 0.3.1 (Omarchy 4.0.4).
- Intellihide polls `hyprctl clients -j` debounced off the Hyprland event socket.
- Packaging as an `omarchy plugin` (`kinds: ["panel"]`, `keepLoaded`) is planned phase 2; the Theme/Config singletons are the only swap points.
