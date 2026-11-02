pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// App appearance for the Minflair session only (GTK/Qt font, icons, cursor): state lives in
// ~/.minflair, ~/.config and gsettings are never touched. See Scripts/theme/appearance.py.
QtObject {
    id: root

    property var values: ({ "gtk_font": "", "gtk_font_size": 11, "icon_theme": "", "cursor": "", "cursor_size": 24 })
    property var fonts: []
    property var iconThemes: []
    property var cursorThemes: []
    property bool loaded: false
    property bool busy: setProc.running
    readonly property string script: Quickshell.shellDir + "/Scripts/theme/appearance.py"

    function refresh() {
        getProc.running = false;
        getProc.running = true;
        if (!loaded)
            listProc.running = true;
    }

    function set(key, value) {
        const patch = {};
        patch[key] = value;
        const v = JSON.parse(JSON.stringify(values));
        v[key] = value;
        values = v;                                   // optimistic, the script confirms
        pending = Object.assign(pending, patch);
        debounce.restart();
    }

    property var pending: ({})

    readonly property Timer debounce: Timer {
        interval: 350
        onTriggered: {
            setProc.command = ["python3", root.script, "set", JSON.stringify(root.pending)];
            root.pending = {};
            setProc.running = false;
            setProc.running = true;
        }
    }

    readonly property Process getProc: Process {
        command: ["python3", root.script, "get"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.values = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    readonly property Process listProc: Process {
        command: ["python3", root.script, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const d = JSON.parse(text);
                    root.fonts = d.fonts || [];
                    root.iconThemes = d.icons || [];
                    root.cursorThemes = d.cursors || [];
                    root.loaded = true;
                } catch (e) {}
            }
        }
    }

    readonly property Process setProc: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.values = JSON.parse(text);
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: refresh()
}
