import QtQuick

// Mono uppercase group caption — the Signal Dark section header.
Text {
    required property var theme
    property string label: ""

    text: label
    color: theme.mutedText
    font.pixelSize: 11
    font.bold: true
    font.family: theme.fontMono
    font.letterSpacing: 1.4
}
