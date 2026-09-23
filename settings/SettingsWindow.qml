import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../services"
import "../ui"

FloatingWindow {
    id: win

    required property var config
    required property var theme
    required property var globals
    readonly property string activeDisplayMode:
        globals.canQuit ? "dock" : config.displayMode

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


    title: win.activeDisplayMode === "menubar"
        ? "Omarchy Menubar Apps" : "Omarchy Dock Settings"
    visible: globals.settingsOpen
    onVisibleChanged: {
        if (visible)
            win.refreshPluginState();
        else if (globals.settingsOpen)
            globals.closeSettings();
    }
    implicitWidth: 480
    implicitHeight: 640
    minimumSize: Qt.size(420, 480)
    color: theme.background

    // ---- shared building blocks ----
    component SectionLabel: Text {
        property string label: ""
        text: label
        color: theme.darkForeground
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 1.4
    }

    component Separator: Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 20
        Layout.rightMargin: 20
        height: 1
        color: theme.borderFill
        opacity: 0.6
    }

    // one settings row: label left, control right
    component FormRow: RowLayout {
        property string label: ""
        default property alias content: slot.data
        Layout.fillWidth: true
        spacing: 16
        Text {
            Layout.preferredWidth: 110
            text: label
            color: theme.foreground
            font.pixelSize: 13
        }
        Item {
            id: slot
            Layout.fillWidth: true
            implicitHeight: children.length ? children[0].implicitHeight : 0
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 0

            // ---------- header ----------
            RowLayout {
                Layout.fillWidth: true
                Layout.margins: 20
                Layout.bottomMargin: 12
                Text {
                    Layout.fillWidth: true
                    text: win.activeDisplayMode === "menubar" ? "Menubar apps" : "Dock"
                    color: theme.foreground
                    font.pixelSize: 20
                    font.bold: true
                }
                DButton {
                    theme: win.theme
                    text: "✕"
                    onClicked: globals.closeSettings()
                }
            }

            // ---------- master switch ----------
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 18
                FormRow {
                    label: win.activeDisplayMode === "menubar" ? "Show in bar" : "Show dock"
                    DToggle {
                        theme: win.theme
                        checked: config.enabled
                        onToggled: c => config.enabled = c
                    }
                }
            }

            // ---------- appearance ----------
            SectionLabel {
                label: "APPEARANCE"
                Layout.leftMargin: 20
                Layout.bottomMargin: 10
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 14
                FormRow {
                    visible: !globals.canQuit
                    label: "Show in"
                    DSegmented {
                        theme: win.theme
                        width: parent.width
                        options: [
                            { label: "Dock", value: "dock" },
                            { label: "Menubar", value: "menubar" }
                        ]
                        currentValue: config.displayMode
                        onSelected: v => config.displayMode = v
                    }
                }

                FormRow {
                    visible: win.activeDisplayMode === "dock"
                    label: "Position"
                    DSegmented {
                        theme: win.theme
                        width: parent.width
                        options: [
                            { label: "Top", value: "top" },
                            { label: "Bottom", value: "bottom" },
                            { label: "Left", value: "left" },
                            { label: "Right", value: "right" }
                        ]
                        currentValue: config.position
                        onSelected: v => config.position = v
                    }
                }

                FormRow {
                    visible: win.activeDisplayMode === "dock"
                    label: "Icon size"
                    RowLayout {
                        width: parent.width
                        spacing: 12
                        DSlider {
                            theme: win.theme
                            Layout.fillWidth: true
                            from: 24; to: 96; stepSize: 4
                            value: config.iconSize
                            onMoved: v => config.iconSize = v
                        }
                        Text {
                            Layout.preferredWidth: 44
                            horizontalAlignment: Text.AlignRight
                            text: config.iconSize + "px"
                            color: theme.darkForeground
                            font.pixelSize: 12
                        }
                    }
                }
                FormRow {
                    visible: win.activeDisplayMode === "dock"
                    label: "Transparent background"
                    DToggle {
                        theme: win.theme
                        checked: config.transparentBackground
                        onToggled: c => config.transparentBackground = c
                    }
                }
            }

            Separator { Layout.topMargin: 18; Layout.bottomMargin: 14 }

            // ---------- behavior ----------
            SectionLabel {
                label: "BEHAVIOR"
                Layout.leftMargin: 20
                Layout.bottomMargin: 10
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                spacing: 14

                FormRow {
                    visible: win.activeDisplayMode === "dock"
                    label: "Auto-hide"
                    DSegmented {
                        theme: win.theme
                        width: parent.width
                        options: [
                            { label: "Never", value: "never" },
                            { label: "Delay", value: "timer" },
                            { label: "Smart", value: "intellihide" }
                        ]
                        currentValue: config.autohide
                        onSelected: v => config.autohide = v
                    }
                }

                FormRow {
                    label: "Start on login"
                    DToggle {
                        theme: win.theme
                        checked: globals.canQuit ? config.autostart : win.pluginEnabled
                        onToggled: c => win.setStartOnLogin(c)
                    }
                }

                Text {
                    visible: !globals.canQuit
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: win.activeDisplayMode === "menubar"
                        ? "Off removes the pinned-app widget from the bar. Turn it back on here or from Omarchy menu → Setup → Plugins."
                        : "Off disables the Omarchy Dock plugin, which closes this window too. Re-enable it from the app launcher (Omarchy Dock) or Omarchy menu → Setup → Plugins."
                    color: theme.muted
                    font.pixelSize: 11
                }

                FormRow {
                    label: "Hide delay"
                    visible: win.activeDisplayMode === "dock" && config.autohide !== "never"
                    DSpinBox {
                        theme: win.theme
                        width: 140
                        from: 0; to: 3000; stepSize: 100
                        value: config.hideDelay
                        suffix: " ms"
                        onValueModified: v => config.hideDelay = v
                    }
                }

                FormRow {
                    visible: win.activeDisplayMode === "dock"
                    label: "Monitor"
                    DCombo {
                        theme: win.theme
                        width: 200
                        model: {
                            const out = [{ label: "All monitors", value: "all" }];
                            for (const s of Quickshell.screens)
                                out.push({ label: s.name, value: s.name });
                            return out;
                        }
                        currentValue: config.monitor
                        onSelected: v => config.monitor = v
                    }
                }
            }

            Separator { Layout.topMargin: 18; Layout.bottomMargin: 14 }

            // ---------- pinned apps ----------
            SectionLabel {
                label: "PINNED APPS"
                Layout.leftMargin: 20
                Layout.bottomMargin: 10
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 16
                spacing: 8

                // current pins
                Repeater {
                    model: config.pinned
                    delegate: Rectangle {
                        required property string modelData
                        required property int index
                        Layout.fillWidth: true
                        height: 38
                        radius: 8
                        color: pinMa.containsMouse ? theme.hoverFill
                                                   : theme.darkerBackground
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 8
                            spacing: 10
                            Image {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 22
                                source: {
                                    const e = DesktopEntries.byId(modelData);
                                    if (!e || !e.icon)
                                        return "";
                                    const p = Quickshell.iconPath(e.icon);
                                    if (!p)
                                        return "";
                                    return p.indexOf("://") !== -1 ? p : "file://" + p;
                                }
                                fillMode: Image.PreserveAspectFit
                            }
                            Text {
                                Layout.fillWidth: true
                                text: {
                                    const e = DesktopEntries.byId(modelData);
                                    return e ? e.name : modelData;
                                }
                                color: theme.foreground
                                font.pixelSize: 13
                                elide: Text.ElideRight
                            }
                            Rectangle {
                                width: 26
                                height: 26
                                radius: 6
                                color: unpinMa.containsMouse ? theme.brightRed
                                                             : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "✕"
                                    color: unpinMa.containsMouse
                                        ? theme.darkerBackground
                                        : theme.darkForeground
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    id: unpinMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: config.unpin(modelData)
                                }
                            }
                        }
                        MouseArea {
                            id: pinMa
                            anchors.fill: parent
                            anchors.rightMargin: 34
                            hoverEnabled: true
                        }
                    }
                }

                Text {
                    visible: config.pinned.length === 0
                    text: "No pinned apps — add some below."
                    color: theme.muted
                    font.pixelSize: 12
                    Layout.bottomMargin: 4
                }

                DField {
                    id: filter
                    theme: win.theme
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    placeholder: "Search applications…"
                }

                // app picker
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 190
                    radius: 9
                    color: theme.darkerBackground
                    border.color: theme.borderFill
                    border.width: 1
                    clip: true

                    ListView {
                        id: appList
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 2
                        model: {
                            const q = filter.text.toLowerCase();
                            const out = [];
                            const apps = DesktopEntries.applications.values;
                            for (const e of apps) {
                                if (e.noDisplay)
                                    continue;
                                if (q !== ""
                                    && e.name.toLowerCase().indexOf(q) === -1)
                                    continue;
                                out.push(e);
                            }
                            out.sort((a, b) => a.name.localeCompare(b.name));
                            return out;
                        }
                        delegate: Rectangle {
                            required property var modelData
                            width: appList.width
                            height: 34
                            radius: 7
                            color: addMa.containsMouse ? theme.hoverFill
                                                       : "transparent"
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 10
                                spacing: 10
                                Image {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    source: {
                                        if (!modelData.icon)
                                            return "";
                                        const p = Quickshell.iconPath(modelData.icon);
                                        if (!p)
                                            return "";
                                        return p.indexOf("://") !== -1 ? p : "file://" + p;
                                    }
                                    fillMode: Image.PreserveAspectFit
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name
                                    color: config.isPinned(modelData.id)
                                        ? theme.muted : theme.foreground
                                    font.pixelSize: 13
                                    elide: Text.ElideRight
                                }
                                Text {
                                    visible: config.isPinned(modelData.id)
                                    text: "pinned"
                                    color: theme.accent
                                    font.pixelSize: 11
                                }
                            }
                            MouseArea {
                                id: addMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                enabled: !config.isPinned(modelData.id)
                                onClicked: config.pin(modelData.id)
                            }
                        }
                    }
                }
            }
        }
    }
}
