import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.ControlCenter.Widgets.QuickSettings.Components

// Sound panel: output volume (slider, scroll, mute), microphone, and device pickers.
ColumnLayout {
    id: root

    readonly property var sinks: deviceList(true)
    readonly property var sources: deviceList(false)

    function deviceList(wantSink) {
        const out = [];
        const nodes = Pipewire.nodes ? Pipewire.nodes.values : [];
        for (let i = 0; i < nodes.length; i++) {
            const n = nodes[i];
            if (n && n.audio && !n.isStream && n.isSink === wantSink)
                out.push(n);
        }
        return out;
    }

    function label(n) {
        return n.description || n.nickname || n.name || "Unknown";
    }

    implicitWidth: 300
    spacing: Constants.sizeSm

    PwObjectTracker {
        objects: Pipewire.nodes.values
    }

    ThemedText {
        text: "Sound"
        font.bold: true
        customSize: Constants.sizeMd
    }

    VolumeSlider {
        Layout.fillWidth: true
    }

    ThemedSlider {
        Layout.fillWidth: true
        visible: AudioService.hasPhysicalMic
        isMuted: AudioService.micMuted
        value: AudioService.micVolume
        icon: AudioService.micMuted ? "microphone-off" : "microphone"
        onMoved: (val) => {
            if (AudioService.micMuted)
                AudioService.setMicMuted(false);
            AudioService.setMicVolume(val);
        }
        onIconClicked: AudioService.setMicMuted(!AudioService.micMuted)
    }

    Divider {
        Layout.fillWidth: true
    }

    ThemedText {
        text: "Output"
        color: Theme.muted
        customSize: Constants.sizeSm
    }

    Repeater {
        model: root.sinks

        DeviceRow {
            required property var modelData

            Layout.fillWidth: true
            text: root.label(modelData)
            selected: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.id === modelData.id
            onPicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }

    ThemedText {
        visible: root.sources.length > 0
        Layout.topMargin: Constants.size2Xs
        text: "Input"
        color: Theme.muted
        customSize: Constants.sizeSm
    }

    Repeater {
        model: root.sources

        DeviceRow {
            required property var modelData

            Layout.fillWidth: true
            text: root.label(modelData)
            selected: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.id === modelData.id
            onPicked: Pipewire.preferredDefaultAudioSource = modelData
        }
    }

    component DeviceRow: Rectangle {
        id: row

        property string text: ""
        property bool selected: false

        signal picked()

        implicitHeight: 34
        radius: 12
        color: selected ? Theme.bgAccent : (rowHover.hovered ? Theme.bgSecondary : "transparent")

        Behavior on color { ColorAnimation { duration: Constants.animFast } }

        Rectangle {
            id: dot

            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            radius: 7
            color: "transparent"
            border.width: 2
            border.color: row.selected ? Theme.accent : Theme.muted

            Rectangle {
                anchors.centerIn: parent
                width: 6
                height: 6
                radius: 3
                color: Theme.accent
                visible: row.selected
            }
        }

        ThemedText {
            anchors.left: dot.right
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: row.text
            elide: Text.ElideRight
            color: row.selected ? Theme.fg : Theme.muted
        }

        HoverHandler {
            id: rowHover

            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: row.picked()
        }
    }
}
