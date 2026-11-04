import QtQuick
import qs.Core

Item {
    id: root

    property real value: 0
    property bool seekable: true
    property bool playing: false
    signal seek(real fraction)

    readonly property bool dragging: area.pressed
    property real drag: 0
    readonly property real shown: dragging ? drag : value
    readonly property real gap: 6
    readonly property real handleW: (area.pressed || area.containsMouse) ? 5 : 4
    readonly property real cut: Math.max(0, Math.min(width, width * shown))

    implicitHeight: 24

    CaelWave {
        x: 0
        y: 0
        width: root.width
        height: root.height
        length: Math.max(0, root.cut - root.gap - root.handleW / 2)
        running: root.playing && !root.dragging
        visible: length > 1
        amplitude: 3
        thickness: 4
    }

    Rectangle {
        x: root.cut + root.gap + root.handleW / 2
        y: (root.height - height) / 2
        width: Math.max(0, root.width - x)
        height: 4
        radius: 2
        color: Qt.rgba(SideState.fg.r, SideState.fg.g, SideState.fg.b, 0.18)
        visible: width > 0.5
    }

    Rectangle {
        x: root.cut - width / 2
        y: (root.height - height) / 2
        width: root.handleW
        height: (area.pressed || area.containsMouse) ? 22 : 18
        radius: width / 2
        color: SideState.primary
        visible: root.seekable

        Behavior on height { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: Constants.animFast } }
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        enabled: root.seekable
        cursorShape: root.seekable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: (m) => root.drag = Math.max(0, Math.min(1, m.x / width))
        onPositionChanged: (m) => {
            if (pressed)
                root.drag = Math.max(0, Math.min(1, m.x / width));
        }
        onReleased: root.seek(root.drag)
    }
}
