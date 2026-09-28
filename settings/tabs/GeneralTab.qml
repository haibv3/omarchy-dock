import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../ui"

// Settings → General: master switch, presentation, startup, display.
ColumnLayout {
    id: root

    required property var config
    required property var theme
    required property var globals
    required property string displayMode      // effective: dock | menubar
    required property bool pluginEnabled
    signal startOnLoginToggled(bool value)

    readonly property bool dockMode: root.displayMode === "dock"

    spacing: 0

    DSectionLabel {
        theme: root.theme
        label: "VISIBILITY"
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 18

        DSettingRow {
            theme: root.theme
            label: root.dockMode ? "Show dock" : "Show in bar"
            description: "Master switch. Off removes the dock entirely."
            DToggle {
                theme: root.theme
                checked: root.config.enabled
                onToggled: c => root.config.enabled = c
            }
        }

        DSettingRow {
            visible: !root.globals.canQuit
            theme: root.theme
            label: "Show in"
            description: "Dock: a floating bar on one edge. Menubar: icons in the Omarchy bar."
            DSegmented {
                theme: root.theme
                width: parent.width
                options: [
                    { label: "Dock", value: "dock" },
                    { label: "Menubar", value: "menubar" }
                ]
                currentValue: root.config.displayMode
                onSelected: v => root.config.displayMode = v
            }
        }
    }

    DSectionLabel {
        theme: root.theme
        label: "STARTUP"
        Layout.topMargin: 30
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        DSettingRow {
            theme: root.theme
            label: "Start on login"
            description: root.globals.canQuit
                ? "Launch the dock when Hyprland starts."
                : "Enable the plugin so the shell loads it at login."
            DToggle {
                theme: root.theme
                checked: root.globals.canQuit ? root.config.autostart : root.pluginEnabled
                onToggled: c => root.startOnLoginToggled(c)
            }
        }

        // Plugin mode only: the toggle drives the plugin's enabled state, and
        // turning it off takes this window down with it — say so up front.
        Text {
            visible: !root.globals.canQuit
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: root.dockMode
                ? "Off disables the Omarchy Dock plugin, which closes this window too. Re-enable it from the app launcher (Omarchy Dock) or Omarchy menu → Setup → Plugins."
                : "Off removes the pinned-app widget from the bar. Turn it back on here or from Omarchy menu → Setup → Plugins."
            color: root.theme.mutedText
            font.pixelSize: 11
            lineHeight: 1.2
        }
    }

    DSectionLabel {
        visible: root.dockMode
        theme: root.theme
        label: "DISPLAY"
        Layout.topMargin: 30
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        visible: root.dockMode
        Layout.fillWidth: true
        spacing: 18

        DSettingRow {
            theme: root.theme
            label: "Monitor"
            description: "Screen that hosts the dock."
            DCombo {
                theme: root.theme
                width: parent.width
                model: {
                    const out = [{ label: "All monitors", value: "all" }];
                    for (const s of Quickshell.screens)
                        out.push({ label: s.name, value: s.name });
                    return out;
                }
                currentValue: root.config.monitor
                onSelected: v => root.config.monitor = v
            }
        }
    }
}
