import QtQuick
import qs.Core
import qs.Core.Services
import qs.Core.Windows

OverlayWindow {
    id: root

    widgetId: "speedTest"
    enableShadow: true
    preferredWidth: panel.implicitWidth + (contentPadding * 2)
    preferredHeight: panel.implicitHeight + (contentPadding * 2)
    onIsOpenChanged: {
        if (isOpen) {
            panel.openPage("speed");
            Qt.callLater(() => panel.initialFocusItem.forceActiveFocus());
        }
    }

    SystemMonitorContent {
        id: panel

        width: implicitWidth
        height: implicitHeight
        active: root.isOpen
        onCloseRequested: AppState.closeWidget("speedTest")
    }
}
