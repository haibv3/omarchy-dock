import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../ui"
import "tabs"

// Settings shell: a fixed sidebar of tabs plus one scrolling pane per tab.
// Each page lives in settings/tabs/ and takes config/theme as required
// properties — no singletons (see AGENTS.md).
FloatingWindow {
    id: win

    required property var config
    required property var theme
    required property var globals

    readonly property string activeDisplayMode:
        globals.canQuit ? "dock" : config.displayMode
    readonly property bool dockMode: win.activeDisplayMode === "dock"

    // ---- "Start on login" in plugin mode ----
    // The shell loads enabled plugins at login, so there the toggle drives the
    // plugin's enabled state. The state is read back from the shell instead of
    // mirrored in our config, so a change made from the Omarchy menu (Setup →
    // Plugins) shows up here too.
    readonly property string pluginId: win.activeDisplayMode === "menubar"
        ? "haibv3.omarchy-dock-menubar" : "haibv3.omarchy-dock"
    property bool pluginEnabled: true

    function refreshPluginState() {
        if (!globals.canQuit)
            pluginListProc.running = true;
    }

    function setStartOnLogin(v) {
        // Keep the standalone hook's gate consistent with the choice.
        config.autostart = v;
        if (globals.canQuit)
            return; // Config syncs the hypr autostart hook itself
        pluginCmdProc.command = ["omarchy", "plugin", v ? "enable" : "disable", win.pluginId];
        pluginCmdProc.running = true;
    }

    Process {
        id: pluginListProc
        command: ["omarchy", "plugin", "list", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    for (const p of JSON.parse(this.text)) {
                        if (p.id === win.pluginId) {
                            win.pluginEnabled = p.enabled === true;
                            break;
                        }
                    }
                } catch (e) {
                    console.warn("omarchy-dock: plugin list parse failed:", e);
                }
            }
        }
    }

    Process {
        id: pluginCmdProc
        onExited: function () { win.refreshPluginState(); }
    }

    // ---- tabs ----
    // Dock-only pages drop out of the rail while the menubar presentation is
    // active, so the rail never offers a page with nothing to configure.
    // Glyphs are nerd-font codepoints (cog, palette, tune, pin, info).
    readonly property var tabs: {
        const t = [
            { id: "general", glyph: String.fromCodePoint(0xF0493), label: "General",
              title: "General", desc: "Visibility, startup and display." },
            { id: "appearance", glyph: String.fromCodePoint(0xF03D8), label: "Appearance",
              title: "Appearance", desc: "Palette, placement and icon sizing." }
        ];
        if (win.dockMode)
            t.push({ id: "behavior", glyph: String.fromCodePoint(0xF062E), label: "Behavior",
                     title: "Behavior", desc: "How the dock hides and reveals itself." });
        t.push(
            { id: "pinned", glyph: String.fromCodePoint(0xF0403), label: "Pinned apps",
              title: "Pinned apps", desc: "Apps that stay on the dock, in order." },
            { id: "about", glyph: String.fromCodePoint(0xF02FC), label: "About",
              title: "About", desc: "Version, host and the config file in use." }
        );
        return t;
    }

    // Selection is tracked by id, not index: the rail shrinks when a dock-only
    // page drops out, and a stored index would silently land on another page.
    property string tabId: "general"
    readonly property int tabIndex: {
        for (let i = 0; i < win.tabs.length; i++)
            if (win.tabs[i].id === win.tabId)
                return i;
        return 0;
    }
    readonly property var currentTab: win.tabs[win.tabIndex]

    title: win.activeDisplayMode === "menubar"
        ? "Omarchy Menubar Apps" : "Omarchy Dock Settings"
    visible: globals.settingsOpen
    onVisibleChanged: {
        if (visible)
            win.refreshPluginState();
        else if (globals.settingsOpen)
            globals.closeSettings();
    }
    // Preferred size only: Hyprland tiles this toplevel, so the compositor
    // decides the real size (see AGENTS.md gotcha 14). The layout is built to
    // work from ~560px wide up.
    implicitWidth: 800
    implicitHeight: 560
    minimumSize: Qt.size(660, 440)
    color: theme.background

    // Escape closes the window once it holds keyboard focus (click anywhere
    // in it first — FloatingWindow has no grabFocus, unlike PopupWindow).
    Shortcut {
        sequence: "Escape"
        onActivated: globals.closeSettings()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ---------- sidebar ----------
        Rectangle {
            Layout.preferredWidth: 180
            Layout.fillHeight: true
            color: theme.darkerBackground

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: theme.borderFill
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.topMargin: 6
                    Layout.bottomMargin: 20
                    spacing: 10

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: theme.radiusControl
                        color: theme.selection

                        Text {
                            anchors.centerIn: parent
                            text: String.fromCodePoint(0xF003B)
                            color: theme.accent
                            font.pixelSize: 15
                            font.family: theme.fontMono
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: "Omarchy Dock"
                            color: theme.foreground
                            font.pixelSize: 13
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: win.dockMode ? "DOCK" : "MENUBAR"
                            color: theme.mutedText
                            font.pixelSize: 10
                            font.family: theme.fontMono
                            font.letterSpacing: 1.2
                        }
                    }
                }

                Repeater {
                    model: win.tabs

                    delegate: DNavItem {
                        required property var modelData

                        Layout.fillWidth: true
                        Layout.bottomMargin: 2
                        theme: win.theme
                        glyph: modelData.glyph
                        label: modelData.label
                        selected: modelData.id === win.currentTab.id
                        onClicked: win.tabId = modelData.id
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.bottomMargin: 8
                    Layout.preferredHeight: 1
                    color: theme.borderFill
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 6
                    Layout.rightMargin: 6
                    Layout.bottomMargin: 6
                    text: globals.canQuit ? "Standalone" : "Omarchy shell plugin"
                    color: theme.mutedText
                    font.pixelSize: 10
                    font.family: theme.fontMono
                    elide: Text.ElideRight
                }
            }
        }

        // ---------- content ----------
        Item {
            id: pane
            Layout.fillWidth: true
            Layout.fillHeight: true

            Item {
                id: header
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 74

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 24
                    anchors.rightMargin: 16
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: win.currentTab.title
                            color: theme.foreground
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: win.currentTab.desc
                            color: theme.mutedText
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                    }

                    DButton {
                        theme: win.theme
                        text: String.fromCodePoint(0xF0156)
                        onClicked: globals.closeSettings()
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: theme.borderFill
                }
            }

            Flickable {
                id: flick
                anchors.top: header.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                contentHeight: tabColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                // Only the active page is visible, so the column's implicit
                // height is exactly the active page's height.
                ColumnLayout {
                    id: tabColumn
                    width: flick.width
                    spacing: 0

                    GeneralTab {
                        Layout.fillWidth: true
                        Layout.margins: 20
                        visible: win.currentTab.id === "general"
                        config: win.config
                        theme: win.theme
                        globals: win.globals
                        displayMode: win.activeDisplayMode
                        pluginEnabled: win.pluginEnabled
                        onStartOnLoginToggled: v => win.setStartOnLogin(v)
                    }

                    AppearanceTab {
                        Layout.fillWidth: true
                        Layout.margins: 20
                        visible: win.currentTab.id === "appearance"
                        config: win.config
                        theme: win.theme
                        dockMode: win.dockMode
                    }

                    BehaviorTab {
                        Layout.fillWidth: true
                        Layout.margins: 20
                        visible: win.currentTab.id === "behavior"
                        config: win.config
                        theme: win.theme
                    }

                    PinnedTab {
                        Layout.fillWidth: true
                        Layout.margins: 20
                        visible: win.currentTab.id === "pinned"
                        config: win.config
                        theme: win.theme
                        // Pane height minus this page's margins, so the pinned
                        // list + picker split the viewport instead of stacking
                        // into one scrollable column.
                        pageHeight: flick.height - 40
                    }

                    AboutTab {
                        Layout.fillWidth: true
                        Layout.margins: 20
                        visible: win.currentTab.id === "about"
                        config: win.config
                        theme: win.theme
                        globals: win.globals
                        displayMode: win.activeDisplayMode
                    }
                }
            }

            // bottom fade — affordance for the column overflowing the window;
            // Signal Dark keeps it a gradient, not a scrollbar restyle. Shown
            // only while there is actually content below the fold.
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 34
                visible: flick.contentHeight > flick.height + 1
                         && flick.contentY < flick.contentHeight - flick.height - 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: theme.background }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 2
                    text: "▼ scroll"
                    color: theme.mutedText
                    font.pixelSize: 11
                    font.family: theme.fontMono
                    font.letterSpacing: 1.2
                }
            }
        }
    }

    onTabIdChanged: flick.contentY = 0
}
