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

    // card surfaces used by the Caelestia-style panels: a little lighter than the panel itself
    readonly property color card: Qt.tint(Theme.opaqueBg, Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.07))
    readonly property color cardHi: Qt.tint(Theme.opaqueBg, Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.13))

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
