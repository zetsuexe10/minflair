pragma Singleton
import QtQuick
import qs.Core.Services

// Shared state between the side bar window and its overlay (hover popouts).
QtObject {
    id: root

    property string popout: ""          // "", "network", "bluetooth", "audio"
    property real popoutCenter: 0       // position of the hovered icon along the bar, in screen pixels
    readonly property bool hoverEnabled: SettingsService.sideBarPopouts

    function hover(name, center) {
        if (hoverEnabled)
            open(name, center);
    }

    function open(name, center) {
        closeTimer.stop();
        popoutCenter = center;
        popout = name;
    }

    function hold() {
        closeTimer.stop();
    }

    function release() {
        closeTimer.restart();
    }

    function close() {
        closeTimer.stop();
        popout = "";
    }

    property Timer closeTimer: Timer {
        interval: 280
        onTriggered: root.popout = ""
    }
}
