import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.Core
import qs.Core.Services
import qs.Modules.Bar.Styles.Side
import qs.Modules.ControlPanel

PanelWindow {
    id: root

    property bool shown: false
    readonly property bool allowed: SettingsService.settingsLoaded && SettingsService.edgeOsdActive && !HyprlandService.isTrueFullscreen
    readonly property bool hovered: panelHover.hovered || volSlider.pressed || briSlider.pressed || micSlider.pressed
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property int volume: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    readonly property bool volumeMuted: (sink && sink.audio) ? sink.audio.muted : false
    readonly property real railInset: (SettingsService.sideFamily && SettingsService.sideBarPosition === "right") ? SideState.inset("right") : 14

    function bump() {
        if (!allowed)
            return;
        shown = true;
        hideTimer.restart();
    }

    function setVolume(v) {
        if (!sink || !sink.audio)
            return;
        if (sink.audio.muted && v > 0)
            sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v / 100));
        bump();
    }

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "minflair-osd"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"
    visible: allowed && (shown || card.opacity > 0.01)
    implicitWidth: card.width + railInset + 24

    anchors {
        top: true
        bottom: true
        right: true
    }

    mask: Region {
        item: card
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    Connections {
        function onEdgeRequested() {
            root.bump();
        }

        target: OsdService
    }

    Timer {
        id: hideTimer

        interval: SettingsService.osdHideDelay
        onTriggered: {
            if (root.hovered)
                hideTimer.restart();
            else
                root.shown = false;
        }
    }

    onShownChanged: BrightnessService.watchers += shown ? 1 : -1

    Rectangle {
        id: card

        property real slide: root.shown ? 0 : 1

        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: root.railInset - slide * (width + root.railInset + 12)
        width: row.implicitWidth + 24
        height: row.implicitHeight + 24
        radius: 34
        color: Qt.rgba(Theme.opaqueBg.r, Theme.opaqueBg.g, Theme.opaqueBg.b, 0.94)
        border.width: 1
        border.color: Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.10)
        opacity: root.shown ? 1 : 0

        Behavior on slide {
            NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic }
        }

        Behavior on opacity {
            NumberAnimation { duration: Constants.animFast }
        }

        HoverHandler {
            id: panelHover
        }

        Row {
            id: row

            anchors.centerIn: parent
            spacing: 10

            PanelSlider {
                id: volSlider

                width: 62
                height: 188
                cornerRadius: 24
                icon: root.volumeMuted || root.volume === 0 ? "volume-off" : "volume"
                muted: root.volumeMuted
                fillColor: Theme.accent
                value: root.volume
                onMoved: (v) => root.setVolume(v)
                onIconClicked: {
                    if (root.sink && root.sink.audio)
                        root.sink.audio.muted = !root.sink.audio.muted;
                    root.bump();
                }
            }

            PanelSlider {
                id: briSlider

                width: 62
                height: 188
                cornerRadius: 24
                icon: "sun"
                fillColor: Theme.fg
                value: BrightnessService.percent
                onMoved: (v) => {
                    BrightnessService.set(Math.max(1, v));
                    root.bump();
                }
                onIconClicked: BrightnessService.set(BrightnessService.percent <= 5 ? 100 : 5)
            }

            PanelSlider {
                id: micSlider

                visible: SettingsService.osdMicrophone
                width: visible ? 62 : 0
                height: 188
                cornerRadius: 24
                icon: AudioService.micMuted ? "microphone-off" : "microphone"
                muted: AudioService.micMuted
                fillColor: Theme.accentComplementary
                value: AudioService.micVolume
                onMoved: (v) => {
                    AudioService.setMicVolume(v);
                    root.bump();
                }
                onIconClicked: AudioService.setMicMuted(!AudioService.micMuted)
            }
        }
    }
}
