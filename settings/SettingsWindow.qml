import QtQuick
import QtQuick.Layouts
import Quickshell
import "../services"
import "../ui"

FloatingWindow {
    id: win

    required property var config
    required property var theme
    required property var globals

    title: "Omarchy Dock Settings"
    visible: globals.settingsOpen
    onVisibleChanged: {
        if (!visible && globals.settingsOpen)
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
        color: theme.lighterBackground
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
                    text: "Dock"
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
                    label: "Hide delay"
                    visible: config.autohide !== "never"
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
                        color: pinMa.containsMouse ? theme.lighterBackground
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
                                color: unpinMa.containsMouse ? theme.red
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
                    border.color: theme.lighterBackground
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
                            color: addMa.containsMouse ? theme.lighterBackground
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
