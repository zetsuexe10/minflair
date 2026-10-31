import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Effects
import QtQuick.Layouts

// Minflair login screen (UI only; shell.qml talks to greetd): blurred wallpaper (synced by the shell), clock, user, password,
// session picker (every installed Wayland/X11 session) and power buttons.
Rectangle {
    id: root

    width: 1920
    height: 1080
    color: pal.bg

    // Colours written by the shell to /var/tmp/minflair-greeter/colors.qml; defaults used until then.
    Loader {
        id: palLoader
        source: "file:///var/tmp/minflair-greeter/colors.qml"
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
    property real appear: 0      // 0 -> 1 on start (drives fade/slide-in)
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

    function doLogin() {
        if (root.busy || pass.text === "" || userPicker.currentText === "") return;
        root.failed = false;
        root.busy = true;
        root.loginRequested(userPicker.currentText, pass.text, sessionPicker.currentIndex);
    }

    // ---- background
    Image {
        id: wall
        anchors.fill: parent
        source: "file:///var/tmp/minflair-greeter/wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
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
        anchors.topMargin: parent.height * 0.12 - (1 - root.appear) * 20
        opacity: root.appear
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
        anchors.verticalCenterOffset: parent.height * 0.12 + (1 - root.appear) * 40
        opacity: root.appear
        transform: Translate { x: root.shakeX }
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
                textRole: "name"
                fg: pal.fg; panel: Qt.rgba(1, 1, 1, 0.07); accent: pal.accent; fontFamily: pal.font
            }

            TextField {
                id: pass
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                enabled: !root.busy
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
                    Behavior on border.color { ColorAnimation { duration: 160 } }
                }
                onAccepted: root.doLogin()
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                opacity: root.failed ? 1 : 0
                Layout.preferredHeight: root.failed ? 18 : 0
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on Layout.preferredHeight { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                text: root.errorText
                color: "#e5534b"
                font.family: pal.font
                font.pixelSize: 13
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                text: root.busy ? "Signing in..." : "Log in"
                enabled: !root.busy
                scale: down ? 0.98 : 1
                Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutQuad } }
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
                    opacity: parent.down || root.busy ? 0.7 : (parent.hovered ? 0.92 : 1)
                    Behavior on opacity { NumberAnimation { duration: 120 } }
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
        textRole: "name"
        fg: pal.fg; panel: pal.panel; accent: pal.accent; fontFamily: pal.font
    }

    Row {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 10

        Repeater {
            model: [
                { label: "Suspend", ok: true, act: function() { root.powerRequested("suspend"); } },
                { label: "Reboot", ok: true, act: function() { root.powerRequested("reboot"); } },
                { label: "Shut down", ok: true, act: function() { root.powerRequested("poweroff"); } }
            ]
            delegate: Rectangle {
                required property var modelData
                visible: modelData.ok
                width: lbl.implicitWidth + 28
                height: 38
                radius: 12
                color: pal.panel
                scale: powerHover.hovered ? 1.05 : 1
                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                HoverHandler { id: powerHover; cursorShape: Qt.PointingHandCursor }
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

    Component.onCompleted: {
        pass.forceActiveFocus();
        root.opacity = 1;
        appearAnim.start();
    }
}
