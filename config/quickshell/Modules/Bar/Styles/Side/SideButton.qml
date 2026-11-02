import QtQuick
import qs.Core
import qs.Core.Components

// Round icon (or short text) button used throughout the side bar.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: SideState.fg
    property bool active: false
    property int iconSize: Constants.sizeLg
    property int size: 28
    readonly property bool hovered: area.containsMouse

    signal clicked(var mouse)
    signal scrolled(var wheel)
    signal hoverStarted()
    signal hoverEnded()

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.active ? SideState.selected : (root.hovered ? SideState.card : "transparent")
        scale: area.pressed ? 0.92 : 1

        Behavior on color { ColorAnimation { duration: Constants.animFast } }
        Behavior on scale { NumberAnimation { duration: Constants.animUltraFast } }
    }

    SvgIcon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        icon: root.icon
        iconColor: root.iconColor
        iconSize: root.iconSize
        flat: true

        Behavior on iconColor { ColorAnimation { duration: Constants.animFast } }
    }

    SideText {
        visible: root.label !== ""
        anchors.centerIn: parent
        text: root.label
        color: root.iconColor
        customSize: 11
        font.bold: true
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: (mouse) => root.clicked(mouse)
        onWheel: (wheel) => root.scrolled(wheel)
        onEntered: root.hoverStarted()
        onExited: root.hoverEnded()
    }
}
