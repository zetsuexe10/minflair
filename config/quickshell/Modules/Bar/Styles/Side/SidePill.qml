import QtQuick
import qs.Core

// Rounded capsule that groups one section of the side bar.
Rectangle {
    // on the frame the pill is a slightly lighter surface; floating it is the usual translucent card
    readonly property bool soft: SideState.frame || SideState.island
    color: soft ? Qt.tint(SideState.surface, SideState.card) : SideState.surface
    radius: Math.min(width, height) / 2
    border.width: soft ? 0 : 1
    border.color: SideState.outline
}
