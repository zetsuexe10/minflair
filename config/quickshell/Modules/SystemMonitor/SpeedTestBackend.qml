import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    property string state: "idle"
    property real downMbps: 0
    property real upMbps: 0
    property real pingMs: -1
    property real progress: 0
    property real liveMbps: 0
    property string message: ""
    property var liveHistory: []
    property real lastDown: -1
    property real lastUp: -1
    property real lastPing: -1
    property string lastAt: ""
    readonly property bool running: state === "latency" || state === "download" || state === "upload" || state === "starting"
    readonly property string script: Quickshell.shellDir + "/Modules/SystemMonitor/scripts/speedtest.py"

    function start() {
        if (running)
            return;
        state = "starting";
        downMbps = 0;
        upMbps = 0;
        pingMs = -1;
        progress = 0;
        liveMbps = 0;
        liveHistory = [];
        message = "";
        proc.running = true;
    }

    function stop() {
        if (proc.running)
            proc.signal(15);
        state = "idle";
    }

    function _line(raw) {
        let m;
        try {
            m = JSON.parse(raw);
        } catch (err) {
            return;
        }
        if (m.phase === "start") {
            state = "starting";
        } else if (m.phase === "latency") {
            state = "latency";
        } else if (m.phase === "latency_done") {
            pingMs = m.ping;
        } else if (m.phase === "download" || m.phase === "upload") {
            state = m.phase;
            liveMbps = m.mbps;
            progress = m.pct;
            const h = liveHistory.slice(-59);
            h.push(m.mbps);
            liveHistory = h;
            if (m.phase === "download")
                downMbps = m.mbps;
            else
                upMbps = m.mbps;
        } else if (m.phase === "download_done") {
            downMbps = m.mbps;
            liveHistory = [];
        } else if (m.phase === "done") {
            downMbps = m.down;
            upMbps = m.up === null || m.up === undefined ? 0 : m.up;
            pingMs = m.ping;
            lastDown = downMbps;
            lastUp = m.up === null || m.up === undefined ? -1 : m.up;
            lastPing = pingMs;
            lastAt = Qt.formatDateTime(new Date(), "h:mm AP");
            state = "done";
        } else if (m.phase === "error") {
            message = m.message;
            state = "error";
        }
    }

    Process {
        id: proc

        command: ["python3", root.script]
        stdout: SplitParser {
            onRead: data => root._line(data)
        }
        onExited: {
            if (root.running) {
                root.message = "The test stopped unexpectedly";
                root.state = "error";
            }
        }
    }
}
