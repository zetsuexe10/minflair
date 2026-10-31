import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Core.Services

// Qt 6.8 compatible replacement for RectangularShadow (Qt 6.9+).
Item {
    id: root

    property bool active: true
    property real radius: 0
    property real blur: HyprlandService.hyprShadowRange
    property real spread: 0
    property color color: Theme.shadow

    visible: active && HyprlandService.hyprShadow && !DisplayProfileService.gameModeActive && (SystemInfoService.powerProfile !== "power-saver")

    Rectangle {
        id: src

        anchors.fill: parent
        radius: root.radius
        color: root.color
        visible: false
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: src
        source: src
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowColor: root.color
        shadowOpacity: 1
        shadowBlur: Math.max(0, Math.min(1, root.blur / 32))
    }
}
