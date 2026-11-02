import QtQuick
import qs.Core
import qs.Core.Components

// Dashboard tab strip: icon over label, a rounded underline that slides to the current tab and a
// hairline underneath (Caelestia). Scrolling over it changes tab.
Item {
    id: root

    property var tabs: []              // [{ icon, label }]
    property int current: 0

    signal picked(int index)

    readonly property real tabWidth: width / Math.max(1, tabs.length)

    implicitHeight: 56

    Row {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 48

        Repeater {
            model: root.tabs

            Item {
                id: tab

                required property var modelData
                required property int index
                readonly property bool isCurrent: root.current === index

                width: root.tabWidth
                height: 48

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: 14
                    color: SideState.fg
                    opacity: tabHover.hovered ? 0.07 : 0

                    Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    SvgIcon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        icon: tab.modelData.icon
                        iconSize: Constants.sizeLg
                        iconColor: tab.isCurrent ? SideState.primary : SideState.muted
                        flat: true
                    }

                    SideText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tab.modelData.label
                        customSize: 11
                        color: tab.isCurrent ? SideState.primary : SideState.muted
                        font.bold: tab.isCurrent
                    }
                }

                HoverHandler {
                    id: tabHover

                    cursorShape: Qt.PointingHandCursor
                }

                TapHandler {
                    onTapped: root.picked(tab.index)
                }
            }
        }
    }

    Item {
        id: indicator

        y: 50
        height: 3
        width: 40
        x: root.tabWidth * root.current + (root.tabWidth - width) / 2
        clip: true

        Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }

        Rectangle {
            width: parent.width
            height: 6
            radius: 3
            color: SideState.primary
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: SideState.outline
    }

    WheelHandler {
        onWheel: (event) => {
            const next = root.current + (event.angleDelta.y < 0 ? 1 : -1);
            root.picked(Math.max(0, Math.min(root.tabs.length - 1, next)));
        }
    }
}
