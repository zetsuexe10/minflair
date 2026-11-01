import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Launcher.Components

// Caelestia-style launcher: the app list grows above a rounded search bar at the bottom edge.
// `>` lists actions, `=` or a plain sum calculates, everything else filters the applications.
Item {
    id: root

    property var widget: null
    property var allApps: []
    property alias initialFocusItem: input
    readonly property string query: input.text
    readonly property bool actionMode: query.startsWith(">")
    readonly property int itemHeight: 56
    readonly property int maxItems: 7
    readonly property var results: build(query)
    readonly property int shown: Math.min(maxItems, results.length)

    implicitWidth: 600
    implicitHeight: 48 + (shown > 0 ? shown * itemHeight + 14 : 0) + 8

    Behavior on implicitHeight { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

    LauncherCommands {
        id: commands
    }

    readonly property var actions: [
        { "name": "Lock", "sub": "Lock the session", "icon": "lock", "run": () => shell("sleep 0.3; socat - UNIX-CONNECT:/tmp/quickshell_lockScreen") },
        { "name": "Log out", "sub": "End the session", "icon": "logout", "run": () => shell("if command -v uwsm >/dev/null 2>&1 && uwsm check is-active 2>/dev/null; then uwsm stop; else hyprctl dispatch 'hl.dsp.exit()'; fi") },
        { "name": "Suspend", "sub": "Sleep", "icon": "moon", "run": () => shell("systemctl suspend") },
        { "name": "Reboot", "sub": "Restart the computer", "icon": "reload", "run": () => shell("systemctl reboot") },
        { "name": "Shut down", "sub": "Power off", "icon": "power", "run": () => shell("systemctl poweroff") },
        { "name": "Settings", "sub": "Minflair settings", "icon": "star", "run": () => open("minflair_settings") },
        { "name": "Shell settings", "sub": "Bar, frame and dashboard", "icon": "bar", "run": () => open("minflair_side_settings") },
        { "name": "Wallpaper", "sub": "Pick a wallpaper", "icon": "star", "run": () => open("wallpaper") },
        { "name": "Clipboard", "sub": "Clipboard history", "icon": "star", "run": () => open("clipboard") },
        { "name": "Screenshot", "sub": "Capture the screen", "icon": "star", "run": () => open("screenshot") }
    ]

    function shell(cmd) {
        AppState.closeAllWidgets();
        const request = Hyprland.usingLua ? "hl.dsp.exec_cmd(" + JSON.stringify("sh -c " + quote(cmd)) + ")" : "exec sh -c " + quote(cmd);
        Hyprland.dispatch(request);
    }

    function quote(t) {
        return "'" + String(t).replace(/'/g, "'\\''") + "'";
    }

    function open(id) {
        AppState.closeAllWidgets();
        // let the launcher finish closing before the next window asks for focus
        Qt.callLater(() => AppState.openWidget(id));
    }

    function calc(text) {
        const expr = text.replace(/^=/, "").trim().replace(/\^/g, "**").replace(/,/g, ".");
        if (expr === "" || !/^[0-9+\-*\/().%\s*]+$/.test(expr) || !/[0-9]/.test(expr))
            return null;
        try {
            const v = Function("\"use strict\"; return (" + expr + ")")();
            return (typeof v === "number" && isFinite(v)) ? v : null;
        } catch (e) {
            return null;
        }
    }

    function build(text) {
        const t = text.trim();
        if (t.startsWith(">")) {
            const n = t.substring(1).trim().toLowerCase();
            return actions.filter(a => n === "" || a.name.toLowerCase().indexOf(n) !== -1 || a.sub.toLowerCase().indexOf(n) !== -1).map(a => ({ "kind": "action", "name": a.name, "sub": a.sub, "icon": a.icon, "run": a.run }));
        }
        const out = [];
        const value = (t.startsWith("=") || /[0-9]\s*[+\-*\/^%]\s*[0-9(]/.test(t)) ? calc(t) : null;
        if (value !== null)
            out.push({ "kind": "calc", "name": String(Math.round(value * 1e10) / 1e10), "sub": "Result - Enter copies it", "icon": "star", "value": value });
        const n = t.toLowerCase();
        const apps = [];
        for (let i = 0; i < allApps.length; i++) {
            const a = allApps[i];
            if (a.exec && a.exec.indexOf("open_minflair_") !== -1)
                continue;
            const name = a.name.toLowerCase();
            let score = 0;
            if (n === "")
                score = 1;
            else if (name.startsWith(n))
                score = 3;
            else if (name.indexOf(" " + n) !== -1)
                score = 2;
            else if (name.indexOf(n) !== -1)
                score = 1;
            else if ((a.exec || "").toLowerCase().indexOf(n) !== -1)
                score = 0.5;
            if (score > 0)
                apps.push({ "score": score, "item": { "kind": "app", "name": a.name, "sub": (a.exec || "").split("/").pop(), "icon": a.icon, "exec": a.exec, "terminal": a.terminal } });
        }
        apps.sort((x, y) => y.score - x.score);
        for (let i = 0; i < apps.length && out.length < 60; i++)
            out.push(apps[i].item);
        // shell commands such as "settings" also match the Minflair entries
        if (n !== "") {
            const extra = commands.items.filter(c => c.name.toLowerCase().indexOf(n) !== -1 || (c.keywords || []).some(k => k.indexOf(n) !== -1));
            for (let i = 0; i < extra.length; i++)
                out.push({ "kind": "action", "name": extra[i].name, "sub": extra[i].subtitle || "", "icon": "star", "run": (() => { const id = extra[i].widgetId; return () => open(id); })() });
        }
        return out;
    }

    function iconSource(icon) {
        if (!icon)
            return "";
        let path = icon;
        const home = Quickshell.env("HOME");
        if (path.startsWith("$HOME"))
            path = home + path.substring(5);
        else if (path.startsWith("~"))
            path = home + path.substring(1);
        if (path.startsWith("/") || path.startsWith("file://"))
            return path.startsWith("file://") ? path : "file://" + path;
        return Quickshell.iconPath(path, true);
    }

    function activate(i) {
        const r = results[i];
        if (!r)
            return;
        if (r.kind === "app") {
            AppState.closeAllWidgets();
            let cmd = String(r.exec).trim();
            if (r.terminal)
                cmd = "foot " + cmd;
            Hyprland.dispatch(Hyprland.usingLua ? "hl.dsp.exec_cmd(" + JSON.stringify(cmd) + ")" : "exec " + cmd);
        } else if (r.kind === "calc") {
            Quickshell.execDetached(["wl-copy", r.name]);
            AppState.closeAllWidgets();
        } else if (r.run) {
            r.run();
        }
    }

    function resetLauncher() {
        input.text = "";
        list.currentIndex = 0;
        if (AppState.launcherApps && AppState.launcherApps.length > 0)
            allApps = AppState.launcherApps;
        else
            loadApps.running = true;
        input.forceActiveFocus();
    }

    Component.onCompleted: resetLauncher()

    Process {
        id: loadApps

        command: ["python3", Quickshell.shellDir + "/Modules/Launcher/scripts/get_apps.py"]
        stdout: StdioCollector {
            id: appsOut

            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text);
                    AppState.launcherApps = parsed;
                    root.allApps = parsed;
                } catch (e) {
                    console.error("launcher apps: " + e);
                }
            }
        }
    }

    ListView {
        id: list

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: bar.top
        anchors.bottomMargin: 10
        height: root.shown * root.itemHeight
        model: root.results
        clip: true
        currentIndex: 0
        highlightMoveDuration: 120
        boundsBehavior: Flickable.StopAtBounds
        visible: root.shown > 0

        Behavior on height { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

        onCountChanged: currentIndex = 0

        highlight: Rectangle {
            radius: 18
            color: SideState.cardHi
        }

        delegate: Item {
            id: row

            required property var modelData
            required property int index

            width: list.width
            height: root.itemHeight

            Image {
                id: icon

                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 34
                height: 34
                sourceSize: Qt.size(68, 68)
                source: row.modelData.kind === "app" ? root.iconSource(row.modelData.icon) : ""
                fillMode: Image.PreserveAspectFit
                visible: status === Image.Ready
                asynchronous: true
            }

            SvgIcon {
                anchors.centerIn: icon
                visible: icon.status !== Image.Ready
                icon: row.modelData.kind === "app" ? "rocket" : row.modelData.icon
                iconSize: 24
                iconColor: row.modelData.kind === "calc" ? Theme.accent : Theme.muted
                flat: true
            }

            Column {
                anchors.left: icon.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter

                ThemedText {
                    width: parent.width
                    text: row.modelData.name
                    customSize: row.modelData.kind === "calc" ? 18 : 13
                    font.bold: row.modelData.kind === "calc"
                    elide: Text.ElideRight
                }

                ThemedText {
                    width: parent.width
                    text: row.modelData.sub
                    customSize: 10
                    color: Theme.muted
                    elide: Text.ElideRight
                    visible: text !== ""
                }
            }

            HoverHandler {
                cursorShape: Qt.PointingHandCursor
                onPointChanged: list.currentIndex = row.index
            }

            TapHandler {
                onTapped: root.activate(row.index)
            }
        }
    }

    Rectangle {
        id: bar

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        height: 48
        radius: 24
        color: SideState.card

        SvgIcon {
            id: searchIcon

            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            icon: root.actionMode ? "chevron-right" : "search"
            iconSize: Constants.sizeMd
            iconColor: input.activeFocus ? Theme.accent : Theme.muted
            flat: true
        }

        TextInput {
            id: input

            anchors.left: searchIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.fg
            selectionColor: Theme.accent
            selectedTextColor: Theme.opaqueBg
            font.family: Constants.fontFamily
            font.pixelSize: Math.round(14 * SettingsService.fontScale)
            clip: true

            Keys.onPressed: (e) => {
                const ctrl = e.modifiers & Qt.ControlModifier;
                if (e.key === Qt.Key_Down || e.key === Qt.Key_Tab || (ctrl && (e.key === Qt.Key_J || e.key === Qt.Key_N))) {
                    list.currentIndex = Math.min(root.results.length - 1, list.currentIndex + 1);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Up || e.key === Qt.Key_Backtab || (ctrl && (e.key === Qt.Key_K || e.key === Qt.Key_P))) {
                    list.currentIndex = Math.max(0, list.currentIndex - 1);
                    e.accepted = true;
                } else if (e.key === Qt.Key_Escape) {
                    AppState.closeAllWidgets();
                    e.accepted = true;
                }
            }
            onAccepted: root.activate(list.currentIndex)

            Text {
                visible: input.text === ""
                text: "Search apps, type > for actions, = to calculate"
                color: Theme.muted
                font: input.font
            }
        }
    }
}
