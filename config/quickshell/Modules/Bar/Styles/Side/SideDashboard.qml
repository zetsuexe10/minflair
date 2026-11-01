import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Calendar
import qs.Modules.Dashboard
import qs.Modules.Music
import qs.Modules.SystemUsage as SystemUsageModule

// Tabbed dashboard (Dashboard / Media / Performance) with a sliding tab indicator and views
// that slide horizontally, after the Caelestia dashboard.
Item {
    id: root

    required property var widget
    property int current: SettingsService.sideDashTab
    readonly property var tabs: [
        { label: "Dashboard", icon: "layout-filled" },
        { label: "Media", icon: "music" },
        { label: "Performance", icon: "cpu" },
        { label: "Calendar", icon: "calendar" }
    ]
    readonly property real viewWidth: Math.max(460, dash.implicitWidth, media.implicitWidth, perf.implicitWidth, cal.implicitWidth)
    readonly property real viewHeight: [dash, media, perf, cal][current].implicitHeight

    implicitWidth: viewWidth
    implicitHeight: bar.height + Constants.sizeSm + viewHeight

    Behavior on implicitHeight { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

    Item {
        id: bar

        width: parent.width
        height: 38

        Rectangle {
            id: indicator

            y: 0
            height: bar.height
            width: bar.width / root.tabs.length
            x: root.current * width
            radius: height / 2
            color: Theme.bgAccent

            Behavior on x { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
        }

        Row {
            anchors.fill: parent

            Repeater {
                model: root.tabs

                Item {
                    id: tab

                    required property var modelData
                    required property int index

                    width: bar.width / root.tabs.length
                    height: bar.height

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        SvgIcon {
                            anchors.verticalCenter: parent.verticalCenter
                            icon: tab.modelData.icon
                            iconSize: Constants.sizeMd
                            iconColor: root.current === tab.index ? Theme.accent : Theme.muted
                            flat: true
                        }

                        ThemedText {
                            anchors.verticalCenter: parent.verticalCenter
                            text: tab.modelData.label
                            color: root.current === tab.index ? Theme.fg : Theme.muted
                            font.bold: root.current === tab.index
                        }
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.current = tab.index
                    }
                }
            }
        }
    }

    Item {
        id: views

        y: bar.height + Constants.sizeSm
        width: parent.width
        height: root.viewHeight
        clip: true

        // slide in from the side of the tab you came from, with a small fade
        component View: Loader {
            required property int slot

            readonly property real shift: (slot - root.current) * root.viewWidth

            width: root.viewWidth
            x: shift
            opacity: slot === root.current ? 1 : 0
            active: true

            Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
            Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        }

        View {
            id: dashView

            slot: 0
            sourceComponent: DashboardContent { widget: root.widget }
        }

        View {
            id: mediaView

            slot: 1
            sourceComponent: MiniMusicWidget { widget: root.widget }
        }

        View {
            id: perfView

            slot: 2
            sourceComponent: SystemUsageModule.SystemUsageContent { widget: root.widget }
        }

        View {
            id: calView

            slot: 3
            sourceComponent: CalendarWidget { widget: root.widget }
        }
    }

    // implicit sizes of the hosted pages
    QtObject {
        id: cal

        readonly property real implicitWidth: calView.item ? calView.item.implicitWidth : 0
        readonly property real implicitHeight: calView.item ? calView.item.implicitHeight : 0
    }

    QtObject {
        id: dash

        readonly property real implicitWidth: dashView.item ? dashView.item.implicitWidth : 0
        readonly property real implicitHeight: dashView.item ? dashView.item.implicitHeight : 0
    }

    QtObject {
        id: media

        readonly property real implicitWidth: mediaView.item ? mediaView.item.implicitWidth : 0
        readonly property real implicitHeight: mediaView.item ? mediaView.item.implicitHeight : 0
    }

    QtObject {
        id: perf

        readonly property real implicitWidth: perfView.item ? perfView.item.implicitWidth : 0
        readonly property real implicitHeight: perfView.item ? perfView.item.implicitHeight : 0
    }
}
