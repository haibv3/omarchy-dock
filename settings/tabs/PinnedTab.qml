import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../ui"

// Settings → Pinned apps. The page hugs the pane height instead of stacking
// into one scroll: the pinned list is a card that grows with content but caps
// at ~42% of the pane and scrolls internally, so the search-and-add picker is
// always visible below it — pinning more apps never pushes the add flow away.
ColumnLayout {
    id: root

    required property var config
    required property var theme

    // Viewport height inside this page's margins — the window hands it down.
    property int pageHeight: 0

    readonly property int _pinRowH: 38
    readonly property int _pinCap: Math.max(120, Math.round(root.pageHeight * 0.42))
    // If the pane is ever shorter than the page's minimum, let the outer
    // flickable scroll rather than squeezing the cards into nothing.
    readonly property int _minPageH: 320

    function iconSource(entry) {
        if (!entry || !entry.icon)
            return "";
        const p = Quickshell.iconPath(entry.icon);
        if (!p)
            return "";
        return p.indexOf("://") !== -1 ? p : "file://" + p;
    }

    function movePin(index, delta) {
        const arr = root.config.pinned.slice();
        const next = index + delta;
        if (next < 0 || next >= arr.length)
            return;
        const item = arr.splice(index, 1)[0];
        arr.splice(next, 0, item);
        root.config.setPinnedOrder(arr);
    }

    Layout.preferredHeight: root.pageHeight > 0
        ? Math.max(root.pageHeight, root._minPageH) : -1
    spacing: 0

    // 24px round-corner hit target with a mono glyph; danger flips the hover
    // colour to red for destructive actions.
    component IconBtn: Rectangle {
        id: btn
        required property var theme
        property string glyph: ""
        property bool enabledBtn: true
        property bool danger: false
        signal clicked()

        Layout.preferredWidth: 24
        Layout.preferredHeight: 24
        radius: theme.radiusControl
        opacity: btn.enabledBtn ? 1 : 0.3
        color: btnMa.containsMouse && btn.enabledBtn
            ? (btn.danger
               ? Qt.rgba(theme.brightRed.r, theme.brightRed.g, theme.brightRed.b, 0.14)
               : theme.hoverFill)
            : "transparent"

        Text {
            anchors.centerIn: parent
            text: btn.glyph
            color: btnMa.containsMouse && btn.enabledBtn
                ? (btn.danger ? btn.theme.brightRed : btn.theme.accent)
                : btn.theme.mutedText
            font.pixelSize: 13
            font.family: btn.theme.fontMono
        }

        MouseArea {
            id: btnMa
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabledBtn
            cursorShape: btn.enabledBtn ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: btn.clicked()
        }
    }

    // ---------- pinned ----------
    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 12
        spacing: 12

        DSectionLabel {
            theme: root.theme
            label: "PINNED"
            Layout.fillWidth: true
        }

        Text {
            visible: root.config.pinned.length > 1
            Layout.alignment: Qt.AlignVCenter
            text: "arrows or drag dock icons to reorder"
            color: root.theme.mutedText
            font.pixelSize: 10
            font.family: root.theme.fontMono
            elide: Text.ElideRight
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: root.config.pinned.length
                  + (root.config.pinned.length === 1 ? " app" : " apps")
            color: root.theme.mutedText
            font.pixelSize: 11
            font.family: root.theme.fontMono
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(
            Math.max(50, root.config.pinned.length * root._pinRowH + 8),
            root._pinCap)
        radius: root.theme.radiusControl
        color: root.theme.darkerBackground
        border.color: root.theme.borderFill
        border.width: 1
        clip: true

        ListView {
            id: pinnedList
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: root.config.pinned

            delegate: Rectangle {
                required property string modelData
                required property int index

                width: pinnedList.width
                height: root._pinRowH
                radius: root.theme.radiusControl
                color: pinMa.containsMouse ? root.theme.hoverFill : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 6
                    spacing: 6

                    Image {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        source: root.iconSource(DesktopEntries.byId(modelData))
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            const e = DesktopEntries.byId(modelData);
                            return e ? e.name : modelData;
                        }
                        color: root.theme.foreground
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    IconBtn {
                        theme: root.theme
                        glyph: String.fromCodePoint(0xF0143)   // chevron-up
                        enabledBtn: index > 0
                        onClicked: root.movePin(index, -1)
                    }

                    IconBtn {
                        theme: root.theme
                        glyph: String.fromCodePoint(0xF0140)   // chevron-down
                        enabledBtn: index < root.config.pinned.length - 1
                        onClicked: root.movePin(index, 1)
                    }

                    IconBtn {
                        theme: root.theme
                        glyph: String.fromCodePoint(0xF0156)   // close
                        danger: true
                        onClicked: root.config.unpin(modelData)
                    }
                }

                MouseArea {
                    id: pinMa
                    anchors.fill: parent
                    anchors.rightMargin: 96
                    hoverEnabled: true
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: root.config.pinned.length === 0
            text: "Nothing pinned yet — add apps below."
            color: root.theme.mutedText
            font.pixelSize: 12
        }
    }

    // ---------- add apps ----------
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 20
        Layout.bottomMargin: 12
        spacing: 12

        DSectionLabel {
            theme: root.theme
            label: "ADD APPS"
            Layout.fillWidth: true
        }

        Text {
            Layout.alignment: Qt.AlignVCenter
            text: appList.count + " shown"
            color: root.theme.mutedText
            font.pixelSize: 10
            font.family: root.theme.fontMono
        }
    }

    DField {
        id: filter
        theme: root.theme
        Layout.fillWidth: true
        placeholder: "Search applications…"
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 90
        Layout.topMargin: 10
        radius: root.theme.radiusControl
        color: root.theme.darkerBackground
        border.color: root.theme.borderFill
        border.width: 1
        clip: true

        ListView {
            id: appList
            anchors.fill: parent
            anchors.margins: 4
            spacing: 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            model: {
                const q = filter.text.toLowerCase();
                const out = [];
                for (const e of DesktopEntries.applications.values) {
                    if (e.noDisplay)
                        continue;
                    if (q !== "" && e.name.toLowerCase().indexOf(q) === -1)
                        continue;
                    out.push(e);
                }
                out.sort((a, b) => a.name.localeCompare(b.name));
                return out;
            }

            delegate: Rectangle {
                required property var modelData

                width: appList.width
                height: 36
                radius: root.theme.radiusControl
                color: addMa.containsMouse ? root.theme.hoverFill : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 10
                    spacing: 10

                    Image {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        source: root.iconSource(modelData)
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.name
                        color: root.config.isPinned(modelData.id)
                            ? root.theme.mutedText : root.theme.foreground
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.config.isPinned(modelData.id)
                        text: "pinned"
                        color: root.theme.accent
                        font.pixelSize: 11
                        font.family: root.theme.fontMono
                    }

                    // A dim pin glyph marks the row as addable; it turns to
                    // full accent on hover as the "click to pin" affordance.
                    Text {
                        visible: !root.config.isPinned(modelData.id)
                        text: String.fromCodePoint(0xF0403)   // pin
                        color: addMa.containsMouse ? root.theme.accent
                                                   : root.theme.mutedText
                        opacity: addMa.containsMouse ? 1 : 0.45
                        font.pixelSize: 13
                        font.family: root.theme.fontMono
                    }
                }

                MouseArea {
                    id: addMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: !root.config.isPinned(modelData.id)
                    onClicked: root.config.pin(modelData.id)
                }
            }
        }

        Text {
            anchors.centerIn: parent
            visible: appList.count === 0
            text: "No applications match."
            color: root.theme.mutedText
            font.pixelSize: 12
        }
    }
}
