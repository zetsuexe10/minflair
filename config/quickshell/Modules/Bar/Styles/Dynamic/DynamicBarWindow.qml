import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Styles.Side
import qs.Modules.ControlPanel
import qs.Modules.SystemMonitor
import qs.Modules.Clipboard
import qs.Modules.ControlCenter
import qs.Modules.Dashboard
import qs.Modules.Launcher
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.WallpaperSelector

PanelWindow {
    id: root

    required property var notificationService

    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "dynamic" && !DisplayProfileService.gameModeActive
    readonly property bool shown: isActive && !HyprlandService.isTrueFullscreen

    readonly property int gap: 8
    readonly property int pillH: 32
    readonly property int btnGap: 8
    readonly property int mediaW: 424
    readonly property int mediaH: 156
    readonly property bool swipeEnabled: SettingsService.dynCfg("swipe") !== false
    readonly property bool reserve: SettingsService.dynCfg("reserve") !== false
    readonly property bool showMusicButton: SettingsService.dynCfg("musicButton") !== false
    readonly property bool glanceEnabled: SettingsService.dynCfg("glance") !== false

    readonly property var activeList: (notificationService && notificationService.activeList) ? notificationService.activeList : null
    readonly property int notifCount: activeList ? activeList.count : 0
    readonly property var latestNotif: notifCount > 0 ? activeList.get(0) : null
    readonly property var latestData: latestNotif ? latestNotif.notifData : null
    readonly property string latestTitle: latestData ? (latestData.summary || latestData.body || "") : ""
    readonly property bool notifOpen: shown && notifCount > 0 && !mediaOpen && !toolsOpen && !ccOpen
    readonly property bool hasPlayer: MprisService.activePlayer !== null && MprisService.activePlayer !== undefined
    readonly property var player: MprisService.activePlayer
    readonly property bool showClock: SettingsService.dynCfg("views", "clock") !== false
    readonly property bool showWorkspaces: SettingsService.dynCfg("views", "workspaces") !== false
    readonly property bool showMusic: SettingsService.dynCfg("views", "music") !== false
    readonly property bool showNotifications: SettingsService.dynCfg("views", "notifications") !== false
    readonly property var views: {
        const out = [];
        if (showClock)
            out.push("clock");
        if (showMusic && hasPlayer)
            out.push("music");
        if (showNotifications && notifCount > 0)
            out.push("notifications");
        return out.length > 0 ? out : ["clock"];
    }
    readonly property string idleSetting: SettingsService.dynCfg("idle") || "auto"
    readonly property string idleView: {
        if (idleSetting === "auto")
            return (hasPlayer && MprisService.isPlaying && showMusic) ? "music" : "clock";
        if (idleSetting === "media")
            return "music";
        if (idleSetting === "notifications")
            return "notifications";
        return "clock";
    }
    readonly property string nowTitle: player ? (player.trackTitle || "Unknown title") : ""
    readonly property string nowArtist: player ? (player.trackArtist || player.trackAlbum || "") : ""
    readonly property string nowLabel: nowTitle + (nowArtist !== "" ? "  ·  " + nowArtist : "")
    readonly property string clockTime: {
        const d = SystemInfoService.currentTime;
        let h = d.getHours();
        if (!SettingsService.clock24h)
            h = h % 12 || 12;
        const mm = d.getMinutes().toString().padStart(2, "0");
        return h.toString().padStart(2, "0") + ":" + mm + (SettingsService.clock24h ? "" : (d.getHours() >= 12 ? " pm" : " am"));
    }
    readonly property string clockLabel: Qt.formatDate(SystemInfoService.currentTime, "ddd d") + "  ·  " + root.clockTime

    property int page: 0
    readonly property int safePage: Math.max(0, Math.min(page, views.length - 1))
    readonly property string view: views[safePage]
    property bool overIsland: false
    property bool overButton: false
    property bool overTools: false
    property bool overCcBtn: false
    property bool overCcPanel: false
    property bool mediaOpen: false
    property string toolsView: ""
    property bool ccOpen: false
    readonly property int cornerPad: 12

    readonly property bool toolsOpen: toolsView !== ""
    readonly property bool toolFocus: toolsView === "wallpaper" || toolsView === "screenshot" || toolsView === "power" || toolsView === "launcher" || toolsView === "dashboard" || toolsView === "github" || toolsView === "clipboard" || toolsView === "quickPanel" || toolsView === "sysMonitor" || toolsView === "speedTest"
    readonly property bool orbsVisible: shown && !toolFocus
    readonly property bool musicButtonVisible: orbsVisible && showMusicButton
    readonly property bool workspacesVisible: shown && showWorkspaces
    readonly property bool glanceActive: shown && glanceEnabled && overIsland && !mediaOpen && !toolsOpen && !notifOpen && hasPlayer
    readonly property bool glanceShowsMusic: view !== "music"
    readonly property string netSpeedText: root.formatRate(root.netRate)
    property bool netUp: false
    property real netRate: 0
    property real netLastRx: -1
    property real netLastTime: 0

    readonly property int toolsMenuW: 560
    readonly property int toolsMenuH: 92
    readonly property real ccW: (ccLoader.item && ccLoader.item.implicitWidth > 0) ? ccLoader.item.implicitWidth + 32 : 532
    readonly property real ccH: (ccLoader.item && ccLoader.item.implicitHeight > 0) ? ccLoader.item.implicitHeight + 32 : 632

    function formatRate(bps) {
        if (bps >= 1048576)
            return (bps / 1048576).toFixed(1) + " MB/s";
        if (bps >= 1024)
            return Math.round(bps / 1024) + " KB/s";
        return "0 KB/s";
    }

    function sampleNet(text) {
        const now = Date.now();
        let rx = 0;
        const lines = String(text).split("\n");
        for (let i = 2; i < lines.length; i++) {
            const parts = lines[i].trim().split(/\s+/);
            if (parts.length < 10)
                continue;
            if (parts[0].replace(":", "") === "lo")
                continue;
            const v = Number(parts[1]);
            if (!isNaN(v))
                rx += v;
        }
        if (root.netLastRx >= 0 && root.netLastTime > 0) {
            const dt = (now - root.netLastTime) / 1000;
            if (dt > 0)
                root.netRate = Math.max(0, (rx - root.netLastRx) / dt);
        }
        root.netLastRx = rx;
        root.netLastTime = now;
    }

    TextMetrics {
        id: glanceMetrics

        text: root.glanceShowsMusic ? root.nowLabel : root.clockLabel
        font.family: Constants.fontFamily
        font.pixelSize: Math.round(12 * SettingsService.fontScale)
    }

    readonly property real glanceWidth: Math.min(300, Math.max(180, glanceMetrics.width + 58))
    readonly property real pageWidth: {
        if (view === "music")
            return Math.max(180, musicView.implicitWidth + 16);
        if (view === "notifications")
            return Math.max(200, notifContent.implicitWidth + 36);
        return Math.max(146, clockView.implicitWidth + 30);
    }
    readonly property real islandWidth: {
        if (!shown)
            return 0;
        if (notifOpen)
            return Math.min(width - 120, 380);
        if (mediaOpen)
            return Math.min(width - 32, mediaW);
        if (toolsView === "wallpaper")
            return Math.min(width - 32, wallpaperView.implicitWidth + 60);
        if (toolsView === "screenshot")
            return Math.min(width - 32, shotView.implicitWidth + 60);
        if (toolsView === "power")
            return Math.min(width - 32, powerView.implicitWidth + 60);
        if (toolsView === "launcher")
            return Math.min(width - 32, launcherView.implicitWidth + 60);
        if (toolsView === "dashboard")
            return Math.min(width - 64, dashView.implicitWidth + 24);
        if (toolsView === "github")
            return Math.min(width - 64, githubView.implicitWidth + 24);
        if (toolsView === "clipboard")
            return Math.min(width - 32, clipboardView.preferredContentWidth + 60);
        if (toolsView === "quickPanel")
            return Math.min(width - 32, quickView.implicitWidth + 48);
        if (toolsView === "sysMonitor" || toolsView === "speedTest")
            return Math.min(width - 32, monView.implicitWidth + 48);
        if (toolsView === "menu")
            return Math.min(width - 120, toolsMenuW);
        return Math.min(width - 120, glanceActive ? glanceWidth : pageWidth);
    }
    readonly property real islandHeight: {
        if (notifOpen)
            return Math.max(toast.notifH + 24, 72);
        if (mediaOpen)
            return mediaH;
        if (toolsView === "wallpaper")
            return wallpaperView.implicitHeight + 24;
        if (toolsView === "screenshot")
            return shotView.implicitHeight + 24;
        if (toolsView === "power")
            return powerView.implicitHeight + 24;
        if (toolsView === "launcher")
            return launcherView.implicitHeight + 24;
        if (toolsView === "dashboard")
            return Math.min(root.height - 120, dashView.implicitHeight + 24);
        if (toolsView === "github")
            return Math.min(root.height - 120, githubView.implicitHeight + 24);
        if (toolsView === "clipboard")
            return clipboardView.implicitHeight + 24;
        if (toolsView === "quickPanel")
            return quickView.implicitHeight + 36;
        if (toolsView === "sysMonitor" || toolsView === "speedTest")
            return monView.implicitHeight + 36;
        if (toolsView === "menu")
            return toolsMenuH;
        return pillH;
    }
    readonly property real islandRadius: (mediaOpen || notifOpen) ? 26 : (toolsOpen ? 24 : pillH / 2)

    function nextPage(dir) {
        if (!swipeEnabled || views.length < 2 || toolsOpen || notifOpen)
            return;
        page = (safePage + dir + views.length) % views.length;
        mediaOpen = false;
        idleTimer.restart();
    }

    function goIdle() {
        if (toolsOpen)
            return;
        const i = views.indexOf(idleView);
        if (i >= 0)
            page = i;
    }

    function toggleMedia() {
        if (!hasPlayer)
            return;
        if (mediaOpen) {
            mediaOpen = false;
            AppState.closeWidget("music");
            closeTimer.stop();
        } else {
            mediaOpen = true;
            toolsView = "";
            ccOpen = false;
            AppState.closeWidget("controlCenter");
            AppState.openWidget("music");
        }
    }

    function toggleTools() {
        if (toolsView !== "") {
            closeTools();
        } else {
            toolsView = "menu";
            mediaOpen = false;
            ccOpen = false;
            AppState.closeWidget("music");
            AppState.closeWidget("controlCenter");
        }
    }

    function openTool(id) {
        toolsView = id;
        mediaOpen = false;
        ccOpen = false;
        AppState.closeWidget("music");
        AppState.closeWidget("controlCenter");
        if (id === "wallpaper")
            AppState.openWidget("wallpaper");
        else if (id === "screenshot")
            AppState.openWidget("screenshot");
        else if (id === "clipboard")
            AppState.openWidget("clipboard");
        else if (id === "quickPanel")
            AppState.openWidget("quickPanel");
        else if (id === "sysMonitor")
            AppState.openWidget("sysMonitor");
        else if (id === "speedTest")
            AppState.openWidget("speedTest");
    }

    function togglePower() {
        if (toolsView === "power") {
            closeTools();
        } else {
            toolsView = "power";
            mediaOpen = false;
            ccOpen = false;
            AppState.closeWidget("music");
            AppState.closeWidget("controlCenter");
            AppState.openWidget("powerMenu");
        }
    }

    function toggleCc() {
        if (ccOpen) {
            ccOpen = false;
            AppState.closeWidget("controlCenter");
        } else {
            ccOpen = true;
            mediaOpen = false;
            toolsView = "";
            AppState.closeWidget("music");
            AppState.openWidget("controlCenter");
        }
        ccTimer.stop();
    }

    function closeTools() {
        if (toolsView === "wallpaper")
            AppState.closeWidget("wallpaper");
        else if (toolsView === "screenshot")
            AppState.closeWidget("screenshot");
        else if (toolsView === "power")
            AppState.closeWidget("powerMenu");
        else if (toolsView === "launcher")
            AppState.closeWidget("launcher");
        else if (toolsView === "dashboard")
            AppState.closeWidget("dashboard");
        else if (toolsView === "github")
            AppState.closeWidget("github");
        else if (toolsView === "clipboard")
            AppState.closeWidget("clipboard");
        else if (toolsView === "quickPanel")
            AppState.closeWidget("quickPanel");
        else if (toolsView === "sysMonitor")
            AppState.closeWidget("sysMonitor");
        else if (toolsView === "speedTest")
            AppState.closeWidget("speedTest");
        root.toolsView = "";
    }

    function syncWidget(id) {
        if (!isActive)
            return;
        const open = AppState.isWidgetOpen(id);
        if (id === "wallpaper" || id === "screenshot" || id === "powerMenu" || id === "launcher" || id === "dashboard" || id === "github" || id === "clipboard" || id === "quickPanel" || id === "sysMonitor" || id === "speedTest") {
            const view = id === "powerMenu" ? "power" : id;
            if (open) {
                toolsView = view;
                mediaOpen = false;
                ccOpen = false;
                if (id === "sysMonitor")
                    AppState.closeWidget("speedTest");
                else if (id === "speedTest")
                    AppState.closeWidget("sysMonitor");
            } else if (toolsView === view) {
                toolsView = "";
            }
        } else if (id === "music") {
            if (open && hasPlayer) {
                mediaOpen = true;
                toolsView = "";
                ccOpen = false;
            } else if (!open) {
                mediaOpen = false;
            }
        } else if (id === "controlCenter") {
            if (open) {
                ccOpen = true;
                mediaOpen = false;
                toolsView = "";
            } else {
                ccOpen = false;
            }
        }
    }

    function armClose() {
        if (mediaOpen || toolsView === "menu")
            closeTimer.restart();
    }

    onToolsViewChanged: {
        monView.active = toolsView === "sysMonitor" || toolsView === "speedTest";
        if (toolsView === "sysMonitor") {
            monView.openPage("overview");
            Qt.callLater(() => monView.initialFocusItem.forceActiveFocus());
        } else if (toolsView === "speedTest") {
            monView.openPage("speed");
            Qt.callLater(() => monView.initialFocusItem.forceActiveFocus());
        }
        quickView.active = toolsView === "quickPanel";
        if (toolsView === "quickPanel") {
            quickView.reset();
            Qt.callLater(() => quickView.initialFocusItem.forceActiveFocus());
        } else if (toolsView === "wallpaper")
            Qt.callLater(() => wallpaperView.initialFocusItem.forceActiveFocus());
        else if (toolsView === "screenshot")
            Qt.callLater(() => shotView.initialFocusItem.forceActiveFocus());
        else if (toolsView === "power")
            Qt.callLater(() => powerView.initialFocusItem.forceActiveFocus());
        else if (toolsView === "launcher")
            Qt.callLater(() => {
                launcherView.resetLauncher();
                launcherView.initialFocusItem.forceActiveFocus();
            });
        else if (toolsView === "dashboard")
            Qt.callLater(() => {
                dashView.contentY = 0;
                caelDash.initialFocusItem.forceActiveFocus();
            });
        else if (toolsView === "github")
            Qt.callLater(() => {
                githubView.contentY = 0;
            });
        else if (toolsView === "clipboard")
            Qt.callLater(() => {
                clipboardView.resetClipboard();
                clipboardView.initialFocusItem.forceActiveFocus();
            });
    }

    onViewsChanged: {
        if (page > views.length - 1)
            page = Math.max(0, views.length - 1);
    }

    onShownChanged: {
        if (!shown) {
            mediaOpen = false;
            toolsView = "";
            ccOpen = false;
            overIsland = false;
            overButton = false;
            overTools = false;
            overCcBtn = false;
            overCcPanel = false;
        }
    }

    QtObject {
        id: toolProxy

        property bool isOpen: root.toolsOpen
        signal fullyClosed()

        function close() {
            root.closeTools();
            toolProxy.fullyClosed();
        }
    }

    QtObject {
        id: ccProxy

        property bool isOpen: root.ccOpen
        signal fullyClosed()

        function close() {
            root.ccOpen = false;
            ccProxy.fullyClosed();
        }
    }

    Connections {
        target: AppState

        function onToggleWidget(id) {
            Qt.callLater(() => root.syncWidget(id));
        }

        function onActiveWidgetsListChanged() {
            if (!AppState.isWidgetOpen("music"))
                root.mediaOpen = false;

            if (!AppState.isWidgetOpen("controlCenter"))
                root.ccOpen = false;

            if (root.toolsView === "" || root.toolsView === "menu")
                return ;

            const id = root.toolsView === "power" ? "powerMenu" : root.toolsView;
            if (!AppState.isWidgetOpen(id))
                root.toolsView = "";
        }
    }

    Process {
        id: netProc

        command: ["sh", "-c", "cat /proc/net/dev"]
        stdout: StdioCollector {
            onStreamFinished: root.sampleNet(text)
        }
    }

    Process {
        id: wifiProc

        command: ["nmcli", "-t", "-f", "TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.netUp = text.indexOf("wifi:connected") !== -1 || text.indexOf("ethernet:connected") !== -1;
            }
        }
    }

    Timer {
        interval: 1000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: netProc.running = true
    }

    Timer {
        interval: 10000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: wifiProc.running = true
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-dynamic-bar"
    WlrLayershell.exclusiveZone: (shown && reserve) ? gap + pillH + 6 : 0
    WlrLayershell.keyboardFocus: toolFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: toolFocus
    color: "transparent"
    visible: SettingsService.settingsLoaded
    implicitWidth: 0
    implicitHeight: 800

    anchors {
        top: true
        left: true
        right: true
    }

    HyprlandFocusGrab {
        active: root.toolFocus
        windows: [root]
    }

    mask: Region {
        Region {
            x: wsChip.visible ? wsChip.x : 0
            y: wsChip.visible ? wsChip.y : 0
            width: wsChip.visible ? wsChip.width : 0
            height: wsChip.visible ? wsChip.height : 0
        }

        Region {
            x: netChip.visible ? netChip.x : 0
            y: netChip.visible ? netChip.y : 0
            width: netChip.visible ? netChip.width : 0
            height: netChip.visible ? netChip.height : 0
        }

        Region {
            x: controlBtn.visible ? controlBtn.x : 0
            y: controlBtn.visible ? controlBtn.y : 0
            width: controlBtn.visible ? controlBtn.width : 0
            height: controlBtn.visible ? controlBtn.height : 0
        }

        Region {
            x: ccPanel.visible ? ccPanel.x : 0
            y: ccPanel.visible ? ccPanel.y : 0
            width: ccPanel.visible ? ccPanel.width : 0
            height: ccPanel.visible ? ccPanel.height : 0
        }

        Region {
            x: root.shown ? island.x : 0
            y: root.shown ? island.y : 0
            width: root.shown ? island.width : 0
            height: root.shown ? island.height : 0
        }

        Region {
            x: musicBtn.visible ? musicBtn.x : 0
            y: musicBtn.visible ? musicBtn.y : 0
            width: musicBtn.visible ? musicBtn.width : 0
            height: musicBtn.visible ? musicBtn.height : 0
        }

        Region {
            x: toolsBtn.visible ? toolsBtn.x : 0
            y: toolsBtn.visible ? toolsBtn.y : 0
            width: toolsBtn.visible ? toolsBtn.width : 0
            height: toolsBtn.visible ? toolsBtn.height : 0
        }
    }

    SideWorkspaces {
        id: wsChip

        x: root.cornerPad
        y: root.gap
        vertical: false
        wheelScroll: true
        implicitWidth: along
        implicitHeight: root.pillH
        color: SideState.surface
        border.width: 1
        border.color: SideState.outline
        opacity: root.workspacesVisible ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
    }

    Rectangle {
        id: netChip

        x: controlBtn.x - width - root.btnGap
        y: root.gap
        width: netLayout.implicitWidth + 20
        height: root.pillH
        radius: height / 2
        color: SideState.surface
        border.width: 1
        border.color: SideState.outline
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }

        RowLayout {
            id: netLayout

            anchors.centerIn: parent
            spacing: 7

            SvgIcon {
                Layout.alignment: Qt.AlignVCenter
                icon: WifiSignalService.connected ? WifiSignalService.stepIcon : (root.netUp ? "wifi" : "wifi-off")
                iconSize: 15
                iconColor: root.netUp ? SideState.primary : SideState.muted
                flat: true
            }

            SideText {
                Layout.alignment: Qt.AlignVCenter
                width: 64
                horizontalAlignment: Text.AlignRight
                text: root.netSpeedText
                customSize: 11
                color: SideState.muted
            }
        }
    }

    Rectangle {
        id: controlBtn

        x: root.width - root.cornerPad - width
        y: root.gap
        width: root.pillH
        height: root.pillH
        radius: width / 2
        color: (root.ccOpen || ccArea.containsMouse) ? Qt.tint(SideState.surface, SideState.cardHi) : SideState.surface
        border.width: 1
        border.color: root.ccOpen ? SideState.primary : SideState.outline
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        scale: ccArea.pressed ? 0.92 : (ccArea.containsMouse ? 1.06 : 1)

        Behavior on color { ColorAnimation { duration: Constants.animFast } }
        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.3; epsilon: 0.002 } }

        SvgIcon {
            anchors.centerIn: parent
            icon: "tune"
            iconSize: 16
            iconColor: root.ccOpen ? SideState.primary : SideState.fg
            flat: true
        }

        HoverHandler {
            onHoveredChanged: {
                root.overCcBtn = hovered;
                if (hovered)
                    ccTimer.stop();
                else if (root.ccOpen)
                    ccTimer.restart();
            }
        }

        MouseArea {
            id: ccArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleCc()
        }
    }

    Rectangle {
        id: ccPanel

        x: controlBtn.x + controlBtn.width - width
        y: root.gap + root.pillH + 8
        width: root.ccW
        height: root.ccH
        radius: 24
        color: SideState.surface
        border.width: 1
        border.color: SideState.outline
        opacity: root.ccOpen ? 1 : 0
        visible: opacity > 0.01
        transformOrigin: Item.TopRight
        scale: root.ccOpen ? 1 : 0.94

        Behavior on opacity { NumberAnimation { duration: Constants.animFast } }
        Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: {
                root.overCcPanel = hovered;
                if (hovered)
                    ccTimer.stop();
                else if (root.ccOpen)
                    ccTimer.restart();
            }
        }

        Loader {
            id: ccLoader

            anchors.fill: parent
            anchors.margins: 16
            active: root.ccOpen
            sourceComponent: Component {
                ControlCenterContent {
                    widget: ccProxy
                }
            }
        }
    }

    Rectangle {
        id: island

        x: (root.width - width) / 2
        y: root.gap
        width: root.islandWidth
        height: root.islandHeight
        radius: root.islandRadius
        color: SideState.surface
        border.width: 1
        border.color: SideState.outline
        opacity: root.shown ? 1 : 0
        visible: opacity > 0.01
        clip: true

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
        Behavior on radius { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: {
                root.overIsland = hovered;
                if (hovered)
                    closeTimer.stop();
                else
                    root.armClose();
            }
        }

        WheelHandler {
            onWheel: (event) => {
                if (!root.swipeEnabled || root.toolsOpen || root.notifOpen || Math.abs(event.angleDelta.y) < 1)
                    return;
                root.nextPage(event.angleDelta.y < 0 ? 1 : -1);
                event.accepted = true;
            }
        }

        DragHandler {
            target: null
            xAxis.enabled: true
            yAxis.enabled: false
            property real lastX: 0

            onActiveChanged: {
                if (active) {
                    lastX = 0;
                } else {
                    if (root.swipeEnabled && !root.toolsOpen && !root.notifOpen) {
                        if (lastX <= -40)
                            root.nextPage(1);
                        else if (lastX >= 40)
                            root.nextPage(-1);
                    }
                    lastX = 0;
                }
            }
            onTranslationChanged: {
                if (active)
                    lastX = translation.x;
            }
        }

        Item {
            id: pages

            anchors.fill: parent
            opacity: (root.glanceActive || root.mediaOpen || root.toolsOpen || root.notifOpen) ? 0 : 1
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }

            SideClock {
                id: clockView

                anchors.centerIn: parent
                vertical: false
                color: "transparent"
                border.width: 0
                visible: root.view === "clock"
            }

            DynamicMusicView {
                id: musicView

                anchors.centerIn: parent
                visible: root.view === "music"
                onActivated: root.toggleMedia()
            }

            Row {
                id: notifContent

                anchors.centerIn: parent
                spacing: 8
                visible: root.view === "notifications"

                SvgIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    icon: "bell"
                    iconSize: 16
                    iconColor: SideState.primary
                    flat: true
                }

                SideText {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(220, Math.max(80, implicitWidth))
                    text: root.notifCount + "  ·  " + root.latestTitle
                    customSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        Row {
            id: glance

            anchors.centerIn: parent
            spacing: 7
            opacity: root.glanceActive ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }

            SvgIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: root.glanceShowsMusic ? "music" : "clock"
                iconSize: 15
                iconColor: SideState.primary
                flat: true
            }

            SideText {
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(40, root.islandWidth - 62)
                text: root.glanceShowsMusic ? root.nowLabel : root.clockLabel
                customSize: 12
                elide: Text.ElideRight
            }
        }

        Row {
            id: toolsMenu

            anchors.centerIn: parent
            spacing: 10
            opacity: root.toolsView === "menu" ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }

            ToolCard {
                icon: "picture"
                label: "Wallpaper"
                onActivated: root.openTool("wallpaper")
            }

            ToolCard {
                icon: "monitor"
                label: "Screenshot"
                onActivated: root.openTool("screenshot")
            }

            ToolCard {
                icon: "clipboard"
                label: "Clipboard"
                onActivated: root.openTool("clipboard")
            }

        }

        SystemMonitorContent {
            id: monView

            x: 24
            y: 18
            active: false
            visible: root.toolsView === "sysMonitor" || root.toolsView === "speedTest"
            onCloseRequested: root.closeTools()
        }

        ControlPanelContent {
            id: quickView

            x: 24
            y: 18
            active: false
            visible: root.toolsView === "quickPanel"
            onCloseRequested: root.closeTools()
        }

        WallpaperSelectorContent {
            id: wallpaperView

            x: 12
            y: 12
            visible: root.toolsView === "wallpaper"
            widget: toolProxy
        }

        ScreenCaptureContent {
            id: shotView

            x: 12
            y: 12
            visible: root.toolsView === "screenshot"
            widget: toolProxy
        }

        PowerMenuContent {
            id: powerView

            x: 12
            y: 12
            visible: root.toolsView === "power"
            widget: toolProxy
        }

        LauncherContent {
            id: launcherView

            x: 12
            y: 12
            width: island.width - 24
            height: island.height - 24
            visible: root.toolsView === "launcher"
            widget: toolProxy
        }

        Flickable {
            id: dashView

            x: 12
            y: 12
            width: island.width - 24
            height: island.height - 24
            implicitWidth: caelDash.implicitWidth
            implicitHeight: caelDash.implicitHeight
            contentWidth: width
            contentHeight: caelDash.implicitHeight
            clip: true
            interactive: contentHeight > height
            visible: root.toolsView === "dashboard"
            boundsBehavior: Flickable.StopAtBounds

            CaelDashboard {
                id: caelDash

                width: dashView.width
                height: implicitHeight
                maxWidth: Math.min(730, root.width - 120)
                widget: toolProxy
            }

        }

        Flickable {
            id: githubView

            x: 12
            y: 12
            width: island.width - 24
            height: island.height - 24
            implicitWidth: githubCard.implicitWidth
            implicitHeight: githubCard.implicitHeight
            contentWidth: width
            contentHeight: githubCard.implicitHeight
            clip: true
            interactive: contentHeight > height
            visible: root.toolsView === "github"
            boundsBehavior: Flickable.StopAtBounds

            GithubWidget {
                id: githubCard

                width: githubView.width
            }

        }

        ClipboardContent {
            id: clipboardView

            x: 12
            y: 12
            width: island.width - 68
            height: island.height - 24
            visible: root.toolsView === "clipboard"
            widget: toolProxy
        }

        Item {
            id: media

            anchors.fill: parent
            anchors.margins: 12
            opacity: root.mediaOpen ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }

            CaelMediaMini {
                anchors.fill: parent
            }
        }

        Item {
            id: notifView

            anchors.fill: parent
            anchors.margins: 12
            opacity: root.notifOpen ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: Constants.animFast } }

            DynamicNotifLayer {
                id: toast

                property real shownProgress: (root.notifCount > 0 && !isRemovingNotif && root.shown) ? 1 : 0

                anchors.fill: parent
                notificationService: root.notificationService
                notifProgress: shownProgress
                onShownProgressChanged: {
                    if (shownProgress === 0 && isRemovingNotif) {
                        isRemovingNotif = false;
                        dismissActiveNotifications();
                    }
                }

                Behavior on shownProgress { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle {
            id: toolsClose

            x: island.width - 34
            y: 12
            width: 28
            height: 28
            radius: 14
            color: closeArea.containsMouse ? SideState.cardHi : Qt.tint(SideState.surface, SideState.card)
            border.width: 1
            border.color: SideState.outline
            visible: root.toolFocus
            scale: closeArea.pressed ? 0.9 : (closeArea.containsMouse ? 1.08 : 1)

            Behavior on scale { NumberAnimation { duration: Constants.animFast } }

            SvgIcon {
                anchors.centerIn: parent
                icon: "x"
                iconSize: 12
                iconColor: SideState.fg
                flat: true
            }

            MouseArea {
                id: closeArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeTools()
            }
        }
    }

    Rectangle {
        id: musicBtn

        x: island.x + island.width + root.btnGap
        y: island.y
        width: root.pillH
        height: root.pillH
        radius: width / 2
        color: (root.mediaOpen || btnArea.containsMouse) ? Qt.tint(SideState.surface, SideState.cardHi) : SideState.surface
        border.width: 1
        border.color: root.mediaOpen ? SideState.primary : SideState.outline
        opacity: root.musicButtonVisible ? 1 : 0
        visible: opacity > 0.01
        scale: btnArea.pressed ? 0.92 : (btnArea.containsMouse ? 1.06 : 1)

        Behavior on color { ColorAnimation { duration: Constants.animFast } }
        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.3; epsilon: 0.002 } }

        SvgIcon {
            anchors.centerIn: parent
            icon: "music"
            iconSize: 16
            iconColor: root.mediaOpen ? SideState.primary : SideState.fg
            flat: true
        }

        HoverHandler {
            onHoveredChanged: {
                root.overButton = hovered;
                if (hovered)
                    closeTimer.stop();
                else
                    root.armClose();
            }
        }

        MouseArea {
            id: btnArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleMedia()
        }
    }

    Rectangle {
        id: toolsBtn

        x: island.x - width - root.btnGap
        y: root.gap
        width: root.pillH
        height: root.pillH
        radius: width / 2
        color: (root.toolsOpen || toolsArea.containsMouse) ? Qt.tint(SideState.surface, SideState.cardHi) : SideState.surface
        border.width: 1
        border.color: root.toolsView === "menu" ? SideState.primary : SideState.outline
        opacity: root.orbsVisible ? 1 : 0
        visible: opacity > 0.01
        scale: toolsArea.pressed ? 0.92 : (toolsArea.containsMouse ? 1.06 : 1)

        Behavior on color { ColorAnimation { duration: Constants.animFast } }
        Behavior on opacity { NumberAnimation { duration: Constants.animNormal } }
        Behavior on scale { SpringAnimation { spring: 3.2; damping: 0.3; epsilon: 0.002 } }

        SvgIcon {
            anchors.centerIn: parent
            icon: "capture"
            iconSize: 16
            iconColor: root.toolsView === "menu" ? SideState.primary : SideState.fg
            flat: true
        }

        HoverHandler {
            onHoveredChanged: {
                root.overTools = hovered;
                if (hovered)
                    closeTimer.stop();
                else
                    root.armClose();
            }
        }

        MouseArea {
            id: toolsArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleTools()
        }
    }

    component ToolCard: Rectangle {
        id: tc

        property string icon: ""
        property string label: ""
        signal activated()

        width: 172
        height: 68
        radius: 18
        color: tcArea.containsMouse ? Qt.tint(SideState.surface, SideState.cardHi) : Qt.tint(SideState.surface, SideState.card)
        border.width: 1
        border.color: SideState.outline

        Behavior on color { ColorAnimation { duration: Constants.animFast } }

        Row {
            anchors.centerIn: parent
            spacing: 9

            SvgIcon {
                anchors.verticalCenter: parent.verticalCenter
                icon: tc.icon
                iconSize: 18
                iconColor: SideState.primary
                flat: true
            }

            SideText {
                anchors.verticalCenter: parent.verticalCenter
                text: tc.label
                customSize: 12
            }
        }

        MouseArea {
            id: tcArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tc.activated()
        }
    }

    Timer {
        id: closeTimer

        interval: 500
        onTriggered: {
            if (root.overIsland || root.overButton || root.overTools)
                return;
            if (root.mediaOpen) {
                root.mediaOpen = false;
                AppState.closeWidget("music");
            }
            if (root.toolsView === "menu")
                root.toolsView = "";
        }
    }

    Timer {
        id: ccTimer

        interval: 600
        onTriggered: {
            if (!root.overCcBtn && !root.overCcPanel) {
                root.ccOpen = false;
                AppState.closeWidget("controlCenter");
            }
        }
    }

    Timer {
        id: idleTimer

        interval: 7000
        running: root.shown && !root.overIsland && !root.overButton && !root.overTools && !root.overCcBtn && !root.overCcPanel && !root.ccOpen && !root.toolsOpen && !root.mediaOpen && root.views.length > 1
        onTriggered: root.goIdle()
    }
}
