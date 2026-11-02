pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Services.Pipewire
import qs.Core.Services

// Shared state between the side bar window and its overlay (hover popouts).
QtObject {
    id: root

    property string popout: ""          // "", "network", "bluetooth", "audio"
    property real popoutCenter: 0       // position of the hovered icon along the bar, in screen pixels
    readonly property bool hoverEnabled: SettingsService.sideBarPopouts

    // geometry shared by the bar, the frame and the panels
    readonly property string position: SettingsService.sideBarPosition
    readonly property bool frame: SettingsService.sideCfg("frame")
    readonly property int border: SettingsService.sideCfg("border")
    readonly property int rounding: SettingsService.sideCfg("rounding")
    readonly property int railSize: 36
    readonly property int barThickness: 44

    // Caelestia-like Material palette for the whole side desktop, derived from the accent hue so
    // it follows light/dark mode and the wallpaper theme but keeps its own softer personality.
    readonly property real hue: Theme.accent.hslHue >= 0 ? Theme.accent.hslHue : Theme.bg.hslHue >= 0 ? Theme.bg.hslHue : 0.72
    readonly property bool dark: Theme.isDark
    readonly property color surface: Qt.hsla(hue, dark ? 0.14 : 0.30, dark ? 0.10 : 0.965, 1)
    readonly property color fg: Qt.hsla(hue, dark ? 0.12 : 0.22, dark ? 0.91 : 0.13, 1)
    readonly property color muted: Qt.hsla(hue, dark ? 0.08 : 0.12, dark ? 0.66 : 0.40, 1)
    readonly property color primary: Qt.hsla(hue, dark ? 0.80 : 0.55, dark ? 0.76 : 0.42, 1)
    readonly property color onPrimary: Qt.hsla(hue, dark ? 0.40 : 0.60, dark ? 0.16 : 0.98, 1)
    readonly property color card: Qt.tint(surface, Qt.rgba(fg.r, fg.g, fg.b, dark ? 0.07 : 0.055))
    readonly property color cardHi: Qt.tint(surface, Qt.rgba(fg.r, fg.g, fg.b, dark ? 0.13 : 0.10))
    readonly property color selected: Qt.tint(card, Qt.rgba(primary.r, primary.g, primary.b, dark ? 0.22 : 0.18))
    readonly property color outline: Qt.rgba(fg.r, fg.g, fg.b, dark ? 0.16 : 0.14)

    // thickness reserved on one screen edge: the bar's edge is thick, the others only carry the frame
    function inset(edge) {
        if (edge === position)
            return barThickness;
        return frame ? border : 0;
    }

    property bool sessionHover: false   // power button hovered: opens the power panel
    property int netTick: 0             // bumped when the network changed, so the bar icon refreshes now
    property real brightness: 0         // 0..100
    property bool brightnessAvailable: false

    function setBrightness(pct) {
        const v = Math.max(1, Math.min(100, Math.round(pct)));
        brightness = v;
        setProc.command = ["brightnessctl", "set", v + "%"];
        setProc.running = false;
        setProc.running = true;
        OsdService.displayBrightness(v);
    }

    function nudgeBrightness(dir) {
        setBrightness(brightness + dir * SettingsService.sideScrollStep);
    }

    function refreshBrightness() {
        getProc.running = false;
        getProc.running = true;
    }

    function nudgeVolume(dir) {
        const sink = Pipewire.defaultAudioSink;
        if (!sink || !sink.audio)
            return;
        if (sink.audio.muted && dir > 0)
            sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + dir * SettingsService.sideScrollStep / 100));
    }

    function hover(name, center) {
        if (hoverEnabled)
            open(name, center);
    }

    function open(name, center) {
        closeTimer.stop();
        popoutCenter = center;
        popout = name;
    }

    function hold() {
        closeTimer.stop();
    }

    function release() {
        closeTimer.restart();
    }

    function close() {
        closeTimer.stop();
        popout = "";
    }

    property Timer closeTimer: Timer {
        interval: 280
        onTriggered: root.popout = ""
    }

    property Process getProc: Process {
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = text.trim().split(",");
                const pct = parseInt((f[3] || "").replace("%", ""));
                root.brightnessAvailable = !isNaN(pct);
                if (!isNaN(pct))
                    root.brightness = pct;
            }
        }
    }

    property Process setProc: Process {}

    property PwObjectTracker tracker: PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Component.onCompleted: refreshBrightness()
}
