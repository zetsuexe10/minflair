import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string page: "main"
    property bool active: true
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool volumeMuted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property real pageHeight: page === "main" ? 212 : 400
    property string passwordFor: ""
    readonly property color soft: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
    readonly property color softBorder: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.08)
    readonly property alias initialFocusItem: keyCatcher
    readonly property alias backend: wifi

    signal closeRequested()

    property bool _watching: false

    function syncWatch() {
        if (active && !_watching) {
            BrightnessService.watchers += 1;
            _watching = true;
        } else if (!active && _watching) {
            BrightnessService.watchers -= 1;
            _watching = false;
        }
    }

    function reset() {
        page = "main";
        passwordFor = "";
    }

    function signalIcon(sig) {
        const n = parseInt(sig) || 0;
        if (n <= 25)
            return "wifi-0";
        if (n <= 50)
            return "wifi-1";
        if (n <= 75)
            return "wifi-2";
        return "wifi";
    }

    function setVolume(v) {
        if (!sink || !sink.audio)
            return;
        if (sink.audio.muted && v > 0)
            sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v / 100));
    }

    implicitWidth: 372
    implicitHeight: pageHeight
    onActiveChanged: syncWatch()
    onPageChanged: {
        if (page === "wifi")
            wifi.scan(true);
    }
    Component.onCompleted: syncWatch()
    Component.onDestruction: {
        active = false;
        syncWatch();
    }

    Behavior on implicitHeight {
        NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    WifiBackend {
        id: wifi

        active: root.active
    }

    Item {
        id: keyCatcher

        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            if (root.page !== "main") {
                root.page = "main";
                root.passwordFor = "";
            } else {
                root.closeRequested();
            }
        }
    }

    Item {
        id: mainPage

        anchors.fill: parent
        opacity: root.page === "main" ? 1 : 0
        visible: opacity > 0
        enabled: root.page === "main"

        Behavior on opacity {
            NumberAnimation { duration: Constants.animFast }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 12

            PanelSlider {
                Layout.preferredWidth: 48
                Layout.fillHeight: true
                icon: BrightnessService.percent <= 20 ? "moon" : "sun"
                fillColor: Theme.accent
                value: BrightnessService.percent
                onMoved: (v) => BrightnessService.set(Math.max(1, v))
                onIconClicked: BrightnessService.set(BrightnessService.percent <= 5 ? 100 : 5)
            }

            PanelSlider {
                Layout.preferredWidth: 48
                Layout.fillHeight: true
                icon: root.volumeMuted || root.volume === 0 ? "volume-off" : "volume"
                muted: root.volumeMuted
                fillColor: Theme.accent
                value: root.volume
                onMoved: (v) => root.setVolume(v)
                onIconClicked: {
                    if (root.sink && root.sink.audio)
                        root.sink.audio.muted = !root.sink.audio.muted;
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                Rectangle {
                    id: wifiTile

                    Layout.fillWidth: true
                    Layout.preferredHeight: 98
                    radius: 26
                    color: wifi.radio ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.20) : root.soft
                    border.width: 1
                    border.color: wifi.radio ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.45) : root.softBorder

                    Behavior on color {
                        ColorAnimation { duration: Constants.animFast }
                    }

                    scale: wifiTileArea.pressed ? 0.97 : 1

                    Behavior on scale {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }

                    MouseArea {
                        id: wifiTileArea

                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.page = "wifi"
                    }

                    Rectangle {
                        id: wifiDot

                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.margins: 14
                        width: 40
                        height: 40
                        radius: 20
                        color: wifi.radio ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.16)

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: wifi.radio ? "wifi" : "wifi-off"
                            iconSize: 20
                            flat: true
                            iconColor: wifi.radio ? Theme.opaqueBg : Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifi.setRadio(!wifi.radio)
                        }
                    }

                    SvgIcon {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 18
                        icon: "chevron-right"
                        iconSize: 18
                        flat: true
                        iconColor: Theme.muted
                    }

                    Column {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 16
                        spacing: 2

                        Text {
                            text: "Wi-Fi"
                            font.pixelSize: 16
                            font.bold: true
                            color: Theme.fg
                        }

                        Text {
                            width: parent.width
                            text: !wifi.radio ? "Off" : (wifi.connectedSsid !== "" ? wifi.connectedSsid : "Not connected")
                            elide: Text.ElideRight
                            font.pixelSize: 13
                            color: Theme.muted
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Repeater {
                        model: [
                            { "id": "sound", "icon": root.volumeMuted ? "volume-off" : "volume", "label": "Sound", "on": !root.volumeMuted },
                            { "id": "mic", "icon": AudioService.micMuted ? "microphone-off" : "microphone", "label": "Mic", "on": !AudioService.micMuted }
                        ]

                        delegate: Rectangle {
                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: 24
                            color: modelData.on ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.92) : root.soft
                            border.width: 1
                            border.color: root.softBorder

                            Behavior on color {
                                ColorAnimation { duration: Constants.animFast }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 6

                                SvgIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    icon: modelData.icon
                                    iconSize: 24
                                    flat: true
                                    iconColor: modelData.on ? Theme.opaqueBg : Theme.fg
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.label
                                    font.pixelSize: 12
                                    font.bold: true
                                    color: modelData.on ? Theme.opaqueBg : Theme.muted
                                }
                            }

                            scale: toggleArea.pressed ? 0.95 : 1

                            Behavior on scale {
                                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                            }

                            MouseArea {
                                id: toggleArea

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData.id === "sound") {
                                        if (root.sink && root.sink.audio)
                                            root.sink.audio.muted = !root.sink.audio.muted;
                                    } else {
                                        AudioService.setMicMuted(!AudioService.micMuted);
                                    }
                                }
                            }
                        }
                    }
                }
            }

        }
    }

    Item {
        id: wifiPage

        anchors.fill: parent
        opacity: root.page === "wifi" ? 1 : 0
        visible: opacity > 0
        enabled: root.page === "wifi"

        Behavior on opacity {
            NumberAnimation { duration: Constants.animFast }
        }

        RowLayout {
            id: wifiHead

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 44
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: root.soft

                SvgIcon {
                    anchors.centerIn: parent
                    icon: "chevron-left"
                    iconSize: 20
                    flat: true
                    iconColor: Theme.fg
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.page = "main";
                        root.passwordFor = "";
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: "Wi-Fi"
                font.pixelSize: 20
                font.bold: true
                color: Theme.fg
            }

            Rectangle {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                radius: 20
                color: root.soft
                opacity: wifi.radio ? 1 : 0.4

                SvgIcon {
                    id: refreshIcon

                    anchors.centerIn: parent
                    icon: "refresh"
                    iconSize: 18
                    flat: true
                    iconColor: Theme.fg

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: 900
                        loops: Animation.Infinite
                        running: wifi.scanning && Constants.durationFactor > 0
                        onRunningChanged: {
                            if (!running)
                                refreshIcon.rotation = 0;
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: wifi.radio
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifi.scan(true)
                }
            }

            Rectangle {
                id: sw

                Layout.preferredWidth: 56
                Layout.preferredHeight: 32
                radius: 16
                color: wifi.radio ? Theme.accent : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.18)

                Behavior on color {
                    ColorAnimation { duration: Constants.animFast }
                }

                Rectangle {
                    y: 3
                    x: wifi.radio ? parent.width - width - 3 : 3
                    width: 26
                    height: 26
                    radius: 13
                    color: wifi.radio ? Theme.opaqueBg : Theme.fg

                    Behavior on x {
                        NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifi.setRadio(!wifi.radio)
                }
            }
        }

        Text {
            id: wifiMsg

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: wifiHead.bottom
            anchors.topMargin: 8
            visible: text !== ""
            height: visible ? implicitHeight : 0
            text: wifi.message
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.pixelSize: 12
            color: "#ff6b6b"
        }

        Text {
            anchors.centerIn: parent
            visible: !wifi.radio || (wifi.networks.length === 0 && !wifi.scanning)
            text: !wifi.radio ? "Wi-Fi is off" : "No networks found"
            font.pixelSize: 14
            color: Theme.muted
        }

        ListView {
            id: list

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: wifiMsg.bottom
            anchors.topMargin: 10
            anchors.bottom: parent.bottom
            clip: true
            spacing: 6
            model: wifi.radio ? wifi.networks : []
            boundsBehavior: Flickable.StopAtBounds

            delegate: Rectangle {
                id: row

                required property var modelData
                readonly property bool secured: (modelData.security || "") !== "" && modelData.security !== "--"
                readonly property bool open: root.passwordFor === modelData.ssid
                readonly property bool working: wifi.busySsid === modelData.ssid

                width: list.width
                height: open ? 112 : 56
                radius: 20
                color: modelData.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.18) : root.soft
                border.width: 1
                border.color: modelData.active ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.4) : root.softBorder
                clip: true

                Behavior on height {
                    NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic }
                }

                MouseArea {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 56
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (row.modelData.active)
                            return;
                        if (row.secured && !row.modelData.saved) {
                            root.passwordFor = row.open ? "" : row.modelData.ssid;
                            pw.text = "";
                            if (!row.open)
                                pw.forceActiveFocus();
                        } else {
                            root.passwordFor = "";
                            wifi.connect(row.modelData.ssid, "");
                        }
                    }
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 14
                    anchors.rightMargin: 12
                    height: 56
                    spacing: 12

                    SvgIcon {
                        icon: root.signalIcon(row.modelData.signal)
                        iconSize: 22
                        flat: true
                        iconColor: row.modelData.active ? Theme.accent : Theme.fg
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            width: parent.width
                            text: row.modelData.ssid
                            elide: Text.ElideRight
                            font.pixelSize: 14
                            font.bold: true
                            color: Theme.fg
                        }

                        Text {
                            width: parent.width
                            text: row.working ? "Connecting…" : (row.modelData.active ? "Connected" : (row.modelData.saved ? "Saved" : (row.secured ? "Secured" : "Open")))
                            elide: Text.ElideRight
                            font.pixelSize: 11
                            color: row.modelData.active ? Theme.accent : Theme.muted
                        }
                    }

                    SvgIcon {
                        visible: row.secured && !row.modelData.active
                        icon: "lock"
                        iconSize: 14
                        flat: true
                        iconColor: Theme.muted
                    }

                    Rectangle {
                        visible: row.modelData.active
                        Layout.preferredWidth: dcText.implicitWidth + 24
                        Layout.preferredHeight: 32
                        radius: 16
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.16)

                        Text {
                            id: dcText

                            anchors.centerIn: parent
                            text: "Disconnect"
                            font.pixelSize: 12
                            font.bold: true
                            color: Theme.fg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifi.disconnect()
                        }
                    }

                    Rectangle {
                        visible: row.modelData.saved && !row.modelData.active
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        radius: 16
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.12)

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "trash"
                            iconSize: 15
                            flat: true
                            iconColor: Theme.muted
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: wifi.forget(row.modelData.ssid)
                        }
                    }
                }

                RowLayout {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 12
                    height: 40
                    spacing: 8
                    visible: row.open

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)

                        TextInput {
                            id: pw

                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            verticalAlignment: TextInput.AlignVCenter
                            echoMode: TextInput.Password
                            font.pixelSize: 14
                            color: Theme.fg
                            clip: true
                            selectByMouse: true
                            onAccepted: join.go()
                            Keys.onEscapePressed: root.passwordFor = ""

                            Text {
                                visible: pw.text === ""
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Password"
                                font.pixelSize: 14
                                color: Theme.muted
                            }
                        }
                    }

                    Rectangle {
                        id: join

                        function go() {
                            if (pw.text.length === 0)
                                return;
                            const p = pw.text;
                            pw.text = "";
                            root.passwordFor = "";
                            wifi.connect(row.modelData.ssid, p);
                        }

                        Layout.preferredWidth: 64
                        Layout.fillHeight: true
                        radius: 14
                        color: Theme.accent

                        Text {
                            anchors.centerIn: parent
                            text: "Join"
                            font.pixelSize: 13
                            font.bold: true
                            color: Theme.opaqueBg
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: join.go()
                        }
                    }
                }
            }
        }
    }
}
