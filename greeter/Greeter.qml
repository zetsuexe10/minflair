import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts

// Minflair login screen, layout adapted from the Archcraft SDDM theme (GPLv3, see Assets/NOTICE):
// header, big clock, pill-shaped user/password fields, pill login button, session link, power icons.
// UI only; shell.qml talks to greetd. Colours come from the shell's palette file.
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: pal.bg

    // ---- palette (written by the shell to /var/tmp/minflair-greeter/colors.qml)
    Loader { id: palLoader; source: "file:///var/tmp/minflair-greeter/colors.qml" }
    QtObject {
        id: pal
        readonly property bool ok: palLoader.status === Loader.Ready && palLoader.item !== null
        readonly property color bg: ok ? palLoader.item.bg : "#1e2128"
        readonly property color fg: ok ? palLoader.item.fg : "#d8d8d8"
        readonly property color muted: ok ? palLoader.item.muted : "#abb2bf"
        readonly property color accent: ok ? palLoader.item.accent : "#5294e2"
        readonly property color panel: ok ? palLoader.item.panel : "#d91e2128"
        readonly property string font: ok ? palLoader.item.font : "Geist"
    }
    readonly property color line: Qt.rgba(pal.fg.r, pal.fg.g, pal.fg.b, 0.28)
    readonly property real u: Math.max(0.7, Math.min(width / 1920, height / 1080))   // UI scale

    // ---- interface to shell.qml
    property bool failed: false
    property bool busy: false
    property string errorText: "Login failed, try again"
    property alias userModel: userPicker.model
    property alias sessionModel: sessionPicker.model
    property alias sessionIndex: sessionPicker.currentIndex
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
    Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
    NumberAnimation on appear { id: appearAnim; from: 0; to: 1; duration: 800; easing.type: Easing.OutCubic; running: false }
    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeX"; to: -14; duration: 55 }
        NumberAnimation { target: root; property: "shakeX"; to: 14; duration: 90 }
        NumberAnimation { target: root; property: "shakeX"; to: -9; duration: 80 }
        NumberAnimation { target: root; property: "shakeX"; to: 5; duration: 70 }
        NumberAnimation { target: root; property: "shakeX"; to: 0; duration: 60 }
    }

    // ---- background: wallpaper (blurred, dimmed) over the flat palette colour
    Image {
        id: wall
        anchors.fill: parent
        source: "file:///var/tmp/minflair-greeter/wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        visible: wall.status === Image.Ready
        blurEnabled: true
        blur: 0.6
        blurMax: 40
    }
    Rectangle {
        anchors.fill: parent
        color: pal.bg
        opacity: wall.status === Image.Ready ? 0.45 : 0
    }

    // ---- centred column
    ColumnLayout {
        id: col
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.04 + (1 - root.appear) * 30
        opacity: root.appear
        spacing: 0
        transform: Translate { x: root.shakeX }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "Welcome!"
            color: pal.fg
            font.family: pal.font
            font.pixelSize: 34 * root.u
        }
        Text {
            id: clock
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 6 * root.u
            color: pal.fg
            font.family: pal.font
            font.pixelSize: 110 * root.u
            font.weight: Font.DemiBold
            text: Qt.formatTime(new Date(), "HH:mm")
        }
        Text {
            id: date
            Layout.alignment: Qt.AlignHCenter
            color: pal.muted
            font.family: pal.font
            font.pixelSize: 22 * root.u
            text: Qt.formatDate(new Date(), "dddd, MMMM d")
        }
        Timer {
            interval: 1000; running: true; repeat: true
            onTriggered: {
                clock.text = Qt.formatTime(new Date(), "HH:mm");
                date.text = Qt.formatDate(new Date(), "dddd, MMMM d");
            }
        }

        Item { Layout.preferredHeight: 56 * root.u }

        // user
        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 400 * root.u
            Layout.preferredHeight: 44 * root.u
            Picker {
                id: userPicker
                anchors.fill: parent
                radius: height / 2
                centered: true
                textRole: "name"
                fg: pal.fg; panel: "transparent"; accent: pal.accent; fontFamily: pal.font
            }
            Icon { source: "Assets/User.svg"; lit: userPicker.hovered
                   anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter }
        }

        // password
        TextField {
            id: pass
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 14 * root.u
            Layout.preferredWidth: 400 * root.u
            Layout.preferredHeight: 44 * root.u
            enabled: !root.busy
            echoMode: showPass.shown ? TextInput.Normal : TextInput.Password
            horizontalAlignment: TextInput.AlignHCenter
            color: pal.fg
            font.family: pal.font
            font.pixelSize: 16 * root.u
            leftPadding: 44; rightPadding: 44
            focus: true
            background: Rectangle {
                radius: height / 2
                color: "transparent"
                border.width: 2
                border.color: root.failed ? "#e06b74" : (pass.activeFocus ? pal.accent : root.line)
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
                id: showPass
                property bool shown: false
                source: shown ? "Assets/Password2.svg" : "Assets/Password.svg"
                lit: passTap.hovered || pass.activeFocus
                anchors.left: parent.left; anchors.leftMargin: 16; anchors.verticalCenter: parent.verticalCenter
                HoverHandler { id: passTap; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: showPass.shown = !showPass.shown }
            }
        }

        // error line
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: 28 * root.u
            verticalAlignment: Text.AlignVCenter
            opacity: root.failed ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            text: root.errorText
            color: "#e06b74"
            font.family: pal.font
            font.italic: true
            font.pixelSize: 13 * root.u
        }

        // login button
        Button {
            id: loginBtn
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 400 * root.u
            Layout.preferredHeight: 44 * root.u
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
                opacity: loginBtn.down || root.busy ? 0.7 : (loginBtn.hovered ? 0.9 : 1)
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }
        }
    }

    // ---- bottom: session link + power icons
    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 30 * root.u
        opacity: root.appear
        spacing: 14 * root.u

        Picker {
            id: sessionPicker
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 420 * root.u
            Layout.preferredHeight: 34 * root.u
            bare: true
            centered: true
            openUp: true
            label: "Session"
            textRole: "name"
            fg: pal.muted; panel: pal.panel; accent: pal.accent; fontFamily: pal.font
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 26 * root.u
            Repeater {
                model: [
                    { icon: "Assets/Suspend.svg", act: "suspend" },
                    { icon: "Assets/Reboot.svg", act: "reboot" },
                    { icon: "Assets/Shutdown.svg", act: "poweroff" }
                ]
                delegate: Item {
                    required property var modelData
                    width: 32 * root.u; height: 32 * root.u
                    scale: ph.hovered ? 1.15 : 1
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Icon { anchors.fill: parent; size: parent.width; source: parent.modelData.icon
                           lit: ph.hovered }
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
