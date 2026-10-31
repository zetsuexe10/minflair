import QtQuick
import QtQuick.Controls.Basic

// Dropdown over a plain string list. Click or Enter/Space opens it, Up/Down changes the choice.
FocusScope {
    id: root

    property var items: []
    property int currentIndex: 0
    property string label: ""
    property color fg: "white"
    property color panel: "#222222"
    property color accent: "#88aaff"
    property string fontFamily: "sans-serif"
    property real fontSize: 15
    property real radius: height / 2
    property bool openUp: false
    property bool centered: false
    property bool bare: false              // text only, no outline
    readonly property bool hovered: hover.hovered
    readonly property bool multi: items.length > 1
    readonly property string currentText:
        currentIndex >= 0 && currentIndex < items.length ? String(items[currentIndex]) : ""

    activeFocusOnTab: true
    implicitWidth: 240
    implicitHeight: 44

    function step(d) {
        if (!multi) return;
        currentIndex = (currentIndex + d + items.length) % items.length;
    }

    Keys.onUpPressed: step(-1)
    Keys.onDownPressed: step(1)
    Keys.onReturnPressed: if (multi) popup.open()
    Keys.onSpacePressed: if (multi) popup.open()

    Rectangle {
        id: face
        anchors.fill: parent
        radius: root.radius
        color: root.bare ? "transparent" : Qt.rgba(1, 1, 1, hover.hovered ? 0.07 : 0.04)
        border.width: root.bare ? 0 : 2
        border.color: root.bare ? "transparent"
                    : (popup.visible || root.activeFocus ? root.accent
                       : (hover.hovered && root.multi ? Qt.rgba(1, 1, 1, 0.45) : Qt.rgba(1, 1, 1, 0.28)))
        scale: tap.pressed && root.multi ? 0.985 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }

        Text {
            anchors.fill: parent
            anchors.leftMargin: root.centered ? 48 : 18
            anchors.rightMargin: root.centered ? 48 : 40
            horizontalAlignment: root.centered ? Text.AlignHCenter : Text.AlignLeft
            verticalAlignment: Text.AlignVCenter
            text: (root.label !== "" ? root.label + ": " : "") + root.currentText
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: root.fontSize
            elide: Text.ElideRight
        }
        Text {
            visible: root.multi && !root.bare
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 18
            text: root.openUp ? "▴" : "▾"
            color: root.fg
            opacity: 0.7
            font.pixelSize: root.fontSize
        }
        HoverHandler { id: hover; cursorShape: root.multi ? Qt.PointingHandCursor : Qt.ArrowCursor }
        TapHandler {
            id: tap
            onTapped: { root.forceActiveFocus(); if (root.multi) popup.visible ? popup.close() : popup.open(); }
        }
    }

    Popup {
        id: popup
        y: root.openUp ? -height - 10 : root.height + 10
        x: Math.round((root.width - width) / 2)
        width: Math.max(root.width, 240)
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 140; easing.type: Easing.OutCubic }
                NumberAnimation { property: "scale"; from: 0.97; to: 1; duration: 140; easing.type: Easing.OutCubic }
            }
        }
        exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: 90 } }

        background: Rectangle {
            radius: 18
            color: root.panel
            border.color: Qt.rgba(1, 1, 1, 0.14)
            border.width: 1
        }

        contentItem: ListView {
            implicitHeight: Math.min(contentHeight, 280)
            clip: true
            spacing: 4
            model: root.items
            currentIndex: root.currentIndex
            delegate: Rectangle {
                id: row
                required property int index
                required property var modelData
                readonly property bool selected: index === root.currentIndex
                width: ListView.view.width
                height: 40
                radius: 12
                color: selected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
                                : (rowHover.hovered ? Qt.rgba(1, 1, 1, 0.09) : "transparent")
                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: tick.left
                    text: String(row.modelData)
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize
                    elide: Text.ElideRight
                }
                Text {
                    id: tick
                    visible: row.selected
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    text: "✓"
                    color: root.accent
                    font.pixelSize: root.fontSize
                }
                HoverHandler { id: rowHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: { root.currentIndex = row.index; popup.close(); } }
            }
        }
    }
}
