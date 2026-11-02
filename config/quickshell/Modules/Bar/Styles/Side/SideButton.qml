import QtQuick
import qs.Core
import qs.Core.Components

// Round icon (or short text) button used throughout the side bar.
Item {
    id: root

    property string icon: ""
    property string label: ""
    property color iconColor: SideState.fg
    property string imageSource: ""
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

    // macOS-like springy response to the pointer
    scale: area.pressed ? 0.84 : (hovered ? 1.14 : 1)

    Behavior on scale { SpringAnimation { spring: 3.4; damping: 0.3; epsilon: 0.002 } }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.active ? SideState.selected : (root.hovered ? SideState.card : "transparent")

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Image {
        id: img

        readonly property int box: Math.round(root.size * 0.62)

        visible: status === Image.Ready
        anchors.centerIn: parent
        width: box
        height: box
        source: root.imageSource
        sourceSize: Qt.size(box * 2, box * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        smooth: true
        mipmap: true
    }

    SvgIcon {
        visible: root.icon !== "" && !img.visible
        anchors.centerIn: parent
        icon: root.icon
        iconColor: root.iconColor
        iconSize: root.iconSize
        flat: true

        Behavior on iconColor { ColorAnimation { duration: 180 } }
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
