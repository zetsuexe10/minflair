import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property bool active: false
    property bool radio: false
    property string connectedSsid: ""
    property var networks: []
    property bool scanning: scanProc.running
    property bool busy: actionProc.running
    property string busySsid: ""
    property string message: ""
    readonly property string script: Quickshell.shellDir + "/Modules/ControlCenter/scripts/wifi.py"

    function refresh() {
        statusProc.running = false;
        statusProc.running = true;
    }

    function scan(rescan) {
        if (!radio)
            return;
        scanProc.command = ["python3", script, "scan", rescan === false ? "no" : "yes"];
        scanProc.running = false;
        scanProc.running = true;
    }

    function setRadio(on) {
        if (on === radio)
            return;
        radio = on;
        if (!on) {
            networks = [];
            connectedSsid = "";
        }
        actionProc.command = ["nmcli", "radio", "wifi", on ? "on" : "off"];
        actionProc.pendingAfter = on ? "scan" : "status";
        actionProc.running = true;
    }

    function connect(ssid, password) {
        message = "";
        busySsid = ssid;
        const cmd = ["python3", script, "connect", ssid];
        if (password)
            cmd.push(password);
        actionProc.command = cmd;
        actionProc.pendingAfter = "scan";
        actionProc.parseResult = true;
        actionProc.running = true;
    }

    function disconnect() {
        busySsid = connectedSsid;
        actionProc.command = ["python3", script, "disconnect", connectedSsid];
        actionProc.pendingAfter = "scan";
        actionProc.parseResult = false;
        actionProc.running = true;
    }

    function forget(ssid) {
        busySsid = ssid;
        actionProc.command = ["python3", script, "forget", ssid];
        actionProc.pendingAfter = "scan";
        actionProc.parseResult = false;
        actionProc.running = true;
    }

    Timer {
        interval: 2500
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!actionProc.running)
                root.refresh();
        }
    }

    Process {
        id: statusProc

        command: ["python3", root.script, "status"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const st = JSON.parse(text.trim());
                    root.radio = st.radio;
                    root.connectedSsid = (st.connected_ssid && st.connected_ssid !== "Disconnected") ? st.connected_ssid : "";
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: scanProc

        command: ["python3", root.script, "scan", "yes"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text.trim());
                    if (Array.isArray(list)) {
                        list.sort((a, b) => (b.active - a.active) || (b.saved - a.saved) || (b.signal - a.signal));
                        root.networks = list;
                    }
                } catch (e) {
                }
            }
        }
    }

    Process {
        id: actionProc

        property string pendingAfter: "status"
        property bool parseResult: false

        stdout: StdioCollector {
            id: actionOut
        }

        onExited: {
            if (actionProc.parseResult) {
                try {
                    const r = JSON.parse(actionOut.text.trim());
                    root.message = r.success ? "" : (r.output || "Could not connect");
                } catch (e) {
                }
            }
            actionProc.parseResult = false;
            root.busySsid = "";
            root.refresh();
            if (pendingAfter === "scan")
                root.scan(true);
        }
    }
}
