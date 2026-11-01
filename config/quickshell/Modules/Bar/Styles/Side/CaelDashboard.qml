import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Caelestia's dashboard for the side style: tab strip over views that slide sideways.
Item {
    id: root

    required property var widget
    property int current: SettingsService.sideDashTab
    readonly property var tabs: [
        { "icon": "layout-filled", "label": "Dashboard" },
        { "icon": "music", "label": "Media" },
        { "icon": "cpu", "label": "Performance" },
        { "icon": "sun", "label": "Weather" }
    ]
    readonly property var views: [dashView, mediaView, perfView, weatherView]
    readonly property real viewW: 730
    readonly property real viewH: views[current].implicitHeight

    implicitWidth: viewW
    implicitHeight: tabsBar.implicitHeight + 12 + viewH

    Behavior on implicitHeight { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }

    CaelTabs {
        id: tabsBar

        width: parent.width
        tabs: root.tabs
        current: root.current
        onPicked: (i) => root.current = i
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

                width: root.viewW
                height: implicitHeight

                x: (0 - root.current) * root.viewW
                opacity: root.current === 0 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }

            CaelMedia {
                id: mediaView

                width: root.viewW
                height: implicitHeight

                x: (1 - root.current) * root.viewW
                opacity: root.current === 1 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }

            CaelPerformance {
                id: perfView

                width: root.viewW
                height: implicitHeight

                x: (2 - root.current) * root.viewW
                opacity: root.current === 2 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }

            CaelWeather {
                id: weatherView

                width: root.viewW
                height: implicitHeight

                x: (3 - root.current) * root.viewW
                opacity: root.current === 3 ? 1 : 0

                Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
            }
        }
    }
}
