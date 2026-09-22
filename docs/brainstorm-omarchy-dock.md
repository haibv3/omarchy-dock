# Brainstorm: omarchy-dock

Date: 2026-09-22 · Status: approved → implementing

## Problem
Omarchy (Hyprland/Wayland) có bar trên top nhưng không có dock kiểu Ubuntu/macOS: pin app hay dùng, thấy app đang chạy, truy cập nhanh.

## Requirements (đã chốt)
- Stack: **Quickshell/QML** — cùng stack omarchy-shell, layer-shell/autohide/position có sẵn.
- Deploy: **standalone trước** (`quickshell -p`), đóng gói thành Omarchy plugin (`kinds:["panel"]`, `keepLoaded`) sau.
- Nội dung dock: pinned apps + running apps gộp vào icon đã pin (indicator), app chưa pin append cuối.
- Settings: GUI riêng trong app (FloatingWindow).
- Scope v1: pin/unpin, drag reorder, intellihide, đồng bộ theme Omarchy, chọn monitor.
- Out of scope v1: window preview, notification badges, launcher/search.

## Evaluated approaches
| Hướng | Ưu | Nhược | Quyết định |
|---|---|---|---|
| Omarchy shell plugin | Dùng chung theme/services, `omarchy plugin add` | Bug dock ảnh hưởng shell; dev reload cả shell | Phase 2 |
| Standalone Quickshell | Cô lập, dễ dev/debug | Process thứ 2, tự đọc theme + IPC | **v1** |
| GTK4 + gtk4-layer-shell | Binary độc lập | Cần cài thêm lib, tự viết nhiều thứ | Loại |

## Design
```
shell.qml              ShellRoot → Variants per selected screen → DockWindow
dock/DockWindow.qml    PanelWindow layer-shell: anchors theo edge, exclusiveZone,
                       slide animation, hover strip 4px (exclusiveZone=strip khi ẩn
                       để maximized window không che mất strip)
dock/DockView.qml      ListView ngang/dọc: ListModel, drag-reorder (Drag/DropArea),
                       running dot, urgent dot, context menu
dock/AppModel.qml      merge Config.pinned + Hyprland.toplevels (per monitor);
                       match appId ↔ DesktopEntry (id/startupClass/heuristicLookup)
dock/DockIcon.qml      delegate: icon, indicators, tooltip, MouseArea, drag
dock/ContextMenu.qml   PopupWindow: windows list, Pin/Unpin, Close, Settings
settings/SettingsWindow.qml  FloatingWindow: position/size/autohide/delay/monitor/pins
services/Config.qml    Singleton: FileView ~/.config/omarchy-dock/config.json,
                       watchChanges, atomicWrites, JSON parse thủ công
services/Theme.qml     Singleton: colors.toml từ ~/.local/state/omarchy/current/theme/
                       (watch theme.name → re-resolve symlink)
services/HyprClients.qml  Singleton: poll `hyprctl clients -j` (debounced rawEvent)
                       → geometry cho intellihide (HyprlandToplevel thiếu x/y/w/h)
services/Globals.qml   Singleton: settingsOpen flag
```

## Key decisions
- **Hover strip 4px giữ exclusiveZone khi ẩn** — fix lỗi maximized window che strip (advisor).
- **Theme/config qua singleton mỏng** — port sang plugin chỉ cần swap Theme/Config (advisor).
- **Intellihide** = overlap test client rect vs edge band trên active workspace của monitor.
- **appId↔desktop match**: exact → lowercase → startupClass → heuristicLookup; log miss.
- Launch: `DesktopEntry.execute()`. Focus: `toplevel.wayland.activate()`.

## Risks
- appId mismatch (Flatpak, `code` vs `code-url-handler`) → heuristic + log.
- Quickshell 0.3.1 API drift → pin version trong README.
- `hyprctl clients` poll → debounce 120ms, chỉ khi intellihide bật.

## Acceptance criteria
1. Dock hiện đúng edge, exclusive zone đúng.
2. Pin/unpin từ context menu; thứ tự persist qua restart.
3. Running indicator; click focus/launch đúng; app chưa pin biến mất khi đóng.
4. Settings apply ngay, persist config.json.
5. Intellihide: window chạm edge → ẩn; đóng/minimize → hiện.
6. Đổi Omarchy theme → màu dock đổi theo.
