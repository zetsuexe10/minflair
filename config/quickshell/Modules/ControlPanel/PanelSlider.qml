import QtQuick
import qs.Core
import qs.Core.Components

Item {
    id: root

    property real value: 0
    property string icon: "sun"
    property bool muted: false
    property color fillColor: Theme.accent
    property real step: 4
    readonly property bool pressed: drag.pressed
    readonly property real shown: muted ? 0 : Math.max(0, Math.min(100, value))
    readonly property real travel: Math.max(1, height - width)
    property bool showNumber: false
    property real _last: -1
    property bool _dragged: false

    signal moved(real v)
    signal iconClicked()

    implicitWidth: 44
    implicitHeight: 180

    onValueChanged: {
        if (_last >= 0 && Math.abs(value - _last) >= 1) {
            showNumber = true;
            numberTimer.restart();
        }
        _last = value;
    }

    Timer {
        id: numberTimer

        interval: 600
        onTriggered: root.showNumber = false
    }

    Rectangle {
        id: track

        anchors.fill: parent
        radius: width / 2
        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)

        Rectangle {
            id: fill

            anchors.bottom: parent.bottom
            width: parent.width
            height: root.width + root.travel * root.shown / 100
            radius: width / 2
            color: root.fillColor

            Behavior on height {
                enabled: !root.pressed
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            id: handle

            width: root.width
            height: root.width
            radius: width / 2
            y: fill.y
            color: Theme.fg
            scale: drag.pressed ? 1.06 : 1

            Behavior on scale {
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }

            SvgIcon {
                anchors.centerIn: parent
                visible: !(root.pressed || root.showNumber)
                icon: root.icon
                iconSize: Math.round(root.width * 0.46)
                flat: true
                iconColor: Theme.opaqueBg
            }

            Text {
                anchors.centerIn: parent
                visible: root.pressed || root.showNumber
                text: Math.round(root.value)
                font.pixelSize: Math.max(11, Math.round(root.width * 0.3))
                font.bold: true
                color: Theme.opaqueBg
            }
        }
    }

    MouseArea {
        id: drag

        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor
        onPressed: (m) => {
            root._dragged = false;
            const onHandle = m.y >= handle.y && m.y <= handle.y + handle.height;
            if (!onHandle) {
                root._dragged = true;
                root.moved(root._at(m.y));
            }
        }
        onPositionChanged: (m) => {
            if (!pressed)
                return;
            root._dragged = true;
            root.moved(root._at(m.y));
        }
        onReleased: {
            if (!root._dragged)
                root.iconClicked();
        }
        onWheel: (w) => root.moved(Math.max(0, Math.min(100, root.value + (w.angleDelta.y > 0 ? root.step : -root.step))))
    }

    function _at(y) {
        return Math.max(0, Math.min(100, (1 - (y - root.width / 2) / root.travel) * 100));
    }
}
