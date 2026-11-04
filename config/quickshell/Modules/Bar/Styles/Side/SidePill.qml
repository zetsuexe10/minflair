import QtQuick
import qs.Core

Rectangle {
    readonly property bool soft: SideState.frame || SideState.island
    color: soft ? Qt.tint(SideState.surface, SideState.card) : SideState.surface
    radius: Math.min(width, height) / 2
    border.width: soft ? 0 : 1
    border.color: SideState.outline
}
