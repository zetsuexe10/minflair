import QtQuick
import qs.Core

// Rounded capsule that groups one section of the side bar.
Rectangle {
    // on the frame the pill is a slightly lighter surface; floating it is the usual translucent card
    color: SideState.frame ? Qt.tint(SideState.surface, SideState.card) : SideState.surface
    radius: Math.min(width, height) / 2
    border.width: SideState.frame ? 0 : 1
    border.color: SideState.outline
}
