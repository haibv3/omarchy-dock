import QtQuick
import QtQuick.Layouts

// Settings sidebar entry: glyph + label, accent rail when selected.
// Selection carries both the accent-dim fill and the rail because some
// palettes (solitude) put selection and hover fills within a few percent
// of each other — the rail keeps the active page unambiguous.
Rectangle {
    id: root

    required property var theme
    property string glyph: ""
    property string label: ""
    property bool selected: false
    signal clicked()

    implicitHeight: 34
    radius: theme.radiusControl
    color: root.selected ? theme.selection
         : ma.containsMouse ? theme.hoverFill
         : "transparent"

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: 16
        radius: 1.5
        color: theme.accent
        visible: root.selected
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 10
        spacing: 10

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.glyph
            color: root.selected ? theme.accent : theme.mutedText
            font.pixelSize: 14
            font.family: theme.fontMono
        }

        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.label
            color: root.selected ? theme.foreground : theme.mutedText
            font.pixelSize: 13
            font.bold: root.selected
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
