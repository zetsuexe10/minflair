import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Modules.Settings.Components

// Wi-Fi panel: radio switch, scan, connect (with an inline password prompt) and disconnect.
// Talks to NetworkManager through the same wifi.py helper as the control center.
ColumnLayout {
    id: root

    readonly property string script: Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py"
    property bool radio: true
    property string connected: ""
    property var networks: []
    property bool busy: false
    property string pending: ""        // ssid awaiting a password
    property string message: ""

    function icon(signal) {
        const s = parseInt(signal) || 0;
        return s <= 25 ? "wifi-0" : (s <= 50 ? "wifi-1" : (s <= 75 ? "wifi-2" : "wifi"));
    }

    function refresh(rescan) {
        statusProc.running = false;
        statusProc.running = true;
        if (!root.radio)
            return;
        scanProc.command = ["python3", root.script, "scan", rescan ? "yes" : "no"];
        scanProc.running = false;
        scanProc.running = true;
    }

    function connectTo(ssid, password) {
        root.busy = true;
        root.message = "";
        connectProc.command = password ? ["python3", root.script, "connect", ssid, password] : ["python3", root.script, "connect", ssid];
        connectProc.running = false;
        connectProc.running = true;
    }

    function pick(net) {
        if (net.active) {
            toggleProc.command = ["python3", root.script, "disconnect"];
            toggleProc.running = true;
            return;
        }
        const secured = net.security !== "" && net.security !== "--";
        if (secured && !net.saved) {
            root.pending = net.ssid;
            return;
        }
        root.connectTo(net.ssid, "");
    }

    implicitWidth: 320
    spacing: Constants.sizeSm
    Component.onCompleted: refresh(false)

    Process {
        id: statusProc

        command: ["python3", root.script, "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const st = JSON.parse(text.trim());
                    root.radio = st.radio;
                    root.connected = st.connected_ssid && st.connected_ssid !== "Disconnected" ? st.connected_ssid : "";
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: scanProc

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text.trim());
                    if (Array.isArray(list))
                        root.networks = list;
                } catch (e) {
                }
                // first pass used the cached list; follow with a real rescan once
                if (!rescanned) {
                    rescanned = true;
                    root.refresh(true);
                }
            }
        }

        property bool rescanned: false
    }

    Process {
        id: toggleProc

        onRunningChanged: {
            if (!running)
                root.refresh(false);
        }
    }

    Process {
        id: connectProc

        stdout: StdioCollector {
            onStreamFinished: {
                root.busy = false;
                try {
                    const r = JSON.parse(text.trim());
                    root.message = r.success ? "" : "Could not connect";
                    if (r.success)
                        root.pending = "";
                } catch (e) {
                    root.message = "Could not connect";
                }
                root.refresh(false);
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            ThemedText {
                text: "Wi-Fi"
                font.bold: true
                customSize: Constants.sizeMd
            }

            ThemedText {
                text: !root.radio ? "Off" : (root.connected !== "" ? root.connected : "Not connected")
                color: Theme.muted
                customSize: 10
                elide: Text.ElideRight
            }
        }

        SideButton {
            icon: "reload"
            size: 30
            iconSize: Constants.sizeMd
            visible: root.radio
            onClicked: {
                scanProc.rescanned = true;
                root.refresh(true);
            }
        }

        Rectangle {
            implicitWidth: 44
            implicitHeight: 24
            radius: 12
            color: root.radio ? Theme.accent : Theme.bgSecondary
            border.width: 1
            border.color: Theme.border

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            Rectangle {
                width: 18
                height: 18
                radius: 9
                y: 3
                x: root.radio ? parent.width - width - 3 : 3
                color: root.radio ? Theme.opaqueBg : Theme.fg

                Behavior on x { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
            }

            TapHandler {
                onTapped: {
                    root.radio = !root.radio;
                    toggleProc.command = ["python3", root.script, "toggle-radio"];
                    toggleProc.running = true;
                }
            }
        }
    }

    ThemedText {
        visible: root.message !== ""
        text: root.message
        color: "#e06b74"
        customSize: Constants.sizeSm
    }

    // password prompt for a secured, unsaved network
    ColumnLayout {
        Layout.fillWidth: true
        visible: root.pending !== ""
        spacing: Constants.size2Xs

        ThemedText {
            text: "Password for " + root.pending
            color: Theme.muted
            customSize: Constants.sizeSm
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true

            ThemedTextField {
                id: pw

                Layout.fillWidth: true
                placeholderText: "Password"
                isPassword: true
                onEditingFinished: {
                    if (text !== "")
                        root.connectTo(root.pending, text);
                }
            }

            SideButton {
                icon: "check"
                size: 32
                iconColor: Theme.accent
                onClicked: {
                    if (pw.text !== "")
                        root.connectTo(root.pending, pw.text);
                }
            }

            SideButton {
                icon: "chevron-left"
                size: 32
                onClicked: {
                    root.pending = "";
                    pw.text = "";
                }
            }
        }
    }

    ThemedText {
        visible: root.radio && root.networks.length === 0
        text: "Scanning..."
        color: Theme.muted
    }

    ListView {
        id: list

        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 300)
        visible: root.radio && root.networks.length > 0 && root.pending === ""
        clip: true
        spacing: 2
        model: root.networks

        delegate: Rectangle {
            id: row

            required property var modelData

            width: ListView.view.width
            height: 40
            radius: 12
            color: modelData.active ? Theme.bgAccent : (hover.hovered ? Theme.bgSecondary : "transparent")

            Behavior on color { ColorAnimation { duration: Constants.animFast } }

            SvgIcon {
                id: sig

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                icon: root.icon(row.modelData.signal)
                iconColor: row.modelData.active ? Theme.accent : Theme.fg
                iconSize: Constants.sizeMd
                flat: true
            }

            ColumnLayout {
                anchors.left: sig.right
                anchors.leftMargin: 10
                anchors.right: lock.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                ThemedText {
                    Layout.fillWidth: true
                    text: row.modelData.ssid
                    elide: Text.ElideRight
                    font.bold: row.modelData.active
                }

                ThemedText {
                    text: row.modelData.active ? "Connected" : (row.modelData.saved ? "Saved" : "")
                    visible: text !== ""
                    customSize: 10
                    color: row.modelData.active ? Theme.accent : Theme.muted
                }
            }

            SvgIcon {
                id: lock

                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                visible: row.modelData.security !== "" && row.modelData.security !== "--"
                icon: "lock"
                iconColor: Theme.muted
                iconSize: Constants.sizeSm
                flat: true
            }

            HoverHandler {
                id: hover

                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.pick(row.modelData)
            }
        }
    }

    ThemedText {
        visible: root.busy
        text: "Connecting..."
        color: Theme.accent
        customSize: Constants.sizeSm
    }
}
