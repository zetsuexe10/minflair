import QtQuick
import Quickshell.Io
pragma Singleton

Item {
    id: root

    property int watchers: 0
    property real rxRate: 0
    property real txRate: 0
    property var rxHistory: []
    property var txHistory: []
    property real peakRx: 0
    property real peakTx: 0
    property real totalRx: 0
    property real totalTx: 0
    property real startedAt: Date.now()
    property real _lastRx: -1
    property real _lastTx: -1
    property real _lastAt: 0
    property real _baseRx: -1
    property real _baseTx: -1
    readonly property real elapsed: Math.max(1, (Date.now() - startedAt) / 1000)
    property real avgRx: 0
    property real avgTx: 0
    readonly property int maxSamples: 60

    function formatRate(bps) {
        const bits = bps * 8;
        if (bits >= 1e9)
            return (bits / 1e9).toFixed(2) + " Gbps";
        if (bits >= 1e6)
            return (bits / 1e6).toFixed(bits >= 1e8 ? 0 : 1) + " Mbps";
        if (bits >= 1e3)
            return Math.round(bits / 1e3) + " Kbps";
        return "0 Kbps";
    }

    function formatBytes(b) {
        if (b >= 1073741824)
            return (b / 1073741824).toFixed(2) + " GB";
        if (b >= 1048576)
            return (b / 1048576).toFixed(1) + " MB";
        if (b >= 1024)
            return Math.round(b / 1024) + " KB";
        return Math.round(b) + " B";
    }

    function _push(arr, v) {
        const next = arr.slice(-(root.maxSamples - 1));
        next.push(v);
        return next;
    }

    function _ingest(text) {
        let rx = 0;
        let tx = 0;
        const lines = text.split("\n");
        for (let i = 2; i < lines.length; i++) {
            const line = lines[i];
            const c = line.indexOf(":");
            if (c < 0)
                continue;
            const name = line.slice(0, c).trim();
            if (name === "lo" || name.startsWith("docker") || name.startsWith("veth") || name.startsWith("br-") || name.startsWith("virbr"))
                continue;
            const f = line.slice(c + 1).trim().split(/\s+/);
            rx += parseFloat(f[0]) || 0;
            tx += parseFloat(f[8]) || 0;
        }
        const now = Date.now();
        if (root._baseRx < 0) {
            root._baseRx = rx;
            root._baseTx = tx;
        }
        if (root._lastRx >= 0 && now > root._lastAt) {
            const dt = (now - root._lastAt) / 1000;
            root.rxRate = Math.max(0, (rx - root._lastRx) / dt);
            root.txRate = Math.max(0, (tx - root._lastTx) / dt);
            root.rxHistory = root._push(root.rxHistory, root.rxRate);
            root.txHistory = root._push(root.txHistory, root.txRate);
            root.peakRx = Math.max(root.peakRx, root.rxRate);
            root.peakTx = Math.max(root.peakTx, root.txRate);
        }
        root._lastRx = rx;
        root._lastTx = tx;
        root._lastAt = now;
        root.totalRx = Math.max(0, rx - root._baseRx);
        root.totalTx = Math.max(0, tx - root._baseTx);
        root.avgRx = root.totalRx / root.elapsed;
        root.avgTx = root.totalTx / root.elapsed;
    }

    Timer {
        interval: root.watchers > 0 ? 1000 : 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!proc.running)
                proc.running = true;
        }
    }

    Process {
        id: proc

        command: ["cat", "/proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: root._ingest(text)
        }
    }
}
