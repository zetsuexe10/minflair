import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Vertical volume / brightness / mic indicator that sits on the right edge.
Item {
    id: root

    implicitWidth: 44
    implicitHeight: OsdService.showProgress ? 190 : 84

    SvgIcon {
        id: icon

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        icon: OsdService.icon
        iconSize: Constants.sizeLg
        iconColor: OsdService.isMuted ? SideState.muted : SideState.primary
        flat: true
    }

    Rectangle {
        visible: OsdService.showProgress
        anchors.top: icon.bottom
        anchors.topMargin: 12
        anchors.bottom: label.top
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        width: 10
        radius: 5
        color: SideState.card

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: parent.height * OsdService.level
            radius: 5
            color: OsdService.isMuted ? SideState.muted : SideState.primary

            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
        }
    }

    SideText {
        id: label

        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        text: OsdService.valueText
        customSize: 11
        font.bold: true
    }
}
