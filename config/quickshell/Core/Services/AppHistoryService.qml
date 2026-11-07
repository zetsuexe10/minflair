import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
pragma Singleton

Item {
    id: root

    property var entries: []
    property bool dirty: false
    readonly property string currentId: ToplevelManager.activeToplevel ? (ToplevelManager.activeToplevel.appId || "") : ""
    readonly property string file: Quickshell.env("HOME") + "/.cache/minflair/apps.json"

    function prettyName(id) {
        if (!id)
            return "";
        let n = id.indexOf(".") > 0 ? id.slice(id.lastIndexOf(".") + 1) : id;
        n = n.replace(/[-_]+/g, " ").trim();
        return n.replace(/\b\w/g, c => c.toUpperCase());
    }

    function formatDuration(sec) {
        const s = Math.round(sec);
        if (s >= 3600)
            return Math.floor(s / 3600) + "h " + Math.floor((s % 3600) / 60) + "m";
        if (s >= 60)
            return Math.floor(s / 60) + "m";
        return s + "s";
    }

    function ago(ms) {
        const d = Math.max(0, (Date.now() - ms) / 1000);
        if (d < 60)
            return "just now";
        if (d < 3600)
            return Math.floor(d / 60) + "m ago";
        if (d < 86400)
            return Math.floor(d / 3600) + "h ago";
        return Math.floor(d / 86400) + "d ago";
    }

    function touch(id, addSeconds) {
        if (!id)
            return;
        const list = root.entries.slice();
        let idx = list.findIndex(e => e.id === id);
        if (idx < 0) {
            list.push({ "id": id, "last": Date.now(), "seconds": 0 });
            idx = list.length - 1;
        }
        const e = Object.assign({}, list[idx]);
        e.last = Date.now();
        e.seconds = (e.seconds || 0) + addSeconds;
        list[idx] = e;
        list.sort((a, b) => b.last - a.last);
        root.entries = list.slice(0, 24);
        root.dirty = true;
    }

    onCurrentIdChanged: touch(currentId, 0)

    Timer {
        interval: 1000
        running: root.currentId !== ""
        repeat: true
        onTriggered: root.touch(root.currentId, 1)
    }

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            if (root.dirty && !saveProc.running) {
                root.dirty = false;
                saveProc.command = ["sh", "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", root.file, JSON.stringify(root.entries)];
                saveProc.running = true;
            }
        }
    }

    Process {
        id: saveProc
    }

    Process {
        id: loadProc

        command: ["sh", "-c", "cat \"$1\" 2>/dev/null || true", "sh", root.file]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const data = JSON.parse(text);
                    if (Array.isArray(data)) {
                        const merged = data.concat(root.entries.filter(e => !data.some(d => d.id === e.id)));
                        merged.sort((a, b) => b.last - a.last);
                        root.entries = merged.slice(0, 24);
                    }
                } catch (err) {
                }
            }
        }
    }

    Component.onCompleted: {
        loadProc.running = true;
        touch(currentId, 0);
    }
}
