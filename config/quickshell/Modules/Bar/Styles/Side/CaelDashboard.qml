import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Caelestia's dashboard for the side style: tab strip over views that slide sideways.
Item {
    id: root

    required property var widget
    property real maxWidth: 730
    readonly property var tabIds: ["dash", "media", "perf", "weather"]
    property int current: Math.max(0, Math.min(3, SettingsService.sideDashTab))
    readonly property int safeCurrent: Math.max(0, Math.min(views.length - 1, current))
    property alias initialFocusItem: keys

    function pick(i) {
        const idx = Math.max(0, Math.min(views.length - 1, i));
        root.current = idx;
        SettingsService.sideDashTab = idx;
    }
    readonly property var tabs: [
        { "icon": "layout-filled", "label": "Dashboard" },
        { "icon": "music", "label": "Media" },
        { "icon": "cpu", "label": "Performance" },
        { "icon": "sun", "label": "Weather" }
    ]
    readonly property var views: [dashView, mediaView, perfView, weatherView]
    readonly property real viewW: Math.max(420, Math.min(730, maxWidth))
    readonly property real viewH: views[safeCurrent] ? views[safeCurrent].implicitHeight : 0

    implicitWidth: viewW
    implicitHeight: tabsBar.implicitHeight + 12 + viewH

    // keyboard: Left/Right/Home/End switch tabs, Escape closes
    Item {
        id: keys

        focus: true
        Keys.onLeftPressed: root.pick(root.current - 1)
        Keys.onRightPressed: root.pick(root.current + 1)
        Keys.onTabPressed: root.pick((root.current + 1) % root.views.length)
        Keys.onBacktabPressed: root.pick((root.current + root.views.length - 1) % root.views.length)
        Keys.onPressed: (e) => {
            if (e.key === Qt.Key_Home) { root.pick(0); e.accepted = true; }
            else if (e.key === Qt.Key_End) { root.pick(root.views.length - 1); e.accepted = true; }
        }
        Keys.onEscapePressed: AppState.closeAllWidgets()
    }

    CaelTabs {
        id: tabsBar

        width: parent.width
        tabs: root.tabs
        current: root.safeCurrent
        onPicked: (i) => root.pick(i)
    }

    Item {
        y: tabsBar.implicitHeight + 12
        width: parent.width
        height: root.viewH
        clip: true

        // the four pages slide sideways as one strip
        Item {
            id: pages

            anchors.fill: parent

            CaelDash {
                id: dashView

                visible: opacity > 0.01

                width: root.viewW
                height: implicitHeight

                x: (0 - root.safeCurrent) * root.viewW
                opacity: root.safeCurrent === 0 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }

            CaelMedia {
                id: mediaView

                visible: opacity > 0.01

                width: root.viewW
                height: implicitHeight

                x: (1 - root.safeCurrent) * root.viewW
                opacity: root.safeCurrent === 1 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }

            CaelPerformance {
                id: perfView

                visible: opacity > 0.01

                width: root.viewW
                height: implicitHeight

                x: (2 - root.safeCurrent) * root.viewW
                opacity: root.safeCurrent === 2 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }

            CaelWeather {
                id: weatherView

                visible: opacity > 0.01

                width: root.viewW
                height: implicitHeight

                x: (3 - root.safeCurrent) * root.viewW
                opacity: root.safeCurrent === 3 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }
        }
    }
}
