import QtQuick
import QtQuick.Layouts

// One settings row: label (plus optional description) on the left, control on
// the right. The control is the default property, so callers write
// `DSettingRow { label: "…"; DToggle { … } }`.
//
// The label block sits in a plain Item rather than a ColumnLayout: a layout's
// implicit width (the unwrapped text) is used as its minimum width, which
// would push the control off the row on narrow windows.
RowLayout {
    id: root

    required property var theme
    property string label: ""
    property string description: ""
    default property alias content: slot.data

    Layout.fillWidth: true
    spacing: 20

    Item {
        id: labelSlot
        Layout.preferredWidth: 124
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: labelCol.implicitHeight

        ColumnLayout {
            id: labelCol
            width: parent.width
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.label
                color: root.theme.foreground
                font.pixelSize: 13
                wrapMode: Text.WordWrap
            }

            Text {
                Layout.fillWidth: true
                visible: root.description !== ""
                text: root.description
                color: root.theme.mutedText
                font.pixelSize: 11
                wrapMode: Text.WordWrap
                lineHeight: 1.15
            }
        }
    }

    Item {
        id: slot
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignVCenter
        implicitHeight: children.length ? children[0].implicitHeight : 0
    }
}
