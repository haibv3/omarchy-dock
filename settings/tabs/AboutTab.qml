import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../ui"

// Settings → About: version, host and the config file in use.
ColumnLayout {
    id: root

    required property var config
    required property var theme
    required property var globals
    required property string displayMode

    property string appName: "Omarchy Dock"
    property string appDescription: ""
    property string version: ""

    // The manifest sits two levels up in every layout this file ships in:
    // the repo root, the dock plugin dir, and the menubar plugin dir (where
    // install.sh writes the menubar manifest to the plugin root).
    readonly property string manifestPath:
        Qt.resolvedUrl("../../manifest.json").toString().replace("file://", "")

    FileView {
        id: manifestFile
        path: root.manifestPath
        onLoaded: {
            try {
                const m = JSON.parse(manifestFile.text());
                if (m.name)
                    root.appName = m.name;
                if (m.description)
                    root.appDescription = m.description;
                if (m.version)
                    root.version = m.version;
            } catch (e) {
                console.warn("omarchy-dock: manifest parse failed:", e);
            }
        }
        onLoadFailed: console.warn("omarchy-dock: manifest.json not found at", path)
    }

    component InfoRow: RowLayout {
        required property var theme
        property string label: ""
        property string value: ""

        Layout.fillWidth: true
        spacing: 20

        Text {
            Layout.preferredWidth: 124
            Layout.maximumWidth: 124
            text: parent.label
            color: parent.theme.mutedText
            font.pixelSize: 12
        }

        Text {
            Layout.fillWidth: true
            text: parent.value
            color: parent.theme.foreground
            font.pixelSize: 12
            elide: Text.ElideMiddle
        }
    }

    spacing: 0

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 26
        spacing: 14

        Rectangle {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            radius: root.theme.radiusWindow
            color: root.theme.selection

            Text {
                anchors.centerIn: parent
                text: String.fromCodePoint(0xF003B)
                color: root.theme.accent
                font.pixelSize: 22
                font.family: root.theme.fontMono
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            Text {
                Layout.fillWidth: true
                text: root.appName
                color: root.theme.foreground
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.appDescription
                color: root.theme.mutedText
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                lineHeight: 1.2
            }
        }
    }

    DSectionLabel {
        theme: root.theme
        label: "BUILD"
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        InfoRow {
            theme: root.theme
            label: "Version"
            value: root.version !== "" ? root.version : "unknown"
        }

        InfoRow {
            theme: root.theme
            label: "Host"
            value: root.globals.canQuit ? "Standalone (own process)" : "Omarchy shell plugin"
        }

        InfoRow {
            theme: root.theme
            label: "Presentation"
            value: root.displayMode === "dock" ? "Dock" : "Menubar widget"
        }

        InfoRow {
            theme: root.theme
            label: "Palette"
            value: root.config.palette === "signal" ? "Signal Dark" : "Omarchy host theme"
        }
    }

    DSectionLabel {
        theme: root.theme
        label: "CONFIG"
        Layout.topMargin: 30
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 12

        InfoRow {
            theme: root.theme
            label: "File"
            value: "~/.config/omarchy-dock/config.json"
        }

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "Every change in this window is written to that file immediately and hot-reloaded by the running dock — no restart needed."
            color: root.theme.mutedText
            font.pixelSize: 11
            lineHeight: 1.2
        }
    }
}
