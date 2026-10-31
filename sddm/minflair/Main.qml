import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts

// Minflair SDDM theme: blurred wallpaper (synced by the shell), clock, user, password,
// session picker (every installed Wayland/X11 session) and power buttons.
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: pal.bg

    // Colours written by the shell to /var/tmp/sddm-theme/colors.qml; defaults used until then.
    Loader {
        id: palLoader
        source: "file:///var/tmp/sddm-theme/colors.qml"
    }
    QtObject {
        id: pal
        readonly property bool ok: palLoader.status === Loader.Ready && palLoader.item !== null
        readonly property color bg: ok ? palLoader.item.bg : "#0c0b08"
        readonly property color fg: ok ? palLoader.item.fg : "#ece8dc"
        readonly property color muted: ok ? palLoader.item.muted : "#8c8a84"
        readonly property color accent: ok ? palLoader.item.accent : "#ccb565"
        readonly property color panel: ok ? palLoader.item.panel : "#d9161410"
        readonly property string font: ok ? palLoader.item.font : "Geist"
    }

    property bool failed: false

    function doLogin() {
        if (pass.text === "" || users.count === 0) return;
        root.failed = false;
        sddm.login(userPicker.currentText, pass.text, sessionPicker.currentIndex);
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.failed = true;
            pass.text = "";
            pass.forceActiveFocus();
        }
    }

    // ---- background
    Image {
        id: wall
        anchors.fill: parent
        source: "file:///var/tmp/sddm-theme/wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    // blurred copy on top; if the renderer has no effect support the plain image stays visible
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blur: 0.7
        blurMax: 48
    }
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.35
        visible: wall.status === Image.Ready
    }

    // ---- clock
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.12
        spacing: 4

        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: pal.fg
            font.family: pal.font
            font.pixelSize: 96
            font.weight: Font.DemiBold
            text: Qt.formatTime(new Date(), "hh:mm")
        }
        Text {
            id: date
            anchors.horizontalCenter: parent.horizontalCenter
            color: pal.muted
            font.family: pal.font
            font.pixelSize: 20
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), "hh:mm");
                date.text = Qt.formatDate(new Date(), "dddd, d MMMM");
            }
        }
    }

    // ---- login card
    Rectangle {
        id: card
        anchors.centerIn: parent
        anchors.verticalCenterOffset: parent.height * 0.12
        width: 360
        height: col.implicitHeight + 48
        radius: 24
        color: pal.panel
        border.color: Qt.rgba(1, 1, 1, 0.08)

        ColumnLayout {
            id: col
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 76; height: 76; radius: 38
                color: pal.accent
                Text {
                    anchors.centerIn: parent
                    text: userPicker.currentText.length > 0 ? userPicker.currentText.charAt(0).toUpperCase() : "?"
                    color: pal.bg
                    font.family: pal.font
                    font.pixelSize: 34
                    font.weight: Font.Bold
                }
            }

            Picker {
                id: userPicker
                Layout.fillWidth: true
                model: userModel
                textRole: "name"
                currentIndex: userModel.lastIndex
                fg: pal.fg; panel: Qt.rgba(1, 1, 1, 0.07); accent: pal.accent; fontFamily: pal.font
            }

            TextField {
                id: pass
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                echoMode: TextInput.Password
                placeholderText: "Password"
                placeholderTextColor: pal.muted
                color: pal.fg
                font.family: pal.font
                font.pixelSize: 15
                leftPadding: 14
                focus: true
                background: Rectangle {
                    radius: 12
                    color: Qt.rgba(1, 1, 1, 0.07)
                    border.color: root.failed ? "#e5534b" : (pass.activeFocus ? pal.accent : "transparent")
                    border.width: 1
                }
                onAccepted: root.doLogin()
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                visible: root.failed
                text: "Login failed, try again"
                color: "#e5534b"
                font.family: pal.font
                font.pixelSize: 13
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                text: "Log in"
                onClicked: root.doLogin()
                contentItem: Text {
                    text: parent.text
                    color: pal.bg
                    font.family: pal.font
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 12
                    color: pal.accent
                    opacity: parent.down ? 0.8 : 1
                }
            }
        }
    }

    // ---- session picker (bottom left) + power (bottom right)
    Picker {
        id: sessionPicker
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 28
        width: 280
        openUp: true
        label: "Session"
        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel.lastIndex
        fg: pal.fg; panel: pal.panel; accent: pal.accent; fontFamily: pal.font
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 10

        Repeater {
            model: [
                { label: "Suspend", ok: sddm.canSuspend, act: function() { sddm.suspend(); } },
                { label: "Reboot", ok: sddm.canReboot, act: function() { sddm.reboot(); } },
                { label: "Shut down", ok: sddm.canPowerOff, act: function() { sddm.powerOff(); } }
            ]
            delegate: Rectangle {
                required property var modelData
                visible: modelData.ok
                width: lbl.implicitWidth + 28
                height: 38
                radius: 12
                color: pal.panel
                Text {
                    id: lbl
                    anchors.centerIn: parent
                    text: parent.modelData.label
                    color: pal.fg
                    font.family: pal.font
                    font.pixelSize: 14
                }
                TapHandler { onTapped: parent.modelData.act() }
            }
        }
    }

    // hidden helper so we can read the user count
    ListView { id: users; visible: false; model: userModel }

    Component.onCompleted: pass.forceActiveFocus()
}
