import QtQuick
import QtQuick.Controls.Basic

// Small dropdown: shows the current item, opens a list above/below it.
Item {
    id: root

    property var model
    property string textRole: "name"
    property int currentIndex: 0
    property string label: ""
    property color fg: "white"
    property color panel: "#222222"
    property color accent: "#88aaff"
    property string fontFamily: "sans-serif"
    property bool openUp: false
    readonly property string currentText: {
        if (!list.currentItem) return "";
        return list.currentItem.itemText;
    }

    implicitWidth: 220
    implicitHeight: 38

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: root.panel
        border.color: popup.visible ? root.accent : "transparent"
        border.width: 1

        Text {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: arrow.left
            text: (root.label !== "" ? root.label + ": " : "") + root.currentText
            color: root.fg
            font.family: root.fontFamily
            font.pixelSize: 14
            elide: Text.ElideRight
        }
        Text {
            id: arrow
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 12
            text: root.openUp ? "▴" : "▾"
            color: root.fg
            font.pixelSize: 14
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }
    }

    Popup {
        id: popup

        y: root.openUp ? -height - 6 : root.height + 6
        width: Math.max(root.width, 220)
        padding: 6
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            radius: 12
            color: root.panel
            border.color: root.accent
            border.width: 1
        }

        contentItem: ListView {
            id: list

            implicitHeight: Math.min(contentHeight, 260)
            clip: true
            model: root.model
            currentIndex: root.currentIndex
            delegate: Rectangle {
                required property int index
                required property var model
                readonly property string itemText: model[root.textRole] !== undefined ? String(model[root.textRole]) : ""

                width: ListView.view.width
                height: 34
                radius: 8
                color: index === root.currentIndex ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
                                                    : (hover.hovered ? Qt.rgba(1, 1, 1, 0.08) : "transparent")

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    text: parent.itemText
                    color: root.fg
                    font.family: root.fontFamily
                    font.pixelSize: 14
                }
                HoverHandler { id: hover }
                TapHandler {
                    onTapped: {
                        root.currentIndex = index;
                        popup.close();
                    }
                }
            }
        }
    }
}
