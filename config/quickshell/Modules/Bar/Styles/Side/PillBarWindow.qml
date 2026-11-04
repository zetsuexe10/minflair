import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

PanelWindow {
    id: root

    required property var notificationService

    readonly property string position: SettingsService.sideBarPosition
    readonly property bool vertical: position === "left" || position === "right"
    readonly property int railSize: SideState.railSize
    readonly property int thickMax: railSize + 8
    readonly property int thickMin: railSize + 2
    readonly property int gapEdge: SideState.islandGap
    readonly property string align: SideState.islandAlign
    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "pill" && !DisplayProfileService.gameModeActive
    readonly property bool shown: isActive && !HyprlandService.isTrueFullscreen
    readonly property bool pinned: SettingsService.sideCfg("pinned") === true
    readonly property string idleSetting: SettingsService.sideCfg("idle") || "auto"
    readonly property bool hasPlayer: MprisService.activePlayer !== null && MprisService.activePlayer !== undefined
    readonly property string idleView: idleSetting === "auto" ? (hasPlayer && MprisService.isPlaying ? "media" : "time") : (idleSetting === "media" && !hasPlayer ? "time" : idleSetting)

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-pill-bar"
    WlrLayershell.exclusiveZone: (shown && SettingsService.sideCfg("reserve") !== false) ? thickMax + gapEdge + 4 : 0
    color: "transparent"
    focusable: false
    visible: SettingsService.settingsLoaded
    implicitWidth: vertical ? thickMax + gapEdge * 2 : 0
    implicitHeight: vertical ? 0 : thickMax + gapEdge * 2

    anchors {
        top: root.vertical || root.position === "top"
        bottom: root.vertical || root.position === "bottom"
        left: !root.vertical || root.position === "left"
        right: !root.vertical || root.position === "right"
    }

    mask: Region {
        x: root.shown ? pill.x : 0
        y: root.shown ? pill.y : 0
        width: root.shown ? pill.width : 0
        height: root.shown ? pill.height : 0
    }

    Item {
        id: pill

        readonly property real total: root.vertical ? root.height : root.width
        readonly property bool wide: root.pinned || hover.hovered || root.keepOpen
        readonly property real compactLen: Math.max(root.thickMax * 2, slot.viewLen + 28)
        readonly property real fullLen: Math.min(total - 24, (full.implicitWidth > 0 ? (root.vertical ? full.implicitHeight : full.implicitWidth) : 0) + 24)
        property real len: wide ? Math.max(fullLen, compactLen) : compactLen
        property real thick: wide ? root.thickMax : root.thickMin

        function along() {
            const m = SideState.islandOffset;
            if (root.align === "start")
                return m;
            if (root.align === "end")
                return total - len - m;
            return (total - len) / 2;
        }

        readonly property real band: root.thickMax + root.gapEdge * 2

        x: root.vertical ? (root.position === "left" ? root.gapEdge : root.width - root.gapEdge - root.thickMax) + (root.thickMax - thick) / 2 : along()
        y: root.vertical ? along() : (root.position === "top" ? root.gapEdge : root.height - root.gapEdge - root.thickMax) + (root.thickMax - thick) / 2
        width: root.vertical ? thick : len
        height: root.vertical ? len : thick
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        transform: Translate {
            readonly property real hidden: root.shown ? 0 : -(root.thickMax + root.gapEdge)
            x: root.vertical ? (root.position === "left" ? hidden : -hidden) : 0
            y: root.vertical ? 0 : (root.position === "top" ? hidden : -hidden)

            Behavior on x { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
            Behavior on y { NumberAnimation { duration: Constants.animSlow; easing.type: Easing.OutExpo } }
        }

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on len { SpringAnimation { spring: 3.4; damping: 0.5; epsilon: 0.3 } }
        Behavior on thick { SpringAnimation { spring: 4; damping: 0.55; epsilon: 0.2 } }

        HoverHandler {
            id: hover

            onHoveredChanged: {
                if (hovered)
                    root.keepOpen = true;
                else
                    collapseTimer.restart();
            }
        }

        Timer {
            id: collapseTimer

            interval: 450
            onTriggered: {
                if (SideState.popout !== "" || AppState.activeWidget !== "")
                    restart();
                else
                    root.keepOpen = false;
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: Math.min(width, height) / 2
            color: SideState.surface
            border.width: 1
            border.color: SideState.outline
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            onWheel: (wheel) => {
                const frac = root.vertical ? wheel.y / height : wheel.x / width;
                const dir = wheel.angleDelta.y > 0 ? 1 : -1;
                if (frac < 0.5) {
                    if (SettingsService.sideCfg("scroll", "volume"))
                        SideState.nudgeVolume(dir);
                } else if (SettingsService.sideCfg("scroll", "brightness") && SideState.brightnessAvailable) {
                    SideState.nudgeBrightness(dir);
                }
            }
        }

        Item {
            id: slot

            readonly property string wanted: root.peekView !== "" ? root.peekView : root.idleView
            readonly property string view: (SettingsService.sideOsd && OsdService.isOpen) ? "osd" : ((wanted === "window" && compactWindow.title === "") ? "time" : wanted)
            readonly property real viewLen: view === "workspaces" ? (root.vertical ? ws.implicitHeight : ws.implicitWidth)
                : view === "window" ? (root.vertical ? 120 : 190)
                : view === "media" ? (root.vertical ? root.railSize : 220)
                : view === "osd" ? (root.vertical ? 150 : 210)
                : (root.vertical ? clk.implicitHeight : clk.implicitWidth)

            anchors.centerIn: parent
            width: root.vertical ? root.railSize : viewLen
            height: root.vertical ? viewLen : root.railSize
            opacity: pill.wide ? 0 : 1
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
            Behavior on width { enabled: !root.vertical; NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
            Behavior on height { enabled: root.vertical; NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

            SideClock {
                id: clk

                anchors.centerIn: parent
                vertical: root.vertical
                color: "transparent"
                border.width: 0
                visible: opacity > 0.01
                opacity: slot.view === "time" ? 1 : 0
                scale: slot.view === "time" ? 1 : 0.85

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }
            }

            SideWorkspaces {
                id: ws

                anchors.centerIn: parent
                vertical: root.vertical
                color: "transparent"
                border.width: 0
                visible: opacity > 0.01
                opacity: slot.view === "workspaces" ? 1 : 0
                scale: slot.view === "workspaces" ? 1 : 0.85

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }
            }

            Item {
                anchors.fill: parent
                opacity: slot.view === "media" ? 1 : 0
                scale: slot.view === "media" ? 1 : 0.85
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }

                Rectangle {
                    id: miniArt

                    anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                    anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                    x: root.vertical ? 0 : 2
                    width: 26
                    height: 26
                    radius: 13
                    color: SideState.cardHi

                    Item {
                        id: artMask

                        anchors.fill: parent
                        visible: false
                        layer.enabled: true

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                        }
                    }

                    Image {
                        anchors.fill: parent
                        source: MprisService.activePlayer ? (MprisService.activePlayer.trackArtUrl || "") : ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize: Qt.size(64, 64)
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: artMask
                        }
                    }
                }

                SideText {
                    visible: !root.vertical
                    anchors.left: miniArt.right
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter
                    text: MprisService.activePlayer ? ((MprisService.activePlayer.trackTitle || "") + (MprisService.activePlayer.trackArtist ? "  ·  " + MprisService.activePlayer.trackArtist : "")) : ""
                    customSize: 12
                    elide: Text.ElideRight
                }
            }

            Item {
                anchors.fill: parent
                opacity: slot.view === "osd" ? 1 : 0
                scale: slot.view === "osd" ? 1 : 0.85
                visible: opacity > 0.01

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }

                GridLayout {
                    anchors.centerIn: parent
                    flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
                    rows: root.vertical ? 99 : 1
                    columns: root.vertical ? 1 : 99
                    rowSpacing: 8
                    columnSpacing: 10

                    SvgIcon {
                        Layout.alignment: Qt.AlignCenter
                        icon: OsdService.icon
                        iconSize: 18
                        iconColor: OsdService.isMuted ? SideState.muted : SideState.primary
                        flat: true
                    }

                    Rectangle {
                        visible: OsdService.showProgress
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredWidth: root.vertical ? 8 : 100
                        Layout.preferredHeight: root.vertical ? 56 : 8
                        radius: 4
                        color: SideState.card

                        Rectangle {
                            x: 0
                            y: root.vertical ? parent.height * (1 - OsdService.level) : 0
                            width: root.vertical ? parent.width : parent.width * OsdService.level
                            height: root.vertical ? parent.height * OsdService.level : parent.height
                            radius: 4
                            color: OsdService.isMuted ? SideState.muted : SideState.primary

                            Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                            Behavior on y { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                        }
                    }

                    SideText {
                        Layout.alignment: Qt.AlignCenter
                        Layout.preferredWidth: root.vertical ? -1 : 40
                        horizontalAlignment: Text.AlignRight
                        text: OsdService.valueText
                        customSize: 11
                        font.bold: true
                    }
                }
            }

            SideActiveWindow {
                id: compactWindow

                anchors.centerIn: parent
                width: root.vertical ? root.railSize : parent.width
                height: root.vertical ? parent.height : root.railSize
                vertical: root.vertical
                visible: opacity > 0.01
                opacity: slot.view === "window" ? 1 : 0
                scale: slot.view === "window" ? 1 : 0.85

                Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
                Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack } }
            }
        }

        GridLayout {
            id: full

            anchors.centerIn: parent
            flow: root.vertical ? GridLayout.TopToBottom : GridLayout.LeftToRight
            rows: root.vertical ? 99 : 1
            columns: root.vertical ? 1 : 99
            rowSpacing: 6
            columnSpacing: 6
            opacity: pill.wide ? 1 : 0
            visible: opacity > 0.01 && root.isActive

            Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }

            SideButton {
                visible: SettingsService.sideCfg("entries", "logo")
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: root.railSize
                Layout.preferredHeight: root.railSize
                size: root.railSize
                icon: "apps-filled"
                iconColor: SideState.primary
                iconSize: Constants.sizeXl
                active: AppState.isWidgetOpen("launcher")
                onClicked: AppState.toggleWidget("launcher")

                SidePill {
                    z: -1
                    anchors.fill: parent
                    radius: width / 2
                }
            }

            SideWorkspaces {
                visible: SettingsService.sideCfg("entries", "workspaces")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideActiveWindow {
                visible: SettingsService.sideCfg("entries", "activeWindow")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: root.vertical ? root.railSize : 170
                Layout.preferredHeight: root.vertical ? 120 : root.railSize
            }

            SideTray {
                visible: SettingsService.sideCfg("entries", "tray")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideStatus {
                visible: SettingsService.sideCfg("entries", "statusIcons")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
                notificationService: root.notificationService
            }

            SideMusicChip {
                visible: active
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
                onHoverChanged: (on) => SideState.musicHover = on
            }

            SideClock {
                visible: SettingsService.sideCfg("entries", "clock")
                vertical: root.vertical
                Layout.alignment: Qt.AlignCenter
            }

            SideButton {
                visible: SettingsService.sideCfg("entries", "power")
                Layout.alignment: Qt.AlignCenter
                Layout.preferredWidth: root.railSize
                Layout.preferredHeight: root.railSize
                size: root.railSize
                icon: "power"
                iconSize: Constants.sizeXl
                active: AppState.isWidgetOpen("powerMenu")
                onClicked: AppState.toggleWidget("powerMenu")

                SidePill {
                    z: -1
                    anchors.fill: parent
                    radius: width / 2
                }
            }
        }
    }

    Binding {
        target: SideState
        property: "pillCenter"
        value: root.shown ? (root.vertical ? pill.y + pill.height / 2 : pill.x + pill.width / 2) : 0
    }

    Binding {
        target: SideState
        property: "pillAlongStart"
        value: root.vertical ? pill.y : pill.x
    }

    Binding {
        target: SideState
        property: "pillLen"
        value: root.vertical ? pill.height : pill.width
    }

    Binding {
        target: SideState
        property: "pillThick"
        value: root.vertical ? pill.width : pill.height
    }

    Binding {
        target: SideState
        property: "pillEdgeGap"
        value: root.vertical ? (root.position === "left" ? pill.x : root.width - pill.x - pill.width) : (root.position === "top" ? pill.y : root.height - pill.y - pill.height)
    }


    property bool keepOpen: false
    property string peekView: ""
    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1

    onActiveWsChanged: {
        if (root.shown && root.idleView !== "workspaces") {
            root.peekView = "workspaces";
            transientTimer.interval = 2200;
            transientTimer.restart();
        }
    }

    Connections {
        target: MprisService.activePlayer
        ignoreUnknownSignals: true

        function onTrackTitleChanged() {
            if (root.shown && MprisService.isPlaying && MprisService.activePlayer && MprisService.activePlayer.trackTitle) {
                root.peekView = "media";
                transientTimer.interval = 3600;
                transientTimer.restart();
            }
        }
    }

    Timer {
        id: transientTimer

        interval: 2200
        onTriggered: {
            root.peekView = "";
            interval = 2200;
        }
    }
}
