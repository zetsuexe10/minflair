import QtQuick
import qs.Core

// Rounded capsule that groups one section of the side bar.
Rectangle {
    color: Theme.bg
    radius: Math.min(width, height) / 2
    border.width: 1
    border.color: Theme.border
}
