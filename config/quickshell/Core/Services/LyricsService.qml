pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core.Services

Item {
    id: root

    readonly property var player: MprisService.activePlayer
    readonly property string title: player ? (player.trackTitle || "") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album: player ? (player.trackAlbum || "") : ""
    readonly property real duration: player && player.length > 0 && player.length < 100000 ? Math.round(player.length) : 0
    readonly property string key: title + "|" + artist
    property var lines: []
    property bool synced: false
    property bool loading: false
    property string state: "idle"
    property int users: 0
    property var cache: ({})

    function parse(synced, plain) {
        const out = [];
        if (synced) {
            const re = /^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/;
            synced.split("\n").forEach((l) => {
                const m = re.exec(l.trim());
                if (m)
                    out.push({ "t": parseInt(m[1]) * 60 + parseFloat(m[2]), "text": m[3] });
            });
            if (out.length > 0) {
                root.synced = true;
                return out;
            }
        }
        root.synced = false;
        (plain || "").split("\n").forEach((l) => out.push({ "t": -1, "text": l.trim() }));
        return out.filter((l, i) => l.text !== "" || i > 0);
    }

    function fetch() {
        if (users <= 0 || title === "") {
            lines = [];
            state = "idle";
            return;
        }
        if (cache[key]) {
            lines = cache[key].lines;
            synced = cache[key].synced;
            state = lines.length > 0 ? "ok" : "none";
            return;
        }
        lines = [];
        state = "loading";
        proc.running = false;
        proc.command = ["curl", "-sfG", "-m", "8", "-A", "minflair-shell", "https://lrclib.net/api/get",
            "--data-urlencode", "track_name=" + title, "--data-urlencode", "artist_name=" + artist,
            "--data-urlencode", "album_name=" + album].concat(duration > 0 ? ["--data-urlencode", "duration=" + duration] : []);
        proc.expectKey = key;
        proc.running = true;
    }

    onKeyChanged: debounce.restart()
    onUsersChanged: debounce.restart()

    Timer {
        id: debounce

        interval: 350
        onTriggered: root.fetch()
    }

    Process {
        id: proc

        property string expectKey: ""

        stdout: StdioCollector {
            onStreamFinished: {
                if (proc.expectKey !== root.key)
                    return;
                let got = [];
                try {
                    const j = JSON.parse(text);
                    got = root.parse(j.syncedLyrics, j.plainLyrics);
                } catch (e) {
                    got = [];
                }
                const c = root.cache;
                c[root.key] = { "lines": got, "synced": root.synced };
                root.cache = c;
                root.lines = got;
                root.state = got.length > 0 ? "ok" : "none";
            }
        }
        onExited: (code) => {
            if (code !== 0 && proc.expectKey === root.key && root.state === "loading")
                root.state = "none";
        }
    }
}
