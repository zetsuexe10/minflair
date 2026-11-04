import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    id: root

    property string icon
    property bool tonal: true
    property bool checked: false
    property bool fill: false
    property bool disabled: false
    property real iconSize: 20
    signal clicked()

    readonly property bool isPrimary: !tonal
    readonly property color bg: checked ? (isPrimary ? SideState.primary : SideState.primary) : (isPrimary ? SideState.primary : SideState.cardHi)
    readonly property color fgc: (checked || isPrimary) ? SideState.primaryText : SideState.fg

    Layout.fillWidth: fill
    Layout.preferredWidth: fill ? -1 : 52
    Layout.preferredHeight: 52
    Layout.minimumWidth: 52
    radius: tap.pressed ? 12 : (checked ? height * 0.34 : height / 2)
    color: bg
    opacity: disabled ? 0.38 : 1

    Behavior on radius { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
    Behavior on color { ColorAnimation { duration: Constants.animFast } }
    Behavior on opacity { NumberAnimation { duration: Constants.animFast } }

    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: root.fgc
        opacity: tap.pressed ? 0.14 : (hov.hovered && !root.disabled ? 0.08 : 0)

        Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
    }

    SvgIcon {
        anchors.centerIn: parent
        icon: root.icon
        iconSize: root.iconSize
        iconColor: root.fgc
        flat: true
    }

    HoverHandler {
        id: hov

        cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
    }

    TapHandler {
        id: tap

        enabled: !root.disabled
        onTapped: root.clicked()
    }
}
