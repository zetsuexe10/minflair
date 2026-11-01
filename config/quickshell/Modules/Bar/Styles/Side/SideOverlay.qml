import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Calendar
import qs.Modules.Clipboard
import qs.Modules.ControlCenter
import qs.Modules.Dashboard
import qs.Modules.Launcher
import qs.Modules.Music
import qs.Modules.NotificationCenter
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.SystemUsage as SystemUsageModule
import qs.Modules.WallpaperSelector

// Hosts every widget (control center, dashboard, calendar, launcher, ...), the hover popouts, the
// power panel, the volume/brightness indicator and the notification toasts of the "side" style.
// Panels grow out of the frame ("docks"); focus widgets such as the launcher open centred.
// Mapped for the whole session, inert for the other styles.
PanelWindow {
    id: root

    required property var notificationService

    readonly property string position: SideState.position
    readonly property bool vertical: position === "left" || position === "right"
    readonly property real insL: SideState.inset("left")
    readonly property real insR: SideState.inset("right")
    readonly property real insT: SideState.inset("top")
    readonly property real insB: SideState.inset("bottom")
    readonly property real freeW: width - insL - insR
    readonly property real freeH: height - insT - insB
    readonly property bool attached: SideState.frame
    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && !DisplayProfileService.gameModeActive
    readonly property bool fullscreen: HyprlandService.isTrueFullscreen
    readonly property var centered: ["launcher", "clipboard", "wallpaper", "powerMenu", "screenshot"]
    readonly property var handled: ["dashboard", "controlCenter", "notificationsCenter", "music", "calendar", "systemUsage"].concat(centered)
    readonly property string activeId: (isActive && handled.indexOf(AppState.activeWidget) !== -1) ? AppState.activeWidget : ""
    readonly property bool open: activeId !== ""
    readonly property bool needsFocus: open && centered.indexOf(activeId) !== -1
    property string shownId: ""
    readonly property bool panelVisible: shownId !== ""
    readonly property bool isCentered: centered.indexOf(shownId) !== -1
    property var _pendingFocusItem: null
    property int _focusAttempts: 0
    property bool dashByHover: false
    readonly property bool hoverDashboard: SettingsService.sideCfg("hover", "dashboard")
    readonly property bool hoverSession: SettingsService.sideCfg("hover", "session")
    readonly property bool hoverLauncher: SettingsService.sideCfg("hover", "launcher")
    readonly property real zoneThickness: Math.max(4, attached ? SideState.border : 4)

    // a flag that turns on at once and off after a short delay, so moving between a trigger and its panel does not flicker
    component Latch: QtObject {
        id: latch

        property bool wanted: false
        property int delay: 280
        property bool on: false
        property Timer timer: Timer {
            interval: latch.delay
            onTriggered: latch.on = false
        }

        onWantedChanged: {
            if (wanted) {
                timer.stop();
                on = true;
            } else {
                timer.restart();
            }
        }
    }

    component HotZone: Item {
        property alias hovered: hh.hovered

        HoverHandler {
            id: hh
        }
    }

    function componentFor(id) {
        switch (id) {
        case "dashboard": return dashboardComp;
        case "controlCenter": return controlCenterComp;
        case "notificationsCenter": return notificationsComp;
        case "music": return musicComp;
        case "calendar": return calendarComp;
        case "systemUsage": return systemUsageComp;
        case "launcher": return launcherComp;
        case "clipboard": return clipboardComp;
        case "wallpaper": return wallpaperComp;
        case "powerMenu": return powerMenuComp;
        case "screenshot": return screenshotComp;
        default: return null;
        }
    }

    function prepare(item) {
        if (!item)
            return;
        const resets = ["resetLauncher", "resetClipboard", "resetWallpaperSelector", "resetPowerMenu", "resetScreenCapture"];
        for (let i = 0; i < resets.length; i++)
            if (typeof item[resets[i]] === "function")
                item[resets[i]]();
        if (needsFocus) {
            _pendingFocusItem = item.initialFocusItem ? (item.initialFocusItem.textField ? item.initialFocusItem.textField : item.initialFocusItem) : item;
            _focusAttempts = 0;
            focusTimer.restart();
        }
    }

    onActiveIdChanged: {
        if (activeId !== "") {
            closeTimer.stop();
            shownId = activeId;
        } else {
            closeTimer.restart();
        }
        if (activeId !== "dashboard")
            dashByHover = false;
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "minflair-side-overlay"
    WlrLayershell.exclusionMode: ExclusionMode.Ignore
    WlrLayershell.keyboardFocus: needsFocus ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    focusable: needsFocus
    color: "transparent"
    visible: SettingsService.settingsLoaded

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    QtObject {
        id: widgetProxy

        property bool isOpen: root.open
        property int cornerRadius: 24
        property real openProgress: 1
        property real bounceProgress: 1

        function close() {
            AppState.closeAllWidgets();
        }
    }

    Timer {
        id: closeTimer

        interval: Constants.animSlow + 80
        onTriggered: root.shownId = ""
    }

    Timer {
        id: focusTimer

        interval: 30
        repeat: true
        onTriggered: {
            if (!root.needsFocus || !root._pendingFocusItem || root._pendingFocusItem.activeFocus || root._focusAttempts >= 10) {
                stop();
                return;
            }
            root._pendingFocusItem.forceActiveFocus();
            root._focusAttempts++;
        }
    }

    // ---- hover triggers on the frame ----------------------------------------------------------

    Latch {
        id: sessionLatch

        wanted: root.isActive && !root.fullscreen && root.hoverSession && (hotSession.hovered || sessionDock.hovered || SideState.sessionHover)
    }

    Latch {
        id: dashLatch

        delay: 350
        wanted: root.isActive && !root.fullscreen && root.hoverDashboard && (hotDash.hovered || (root.dashByHover && panelDock.hovered))
        onOnChanged: {
            if (on && AppState.activeWidget === "") {
                root.dashByHover = true;
                AppState.openWidget("dashboard");
            } else if (!on && root.dashByHover) {
                root.dashByHover = false;
                AppState.closeAllWidgets();
            }
        }
    }

    Connections {
        target: hotLauncher

        function onHoveredChanged() {
            if (hotLauncher.hovered && root.isActive && !root.fullscreen && root.hoverLauncher && AppState.activeWidget === "")
                AppState.openWidget("launcher");
        }
    }

    HotZone {
        id: hotDash

        enabled: root.hoverDashboard && root.position !== "top"
        x: root.insL + (root.freeW - width) / 2
        y: 0
        width: 360
        height: root.zoneThickness
    }

    HotZone {
        id: hotSession

        enabled: root.hoverSession && root.position !== "right"
        x: root.width - width
        y: root.insT + (root.freeH - height) / 2
        width: root.zoneThickness
        height: 220
    }

    HotZone {
        id: hotLauncher

        enabled: root.hoverLauncher && root.position !== "bottom"
        x: root.insL + (root.freeW - width) / 2
        y: root.height - height
        width: 360
        height: root.zoneThickness
    }

    // ---- stage: the screen minus the frame, panels live in here ---------------------------------

    // click outside closes, Escape closes
    MouseArea {
        x: root.insL
        y: root.insT
        width: root.freeW
        height: root.freeH
        enabled: root.open
        focus: root.needsFocus
        Keys.onEscapePressed: AppState.closeAllWidgets()
        onClicked: AppState.closeAllWidgets()
    }

    Item {
        id: stage

        x: root.insL
        y: root.insT
        width: root.freeW
        height: root.freeH
        clip: true

        // widgets, attached to the bar's edge (the dashboard hangs from the top edge)
        SideDock {
            id: panelDock

            readonly property bool isDash: root.shownId === "dashboard"
            property bool hovered: panelHover.hovered

            edge: isDash ? "top" : root.position
            align: isDash ? "center" : "end"
            open: root.open && !root.isCentered
            attached: root.attached
            rounding: SideState.rounding
            contentWidth: panelLoader.item ? panelLoader.item.implicitWidth : 0
            contentHeight: panelLoader.item ? panelLoader.item.implicitHeight : 0

            HoverHandler {
                id: panelHover
            }

            Loader {
                id: panelLoader

                anchors.fill: parent
                anchors.margins: panelDock.padding
                active: root.panelVisible && !root.isCentered
                sourceComponent: root.componentFor(root.shownId)
                onLoaded: root.prepare(item)
            }
        }

        // hover popouts (Wi-Fi, Bluetooth, sound, calendar, notifications) beside the icon that opened them
        SideDock {
            id: popDock

            readonly property bool wanted: root.isActive && SideState.popout !== "" && !root.open
            property string shownPop: ""
            property bool hovered: popHover.hovered

            edge: root.position
            center: SideState.popoutCenter - (root.vertical ? root.insT : root.insL)
            open: wanted
            attached: root.attached
            rounding: SideState.rounding
            contentWidth: popLoader.item ? popLoader.item.implicitWidth : 0
            contentHeight: popLoader.item ? popLoader.item.implicitHeight : 0
            onWantedChanged: if (wanted) shownPop = SideState.popout

            Connections {
                target: SideState

                function onPopoutChanged() {
                    if (SideState.popout !== "")
                        popDock.shownPop = SideState.popout;
                }
            }

            HoverHandler {
                id: popHover

                onHoveredChanged: hovered ? SideState.hold() : SideState.release()
            }

            Loader {
                id: popLoader

                anchors.fill: parent
                anchors.margins: popDock.padding
                active: popDock.shown
                sourceComponent: popDock.shownPop === "network" ? networkComp : (popDock.shownPop === "bluetooth" ? bluetoothComp : (popDock.shownPop === "audio" ? audioComp : (popDock.shownPop === "calendar" ? calendarPopComp : (popDock.shownPop === "notifications" ? notifPopComp : null))))
            }
        }

        // power panel on the right edge
        SideDock {
            id: sessionDock

            property bool hovered: sessionHover.hovered

            edge: "right"
            align: "center"
            padding: 14
            open: root.isActive && sessionLatch.on
            attached: root.attached
            rounding: SideState.rounding
            contentWidth: session.implicitWidth
            contentHeight: session.implicitHeight

            HoverHandler {
                id: sessionHover
            }

            SideSession {
                id: session

                x: sessionDock.padding
                y: sessionDock.padding
                onDone: sessionLatch.on = false
            }
        }

        // volume / brightness / microphone feedback on the right edge
        SideDock {
            id: osdDock

            edge: "right"
            align: "center"
            padding: 14
            open: root.isActive && SettingsService.sideOsd && OsdService.isOpen && !root.open && !sessionLatch.on
            attached: root.attached
            rounding: SideState.rounding
            contentWidth: osd.implicitWidth
            contentHeight: osd.implicitHeight

            SideOsd {
                id: osd

                x: osdDock.padding
                y: osdDock.padding
            }
        }
    }

    // focus widgets (launcher, clipboard, ...) float in the middle
    Rectangle {
        id: centerPanel

        readonly property int pad: (root.shownId === "powerMenu" || root.shownId === "screenshot") ? 0 : Constants.sizeLg

        visible: opacity > 0.01
        opacity: (root.open && root.isCentered) ? 1 : 0
        scale: (root.open && root.isCentered) ? 1 : 0.94
        width: Math.min(centerLoader.implicitWidth + pad * 2, root.freeW - 24)
        height: Math.min(centerLoader.implicitHeight + pad * 2, root.freeH - 24)
        x: Math.round(root.insL + (root.freeW - width) / 2)
        y: Math.round(root.insT + (root.freeH - height) / 2)
        color: Theme.bg
        radius: Constants.size3Xl - 4
        border.width: 1
        border.color: Theme.border

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Loader {
            id: centerLoader

            anchors.fill: parent
            anchors.margins: centerPanel.pad
            active: root.panelVisible && root.isCentered
            sourceComponent: root.componentFor(root.shownId)
            onLoaded: root.prepare(item)
        }
    }

    // notification toast, top right under the frame
    Rectangle {
        id: toastBox

        x: root.width - root.insR - 12 - width
        y: root.insT + 12
        width: 380
        height: Math.max(toast.notifH, 64)
        radius: 22
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        opacity: toast.opacity
        visible: toast.visible && root.isActive

        SideNotifLayer {
            id: toast

            property real shownProgress: (hasActiveNotifications && !isRemovingNotif && root.isActive) ? 1 : 0

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

    mask: Region {
        Region {
            x: root.insL
            y: root.insT
            width: (root.open || root.panelVisible) ? root.freeW : 0
            height: (root.open || root.panelVisible) ? root.freeH : 0
        }

        Region {
            x: stage.x + popDock.x
            y: stage.y + popDock.y
            width: popDock.shown ? popDock.width : 0
            height: popDock.shown ? popDock.height : 0
        }

        Region {
            x: stage.x + sessionDock.x
            y: stage.y + sessionDock.y
            width: sessionDock.shown ? sessionDock.width : 0
            height: sessionDock.shown ? sessionDock.height : 0
        }

        Region {
            x: toastBox.x
            y: toastBox.y
            width: toastBox.visible ? toastBox.width : 0
            height: toastBox.visible ? toastBox.height : 0
        }

        Region {
            x: hotDash.x
            y: hotDash.y
            width: hotDash.enabled ? hotDash.width : 0
            height: hotDash.enabled ? hotDash.height : 0
        }

        Region {
            x: hotSession.x
            y: hotSession.y
            width: hotSession.enabled ? hotSession.width : 0
            height: hotSession.enabled ? hotSession.height : 0
        }

        Region {
            x: hotLauncher.x
            y: hotLauncher.y
            width: hotLauncher.enabled ? hotLauncher.width : 0
            height: hotLauncher.enabled ? hotLauncher.height : 0
        }
    }

    Component {
        id: calendarPopComp
        CalendarWidget {}
    }

    Component {
        id: notifPopComp
        SideNotifPopout { notificationService: root.notificationService }
    }

    Component {
        id: networkComp
        SideNetworkPopout {}
    }

    Component {
        id: bluetoothComp
        SideBluetoothPopout {}
    }

    Component {
        id: audioComp
        SideAudioPopout {}
    }

    Component {
        id: dashboardComp
        CaelDashboard { widget: widgetProxy }
    }

    Component {
        id: controlCenterComp
        ControlCenterContent {
            widget: widgetProxy
            notificationService: root.notificationService
        }
    }

    Component {
        id: notificationsComp
        NotificationCenter {
            notificationService: root.notificationService
            controlCenterOpen: true
        }
    }

    Component {
        id: musicComp
        MiniMusicWidget { widget: widgetProxy }
    }

    Component {
        id: calendarComp
        CalendarWidget { widget: widgetProxy }
    }

    Component {
        id: systemUsageComp
        SystemUsageModule.SystemUsageContent { widget: widgetProxy }
    }

    Component {
        id: launcherComp
        LauncherContent { widget: widgetProxy }
    }

    Component {
        id: clipboardComp
        ClipboardContent { widget: widgetProxy }
    }

    Component {
        id: wallpaperComp
        WallpaperSelectorContent { widget: widgetProxy }
    }

    Component {
        id: powerMenuComp
        PowerMenuContent { widget: widgetProxy }
    }

    Component {
        id: screenshotComp
        ScreenCaptureContent { widget: widgetProxy }
    }
}
