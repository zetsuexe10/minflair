pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Audio levels for the media visualiser, from `cava` when it is installed. Consumers raise `users`
// while they are on screen; the process only runs while someone is watching.
Item {
    id: root

    readonly property int bars: 28
    property int users: 0
    property var values: new Array(bars).fill(0)
    property bool available: true
    readonly property bool wanted: users > 0

    Process {
        id: proc

        running: root.wanted && root.available
        command: ["bash", "-c", "command -v cava >/dev/null || exit 127; exec cava -p <(printf '[general]\\nbars=" + root.bars + "\\nframerate=30\\nsleep_timer=3\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_value=100\\nbar_delimiter=59\\n[smoothing]\\nnoise_reduction=70\\n')"]
        onExited: (code) => {
            if (code === 127)
                root.available = false;
        }

        stdout: SplitParser {
            onRead: (line) => {
                const parts = line.split(";");
                const out = new Array(root.bars);
                for (let i = 0; i < root.bars; i++)
                    out[i] = Math.max(0, Math.min(1, (parseInt(parts[i]) || 0) / 100));
                root.values = out;
            }
        }
    }

    onWantedChanged: {
        if (!wanted)
            values = new Array(bars).fill(0);
    }
}
