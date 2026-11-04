import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
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
    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.sideFamily && !DisplayProfileService.gameModeActive
    readonly property bool fullscreen: HyprlandService.isTrueFullscreen
    readonly property var centered: ["clipboard", "wallpaper", "powerMenu", "screenshot"]
    readonly property var keyboardWidgets: centered.concat(["launcher"])
    readonly property var handled: ["dashboard", "controlCenter", "notificationsCenter", "music", "calendar", "systemUsage", "launcher"].concat(centered)
    readonly property string activeId: (isActive && handled.indexOf(AppState.activeWidget) !== -1) ? AppState.activeWidget : ""
    readonly property bool open: activeId !== ""
    readonly property bool needsFocus: open && (keyboardWidgets.indexOf(activeId) !== -1 || (activeId === "dashboard" && !dashByHover))
    property string shownId: ""
    readonly property bool panelVisible: shownId !== ""
    readonly property bool isCentered: centered.indexOf(shownId) !== -1
    property var _pendingFocusItem: null
    property int _focusAttempts: 0
    property bool dashByHover: false
    property bool musicByHover: false
    readonly property bool hoverMusic: SettingsService.sideCfg("hover", "music")
    readonly property bool hoverDashboard: SettingsService.sideCfg("hover", "dashboard")
    readonly property bool hoverSession: SettingsService.sideCfg("hover", "session")
    readonly property bool hoverLauncher: SettingsService.sideCfg("hover", "launcher")
    readonly property real zoneThickness: Math.max(4, attached ? SideState.border : 4)

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

    readonly property bool island: SideState.island
    readonly property real pillAlong: SideState.pillCenter - (vertical ? insT : insL)
    readonly property string opposite: position === "left" ? "right" : (position === "right" ? "left" : (position === "top" ? "bottom" : "top"))

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
            refocus.restart();
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
        if (activeId !== "music")
            musicByHover = false;
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

    HyprlandFocusGrab {
        active: root.needsFocus
        windows: [root]
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

        interval: Math.max(Constants.animSlow + 80, 560)
        onTriggered: root.shownId = ""
    }

    Timer {
        id: refocus

        interval: 120
        onTriggered: {
            const it = keySink.activeItem;
            if (!root.needsFocus || !it)
                return ;
            const f = it.initialFocusItem ? (it.initialFocusItem.textField ? it.initialFocusItem.textField : it.initialFocusItem) : it;
            f.forceActiveFocus();
            console.log("side overlay focus: item=" + f + " activeFocus=" + f.activeFocus + " widget=" + root.activeId);
        }
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
                if (AppState.activeWidget === "dashboard")
                    AppState.closeWidget("dashboard");
            }
        }
    }

    Latch {
        id: musicLatch

        delay: 350
        wanted: root.isActive && !root.fullscreen && !root.island && root.hoverMusic && (SideState.musicHover || (root.musicByHover && panelDock.hovered))
        onOnChanged: {
            if (on && AppState.activeWidget === "") {
                root.musicByHover = true;
                AppState.openWidget("music");
            } else if (!on && root.musicByHover) {
                root.musicByHover = false;
                if (AppState.activeWidget === "music")
                    AppState.closeWidget("music");
            }
        }
    }

    Connections {
        target: AppState

        function onActiveWidgetChanged() {
            if (AppState.activeWidget === "" && dashLatch.on && !root.dashByHover && root.isActive && root.hoverDashboard) {
                root.dashByHover = true;
                AppState.openWidget("dashboard");
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

        enabled: root.hoverDashboard && root.position !== "top" && !root.island
        x: root.insL + (root.freeW - width) / 2
        y: 0
        width: 360
        height: root.zoneThickness
    }

    HotZone {
        id: hotSession

        enabled: root.hoverSession && root.position !== "right" && !root.island
        x: root.width - width
        y: root.insT + (root.freeH - height) / 2
        width: root.zoneThickness
        height: 220
    }

    HotZone {
        id: hotLauncher

        enabled: root.hoverLauncher && root.position !== "bottom" && !root.island
        x: root.insL + (root.freeW - width) / 2
        y: root.height - height
        width: 360
        height: root.zoneThickness
    }

    Item {
        id: keySink

        readonly property var activeItem: root.isCentered ? centerLoader.item : panelLoader.item
        readonly property var target: (activeItem && activeItem.initialFocusItem) ? activeItem.initialFocusItem : null

        focus: root.needsFocus
        Keys.enabled: root.needsFocus
        Keys.forwardTo: target ? (target.textField ? [target.textField, target] : [target]) : (activeItem ? [activeItem] : [])
        Keys.onEscapePressed: AppState.closeAllWidgets()
    }

    MouseArea {
        x: root.insL
        y: root.insT
        width: root.freeW
        height: root.freeH
        enabled: root.open
        onClicked: AppState.closeAllWidgets()
    }

    Item {
        id: stage

        x: root.insL
        y: root.insT
        width: root.freeW
        height: root.freeH
        clip: true

        SideDock {
            id: panelDock

            readonly property bool isDash: root.shownId === "dashboard"
            readonly property bool isLauncher: root.shownId === "launcher"
            property bool hovered: panelHover.hovered

            edge: isLauncher ? "bottom" : (root.island ? root.position : (isDash ? "top" : root.position))
            align: (isLauncher || (!root.island && isDash)) ? "center" : ((root.island && (root.shownId === "controlCenter" || root.shownId === "notificationsCenter")) ? "end" : (root.island ? "center" : "end"))
            center: (!root.island && root.shownId === "music" && SideState.musicCenter >= 0) ? SideState.musicCenter - (root.vertical ? root.insT : root.insL) : (root.island && !isLauncher && root.shownId !== "controlCenter" && root.shownId !== "notificationsCenter") ? root.pillAlong : -1
            open: root.open && !root.isCentered
            attached: root.attached
            rounding: SideState.rounding
            property real lastW: 0
            property real lastH: 0

            contentWidth: panelLoader.item ? panelLoader.item.implicitWidth : lastW
            contentHeight: panelLoader.item ? panelLoader.item.implicitHeight : lastH
            onContentWidthChanged: if (panelLoader.item) lastW = contentWidth
            onContentHeightChanged: if (panelLoader.item) lastH = contentHeight

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

        SideDock {
            id: sessionDock

            property bool hovered: sessionHover.hovered

            edge: root.island ? root.position : (root.position === "right" ? "left" : "right")
            align: "center"
            center: root.island ? root.pillAlong : -1
            padding: 14
            open: root.isActive && !root.island && sessionLatch.on
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

        SideDock {
            id: osdDock

            edge: root.opposite === "left" && root.position === "right" ? "left" : (root.position === "right" ? "left" : "right")
            align: "center"
            padding: 14
            open: root.isActive && !root.island && SettingsService.sideOsd && OsdService.isOpen && !root.open && !sessionLatch.on
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

    Rectangle {
        id: centerPanel

        readonly property int pad: (root.shownId === "powerMenu" || root.shownId === "screenshot") ? 0 : Constants.sizeLg
        readonly property bool dropDown: root.shownId === "wallpaper" || root.shownId === "screenshot"
        readonly property bool morphing: dropDown && root.island
        readonly property bool shownNow: root.open && root.isCentered
        readonly property real tw: Math.min(centerLoader.implicitWidth + pad * 2, root.freeW - 24)
        readonly property real th: Math.min(centerLoader.implicitHeight + pad * 2, root.freeH - 24)
        readonly property real gap: SideState.pillEdgeGap
        readonly property real pw: root.vertical ? SideState.pillThick : SideState.pillLen
        readonly property real ph: root.vertical ? SideState.pillLen : SideState.pillThick
        readonly property real px: root.vertical ? (root.position === "left" ? gap : root.width - gap - pw) : SideState.pillAlongStart
        readonly property real py: root.vertical ? SideState.pillAlongStart : (root.position === "top" ? gap : root.height - gap - ph)
        readonly property bool fromTop: root.shownId === "screenshot"
        readonly property real tx: fromTop ? Math.round(root.insL + (root.freeW - tw) / 2) : (root.vertical ? (root.position === "left" ? gap : root.width - gap - tw) : Math.max(12, Math.min(root.width - tw - 12, SideState.pillCenter - tw / 2)))
        readonly property real ty: fromTop ? root.insT + 12 : (root.vertical ? Math.max(12, Math.min(root.height - th - 12, SideState.pillCenter - th / 2)) : (root.position === "bottom" ? root.height - gap - th : gap))
        property real morph: shownNow ? 1 : 0

        visible: morphing ? morph > 0.005 : opacity > 0.01
        opacity: morphing ? 1 : (shownNow ? 1 : 0)
        transformOrigin: dropDown ? Item.Top : Item.Center
        scale: morphing ? 1 : (shownNow ? 1 : (dropDown ? 0.7 : 0.94))
        width: morphing ? pw + (tw - pw) * morph : tw
        height: morphing ? ph + (th - ph) * morph : th
        x: Math.round(morphing ? px + (tx - px) * morph : root.insL + (root.freeW - width) / 2)
        y: Math.round(morphing ? py + (ty - py) * morph : (dropDown ? root.insT + 12 : root.insT + (root.freeH - height) / 2))
        color: SideState.surface
        radius: morphing ? Math.min(width, height) / 2 + ((Constants.size3Xl - 4) - Math.min(width, height) / 2) * Math.pow(morph, 2) : Constants.size3Xl - 4
        border.width: 1
        border.color: SideState.outline

        Behavior on morph { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }
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
            opacity: centerPanel.morphing ? Math.max(0, (centerPanel.morph - 0.55) / 0.45) : 1
            active: root.panelVisible && root.isCentered
            sourceComponent: root.componentFor(root.shownId)
            onLoaded: root.prepare(item)
        }
    }

    Rectangle {
        id: toastBox

        x: root.width - root.insR - 12 - width
        y: root.insT + 12
        width: 380
        height: Math.max(toast.notifH, 64)
        radius: 22
        color: SideState.surface
        border.width: 1
        border.color: SideState.outline
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
        CaelDashboard {
            widget: widgetProxy
            maxWidth: stage.width - 2 * (SideState.rounding + 24)
        }
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
        CaelMediaMini { widget: widgetProxy }
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
        CaelLauncher { widget: widgetProxy }
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
