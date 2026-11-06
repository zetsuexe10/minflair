import QtQuick
import qs.Core
import qs.Core.Services
import qs.Core.Windows

OverlayWindow {
    id: root

    widgetId: "quickPanel"
    enableShadow: true
    preferredWidth: panel.implicitWidth + (contentPadding * 2)
    preferredHeight: panel.implicitHeight + (contentPadding * 2)
    onIsOpenChanged: {
        if (isOpen) {
            panel.reset();
            Qt.callLater(() => panel.initialFocusItem.forceActiveFocus());
        }
    }

    ControlPanelContent {
        id: panel

        width: implicitWidth
        height: implicitHeight
        active: root.isOpen
        onCloseRequested: AppState.closeWidget("quickPanel")
    }
}
