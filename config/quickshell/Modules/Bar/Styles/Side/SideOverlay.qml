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

// Hosts every widget (control center, dashboard, calendar, launcher, ...) and the notification
// toasts while the "side" bar style is active. Panels open next to the bar; focus widgets such as
// the launcher open centred. Mapped for the whole session, inert for the other styles.
PanelWindow {
    id: root

    required property var notificationService
    required property int barWidth

    readonly property string position: SettingsService.sideBarPosition
    readonly property bool vertical: position === "left" || position === "right"
    readonly property real gap: 4
    readonly property real margin: 12
    // free rectangle of the screen that is not the bar
    readonly property real freeX: position === "left" ? barWidth : 0
    readonly property real freeY: position === "top" ? barWidth : 0
    readonly property real freeW: width - (vertical ? barWidth : 0)
    readonly property real freeH: height - (vertical ? 0 : barWidth)

    readonly property bool isActive: SettingsService.settingsLoaded && SettingsService.barStyle === "side" && !DisplayProfileService.gameModeActive
    readonly property var centered: ["launcher", "clipboard", "wallpaper", "powerMenu", "screenshot"]
    readonly property var handled: ["dashboard", "controlCenter", "notificationsCenter", "music", "calendar", "systemUsage"].concat(centered)
    readonly property string activeId: (isActive && handled.indexOf(AppState.activeWidget) !== -1) ? AppState.activeWidget : ""
    readonly property bool open: activeId !== ""
    readonly property bool needsFocus: open && centered.indexOf(activeId) !== -1
    property string shownId: ""
    readonly property bool panelVisible: shownId !== ""
    property var _pendingFocusItem: null
    property int _focusAttempts: 0

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

        interval: Constants.animNormal + 40
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

    // click outside closes, Escape closes
    MouseArea {
        x: root.freeX
        y: root.freeY
        width: root.freeW
        height: root.freeH
        enabled: root.open
        focus: root.needsFocus
        Keys.onEscapePressed: AppState.closeAllWidgets()
        onClicked: AppState.closeAllWidgets()
    }

    // main panel, anchored to the bar edge
    Rectangle {
        id: panel

        readonly property bool isCentered: root.centered.indexOf(root.shownId) !== -1
        readonly property bool atStart: root.shownId === "dashboard"
        readonly property int pad: (root.shownId === "powerMenu" || root.shownId === "screenshot") ? 0 : Constants.sizeLg
        readonly property real maxW: root.freeW - 24
        readonly property real maxH: root.freeH - 24

        visible: opacity > 0.01
        opacity: root.open ? 1 : 0
        scale: root.open ? 1 : 0.94
        transformOrigin: {
            if (isCentered)
                return Item.Center;
            switch (root.position) {
            case "left": return Item.Left;
            case "right": return Item.Right;
            case "top": return Item.Top;
            default: return Item.Bottom;
            }
        }
        width: Math.min(content.implicitWidth + pad * 2, maxW)
        height: Math.min(content.implicitHeight + pad * 2, maxH)
        x: {
            if (isCentered)
                return Math.round((root.width - width) / 2);
            if (root.vertical)
                return root.position === "left" ? root.barWidth + root.gap : root.width - root.barWidth - root.gap - width;
            return atStart ? Math.round((root.width - width) / 2) : root.width - width - root.margin;
        }
        y: {
            if (isCentered)
                return Math.round((root.height - height) / 2);
            if (!root.vertical)
                return root.position === "top" ? root.barWidth + root.gap : root.height - root.barWidth - root.gap - height;
            return atStart ? root.margin : root.height - height - root.margin;
        }
        color: Theme.bg
        radius: Constants.size3Xl - 4
        border.width: 1
        border.color: Theme.border

        // slide in from the bar edge as well as scale
        property real slide: root.open ? 0 : 18
        transform: Translate {
            x: panel.isCentered || !root.vertical ? 0 : (root.position === "left" ? -panel.slide : panel.slide)
            y: panel.isCentered || root.vertical ? 0 : (root.position === "top" ? -panel.slide : panel.slide)
        }

        Behavior on slide { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutBack; easing.overshoot: 0.6 } }
        Behavior on height { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Loader {
            id: content

            anchors.fill: parent
            anchors.margins: panel.pad
            active: root.panelVisible
            sourceComponent: root.componentFor(root.shownId)
            onLoaded: root.prepare(item)
        }
    }

    // hover popout (Wi-Fi, Bluetooth, sound) beside the icon that opened it
    Rectangle {
        id: pop

        readonly property bool wanted: root.isActive && SideState.popout !== "" && !root.open
        property string shownPop: ""

        visible: opacity > 0.01
        opacity: wanted ? 1 : 0
        width: Math.min(popLoader.implicitWidth + Constants.sizeLg * 2, root.freeW - 24)
        height: Math.min(popLoader.implicitHeight + Constants.sizeLg * 2, root.freeH - 24)
        x: {
            if (root.vertical)
                return root.position === "left" ? root.barWidth + root.gap : root.width - root.barWidth - root.gap - width;
            return Math.max(root.margin, Math.min(root.width - width - root.margin, SideState.popoutCenter - width / 2));
        }
        y: {
            if (!root.vertical)
                return root.position === "top" ? root.barWidth + root.gap : root.height - root.barWidth - root.gap - height;
            return Math.max(root.margin, Math.min(root.height - height - root.margin, SideState.popoutCenter - height / 2));
        }
        color: Theme.bg
        radius: Constants.size3Xl - 4
        border.width: 1
        border.color: Theme.border

        onWantedChanged: if (wanted) shownPop = SideState.popout
        Connections {
            target: SideState

            function onPopoutChanged() {
                if (SideState.popout !== "")
                    pop.shownPop = SideState.popout;
            }
        }

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }
        Behavior on x { enabled: pop.opacity > 0.5; NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
        Behavior on y { enabled: pop.opacity > 0.5; NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Constants.animFast; easing.type: Easing.OutCubic } }

        HoverHandler {
            onHoveredChanged: hovered ? SideState.hold() : SideState.release()
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Loader {
            id: popLoader

            anchors.fill: parent
            anchors.margins: Constants.sizeLg
            active: pop.visible
            sourceComponent: pop.shownPop === "network" ? networkComp : (pop.shownPop === "bluetooth" ? bluetoothComp : (pop.shownPop === "audio" ? audioComp : null))
        }
    }

    // volume / brightness / mic feedback
    Rectangle {
        id: osd

        readonly property bool wanted: root.isActive && OsdService.isOpen && !root.open

        visible: opacity > 0.01
        opacity: wanted ? 1 : 0
        width: root.vertical ? 220 : 220
        height: 52
        radius: height / 2
        color: Theme.bg
        border.width: 1
        border.color: Theme.border
        x: root.vertical ? (root.position === "left" ? root.barWidth + root.gap : root.width - root.barWidth - root.gap - width) : Math.round((root.width - width) / 2)
        y: root.vertical ? Math.round(root.height - height - 48) : (root.position === "top" ? root.barWidth + root.gap : root.height - root.barWidth - root.gap - height)

        Behavior on opacity { NumberAnimation { duration: Constants.animNormal; easing.type: Easing.OutCubic } }

        SvgIcon {
            id: osdIcon

            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            icon: OsdService.icon
            iconSize: Constants.sizeLg
            iconColor: OsdService.isMuted ? Theme.muted : Theme.accent
            flat: true
        }

        Rectangle {
            visible: OsdService.showProgress
            anchors.left: osdIcon.right
            anchors.leftMargin: 12
            anchors.right: osdText.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            height: 6
            radius: 3
            color: Theme.bgSecondary

            Rectangle {
                width: parent.width * OsdService.level
                height: parent.height
                radius: 3
                color: OsdService.isMuted ? Theme.muted : Theme.accent

                Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
            }
        }

        ThemedText {
            id: osdText

            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: OsdService.valueText
            font.bold: true
        }

        ThemedText {
            visible: !OsdService.showProgress
            anchors.left: osdIcon.right
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: OsdService.title
        }
    }

    // notification toast, next to the bar
    Rectangle {
        id: toastBox

        x: root.vertical ? (root.position === "left" ? root.barWidth + 4 : root.width - root.barWidth - 4 - width) : Math.round((root.width - width) / 2)
        y: root.vertical ? 12 : (root.position === "top" ? root.barWidth + 4 : root.height - root.barWidth - 4 - height)
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
            x: root.freeX
            y: root.freeY
            width: root.panelVisible ? root.freeW : 0
            height: root.panelVisible ? root.freeH : 0
        }

        Region {
            x: pop.x
            y: pop.y
            width: pop.visible ? pop.width : 0
            height: pop.visible ? pop.height : 0
        }

        Region {
            x: toastBox.x
            y: toastBox.y
            width: toastBox.visible ? toastBox.width : 0
            height: toastBox.visible ? toastBox.height : 0
        }
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
        SideDashboard { widget: widgetProxy }
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
