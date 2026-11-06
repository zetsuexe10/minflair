import QtQuick
import qs.Core
import qs.Core.Components

Item {
    id: root

    property real value: 0
    property string icon: "sun"
    property bool muted: false
    property color fillColor: Theme.fg
    property real step: 4
    property real cornerRadius: 28
    readonly property bool pressed: drag.pressed
    readonly property real shown: muted ? 0 : Math.max(0, Math.min(100, value))

    signal moved(real v)
    signal iconClicked()

    implicitWidth: 88
    implicitHeight: 190

    Rectangle {
        id: track

        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
        border.width: 1
        border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
        clip: true

        Rectangle {
            id: fill

            anchors.bottom: parent.bottom
            width: parent.width
            height: Math.max(radius * 2, parent.height * root.shown / 100)
            radius: track.radius
            color: root.fillColor
            opacity: root.shown > 0 ? 0.92 : 0
            visible: root.shown > 0

            Behavior on height {
                enabled: !root.pressed
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }

        SvgIcon {
            id: glyph

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 16
            icon: root.icon
            iconSize: 24
            flat: true
            iconColor: (root.shown > 14) ? Theme.opaqueBg : Theme.fg
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 14
            text: root.muted ? "Muted" : Math.round(root.value) + "%"
            font.pixelSize: 12
            font.bold: true
            color: Theme.muted
        }
    }

    MouseArea {
        id: drag

        anchors.fill: parent
        preventStealing: true
        onPressed: (m) => root.moved(root._at(m.y))
        onPositionChanged: (m) => {
            if (pressed)
                root.moved(root._at(m.y));
        }
        onWheel: (w) => root.moved(Math.max(0, Math.min(100, root.value + (w.angleDelta.y > 0 ? root.step : -root.step))))
    }

    MouseArea {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        width: 52
        height: 52
        cursorShape: Qt.PointingHandCursor
        onClicked: root.iconClicked()
    }

    function _at(y) {
        return Math.max(0, Math.min(100, (1 - y / Math.max(1, root.height)) * 100));
    }
}
