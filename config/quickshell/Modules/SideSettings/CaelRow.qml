import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Styles.Side

// One settings row: label and description on the left, the control on the right. Caelestia's
// nexus uses the same pattern (toggle, stepper, select, text field, info).
Rectangle {
    id: root

    property string kind: "toggle"          // toggle, stepper, select, text, info, button
    property string label: ""
    property string desc: ""
    property var value: null
    property var options: []                // select: [{ text, value }]
    property real from: 0
    property real to: 100
    property real step: 1
    property string suffix: ""
    property bool password: false
    property string placeholder: ""

    signal edited(var v)
    signal clicked()

    implicitHeight: Math.max(60, textCol.implicitHeight + 24)
    radius: 18
    color: SideState.card

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 18
        anchors.rightMargin: 14
        spacing: 16

        ColumnLayout {
            id: textCol

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            SideText {
                Layout.fillWidth: true
                text: root.label
                customSize: 13
                font.bold: true
                elide: Text.ElideRight
            }

            SideText {
                Layout.fillWidth: true
                visible: root.desc !== ""
                text: root.desc
                color: SideState.muted
                customSize: 11
                wrapMode: Text.WordWrap
            }
        }

        Loader {
            Layout.alignment: Qt.AlignVCenter
            sourceComponent: root.kind === "toggle" ? toggleC : (root.kind === "stepper" ? stepperC : (root.kind === "select" ? selectC : (root.kind === "text" ? textC : (root.kind === "button" ? buttonC : (root.kind === "picker" ? pickerC : infoC)))))
        }
    }

    Component {
        id: toggleC

        Rectangle {
            implicitWidth: 46
            implicitHeight: 26
            radius: 13
            color: root.value ? SideState.primary : SideState.cardHi

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            Rectangle {
                y: 4
                x: root.value ? parent.width - width - 4 : 4
                width: root.value ? 18 : 14
                height: width
                anchors.verticalCenter: parent.verticalCenter
                radius: width / 2
                color: root.value ? SideState.surface : SideState.fg

                Behavior on x { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
                Behavior on width { NumberAnimation { duration: Constants.animFast } }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.edited(!root.value)
            }
        }
    }

    Component {
        id: stepperC

        Row {
            spacing: 8

            Repeater {
                model: [-1, 0, 1]

                Item {
                    required property int modelData

                    width: modelData === 0 ? 64 : 30
                    height: 30

                    Rectangle {
                        anchors.fill: parent
                        radius: 15
                        color: parent.modelData === 0 ? "transparent" : (bh.hovered ? SideState.selected : SideState.cardHi)
                        visible: parent.modelData !== 0
                    }

                    SideText {
                        anchors.centerIn: parent
                        text: parent.modelData === 0 ? (root.value + root.suffix) : (parent.modelData < 0 ? "−" : "+")
                        font.bold: true
                        customSize: parent.modelData === 0 ? 13 : 16
                    }

                    HoverHandler {
                        id: bh

                        enabled: parent.modelData !== 0
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: parent.modelData !== 0
                        onTapped: root.edited(Math.max(root.from, Math.min(root.to, root.value + parent.modelData * root.step)))
                    }
                }
            }
        }
    }

    Component {
        id: selectC

        Row {
            spacing: 4

            Repeater {
                model: root.options

                Rectangle {
                    required property var modelData

                    width: lbl.implicitWidth + 24
                    height: 30
                    radius: 15
                    color: root.value === modelData.value ? SideState.primary : (sh.hovered ? SideState.cardHi : "transparent")

                    Behavior on color { ColorAnimation { duration: Constants.animFast } }

                    SideText {
                        id: lbl

                        anchors.centerIn: parent
                        text: parent.modelData.text
                        customSize: 12
                        font.bold: root.value === parent.modelData.value
                        color: root.value === parent.modelData.value ? SideState.surface : SideState.fg
                    }

                    HoverHandler {
                        id: sh

                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: root.edited(parent.modelData.value)
                    }
                }
            }
        }
    }

    // picker: type a name or step through the installed ones with the arrows (options: [string])
    Component {
        id: pickerC

        Row {
            id: pk

            readonly property int idx: root.options.indexOf(String(root.value))

            function move(d) {
                const n = root.options.length;
                if (n === 0)
                    return;
                const i = idx < 0 ? (d > 0 ? 0 : n - 1) : (idx + d + n) % n;
                root.edited(root.options[i]);
            }

            spacing: 6

            Repeater {
                model: ["‹", "›"]

                Rectangle {
                    id: arrow

                    required property string modelData
                    required property int index

                    visible: arrow.index === 0
                    width: 32
                    height: 34
                    radius: 17
                    color: ah.hovered ? SideState.cardHi : SideState.card

                    SideText {
                        anchors.centerIn: parent
                        text: arrow.modelData
                        customSize: 16
                        font.bold: true
                    }

                    HoverHandler { id: ah; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: pk.move(-1) }
                }
            }

            Rectangle {
                width: 200
                height: 34
                radius: 17
                color: SideState.cardHi
                border.width: pin.activeFocus ? 1 : 0
                border.color: SideState.primary

                TextInput {
                    id: pin

                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    verticalAlignment: TextInput.AlignVCenter
                    text: root.value === null ? "" : String(root.value)
                    color: SideState.fg
                    selectionColor: SideState.primary
                    selectedTextColor: SideState.surface
                    font.family: Constants.fontFamily
                    font.pixelSize: Math.round(12 * SettingsService.fontScale)
                    clip: true
                    onEditingFinished: root.edited(text.trim())
                }

                Text {
                    visible: pin.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    text: root.placeholder
                    color: SideState.muted
                    font: pin.font
                }
            }

            Rectangle {
                width: 32
                height: 34
                radius: 17
                color: bh2.hovered ? SideState.cardHi : SideState.card

                SideText {
                    anchors.centerIn: parent
                    text: "›"
                    customSize: 16
                    font.bold: true
                }

                HoverHandler { id: bh2; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: pk.move(1) }
            }
        }
    }

    Component {
        id: textC

        Rectangle {
            implicitWidth: 260
            implicitHeight: 34
            radius: 17
            color: SideState.cardHi
            border.width: input.activeFocus ? 1 : 0
            border.color: SideState.primary

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                text: root.value === null ? "" : String(root.value)
                color: SideState.fg
                selectionColor: SideState.primary
                selectedTextColor: SideState.surface
                echoMode: root.password ? TextInput.Password : TextInput.Normal
                font.family: Constants.fontFamily
                font.pixelSize: Math.round(12 * SettingsService.fontScale)
                clip: true
                onEditingFinished: root.edited(text.trim())

                Text {
                    visible: input.text === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.placeholder
                    color: SideState.muted
                    font: input.font
                }
            }
        }
    }

    Component {
        id: buttonC

        Rectangle {
            implicitWidth: btnLabel.implicitWidth + 32
            implicitHeight: 32
            radius: 16
            color: bth.hovered ? SideState.primary : SideState.cardHi

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            SideText {
                id: btnLabel

                anchors.centerIn: parent
                text: root.value === null ? "Run" : String(root.value)
                font.bold: true
                color: bth.hovered ? SideState.surface : SideState.fg
            }

            HoverHandler {
                id: bth

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.clicked()
            }
        }
    }

    Component {
        id: infoC

        SideText {
            text: root.value === null ? "" : String(root.value)
            color: SideState.muted
            font.bold: true
        }
    }
}
