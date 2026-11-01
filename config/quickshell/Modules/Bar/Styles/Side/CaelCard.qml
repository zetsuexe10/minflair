import QtQuick
import qs.Core

// A rounded surface inside the dashboard.
Rectangle {
    property real corner: 22

    color: SideState.card
    radius: corner
}
