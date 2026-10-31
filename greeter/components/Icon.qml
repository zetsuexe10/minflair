import QtQuick

// White SVG icon, dimmed unless `lit` (no shader effects needed).
Image {
    property bool lit: false
    property real size: 20
    width: size; height: size
    sourceSize: Qt.size(size * 2, size * 2)
    fillMode: Image.PreserveAspectFit
    opacity: lit ? 1 : 0.55
    Behavior on opacity { NumberAnimation { duration: 150 } }
}
