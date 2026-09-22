import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../services"

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
    implicitWidth: 420
    implicitHeight: 480
    minimumSize: Qt.size(360, 400)
    color: theme.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Dock"
            color: theme.foreground
            font.pixelSize: 18
            font.bold: true
        }

        // ---- position ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Position"; color: theme.foreground; Layout.fillWidth: true }
            ComboBox {
                model: ["top", "bottom", "left", "right"]
                currentIndex: model.indexOf(config.position)
                onActivated: config.position = model[currentIndex]
            }
        }

        // ---- icon size ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Icon size"; color: theme.foreground; Layout.fillWidth: true }
            Slider {
                id: sizeSlider
                from: 24; to: 96; stepSize: 4
                value: config.iconSize
                Layout.preferredWidth: 160
                onMoved: config.iconSize = value
            }
            Text {
                text: config.iconSize + "px"
                color: theme.darkForeground
                Layout.preferredWidth: 42
            }
        }

        // ---- autohide ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Auto-hide"; color: theme.foreground; Layout.fillWidth: true }
            ComboBox {
                model: ListModel {
                    ListElement { label: "Never"; value: "never" }
                    ListElement { label: "After delay"; value: "timer" }
                    ListElement { label: "When window near (intellihide)"; value: "intellihide" }
                }
                textRole: "label"
                valueRole: "value"
                currentIndex: Math.max(0, ["never","timer","intellihide"].indexOf(config.autohide))
                onActivated: config.autohide = currentValue
            }
        }

        // ---- hide delay ----
        RowLayout {
            Layout.fillWidth: true
            visible: config.autohide !== "never"
            Text { text: "Hide delay"; color: theme.foreground; Layout.fillWidth: true }
            SpinBox {
                from: 0; to: 3000; stepSize: 100
                value: config.hideDelay
                onValueModified: config.hideDelay = value
            }
            Text { text: "ms"; color: theme.darkForeground }
        }

        // ---- monitor ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Monitor"; color: theme.foreground; Layout.fillWidth: true }
            ComboBox {
                model: {
                    const names = ["all"];
                    for (const s of Quickshell.screens)
                        names.push(s.name);
                    return names;
                }
                currentIndex: Math.max(0, model.indexOf(config.monitor))
                onActivated: config.monitor = model[currentIndex]
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: theme.muted; opacity: 0.4 }

        // ---- pinned apps ----
        Text {
            text: "Pinned apps"
            color: theme.foreground
            font.pixelSize: 14
            font.bold: true
        }

        ListView {
            id: pinList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: config.pinned
            spacing: 2
            delegate: Rectangle {
                required property string modelData
                required property int index
                width: pinList.width
                height: 32
                radius: 6
                color: pinMa.containsMouse ? theme.lighterBackground : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    Text {
                        Layout.fillWidth: true
                        text: {
                            const e = DesktopEntries.byId(modelData);
                            return e ? e.name : modelData;
                        }
                        color: theme.foreground
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "✕"
                        color: theme.red
                        MouseArea {
                            id: pinMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: config.unpin(modelData)
                        }
                    }
                }
            }
        }

        // add app
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            TextField {
                id: filter
                Layout.fillWidth: true
                placeholderText: "Filter applications…"
                color: theme.foreground
                background: Rectangle {
                    color: theme.darkerBackground
                    radius: 6
                    border.color: theme.muted
                }
            }
        }
        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 140
            clip: true
            model: {
                const q = filter.text.toLowerCase();
                const out = [];
                const apps = DesktopEntries.applications.values;
                for (const e of apps) {
                    if (e.noDisplay)
                        continue;
                    if (q !== "" && e.name.toLowerCase().indexOf(q) === -1)
                        continue;
                    out.push(e);
                }
                return out;
            }
            delegate: Rectangle {
                required property var modelData
                width: parent.width
                height: 30
                radius: 6
                color: addMa.containsMouse ? theme.lighterBackground : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name + (config.isPinned(modelData.id) ? "  (pinned)" : "")
                        color: config.isPinned(modelData.id) ? theme.muted : theme.foreground
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: addMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !config.isPinned(modelData.id)
                    onClicked: config.pin(modelData.id)
                }
            }
        }
    }
}
