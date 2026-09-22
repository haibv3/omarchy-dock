import QtQuick
import Quickshell
import "../services"

// The icon strip. Horizontal for top/bottom docks, vertical for left/right.
Item {
    id: root

    required property var appModel    // AppModel
    required property var config
    required property var theme
    required property var globals
    property bool vertical: false
    property var dockWindow: null     // PanelWindow, for menu anchoring
    readonly property bool menuOpen: menu.visible


    implicitWidth: vertical ? config.iconSize + config.margin * 2
                          : view.contentWidth + config.margin * 2
    implicitHeight: vertical ? view.contentHeight + config.margin * 2
                             : config.iconSize + config.margin * 2

    // manual reorder state
    property int dragIndex: -1

    function persistOrder() {
        const ids = [];
        for (let i = 0; i < appModel.model.count; i++) {
            const row = appModel.model.get(i);
            if (row.pinned)
                ids.push(row.desktopId);
        }
        config.setPinnedOrder(ids);
    }

    ListView {
        id: view
        anchors.fill: parent
        anchors.margins: config.margin
        orientation: root.vertical ? ListView.Vertical : ListView.Horizontal
        model: root.appModel.model
        spacing: 0
        interactive: false
        boundsBehavior: Flickable.StopAtBounds

        displaced: Transition {
            NumberAnimation { properties: "x,y"; duration: 120; easing.type: Easing.OutQuad }
        }

        delegate: DockIcon {
            config: root.config
            theme: root.theme
            vertical: root.vertical
            dragging: root.dragIndex === index

            onClicked: root.appModel.activateOrLaunch(index)

            onRightClicked: pos => {
                const p = mapToItem(null, pos.x, pos.y);
                menu.openFor(root.appModel.rowAt(index), root.dockWindow, p.x, p.y);
            }

            onDragMoved: pos => {
                if (root.dragIndex === -1)
                    root.dragIndex = index;
                const p = mapToItem(view, root.vertical ? 0 : pos, root.vertical ? pos : 0);
                let target = root.vertical
                    ? view.indexAt(1, p.y + view.contentY)
                    : view.indexAt(p.x + view.contentX, 1);
                if (target === -1) {
                    // dragged past the end → clamp to last pinned index
                    for (let i = root.appModel.model.count - 1; i >= 0; i--) {
                        if (root.appModel.model.get(i).pinned) {
                            target = i;
                            break;
                        }
                    }
                }
                if (target === -1 || target === root.dragIndex)
                    return;
                const targetRow = root.appModel.model.get(target);
                if (!targetRow.pinned)
                    return; // running-only section is not reorderable
                root.appModel.model.move(root.dragIndex, target, 1);
                root.dragIndex = target;
            }

            onDragEnded: {
                root.dragIndex = -1;
                root.persistOrder();
            }
        }
    }

    ContextMenu {
        id: menu
        config: root.config
        theme: root.theme
        globals: root.globals
    }
}
