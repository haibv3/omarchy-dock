# AGENTS.md

Quickshell/QML application dock for Omarchy OS (Hyprland/Wayland), plus an
optional pinned-app widget for the Omarchy bar.

**Stack:** Qt6 QML via Quickshell 0.3.1, bash for install/launch. No compiler,
no package manager, no test suite, no CI. Every change is verified by running
the thing and looking at it.

## Two deployment modes (read this first)

The same QML tree runs in two very different hosts. Most design decisions in
this repo exist to keep both working.

| | Standalone | Omarchy shell plugin |
|---|---|---|
| Entry | `shell.qml` → `ShellRoot { DockRoot { canQuit: true } }` | `PluginEntry.qml` (manifest `kinds:["panel"]`, `keepLoaded: true`) |
| Process | own `quickshell -p <repo>` process | mounted inside the long-running `omarchy-shell` process |
| `canQuit` | `true` — enables `Qt.quit()` and the "Start on login" toggle | `false` — `Qt.quit()` would kill the entire shell |
| Settings | right-click icon → *Dock settings…* | `omarchy-shell dock toggleSettings` |

A third surface, `dock/BarWidget.qml` (manifest `menubar/manifest.json`,
`kinds:["bar-widget"]`), is hosted by Omarchy's bar and shows **pinned icons
only** (`includeUnpinnedRunning: false`). It adopts the bar's own metrics:
icons at `Style.space(12)` (the bar's raster-icon size — `Style.bar.iconCanvas`
is the *glyph* canvas, which nerd-font glyphs only fill to ~11px), and
`thickness: bar.barSize` so the strip fills the bar. The bar's `Row`
top-aligns slots shorter than the bar, so a shorter strip would sit above the
bar's optical center.

**Dependency injection is mandatory.** Quickshell file singletons do not
resolve inside plugin directories, so `services/*.qml` are plain `QtObject`s
instantiated once in `dock/DockRoot.qml` and passed down as
`required property var config / theme / globals / hyprClients`. Never add a
singleton, never reach for a global — thread the property through.

## Layout

```
shell.qml                  standalone entry (ShellRoot)
PluginEntry.qml            plugin entry; panel contract: `opened` + open()/close()
manifest.json              dock plugin manifest (id haibv3.omarchy-dock)
menubar/manifest.json      bar-widget manifest (id haibv3.omarchy-dock-menubar)
dock/
  DockRoot.qml             instantiates services; one DockWindow per screen (Variants) + SettingsWindow
  DockWindow.qml           PanelWindow: layer-shell anchors, exclusiveZone, 4px hover strip, slide, input mask
  DockView.qml             ListView, drag-reorder, owns the ContextMenu
  DockIcon.qml             delegate: icon, running/urgent indicators, drag threshold
  AppModel.qml             merges Config.pinned + Hyprland toplevels for one monitor
  ContextMenu.qml          PopupWindow: window list, pin/unpin, close, settings, quit
  BarWidget.qml            bar-widget entry (pinned icons only)
services/
  Config.qml               ~/.config/omarchy-dock/config.json (FileView, watchChanges, atomicWrites)
  Theme.qml                ~/.local/state/omarchy/current/theme/colors.toml
  HyprClients.qml          `hyprctl clients -j` geometry for intellihide
  Globals.qml              settingsOpen flag + `dock` IPC target
settings/SettingsWindow.qml  FloatingWindow settings UI
ui/D*.qml                  themed controls (Button, Toggle, Slider, Field, Combo, SpinBox, Segmented)
install.sh, omarchy-dock.sh, omarchy-dock.desktop, assets/
docs/brainstorm-omarchy-dock.md   original design doc (Vietnamese)
```

## Commands

```bash
# Dev run — Quickshell hot-reloads on save. Dock appears as a layer-shell surface.
quickshell -p .                      # or: qs -p .

# Quit a standalone instance (IPC resolves the instance by config path)
quickshell ipc -p . call dock quit

# Lint. qmllint is NOT on PATH.
/usr/lib/qt6/bin/qmllint $(find . -name '*.qml' -not -path './.git/*')

# Validate plugin manifests
omarchy plugin validate .            # repo root (dock plugin) — passes
omarchy plugin validate ~/.config/omarchy/plugins/haibv3.omarchy-dock-menubar

# Install
./install.sh                         # launcher + .desktop + icon + login autostart
./install.sh --plugin                # copy into ~/.config/omarchy/plugins/, enable both
omarchy restart shell                # REQUIRED after keepLoaded plugin changes

# Plugin-mode control
omarchy-shell shell summon haibv3.omarchy-dock     # force dock visible
omarchy-shell shell hide haibv3.omarchy-dock       # resume autohide
omarchy-shell dock toggleSettings
```

`qmllint` must report **0 errors**. It emits many `unqualified access` warnings
— those are inherent to the DI pattern (child elements read `theme`/`config`
from the root) and are not defects. `dock/BarWidget.qml` additionally warns
`Failed to import qs.Commons`; also expected (see gotchas).

There is no test suite. Verify by launching, exercising the changed path, and
reading the log — Quickshell prints QML errors to stderr, and `qs log` reads
`/run/user/$UID/quickshell/by-id/<id>/log.qslog`.

## Architecture

```
Config (config.json) ─┐
Hyprland.toplevels ───┼─→ AppModel (one per screen) ─→ ListModel ─→ DockView ─→ DockIcon
DesktopEntries ───────┘                                                          │
                                                                        ContextMenu (PopupWindow)
HyprClients (hyprctl clients -j) ─→ DockWindow.edgeBusy ─→ autohide state machine
Theme (colors.toml) ─→ every visual
```

- **AppModel** merges `Config.pinned` (ordered) with running toplevels for one
  monitor. Pinned apps absorb their running windows into one row; running-but-
  unpinned apps append at the end. appId→entry matching order: exact id →
  lowercase id → `startupClass` → `heuristicLookup`.
- **DockWindow** is one layer-shell `PanelWindow` per selected screen, created
  only while `config.enabled` (or a plugin summon). It anchors the dock edge
  *plus both cross-axis ends* so the compositor sizes the
  surface to the free space; a fixed `screen.width/height` overflows and gets
  centered, shifting the pill off-center. A 4px strip keeps a small
  `exclusiveZone` while hidden so maximized windows can never cover the hover
  target. Autohide: `never` | `timer` (hide when not hovered) | `intellihide`
  (hide when a window touches the edge band, `thickness + 8`).
- **HyprClients** exists because `HyprlandToplevel` exposes no x/y/w/h. It polls
  `hyprctl clients -j`, debounced 120ms off the Hyprland event stream, and is
  only consulted when intellihide is active.
- **Config** persists on every property change; `_loaded`/`_applying` guard
  against save-on-load loops.
- **Theme** watches `theme.name` (a regular file) and re-toggles
  `colorsFile.path`, because `~/.local/state/omarchy/current/theme` is a symlink
  retargeted on theme-set.

## Conventions

- 4-space indent. `id: root` on every component. `required property var` for
  injected dependencies, `readonly property` for derived values, `_`-prefixed
  names for private state (`_rows`, `_loaded`, `_dragging`, `_pending`).
- Comments explain **why**, not what — most encode a constraint that forced the
  design (compositor behavior, API gaps, theme quirks). Keep that style.
- Colors come only from `theme.*`. Hover/state fills use the alpha-composited
  `theme.normalFill / hoverFill / trackFill / borderFill`, which composite
  `foreground` at low alpha. Do **not** use `lighterBackground` for hovers —
  some themes (e.g. solitude) set it equal to `background`, making hover
  invisible.
- `ui/D*.qml` controls take `required property var theme` and emit signals
  (`clicked`, `toggled`, `moved`, `selected`, `valueModified`). They never read
  `config` directly; the caller wires them.
- JS style: `const`/`let`, arrow functions, `for...of`.
- Commit messages: imperative subject; `Fix <area>: <detail>` for fixes. No
  conventional-commit prefixes.
- Code comments and README are English; `docs/` may be Vietnamese.

## Gotchas

1. **Adding a config option is a 4-place edit** in `services/Config.qml`:
   the property + default, an `_apply()` branch, a field in `save()`'s JSON
   literal, and an `onXChanged: save()` handler. Miss one and the option either
   never persists or never loads.
2. **Adding an AppModel row field is a 2-place edit**: the `model.append({...})`
   in `AppModel.rebuild()` and a matching `required property` in `DockIcon.qml`.
3. **`install.sh` copies an explicit directory list** (`{manifest.json,
   PluginEntry.qml,dock,services,settings,ui}` for the dock plugin;
   `{dock,services,settings,ui}` + `menubar/manifest.json` for the bar plugin).
   A new top-level directory must be added to both `cp -r` lines or it silently
   won't ship.
4. **`keepLoaded: true` means plugin code changes are not hot-reloaded.** Run
   `omarchy restart shell` after `./install.sh --plugin`, or you will test stale
   code. The installed plugin dir is a *snapshot* — editing the repo does not
   update it.
5. **`Qt.quit()` is gated on `canQuit`.** In plugin mode the dock shares the
   shell process; quitting would take down the whole desktop shell.
6. **`dock/BarWidget.qml` imports `qs.Commons`**, which Quickshell resolves to
   the *host shell's* config root (`/usr/share/omarchy/shell`), not this repo.
   It therefore only works inside omarchy-shell. A standalone run logs
   `Ignoring unresolvable import .../Commons` — expected and harmless.
7. **`menubar/manifest.json`'s entryPoint (`dock/BarWidget.qml`) resolves only
   after `install.sh` assembles the plugin dir**, so
   `omarchy plugin validate menubar` fails by design. Validate the installed
   directory instead.
8. **`AppModel` keeps `_rows` parallel to the ListModel** because ListModel
   drops QObject/array roles. `entry` and `toplevels` live only in `_rows` —
   read them via `rowAt(i)`, never off a model row.
9. **`dockScreens()` returns `[]` in plugin menubar mode**, so no dock windows
   are created when the menubar presentation is active.
10. **Standalone and plugin instances can run simultaneously** and share
    `~/.config/omarchy-dock/config.json`. Don't leave a standalone instance
    running while testing plugin mode — you'll be looking at two docks.
11. **`omarchy-dock.sh --autostart`** deliberately no-ops when the plugin is
    *installed* (enabled or not — a disabled plugin means the user turned the
    dock off) or `"autostart": false` is in the config, to avoid double-launching.
    The launcher entry itself re-enables a disabled plugin before opening
    settings, so `omarchy plugin disable haibv3.omarchy-dock` is never a dead end.
12. **`config.enabled` is the master switch.** Off means no `DockWindow` at all
    (`DockRoot.dockScreens()` returns `[]`) and no bar widget — not a hidden
    dock. A plugin summon still overrides it (`forceVisible`).
13. **"Start on login" means different things per host.** Standalone: `Config`
    owns the `o.launch_on_start("omarchy-dock --autostart")` line in
    `~/.config/hypr/autostart.lua` (add/remove on toggle; skipped when
    `standalone` is false). Plugin: the settings window drives the *plugin's*
    enabled state via `omarchy plugin enable|disable` and reads it back from
    `omarchy plugin list --json` — never mirror it in config.json.
