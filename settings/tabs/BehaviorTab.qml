import QtQuick
import QtQuick.Layouts
import "../../ui"

// Settings → Behavior: how the dock hides and reveals. Dock presentation only.
ColumnLayout {
    id: root

    required property var config
    required property var theme

    // The segmented labels are one word each; spell out what the selected
    // mode actually does instead of leaving it to the label.
    readonly property string modeHint: {
        switch (root.config.autohide) {
        case "never":
            return "The dock stays on screen. Maximized windows stop at its edge, so nothing is ever covered.";
        case "timer":
            return "The dock slides away once the pointer leaves it, after the delay below. Move the pointer back to the edge to bring it up.";
        default:
            return "The dock hides only while a window covers its edge band, so it stays out of the way without disappearing when the desktop is clear.";
        }
    }

    spacing: 0

    DSectionLabel {
        theme: root.theme
        label: "AUTO-HIDE"
        Layout.bottomMargin: 14
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 18

        DSettingRow {
            theme: root.theme
            label: "Mode"
            description: "When the dock gets out of the way."
            DSegmented {
                theme: root.theme
                width: parent.width
                options: [
                    { label: "Never", value: "never" },
                    { label: "Delay", value: "timer" },
                    { label: "Smart", value: "intellihide" }
                ]
                currentValue: root.config.autohide
                onSelected: v => root.config.autohide = v
            }
        }

        DSettingRow {
            visible: root.config.autohide !== "never"
            theme: root.theme
            label: "Hide delay"
            description: "Grace period after the pointer leaves."
            DSpinBox {
                theme: root.theme
                width: 150
                from: 0; to: 3000; stepSize: 100
                value: root.config.hideDelay
                suffix: " ms"
                onValueModified: v => root.config.hideDelay = v
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.topMargin: 24
        Layout.preferredHeight: hint.implicitHeight + 26
        radius: root.theme.radiusControl
        color: root.theme.normalFill
        border.color: root.theme.borderFill
        border.width: 1

        Text {
            id: hint
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            text: root.modeHint
            color: root.theme.mutedText
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            lineHeight: 1.25
        }
    }
}
