import QtQuick
import QtQuick.Layouts
import "../../ui"

// Settings → Appearance: palette, placement, icon sizing.
ColumnLayout {
    id: root

    required property var config
    required property var theme
    required property bool dockMode

    spacing: 0

    DSectionLabel {
        theme: root.theme
        label: "THEME"
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 18

        DSettingRow {
            theme: root.theme
            label: "Palette"
            description: "Signal Dark ships with the dock; Omarchy follows the host theme."
            DSegmented {
                theme: root.theme
                width: parent.width
                options: [
                    { label: "Signal Dark", value: "signal" },
                    { label: "Omarchy", value: "omarchy" }
                ]
                currentValue: root.config.palette
                onSelected: v => root.config.palette = v
            }
        }
    }

    DSectionLabel {
        visible: root.dockMode
        theme: root.theme
        label: "PLACEMENT"
        Layout.topMargin: 30
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        visible: root.dockMode
        Layout.fillWidth: true
        spacing: 18

        // Live preview: a screen frame with the pill drawn at the configured
        // edge. Position, icon size and transparency are all spatial settings,
        // so showing the result beats describing it.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 150
            radius: root.theme.radiusWindow
            color: root.theme.darkerBackground
            border.color: root.theme.borderFill
            border.width: 1
            clip: true

            Text {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 10
                text: "PREVIEW"
                color: root.theme.mutedText
                font.pixelSize: 10
                font.family: root.theme.fontMono
                font.letterSpacing: 1.2
            }

            Rectangle {
                id: previewPill

                readonly property bool vertical:
                    root.config.position === "left" || root.config.position === "right"
                // iconSize 24–96 maps to 12–30px of pill thickness so the
                // preview stays legible at both ends of the slider.
                readonly property real thickness:
                    12 + (Math.max(24, Math.min(96, root.config.iconSize)) - 24) / 72 * 18
                readonly property real length:
                    vertical ? parent.height * 0.58 : parent.width * 0.44
                readonly property real dot: Math.max(3, thickness * 0.42)

                width: vertical ? thickness : length
                height: vertical ? length : thickness
                x: root.config.position === "left" ? 12
                 : root.config.position === "right" ? parent.width - width - 12
                 : (parent.width - width) / 2
                y: root.config.position === "top" ? 12
                 : root.config.position === "bottom" ? parent.height - height - 12
                 : (parent.height - height) / 2
                radius: root.theme.radiusDock
                color: root.config.transparentBackground ? "transparent"
                     : Qt.rgba(root.theme.background.r, root.theme.background.g,
                               root.theme.background.b, 0.85)
                border.color: root.theme.borderFill
                border.width: 1

                Repeater {
                    model: 5
                    delegate: Rectangle {
                        required property int index
                        width: previewPill.dot
                        height: previewPill.dot
                        radius: previewPill.dot / 2
                        color: root.theme.foreground
                        opacity: 0.85
                        x: previewPill.vertical
                            ? (previewPill.width - width) / 2
                            : (index + 0.5) * previewPill.width / 5 - width / 2
                        y: previewPill.vertical
                            ? (index + 0.5) * previewPill.height / 5 - height / 2
                            : (previewPill.height - height) / 2
                    }
                }
            }
        }

        DSettingRow {
            theme: root.theme
            label: "Position"
            description: "Screen edge the dock is anchored to."
            DSegmented {
                theme: root.theme
                width: parent.width
                options: [
                    { label: "Top", value: "top" },
                    { label: "Bottom", value: "bottom" },
                    { label: "Left", value: "left" },
                    { label: "Right", value: "right" }
                ]
                currentValue: root.config.position
                onSelected: v => root.config.position = v
            }
        }

        DSettingRow {
            theme: root.theme
            label: "Icon size"
            description: "Icon canvas in pixels. The pill grows with it."
            RowLayout {
                width: parent.width
                spacing: 12
                DSlider {
                    theme: root.theme
                    Layout.fillWidth: true
                    from: 24; to: 96; stepSize: 4
                    value: root.config.iconSize
                    onMoved: v => root.config.iconSize = v
                }
                Text {
                    Layout.preferredWidth: 46
                    horizontalAlignment: Text.AlignRight
                    text: root.config.iconSize + "px"
                    color: root.theme.mutedText
                    font.pixelSize: 12
                    font.family: root.theme.fontMono
                }
            }
        }

        DSettingRow {
            theme: root.theme
            label: "Transparent background"
            description: "Drop the pill so only the icons remain."
            DToggle {
                theme: root.theme
                checked: root.config.transparentBackground
                onToggled: c => root.config.transparentBackground = c
            }
        }
    }
}
