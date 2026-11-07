import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "components"

// Minflair login screen. Layout adapted from the Archcraft SDDM theme (GPLv3, see assets/NOTICE).
// UI only: shell.qml talks to greetd. Colours come from the palette file written by the shell,
// the wallpaper is pre-blurred and pre-dimmed by the theme script, so no shaders run here.
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: pal.bg

    readonly property string stateDir: "file:///var/tmp/minflair-greeter/"

    Loader { id: palLoader; source: root.stateDir + "colors.qml" }
    Loader { id: clockLoader; source: root.stateDir + "clock.qml" }
    readonly property bool hour24: clockLoader.status === Loader.Ready && clockLoader.item !== null ? clockLoader.item.hour24 : true
    readonly property string timeFormat: hour24 ? "HH:mm" : "h:mm AP"
    QtObject {
        id: pal
        readonly property bool ok: palLoader.status === Loader.Ready && palLoader.item !== null
        readonly property color bg: ok ? palLoader.item.bg : "#1e2128"
        readonly property color fg: ok ? palLoader.item.fg : "#d8d8d8"
        readonly property color muted: ok ? palLoader.item.muted : "#abb2bf"
        readonly property color accent: ok ? palLoader.item.accent : "#5294e2"
        readonly property color panel: ok ? palLoader.item.opaquePanel : "#262a33"
        readonly property string font: ok ? palLoader.item.font : "Geist"
    }
    readonly property real u: Math.max(0.7, Math.min(width / 1920, height / 1080))

    // ---- interface to shell.qml
    property var users: []
    property var sessions: []
    property alias sessionIndex: sessionPicker.currentIndex
    property bool failed: false
    property bool busy: false
    property string errorText: "Login failed, try again"
    readonly property string currentUser: userPicker.currentText
    readonly property string currentSession: sessionPicker.currentText
    signal loginRequested(string user, string password, int sessionIndex)
    signal powerRequested(string action)

    function fail(msg) {
        busy = false; failed = true;
        if (msg) errorText = msg;
        shake.restart(); pass.text = ""; pass.forceActiveFocus();
    }
    function doLogin() {
        if (busy || pass.text === "" || userPicker.currentText === "") return;
        failed = false; busy = true;
        loginRequested(userPicker.currentText, pass.text, sessionPicker.currentIndex);
    }

    property real appear: 0
    property real shakeX: 0
    opacity: 0
    Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    NumberAnimation on appear { id: appearAnim; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic; running: false }
    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeX"; to: -14; duration: 55 }
        NumberAnimation { target: root; property: "shakeX"; to: 14; duration: 90 }
        NumberAnimation { target: root; property: "shakeX"; to: -9; duration: 80 }
        NumberAnimation { target: root; property: "shakeX"; to: 5; duration: 70 }
        NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 60 }
    }

    // ---- background
    Image {
        id: wall
        anchors.fill: parent
        source: root.stateDir + "wallpaper.jpg"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(root.width, root.height)
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }
    Rectangle {      // soft vignette so text stays readable on any wallpaper
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.18) }
            GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.0) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.35) }
        }
    }

    // ---- header, clock, form
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.05 + (1 - root.appear) * 24
        opacity: root.appear
        spacing: 0
        transform: Translate { x: root.shakeX }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome!"
            color: pal.fg
            font.family: pal.font
            font.pixelSize: 36 * root.u
        }
        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8 * root.u
            color: pal.fg
            font.family: pal.font
            font.pixelSize: 120 * root.u
            font.weight: Font.DemiBold
            text: Qt.formatTime(new Date(), root.timeFormat)
        }
        Text {
            id: date
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 2 * root.u
            color: pal.muted
            font.family: pal.font
            font.pixelSize: 22 * root.u
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), root.timeFormat);
                date.text = Qt.formatDate(new Date(), "dddd, MMMM d");
            }
        }

        Item { Layout.preferredHeight: 72 * root.u }

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420 * root.u
            Layout.preferredHeight: 50 * root.u
            Picker {
                id: userPicker
                anchors.fill: parent
                centered: true
                items: root.users
                fg: pal.fg; panel: pal.panel; accent: pal.accent; fontFamily: pal.font
                fontSize: 16 * root.u
            }
            Icon {
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                size: 20 * root.u
                source: "assets/User.svg"
                lit: userPicker.hovered || userPicker.activeFocus
            }
        }

        TextField {
            id: pass
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 16 * root.u
            Layout.preferredWidth: 420 * root.u
            Layout.preferredHeight: 50 * root.u
            enabled: !root.busy
            echoMode: eye.shown ? TextInput.Normal : TextInput.Password
            horizontalAlignment: TextInput.AlignHCenter
            color: pal.fg
            font.family: pal.font
            font.pixelSize: 16 * root.u
            leftPadding: 52; rightPadding: 52
            focus: true
            background: Rectangle {
                radius: height / 2
                color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 2
                border.color: root.failed ? "#e06b74" : (pass.activeFocus ? pal.accent : Qt.rgba(1, 1, 1, 0.28))
                Behavior on border.color { ColorAnimation { duration: 160 } }
            }
            onAccepted: root.doLogin()
            onTextEdited: root.failed = false

            Text {
                anchors.centerIn: parent
                visible: pass.text === ""
                text: "Password"
                color: pal.muted
                font: pass.font
            }
            Icon {
                id: eye
                property bool shown: false
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                size: 20 * root.u
                source: shown ? "assets/Password2.svg" : "assets/Password.svg"
                lit: eyeHover.hovered || pass.activeFocus
                HoverHandler { id: eyeHover; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: eye.shown = !eye.shown }
            }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 40 * root.u
            verticalAlignment: Text.AlignVCenter
            opacity: root.failed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            text: root.errorText
            color: "#e06b74"
            font.family: pal.font
            font.italic: true
            font.pixelSize: 14 * root.u
        }

        Button {
            id: loginBtn
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420 * root.u
            Layout.preferredHeight: 50 * root.u
            enabled: !root.busy
            scale: down ? 0.98 : 1
            Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
            onClicked: root.doLogin()
            contentItem: Text {
                text: root.busy ? "Signing in..." : "Login"
                color: pal.bg
                font.family: pal.font
                font.pixelSize: 16 * root.u
                font.weight: Font.DemiBold
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle {
                radius: height / 2
                color: pal.accent
                opacity: loginBtn.down || root.busy ? 0.7 : (loginBtn.hovered ? 0.88 : 1)
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    // ---- bottom: session + power
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 36 * root.u
        opacity: root.appear
        spacing: 20 * root.u

        Picker {
            id: sessionPicker
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 440 * root.u
            Layout.preferredHeight: 36 * root.u
            bare: true
            centered: true
            openUp: true
            label: "Session"
            items: root.sessions
            fg: pal.muted; panel: pal.panel; accent: pal.accent; fontFamily: pal.font
            fontSize: 15 * root.u
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 36 * root.u
            Repeater {
                model: [
                    { icon: "assets/Suspend.svg", act: "suspend" },
                    { icon: "assets/Reboot.svg", act: "reboot" },
                    { icon: "assets/Shutdown.svg", act: "poweroff" }
                ]
                delegate: Item {
                    required property var modelData
                    width: 30 * root.u; height: 30 * root.u
                    scale: ph.hovered ? 1.15 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Icon { anchors.fill: parent; size: parent.width; source: parent.modelData.icon; lit: ph.hovered }
                    HoverHandler { id: ph; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: root.powerRequested(parent.modelData.act) }
                }
            }
        }
    }

    Component.onCompleted: {
        pass.forceActiveFocus();
        root.opacity = 1;
        appearAnim.start();
    }
}
