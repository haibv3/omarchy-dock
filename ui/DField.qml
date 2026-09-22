import QtQuick

// Omarchy-style text field.
Rectangle {
    id: root

    required property var theme
    property alias text: input.text
    property string placeholder: ""
    signal accepted()

    implicitHeight: 34
    radius: 9
    color: theme.darkerBackground
    border.color: input.activeFocus ? theme.accent : theme.lighterBackground
    border.width: 1

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        verticalAlignment: TextInput.AlignVCenter
        color: theme.foreground
        font.pixelSize: 13
        clip: true
        selectByMouse: true
        onAccepted: root.accepted()

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: input.text.length === 0 && !input.activeFocus
            text: root.placeholder
            color: theme.muted
            font.pixelSize: 13
        }
    }
}
