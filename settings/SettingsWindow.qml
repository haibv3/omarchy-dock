import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import "../services"

FloatingWindow {
    id: win

    title: "Omarchy Dock Settings"
    visible: Globals.settingsOpen
    onVisibleChanged: {
        if (!visible && Globals.settingsOpen)
            Globals.closeSettings();
    }
    implicitWidth: 420
    implicitHeight: 480
    minimumSize: Qt.size(360, 400)
    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Text {
            text: "Dock"
            color: Theme.foreground
            font.pixelSize: 18
            font.bold: true
        }

        // ---- position ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Position"; color: Theme.foreground; Layout.fillWidth: true }
            ComboBox {
                model: ["top", "bottom", "left", "right"]
                currentIndex: model.indexOf(Config.position)
                onActivated: Config.position = model[currentIndex]
            }
        }

        // ---- icon size ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Icon size"; color: Theme.foreground; Layout.fillWidth: true }
            Slider {
                id: sizeSlider
                from: 24; to: 96; stepSize: 4
                value: Config.iconSize
                Layout.preferredWidth: 160
                onMoved: Config.iconSize = value
            }
            Text {
                text: Config.iconSize + "px"
                color: Theme.darkForeground
                Layout.preferredWidth: 42
            }
        }

        // ---- autohide ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Auto-hide"; color: Theme.foreground; Layout.fillWidth: true }
            ComboBox {
                model: ListModel {
                    ListElement { label: "Never"; value: "never" }
                    ListElement { label: "After delay"; value: "timer" }
                    ListElement { label: "When window near (intellihide)"; value: "intellihide" }
                }
                textRole: "label"
                valueRole: "value"
                currentIndex: Math.max(0, ["never","timer","intellihide"].indexOf(Config.autohide))
                onActivated: Config.autohide = currentValue
            }
        }

        // ---- hide delay ----
        RowLayout {
            Layout.fillWidth: true
            visible: Config.autohide !== "never"
            Text { text: "Hide delay"; color: Theme.foreground; Layout.fillWidth: true }
            SpinBox {
                from: 0; to: 3000; stepSize: 100
                value: Config.hideDelay
                onValueModified: Config.hideDelay = value
            }
            Text { text: "ms"; color: Theme.darkForeground }
        }

        // ---- monitor ----
        RowLayout {
            Layout.fillWidth: true
            Text { text: "Monitor"; color: Theme.foreground; Layout.fillWidth: true }
            ComboBox {
                model: {
                    const names = ["all"];
                    for (const s of Quickshell.screens)
                        names.push(s.name);
                    return names;
                }
                currentIndex: Math.max(0, model.indexOf(Config.monitor))
                onActivated: Config.monitor = model[currentIndex]
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.muted; opacity: 0.4 }

        // ---- pinned apps ----
        Text {
            text: "Pinned apps"
            color: Theme.foreground
            font.pixelSize: 14
            font.bold: true
        }

        ListView {
            id: pinList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: Config.pinned
            spacing: 2
            delegate: Rectangle {
                required property string modelData
                required property int index
                width: pinList.width
                height: 32
                radius: 6
                color: pinMa.containsMouse ? Theme.lighterBackground : "transparent"
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
                        color: Theme.foreground
                        elide: Text.ElideRight
                    }
                    Text {
                        text: "✕"
                        color: Theme.red
                        MouseArea {
                            id: pinMa
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Config.unpin(modelData)
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
                color: Theme.foreground
                background: Rectangle {
                    color: Theme.darkerBackground
                    radius: 6
                    border.color: Theme.muted
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
                color: addMa.containsMouse ? Theme.lighterBackground : "transparent"
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    Text {
                        Layout.fillWidth: true
                        text: modelData.name + (Config.isPinned(modelData.id) ? "  (pinned)" : "")
                        color: Config.isPinned(modelData.id) ? Theme.muted : Theme.foreground
                        elide: Text.ElideRight
                    }
                }
                MouseArea {
                    id: addMa
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !Config.isPinned(modelData.id)
                    onClicked: Config.pin(modelData.id)
                }
            }
        }
    }
}
